# By mseng3
function Get-ADOUStructureObject {
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$OUDN,
		
		[string]$OutputFilePath,
		
		[ValidateSet("XML","Simplified")]
		[string]$OutputFormat = "XML",
		
		[switch]$IncludeGpoInheritance,
		
		[switch]$IncludeGpos,
		
		[switch]$IncludeComputers,
		
		[switch]$NoOuEndCap,
		
		[switch]$NoOuBrackets,
		
		[switch]$NoGpoBrackets,
		
		[string]$IndentChar = "`t",
		
		[switch]$Silent,
		
		[switch]$PassThru
	)
	
	$OUTPUT_FORMAT_CAPS = $false
	if(
		($OutputFormat -eq "XML")
	) {
		$OUTPUT_FORMAT_CAPS = $true
	}
	
	$SIMP_OU_START = "["
	$SIMP_OU_END = "]"
	$SIMP_INHBLK_START = "*"
	$SIMP_INHBLK_END = "*"
	$SIMP_INHGPO_START = "~"
	$SIMP_INHGPO_END = "~"
	$SIMP_GPO_START = "<"
	$SIMP_GPO_END = ">"
	$SIMP_COMP_START = ""
	$SIMP_COMP_END = ""
	
	function count($array) {
		$count = 0
		if($array) {
			# If we didn't check $array in the above if statement, this would return 1 if $array was $null
			# i.e. @().count = 0, @($null).count = 1
			$count = @($array).count
			# We can't simply do $array.count, because if it's null, that would throw an error due to trying to access a method on a null object
		}
		$count
	}
	
	function Get-Ous {
		if($PassThru) {
			$ous = Get-ADOrganizationalUnit -Filter "*" -SearchBase $OUDN
		}
		else {
			# For optimization if not outputting an object to the pipeline
			# Because the script actually only needs Name and DistinguishedName to function otherwise
			$ous = Get-ADOrganizationalUnit -Filter "*" -SearchBase $OUDN -Properties "Name","DistinguishedName" | Select Name,DistinguishedName | Sort Name
		}
		$ous
	}
	
	function Get-Comps {
		if($PassThru) {
			$comps = Get-ADComputer -Filter "*" -SearchBase $OUDN
		}
		else {
			# For optimization if not outputting an object to the pipeline
			# Because the script actually only needs Name and DistinguishedName to function otherwise
			$comps = Get-ADComputer -Filter "*" -SearchBase $OUDN -Properties "Name","DistinguishedName","Description","Enabled" | Select Name,DistinguishedName,Description,Enabled | Sort Name
		}
		$comps
	}
	
	function Get-Children($object) {
		$dn = $object.OU.DistinguishedName
		
		$children = $ous | Where { $_.DistinguishedName -eq "OU=$($_.Name),$dn" }
		
		$childObjects = @()
		foreach($child in $children) {
			$childDn = $child.DistinguishedName
			
			$childObject = [PSCustomObject]@{
				"OU" = $child
			}
			$grandChildren = Get-Children $childObject
			$childObject | Add-Member -NotePropertyName "Children" -NotePropertyValue $grandChildren
			
			$childComps = $comps | Where { $_.DistinguishedName -eq "CN=$($_.Name),$childDn" }
			$childObject | Add-Member -NotePropertyName "Computers" -NotePropertyValue $childComps
			
			$childObjects += @($childObject)
		}
		
		$childObjects
	}
	
	function Get-ExportFormatted($type, $data, $side, $inherited) {
		switch($OutputFormat) {
			"XML" {
				switch($type) {
					"gposCap" {
						switch($side) {
							"start" { return "<gpos>" }
							"end" { return "</gpos>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"gpoCap" {
						switch($side) {
							"start" { return "<gpo>" }
							"end" { return "</gpo>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"gpoName" { return "<name>$data</name>" }
					"gpoId" { return "<id>$data</id>" }
					"gpoEnabled" { return "<enabled>$data</enabled>" }
					"gpoEnforced" { return "<enforced>$data</enforced>" }
					"gpoOrder" { return "<order>$data</order>" }
					
					"compsCap" {
						switch($side) {
							"start" { return "<computers>" }
							"end" { return "</computers>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"compCap" {
						switch($side) {
							"start" { return "<computer>" }
							"end" { return "</computer>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"compName" { return "<name>$data</name>" }
					"compEnabled" { return "<enabled>$data</enabled>" }
					"compDescription" {
						# Descriptions can also contain other characters which break the XML format (e.g. "<", and ">", etc.).
						# So lets' make sure nothing in the description is ever parsed by putting it in inside CDATA tags.
						# https://www.w3schools.com/xml/dom_cdatasection.asp
						# This comes with the downside that the raw data inside the <description> tag now contains data which is not strictly representative of the raw description data. But that can just be a caveat to note in the readme, and it could easily be removed programmatically if necessary.
						# On the other hand this keeps the data in a human-readable format versus encoding it somehow.
						return "<description><![CDATA[$($data)]]></description>"
					}
					
					"ousCap" {
						switch($side) {
							"start" { return "<ous>" }
							"end" { return "</ous>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"ouCap" {
						switch($side) {
							"start" { return "<ou>" }
							"end" { return "</ou>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"ouName" { return "<name>$data</name>" }
					
					"gpoInheritanceCap" {
						switch($side) {
							"start" { return "<gpoInheritance>" }
							"end" { return "</gpoInheritance>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"gpoInheritanceBlocked" { return "<gpoInheritanceBlocked>$data</gpoInheritanceBlocked>" }
					"gpoInheritanceGposCap" {
						switch($side) {
							"start" { return "<inheritedGpos>" }
							"end" { return "</inheritedGpos>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"gpoInheritanceGpoCap" {
						switch($side) {
							"start" { return "<inheritedGpo>" }
							"end" { return "</inheritedGpo>" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					
					Default { return "Invalid `$type sent to Get-ExportFormatted()!" }
				}
			}
			"Simplified" {
				switch($type) {
					"gposCap" { return $null }
					"gpoCap" { return $null }
					"gpoName" {
						if($NoGpoBrackets) { return $data }
						else {
							if($inherited) { return "$($SIMP_INHGPO_START)$data$($SIMP_INHGPO_END)" }
							else { return "$($SIMP_GPO_START)$data$($SIMP_GPO_END)" }
						}
					}
					"gpoId" { return $null }
					"gpoEnabled" { return $null }
					"gpoEnforced" { return $null }
					"gpoOrder" { return $null }
					
					"compsCap" { return $null }
					"compCap" { return $null }
					"compName" { return $data }
					"compEnabled" { return $null }
					"compDescription" { return $null }
					
					"ousCap" { return $null }
					"ouCap" {
						switch($side) {
							"start" {
								if($NoOuBrackets) { return $data }
								else { return "$($SIMP_OU_START)$data$($SIMP_OU_END)" }
							}
							"end" {
								if($NoOuBrackets) { return "End $data" }
								else { return "End $($SIMP_OU_START)$data$($SIMP_OU_END)" }
							}
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"ouName" { return $null }
					
					"gpoInheritanceCap" { return $null}
					"gpoInheritanceBlocked" { return "$($SIMP_INHBLK_START)gpoInheritanceBlocked=$data$($SIMP_INHBLK_END)" }
					"gpoInheritanceGposCap" { return $null }
					"gpoInheritanceGpoCap" { return $null }
					
					Default { return "Invalid `$type sent to Get-ExportFormatted()!" }
				}
			}
			Default {
				return "Invalid `$OutputFormat!"
			}
		}
	}
	
	function Export-Header {
		$string = "Invalid `$OutputFormat!"
		
		switch($OutputFormat) {
			"Simplified" { $string = "Export of `"$OUDN`":" }
			"XML" { $string = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>" }
			Default { $string = "Invalid `$OutputFormat!" }
		}
		
		Export $string 0 $false
	}
	
	function Export-Structure($object) {
		Export-Header
		Export-Ou $object 0
	}
	
	function Export-Children($object, $indent) {
		
		if($IncludeGpoInheritance -or $IncludeGpos) {
			$object = Get-GpoInheritance $object
		}
		
		if($IncludeGpoInheritance) {
			Export-GpoInheritance $object $indent1
		}
		
		if($IncludeGpos) {
			Export-Gpos $object $indent
		}
			
		if($IncludeComputers) {
			Export-ChildComps $object $indent
		}
		
		Export-ChildOus $object $indent
	}
	
	function Get-GpoInheritance($object) {
		$dn = $object.OU.DistinguishedName
		
		# Workaround for a bug in Get-GpInheritance in PowerShell 7
		# https://techcommunity.microsoft.com/t5/windows-powershell/using-get-gpinheritance-command-in-powershell-7/m-p/2061936
		# https://github.com/PowerShell/PowerShell/issues/18519
		# -SkipEditionCheck fixes the issue, but this parameter doesn't exist before v7
		if($host.Version.Major -eq 7) {
			Import-Module -Name "GroupPolicy" -Force -SkipEditionCheck
		}
		else {
			Import-Module -Name "GroupPolicy" -Force
		}
		
		$gpoInheritance = Get-GpInheritance -Target $dn
		$object | Add-Member -NotePropertyName "GpoInheritance" -NotePropertyValue $gpoInheritance
		
		$object
	}
	
	function Export-Gpos($object, $indent, $inherited) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$gpos = $object.GpoInheritance.GpoLinks
		$gposCap = "gposCap"
		if($inherited) {
			$gpos = $object.GpoInheritance.InheritedGpoLinks
			# Remove GPOs that are directly linked to the given OU, as these are redundant
			$gpos = $gpos | Where { $_.Target -ne $OUDN }
			$gposCap = "gpoInheritanceGposCap"
		}
		
		$gposCapStart = Get-ExportFormatted $gposCap $null "start"
		$gposCapEnd = Get-ExportFormatted $gposCap $null "end"
		$gposCapStartEnd = $gposCapStart + $gposCapEnd
		
		if((count $gpos) -gt 0) {
			
			Export $gposCapStart $indent
			
			$gpos | ForEach-Object {
				$gpo = $_
				
				$gpoCapStart = Get-ExportFormatted "gpoCap" $null "start"
				$gpoName = Get-ExportFormatted "gpoName" $gpo.DisplayName $null $inherited
				$gpoEnabled = Get-ExportFormatted "gpoEnabled" $gpo.Enabled
				$gpoEnforced = Get-ExportFormatted "gpoEnforced" $gpo.Enforced
				$gpoOrder = Get-ExportFormatted "gpoOrder" $gpo.Order
				$gpoId = Get-ExportFormatted "gpoId" $gpo.GpoId
				$gpoCapEnd = Get-ExportFormatted "gpoCap" $null "end"
				
				$gpoLine = $gpoCapStart + $gpoName + $gpoEnabled + $gpoEnforced + $gpoOrder + $gpoId + $gpoCapEnd
				Export $gpoLine $indent1
			}
			
			Export $gposCapEnd $indent
		}
		else {
			Export $gposCapStartEnd $indent
		}
	}
	
	function Export-ChildComps($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$compsCapStart = Get-ExportFormatted "compsCap" $null "start"
		$compsCapEnd = Get-ExportFormatted "compsCap" $null "end"
		$compsCapStartEnd = $compsCapStart + $compsCapEnd
		
		if((count $object.Computers) -gt 0) {
			
			Export $compsCapStart $indent
			
			foreach($comp in $object.Computers) {
				
				$compCapStart = Get-ExportFormatted "compCap" $null "start"
				$compName = Get-ExportFormatted "compName" $comp.Name
				$compEnabled = Get-ExportFormatted "compEnabled" $comp.Enabled
				$compDescription = Get-ExportFormatted "compDescription" $comp.Description
				# Rarely, descriptions will contain newlines, which breaks the code folding ability of text editors (Notepad++ and VSCode at least).
				# There's no legitimate reason for newlines in a description, so just remove them.
				$compDescription = $compDescription.Replace("`n","")
				$compDescription = $compDescription.Replace("`r","")
				$compCapEnd = Get-ExportFormatted "compCap" $null "end"
				
				$compLine = $compCapStart + $compName + $compEnabled + $compDescription + $compCapEnd
				Export $compLine $indent1
			}
			
			Export $compsCapEnd $indent
		}
		else {
			Export $compsCapStartEnd $indent
		}
	}
	
	function Export-ChildOus($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$ousCapStart = Get-ExportFormatted "ousCap" $null "start"
		$ousCapEnd = Get-ExportFormatted "ousCap" $null "end"
		$ousCapStartEnd = $ousCapStart + $ousCapEnd
		
		if((count $object.Children) -gt 0) {
			Export $ousCapStart $indent
			foreach($child in $object.Children) {
				Export-Ou $child $indent1
			}
			Export $ousCapEnd $indent
		}
		else {
			Export $ousCapStartEnd $indent
		}
	}
	
	function Export-GpoInheritance($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$gpoInheritanceStart = Get-ExportFormatted "gpoInheritanceCap" $null "start"
		Export $gpoInheritanceStart $indent
		
		$gpoInheritanceBlocked = Get-ExportFormatted "gpoInheritanceBlocked" $object.GpoInheritance.GpoInheritanceBlocked
		Export $gpoInheritanceBlocked $indent1
		
		# Only list inherited GPOs at the parent level, as they are redundant otherwise
		if($object.OU.DistinguishedName -eq $OUDN) {
			Export-Gpos $object $indent1 $true
		}
		
		$gpoInheritanceEnd = Get-ExportFormatted "gpoInheritanceCap" $null "end"
		Export $gpoInheritanceEnd $indent
	}
	
	function Export-Ou($object, $indent) {
		
		#$indent1 = $indent
		#if($OUTPUT_FORMAT_CAPS) {
		#	$indent1 = $indent + 1
		#}
		$indent1 = $indent + 1
		
		$ouCapStart = Get-ExportFormatted "ouCap" $object.OU.Name "start"
		#Export $ouCapStart $indent
		
		$ouName = Get-ExportFormatted "ouName" $object.OU.Name
		#Export $ouName $indent1
		
		# Putting OU name on opening tag line (for XML output) for easier "foldability" when viewing in an XML editor (such as Notepad++)
		if($OutputFormat -ne "XML") {
			Export $ouCapStart $indent
			Export $ouName $indent1
		}
		else {
			$ouStartLine = $ouCapStart + $ouName
			Export $ouStartLine $indent
		}
		
		Export-Children $object $indent1
		
		if(
			-not(
				($OutputFormat -eq "Simplified" ) -and
				($NoOuEndCap)
			)
		) {
			$ouCapEnd = Get-ExportFormatted "ouCap" $object.OU.Name "end"
			Export $ouCapEnd $indent
		}
	}
	
	function Export($string, $indentSize=0, $append=$true, $nonewline=$false) {
		if($string -ne $null) {
			if($OutputFilePath) {
				if(!(Test-Path -PathType leaf -Path $OutputFilePath)) {
					New-Item -ItemType File -Force -Path $OutputFilePath | Out-Null
				}
			}
			
			$indent = ""
			for($i = 0; $i -lt $indentSize; $i += 1) {
				$indent = "$indent$IndentChar"
			}
			$string = "$indent$string"
			
			if($nonewline) {
				if(!$Silent) {
					$string | Write-Host -NoNewline
				}
				if($OutputFilePath) {
					if($append) {
						$string | Out-File $OutputFilePath -Encoding ascii -Append -NoNewline
					}
					else {
						$string | Out-File $OutputFilePath -Encoding ascii -NoNewline
					}
				}
			}
			else {
				if(!$Silent) {
					$string | Write-Host
				}
				if($OutputFilePath) {
					if($append) {
						$string | Out-File $OutputFilePath -Encoding ascii -Append
					}
					else {
						$string | Out-File $OutputFilePath -Encoding ascii
					}
				}
			}
		}
	}
	
	function Do-Stuff {
		if(
			(!$OutputFilePath) -and
			($Silent) -and
			(!$PassThru)
		) {
			Write-Host "No forms of output were requested. Aborting."
		}
		else {
			$ous = Get-Ous
			$comps = Get-Comps
			
			$object = [PSCustomObject]@{
				"OU" = $ous | Where { $_.DistinguishedName -eq $OUDN }
			}
			
			$children = Get-Children $object
			$object | Add-Member -NotePropertyName "Children" -NotePropertyValue $children
			
			$dn = $object.OU.DistinguishedName
			$childComps = $comps | Where { $_.DistinguishedName -eq "CN=$($_.Name),$dn" }
			$object | Add-Member -NotePropertyName "Computers" -NotePropertyValue $childComps
			
			Export-Structure $object
			
			if($PassThru) {
				$object
			}
		}
	}
	
	Do-Stuff
}