# By mseng3
function Get-ADOUStructureObject {
	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$OUDN,
		
		[string]$OutputFilePath,
		
		[ValidateSet("HumanReadable","XML")]
		[string]$OutputFormat = "HumanReadable",
		
		[string]$IndentChar = "	"
	)
	
	$OUTPUT_FORMAT_CAPS = $false
	if(
		($OutputFormat -eq "XML")
	) {
		$OUTPUT_FORMAT_CAPS = $true
	}
	
	$ous = Get-ADOrganizationalUnit -Filter "*" -SearchBase $OUDN
	$comps = Get-ADComputer -Filter "*" -SearchBase $OUDN
	
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
	
	function Print-Structure($object) {
		$object | ConvertTo-Json -Depth 3
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
					}
					"compsCap" { return $null }
					"ou" {
						switch($side) {
							"start" { return "[$name]" }
							"end" { return "End [$name]" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
					"ouCap" { return $null }
					"ousCap" { return $null }
					Default {
						return "Invalid `$type sent to Get-ExportFormatted()!"
					}
				}
			}
			"XML" {
				switch($type) {
					"comp" {
						return "<computer><name>$name</name></computer>"
					}
					"compCap" {
						# Currently doing this on the same line as each comp
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
					Default {
						return "Invalid `$type sent to Get-ExportFormatted()!"
					}
				}
			}
			Default {
				return "Invalid `$OutputFormat!"
			}
		}
	}
	
	function Export-Structure($object) {
		$name = $($object.OU.Name)
		$nameStart = Get-ExportFormatted "ou" $name "start" 
		$nameEnd = Get-ExportFormatted "ou" $name "end"
		
		Export $nameStart $false
		
		Export-Children $object 1
		
		Export $nameEnd
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
		$indent2 = $indent
		if($OUTPUT_FORMAT_CAPS) {
			$indent1 = $indent + 1
			$indent2 = $indent + 2
		}
		
		$ousCapStart = Get-ExportFormatted "ousCap" $null "start"
		Export $ousCapStart $indent
		
		foreach($child in $object.Children) {
			$ouCapstart = Get-ExportFormatted "ouCap" $null "start"
			Export $ouCapStart $indent1
			
			$name = $child.OU.Name
			
			$nameStart = Get-ExportFormatted "ou" $name "start" 
			Export $nameStart $indent2
			
			Export-Children $child $indent2
			
			$nameEnd = Get-ExportFormatted "ou" $name "end"
			Export $nameEnd $indent2
			
			$ouCapEnd = Get-ExportFormatted "ouCap" $null "end"
			Export $ouCapEnd $indent1
		}
		
		$ousCapEnd = Get-ExportFormatted "ousCap" $null "end"
		Export $ousCapEnd $indent
	}
	
	function Export($string, $indentSize, $append=$true) {
		if($string -ne $null) {
			if(!(Test-Path -PathType leaf -Path $OutputFilePath)) {
				New-Item -ItemType File -Force -Path $OutputFilePath | Out-Null
			}
			
			$indent = ""
			for($i = 0; $i -lt $indentSize; $i += 1) {
				$indent = "$indent$IndentChar"
			}
			$string = "$indent$string"
			
			if($append) {
				$string | Out-File $OutputFilePath -Encoding ascii -Append
			}
			else {
				$string | Out-File $OutputFilePath -Encoding ascii
			}
		}
	}
	
	function Do-Stuff {
		$object = [PSCustomObject]@{
			"OU" = $ous | Where { $_.DistinguishedName -eq $OUDN }
		}
		
		$children = Get-Children $object
		$object | Add-Member -NotePropertyName "Children" -NotePropertyValue $children
		
		$dn = $object.OU.DistinguishedName
		$childComps = $comps | Where { $_.DistinguishedName -eq "CN=$($_.Name),$dn" }
		$object | Add-Member -NotePropertyName "Computers" -NotePropertyValue $childComps
		
		#Print-Structure $object
		
		if($OutputFilePath) {
			Export-Structure $object
		}
	}
	
	Do-Stuff
}