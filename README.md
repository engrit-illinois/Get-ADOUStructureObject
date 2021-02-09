# THIS SCRIPT IS A WORK IN PROGRESS

# Summary
Takes an OU and returns an object containing all data about the OU and it's sub-OUs, retaining the OU structure. Optionally outputs structure to a file in simplified or XML format.  

# Usage
1. Download `Get-ADOUStructure.psm1`.
2. Import it as a module: `Import-Module "c:\path\to\Get-ADOUStructure.psm1"`
3. Run it, e.g.:
  - `Get-ADOUStructureObject "OU=Given OU,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"`
  - `Get-ADOUStructureObject -OUDN "OU=Given OU,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "c:\engrit\logs\Get-ADOUStructureObejct.xml" -OutputFormat "XML"

# Parameters

### -OUDN \<string\>
WIP

### -OutputFormat ["HumanReadable" | "XML"]
WIP

### -OutputFilePath \<string\>
WIP

### -IndentChar \<string\>
WIP

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.