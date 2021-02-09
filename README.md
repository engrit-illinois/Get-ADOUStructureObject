# THIS SCRIPT IS A WORK IN PROGRESS

# Summary
Takes an OU and returns an object containing all data about the OU and it's sub-OUs, retaining the OU structure. Optionally outputs structure to a file in simplified or XML format.  

# Usage
1. Download `Get-ADOUStructure.psm1`.
2. Import it as a module: `Import-Module "c:\path\to\Get-ADOUStructure.psm1"`
3. Run it, e.g.:
  - `Get-ADOUStructureObject "OU=Given OU,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"`
  - `Get-ADOUStructureObject -OUDN "OU=Given OU,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu" -OutputFilePath "c:\ou-structure.xml" -OutputFormat "XML"`

For a preview of what the output looks like, see [output-example.txt](output-example.txt) and [output-example.xml](output-example.xml).  

# Parameters

### -OUDN \<string\>
Required string.  
The DistinguishedName of the OU to output.  
The switch itself may be omitted if given as the first argument.  

### -OutputFormat ["HumanReadable" | "XML"]
Optional string from a set of predefined strings.  
The format of the output.  
Specifying `HumanReadable` outputs a simplified, custom format, designed for easy readability.  
Specifying `XML` outputs valid XML, with custom markup tags.  
Default is `HumanReadable`.  

### -OutputFilePath \<string\>
Optional string.  
The full file path to the output file.  
If omitted, no file will be written.  

### -IndentChar \<string\>
Optional string.  
The string to use as a single indentation.  
Default is a single tab character.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.