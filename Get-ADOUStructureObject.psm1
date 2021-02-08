# By mseng3
function Get-ADOUStructureObject {
	param(
		[string]$OUDN,
		[string]$OutputFilePath,
		[string]$OutputFormat = "Human",
		[string]$IndentChar = "	"
	)
	
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
	
	function Get-ExportFormatted($type, $name="cap", $side="comp") {
		switch($OutputFormat) {
			"Human" {
				switch($type) {
					"comp" {
						return $name
					}
					"ou" {
						switch($side) {
							"start" { return "[$name]" }
							"end" { return "End [$name]" }
							Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
						}
					}
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
					"ou" {
						switch($name) {
							"cap" {
								switch($side) {
									"start" { return "<ou>" }
									"end" { return "</ou>" }
									Default { return "Invalid `$side sent to Get-ExportFormatted()!" }
								}
							}
							Default {
								return "<name>$name</name>" }
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
	
	function Export-Children($object, $depth) {
			
		Export-ChildComps $object $depth
		
		Export-ChildOus $object $depth
	}
	
	function Export-ChildComps($object, $depth) {
		
		$indent = ""
		for($i = 0; $i -lt $depth; $i += 1) {
			$indent = "$indent$IndentChar"
		}
		
		$start = Get-ExportFormatted "comp" $null "start"
		Export "$indent$start"
		
		foreach($comp in $object.Computers) {
			if($OutputFormat -eq "XML") {
				$compIndent = "$indent$IndentChar"
			}
			$name = Get-ExportFormatted "comp" $comp.Name
			Export "$compIndent$name"
		}
		
		$end = Get-ExportFormatted "comp" $null "end"
		Export "$indent$end"
	}
	
	function Export-ChildOus($object, $depth) {
		
		$indent = ""
		for($i = 0; $i -lt $depth; $i += 1) {
			$indent = "$indent$IndentChar"
		}
		
		foreach($child in $object.Children) {
			$start = Get-ExportFormatted "ou" $null "start"
			Export "$indent$start"
			
			$name = $child.OU.Name
			$nameStart = Get-ExportFormatted "ou" $name "start" 
			$nameEnd = Get-ExportFormatted "ou" $name "end"
			
			Export "$($indent)$nameStart"
			Export-Children $child ($depth + 1)
			Export "$($indent)$nameEnd"
			
			$end = Get-ExportFormatted "ou" $null "end"
			Export "$indent$end"
		}
	}
	
	function Export($string, $append=$true) {
		if($string -ne $null) {
			if(!(Test-Path -PathType leaf -Path $OutputFilePath)) {
				New-Item -ItemType File -Force -Path $OutputFilePath | Out-Null
			}
			
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