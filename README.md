# Summary
Takes an OU and prints a visual, textual representation of the OU and it's sub-OUs and computers, retaining the OU structure. Optionally outputs to a file in simplified or XML format. Optionally outputs a Powershell object to the pipeline containing all of the data about all sub-OUs, computer objects, and GPO links, including GPO inheritance information.  

This module was originally written as a helper function for [Get-RdcmanFileForOu](https://github.com/engrit-illinois/Get-RdcmanFileForOu), but has been expanded to additionally act as a way to quickly back up OU configuration data to a file, with the goal of easily referencing past states in a human-digestible format, to aid in manual reconstruction in the case of accidental deletion/corruption, etc. Currently the data exported to file is intentionally incomplete and heavily curated.  

# Usage
1. Download `Get-ADOUStructure.psm1` to the appropriate subdirectory of your PowerShell [modules directory](https://github.com/engrit-illinois/how-to-install-a-custom-powershell-module).
2. Run it using the examples and documentation provided below.

# Examples
For brevity and clarity, the examples below use the `$oudn` variable to represent the full OUDN being specified. If you want to preview the output for these examples, you may use the following value for `$oudn`, which refers to a test OU set up specifically to test this module's functionality:  
`$oudn = "OU=export-test-ou,OU=mseng3,OU=Staff Desktops,OU=NoInheritance,OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"`  

Some pre-generated previews are provided in [output-example.txt](output-example.txt) and [output-example.xml](output-example.xml).  

### XML format examples

OU structure only:  
`Get-ADOUStructureObject $oudn`  

OU structure + computer objects:  
`Get-ADOUStructureObject $oudn -IncludeComputers`  

OU structure + computer objects + GPOs:  
`Get-ADOUStructureObject $oudn -IncludeComputers -IncludeGpos`  

OU structure + computer objects + GPOs + GPO inheritance:  
`Get-ADOUStructureObject $oudn -IncludeComputers -IncludeGpos -IncludeGpoInheritance`  

Output everything to a file in XML format:  
`Get-ADOUStructureObject $oudn -IncludeComputers -IncludeGpos -IncludeGpoInheritance -OutpuFilePath "c:\ou-structure.xml"`  

### Simplified format examples

OU structure only:  
`Get-ADOUStructureObject $oudn -OutputFormat "Simplified"`  

OU structure + computer objects:  
`Get-ADOUStructureObject $oudn -OutputFormat "Simplified" -IncludeComputers`  

OU structure + computer objects + GPOs:  
`Get-ADOUStructureObject $oudn -OutputFormat "Simplified" -IncludeComputers -IncludeGpos`  

OU structure + computer objects + GPOs + GPO inheritance:  
`Get-ADOUStructureObject $oudn -OutputFormat "Simplified" -IncludeComputers -IncludeGpos -IncludeGpoInheritance`  

Output everything to a file in simplified format:  
`Get-ADOUStructureObject $oudn -OutputFormat "Simplified" -IncludeComputers -IncludeGpos -IncludeGpoInheritance -OutpuFilePath "c:\ou-structure.txt"`  

### Dump entire Instructional OU to an XML file
```powershell
$oudn = "OU=Instructional,OU=Desktops,OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu"
$ts = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
Get-ADOUStructureObject $oudn -IncludeComputers -IncludeGpos -IncludeGpoInheritance -Silent -OutputFilePath "c:\engrit\ews\Instructional OU Backups\Instructional-OU-Export_$($ts).xml"
```

# Parameters

### -OUDN \<string\>
Required string.  
The DistinguishedName of the OU to output.  
The switch itself may be omitted if given as the first argument.  

### -OutputFormat ["XML" | "Simplified"]
Optional string from a set of predefined strings.  
The format of the output.  
Specifying `XML` outputs valid XML, with custom markup tags. See `output-example.xml` for an example.  
Specifying `Simplified` outputs a simplified, custom format, designed for easier readability. See `output-example.txt` for an example.  
When using `Simplified` format, the following syntax is used to denote different types of objects:
  - `[GPO Name]`
  - `*gpoInheritanceBlocked=<True|False>*`
  - `~Inherted GPO Name~`
  - `<Linked GPO Name>`
  - `computer-name` (i.e. no special characters)

Default is `XML`.  
Note: When using `-OutputFormat "XML"` with `-IncludeComputers`, the computer object description data captured in the XML output is "sanitized" by wrapping it all in [CDATA](https://www.w3schools.com/xml/dom_cdatasection.asp) tags, so that it can contain characters such as `<` and `>`, etc. without breaking the XML formatting. This comes with the downside that the raw data inside the `<description>` tags will contain extraneous characters (`<![CDATA[` and `]]>`) wrapping the raw description data. But these can be easily targeted and removed programmatically if necessary. However this keeps the data in a human-readable format versus encoding it somehow.  

### -IncludeComputers
Optional switch.  
If specified, the output will additionally include representations of child computer objects present in the target OU(s).  
In `Simplified` format, the data includes only the computer names.  
In `XML` format, the data additionally includes the computer objects' enabled status and description.  

### -IncludeGpos
Optional switch.  
If specified, the output will additionally include representations of GPOs directly linked to the target OU(s).  
In `Simplified` format, the data includes only the GPO names.  
In `XML` format, that data additionally includes the links' enabled and enforced statuses, the links' orders, and the GPOs' GUIDs.  

### -IncludeGpoInheritance
Optional switch.  
If specified, the output will additionally include representations of the state of GPO inheritance blocking for the target OU(s), and GPO links inherited from above the given parent OU.  
In `Simplified` format, the data includes only the GPO names.  
In `XML` format, that data additionally includes the links' enabled and enforced statuses, the links' orders, and the GPOs' GUIDs.  

### -NoOuEndCap
Optional switch.  
By default, regardless of the value of `-OutputFormat`, the output includes "end caps" (i.e. closing tags) for OUs, to denote where they end after their list of child computer objects.  
If specified, and `-OutputFormat` is specified as `HumanReadable`, the output will omit the OU "end caps".  
Has no effect if `-OutputFormat` is not specified as `HumanReadable`, as closing tags are required for XML syntax.  

### -NoOuBrackets
Optional switch.  
By default, if `-OutputFormat` is specified as `HumanReadable`, the output includes square brackets around OU names, to differentiate them from child computer objects.  
If specified, and `-OutputFormat` is specified as `HumanReadable`, the output will omit the square brackets.  
Has no effect if `-OutputFormat` is not specified as `HumanReadable`, as square brackets are not used in the XML syntax.  

### -OutputFilePath \<string\>
Optional string.  
The full file path to the output file.  
If omitted, no file will be written.  

### -IndentChar \<string\>
Optional string.  
The string to use as a single indentation.  
Default is a single tab character.  

### -Silent
Optional switch.  
If specified, nothing is written to the console.  
By default, the same output that would be written to a file is also written to the console.  
For large OUs, the default output behavior can be somewhat pointless, as it may overrun the console buffer, especially if using a default buffer size.  

### -PassThru
Optional switch.  
If specified, the object which the script uses to store all of the gathered data is output to the pipeline, for you to do with as you see fit.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
