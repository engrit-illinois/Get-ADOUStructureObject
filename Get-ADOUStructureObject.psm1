# By mseng3
function Get-ADOUStructureObject {
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$OUDN,
		
		[string]$OutputFilePath,
		
		[ValidateSet("HumanReadable","XML")]
		[string]$OutputFormat = "HumanReadable",
		
		[switch]$IncludeComputers,
		
		[switch]$IncludeGpos,
		
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
	
	function Get-GPOs {
		
		$gpos
	}
	
	function Get-Comps {
		if($PassThru) {
			$comps = Get-ADComputer -Filter "*" -SearchBase $OUDN
		}
		else {
			# For optimization if not outputting an object to the pipeline
			# Because the script actually only needs Name and DistinguishedName to function otherwise
			$comps = Get-ADComputer -Filter "*" -SearchBase $OUDN -Properties "Name","DistinguishedName" | Select Name,DistinguishedName | Sort Name
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
	
	function Get-ExportFormatted($type, $data, $side) {
		switch($OutputFormat) {
			"HumanReadable" {
				switch($type) {
					"gposCap" { return $null }
					"gpoCap" { return $null }
					"gpoName" {
						if($NoGpoBrackets) { return $data }
						else { return "<$data>" }
					}
					"gpoId" { return $null }
					"gpoEnabled" { return $null }
					"gpoEnforced" { return $null }
					"gpoOrder" { return $null }
					
					"compsCap" { return $null }
					"compCap" { return $null }
					"compName" { return $data }
					
					"ousCap" { return $null }
					"ouCap" {
						switch($side) {
							"start" {
								if($NoOuBrackets) { return $data }
								else { return "[$data]" }
							}
							"end" {
								if($NoOuBrackets) { return "End $data" }
								else { return "End [$data]" }
							}
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"ouName" { return $null }
					"ouGpoInheritanceBlocked" { return $null }
					
					Default { return "Invalid `$type sent to Get-ExportFormatted()!" }
				}
			}
			"XML" {
				switch($type) {
					"gposCap" {
						switch($side) {
							"start" { return "<gpos>" }
							"end" { return "</gpos>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"gpoCap" {
						switch($side) {
							"start" { return "<gpo>" }
							"end" { return "</gpo>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
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
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"compCap" {
						switch($side) {
							"start" { return "<computer>" }
							"end" { return "</computer>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"compName" { return "<name>$data</name>" }
					
					"ousCap" {
						switch($side) {
							"start" { return "<ous>" }
							"end" { return "</ous>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"ouCap" {
						switch($side) {
							"start" { return "<ou>" }
							"end" { return "</ou>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"ouName" { return "<name>$data</name>" }
					"ouGpoInheritanceBlocked" { return "<gpoInheritanceBlocked>$data</gpoInheritanceBlocked>" }
					
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
			"HumanReadable" { $string = "Export of `"$OUDN`":" }
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
		
		$gpoInheritance = Get-GpInheritance -Target $dn
		$object | Add-Member -NotePropertyName "GpoInheritance" -NotePropertyValue $gpoInheritance
		
		$object
	}
	
	function Export-Gpos($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$gposCapStart = Get-ExportFormatted "gposCap" $null "start"
		Export $gposCapStart $indent
		
		$object.GpoInheritance.GpoLinks | ForEach-Object {
			$gpo = $_
			
			$gpoCapStart = Get-ExportFormatted "gpoCap" $null "start"
			$gpoName = Get-ExportFormatted "gpoName" $gpo.DisplayName
			$gpoEnabled = Get-ExportFormatted "gpoEnabled" $gpo.Enabled
			$gpoEnforced = Get-ExportFormatted "gpoEnforced" $gpo.Enforced
			$gpoOrder = Get-ExportFormatted "gpoOrder" $gpo.Order
			$gpoId = Get-ExportFormatted "gpoId" $gpo.GpoId
			$gpoCapEnd = Get-ExportFormatted "gpoCap" $null "end"
			
			$gpoNameLine = $gpoCapStart + $gpoName + $gpoEnabled + $gpoEnforced + $gpoOrder + $gpoId + $gpoCapEnd
			Export $gpoNameLine $indent1
		}
		
		$gposCapEnd = Get-ExportFormatted "gposCap" $null "end"
		Export $gposCapEnd $indent
		
	}
	
	function Export-ChildComps($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$compsCapStart = Get-ExportFormatted "compsCap" $null "start"
		Export $compsCapStart $indent
		
		foreach($comp in $object.Computers) {
			
			$compCapStart = Get-ExportFormatted "compCap" $null "start"
			$compName = Get-ExportFormatted "compName" $comp.Name
			$compCapEnd = Get-ExportFormatted "compCap" $null "end"
			
			$compNameLine = $compCapStart + $compName + $compCapEnd
			Export $compNameLine $indent1
		}
		
		$compsCapEnd = Get-ExportFormatted "compsCap" $null "end"
		Export $compsCapEnd $indent
	}
	
	function Export-ChildOus($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$ousCapStart = Get-ExportFormatted "ousCap" $null "start"
		Export $ousCapStart $indent
		
		foreach($child in $object.Children) {
			Export-Ou $child $indent1
		}
		
		$ousCapEnd = Get-ExportFormatted "ousCap" $null "end"
		Export $ousCapEnd $indent
	}
	
	function Export-Ou($object, $indent) {
		
		#$indent1 = $indent
		#if($OUTPUT_FORMAT_CAPS) {
		#	$indent1 = $indent + 1
		#}
		$indent1 = $indent + 1
		
		$ouCapStart = Get-ExportFormatted "ouCap" $object.OU.Name "start"
		Export $ouCapStart $indent
		
		$ouName = Get-ExportFormatted "ouName" $object.OU.Name
		Export $ouName $indent1
		
		$object = Get-GpoInheritance $object
		$ouGpoInheritanceBlocked = Get-ExportFormatted "ouGpoInheritanceBlocked" $object.GpoInheritance.GpoInheritanceBlocked
		Export $ouGpoInheritanceBlocked $indent1
		
		Export-Children $object $indent1
		
		if(
			-not(
				($OutputFormat -eq "HumanReadable" ) -and
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