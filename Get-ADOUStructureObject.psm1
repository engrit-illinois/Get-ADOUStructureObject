# By mseng3
function Get-ADOUStructureObject {
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$OUDN,
		
		[string]$OutputFilePath,
		
		[ValidateSet("HumanReadable","XML")]
		[string]$OutputFormat = "HumanReadable",
		
		[string]$IndentChar = "`t",
		
		[switch]$Silent,
		
		[switch]$OutputObject
	)
	
	$OUTPUT_FORMAT_CAPS = $false
	if(
		($OutputFormat -eq "XML")
	) {
		$OUTPUT_FORMAT_CAPS = $true
	}
	
	function Get-Ous {
		if($OutputObject) {
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
		if($OutputObject) {
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
	
	function Get-ExportFormatted($type, $name, $side) {
		switch($OutputFormat) {
			"HumanReadable" {
				switch($type) {
					"comp" {
						return $name
					}
					"compCap" { 
						# Currently doing this on the same line as each comp
						return $null
					}
					"compsCap" { return $null }
					"ou" { return $null }
					"ouCap" {
						switch($side) {
							"start" { return "[$name]" }
							"end" { return "End [$name]" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"ousCap" { return $null }
					Default { return "Invalid `$type sent to Get-ExportFormatted()!" }
				}
			}
			"XML" {
				switch($type) {
					"comp" { return "<computer><name>$name</name></computer>" }
					"compCap" {
						# Currently doing this on the same line as each comp
						return $null
					}
					"compsCap" {
						switch($side) {
							"start" { return "<computers>" }
							"end" { return "</computers>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"ou" { return "<name>$name</name>" }
					"ouCap" {
						switch($side) {
							"start" { return "<ou>" }
							"end" { return "</ou>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
					"ousCap" {
						switch($side) {
							"start" { return "<ous>" }
							"end" { return "</ous>" }
							Default { return "Invalid `$side sent to t-ExportFormatted()!" }
						}
					}
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
		#$name = $($object.OU.Name)
		#$nameStart = Get-ExportFormatted "ou" $name "start" 
		#$nameEnd = Get-ExportFormatted "ou" $name "end"
		
		#Export $nameStart 0 $false
		#Export-Children $object 1
		#Export $nameEnd 0
		
		Export-Header
		
		Export-Ou $object 0
	}
	
	function Export-Children($object, $indent) {
			
		Export-ChildComps $object $indent
		
		Export-ChildOus $object $indent
	}
	
	function Export-ChildComps($object, $indent) {
		
		$indent1 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
		}
		
		$compsCapStart = Get-ExportFormatted "compsCap" $null "start"
		Export $compsCapStart $indent
		
		foreach($comp in $object.Computers) {
			
			# Combined compCap into comp line
			#$compCapStart = Get-ExportFormatted "compCap" $null "start"
			#Export $compCapStart $indent1
			
			$name = Get-ExportFormatted "comp" $comp.Name
			#Export $name indent1
			Export $name $indent1
			
			#$compCapEnd = Get-ExportFormatted "compCap" $null "end"
			#Export $compCapEnd $indent1
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
		
		$ouCapstart = Get-ExportFormatted "ouCap" $object.OU.Name "start"
		if($OUTPUT_FORMAT_CAPS) {
			# Putting the <name> tag on the same line as <ou> for condensed readability
			Export $ouCapStart $indent $true $true
		}
		else {
			Export $ouCapStart $indent
		}
		
		
		$name = Get-ExportFormatted "ou" $object.OU.Name
		if($OUTPUT_FORMAT_CAPS) {
			# Putting the <name> tag on the same line as <ou> for condensed readability
			Export $name 0
		}
		else {
			Export $name $indent1
		}
		
		Export-Children $object $indent1
		
		$ouCapEnd = Get-ExportFormatted "ouCap" $object.OU.Name "end"
		Export $ouCapEnd $indent
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
			(!$OutputObject)
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
			
			if($OutputObject) {
				$object
			}
		}
	}
	
	Do-Stuff
}