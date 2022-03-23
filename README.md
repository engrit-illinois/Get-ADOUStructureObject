# Summary
Takes an OU and prints a visual, textual representation of the OU and it's sub-OUs and computers, retaining the OU structure. Optionally outputs to a file in simplified or XML format. Optionally outputs a Powershell object to the pipeline containing all of the data about all OUs and computers discovered, which also retains the OU structure.  

# Usage
1. Download `Get-ADOUStructure.psm1` to `$HOME\Documents\WindowsPowerShell\Modules\Get-ADOUStructure\Get-ADOUStructure.psm1`.
2. Run it, e.g.:
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
Has no effect if `-OutputFilePath` is not specified.  

### -OusOnly
Optional switch.  
By default the output includes child computer objects.  
If specified, the output will omit child computers, and will contain only OUs.  

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
For large OUs, this can be somewhat pointless, as it may overrun the console buffer, especially if using a default buffer size.  

### -OutputObject
Optional switch.  
If specified, the object which the script uses to store all of the gathered data is output to the pipeline, for you to do with as you see fit.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
