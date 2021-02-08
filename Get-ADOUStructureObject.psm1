# By mseng3
function Get-ADOUStructureObject {
	param(
		[string]$OUDN,
		[string]$OutputFilePath
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
	
	function Export-Structure($object) {
		$name = $($object.OU.Name)
		
		Export "Start OU: $name" $false
		
		Export-Children $object 1
		
		Export "End OU: $name"
	}
	
	function Export-Children($object, $depth) {
			
		Export-ChildComps $object $depth
		
		Export-ChildOus $object $depth
	}
	
	function Export-ChildComps($object, $depth) {
		
		$indent = ""
		for($i = 0; $i -lt $depth; $i += 1) {
			$indent = "$indent	"
		}
		
		foreach($comp in $object.Computers) {
			$name = $comp.Name
			Export "$indent$name"
		}
	}
	
	function Export-ChildOus($object, $depth) {
		
		$indent = ""
		for($i = 0; $i -lt $depth; $i += 1) {
			$indent = "$indent	"
		}
		
		foreach($child in $object.Children) {
			$name = $child.OU.Name
			Export "$($indent)Start OU: $name"
			Export-Children $child ($depth + 1)
			Export "$($indent)End OU: $name"
		}
	}
	
	function Export($string, $append=$true) {
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