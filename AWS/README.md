# AWS Route 53

Helper scripts for creating, managing zones and records in AWS Route 53 DNS

## Overview
PowerShell scripts for checking, creating, and managing zones in Route 53. Note that because we use white-label nameservers via delegation sets ([see wiki](http://intranet.cmgdigital.com/display/collaboration/White-label%2C+Vanity%2C+Private+Nameservers+on+Route+53+DNS)) , **YOU MUST** use the Create-R53HostedZone.ps1 script in this repo (or roll your own) to create a new zone. You can't use the AWS web console.

## Requirements
* PowerShell v5.0+ (required for automatic installation of AWSPowerShell module.  Otherwise, PowerShell 2.0+ is required for AWSPowerShell module.)
* AWSPowerShell:  Automatically installs upon first run.  Can be manually installed via https://aws.amazon.com/powershell/.

## Deployment Notes

### Get-R53HostedZones.ps1

The script has menus to walk you through it and allows for exporting the following data:
  All records within a single zone in a single AWS environment.
  All records within all zones in a single AWS environment.
  All zones (no records) in a single AWS environment.

The Get-R53HostedZones.ps1 usage looks like:

`.\Get-R53HostedZones`

### Create-R53HostedZone.ps1

The script has menus to walk you through it.  
If you'd prefer to create zones and records via a CSV file, the script will allow the importing of a CSV file in the following format:

<sub>ZoneName</sub> | <sub>RecordName</sub> | <sub>RecordType</sub> | <sub>RecordTTL</sub> | <sub>RecordData</sub>              | <sub>Environment </sub>
----------|------------|------------|-----------|-------------------------|-------------
 <sub>abcd.com</sub> | <sub>@</sub>          | <sub>A</sub>          | <sub>3600</sub>      | <sub>192.168.1.1,192.168.1.2</sub> | <sub>CMG-DST</sub>     
 <sub>abcd.com</sub> | <sub>www</sub>        | <sub>CNAME</sub>      | <sub>3600</sub>      | <sub>abcd.com</sub>                | <sub>CMG-DST  </sub>   
 <sub>abcd.com</sub> | <sub>www</sub>        | <sub>CNAME</sub>      | <sub>3600</sub>      | <sub>abcd.com</sub>                | <sub>CMGSandbox  </sub>

If you want to create multiple zones without creating records inside of them, you can use a CSV in the same format as above but the only required data is the ZoneName and Environment.   
   
The Create-R53HostedZone.ps1 script creates your zone in Route 53 using the correct delegation set (vanity nameservers), then updates the SOA and NS records so they match our standard.

If you're unsure about any of this, run the script against test/sandbox and check the results.

The Create-R53HostedZone.ps1 usage looks like:

`.\Create-R53HostedZone.ps1`

### Change-R53ResourceRecords.ps1

The script has menus to walk you through it and allows for the following actions:
  * Create DNS Records
  * Modify DNS Records
  * Delete DNS Records

Each record creation will ask for a ConflictAction:
  * Skip - If the record already exists, your change will be ignored.
  * Overwrite - If the record already exists, the value you inputted will overwrite the existing value.
  * Append - If the record already exists, the value you inputted will be appended to the existing value.
  
If you'd prefer to manage records via a CSV file, the script will allow the importing of a CSV file in the following format:

<sub>ZoneName</sub> | <sub>RecordName</sub> | <sub>RecordType</sub> | <sub>RecordTTL</sub> | <sub>RecordData</sub> | <sub>Environment</sub> | <sub>RecordAction</sub> | <sub>ConflictAction</sub> 
----------|------------|------------|-----------|-------------------------|-------------|--------------|----------------
 <sub>abcd.com</sub> | <sub>@</sub>          | <sub>A</sub>          | <sub>3600</sub>      | <sub>192.168.1.1,192.168.1.2</sub> | <sub>CMG-DST</sub>     | <sub>Create</sub>       | <sub>Overwrite</sub>      
 <sub>abcd.com</sub> | <sub>www</sub>        | <sub>CNAME</sub>      | <sub>3600</sub>      | <sub>abcd.com</sub>                | <sub>CMG-DST</sub>     | <sub>Create</sub>       | <sub>Overwrite</sub>      
 <sub>abcd.com</sub> | <sub>testrecord</sub> | <sub>CNAME</sub>      | <sub></sub>          | <sub></sub>                        | <sub>CMG-DST</sub>     | <sub>Delete</sub>       | <sub></sub>               
 <sub>abcd.com</sub> | <sub>record1</sub>    | <sub>A</sub>          | <sub>3600</sub>      | <sub>192.168.1.13</sub>            | <sub>CMG-DST</sub>     | <sub>Create</sub>       | <sub>Append</sub>         
 <sub>abcd.com</sub> | <sub>record2</sub>    | <sub>CNAME</sub>      | <sub>3600</sub>      | <sub>www.abcd.com</sub>            | <sub>CMG-DST</sub>     | <sub>Create</sub>       | <sub>Overwrite</sub>      
 <sub>test.com</sub> | <sub>@</sub>          | <sub>A</sub>          | <sub>3600</sub>      | <sub>192.168.1.1,192.168.1.2</sub> | <sub>CMGSandbox</sub>  | <sub>Create</sub>       | <sub>Skip</sub>           
 <sub>test.com</sub> | <sub>www</sub>        | <sub>A</sub>          | <sub>3600</sub>      | <sub>192.168.1.1,192.168.1.2</sub> | <sub>CMGSandbox</sub>  | <sub>Create</sub>       | <sub>Skip</sub>           
 <sub>test.com</sub> | <sub>record5</sub>    | <sub>A</sub>          | <sub></sub>          | <sub></sub>                        | <sub>CMGSandbox</sub>  | <sub>Delete</sub>       | <sub></sub>               
   
	
The Change-R53ResourceRecords.ps1 usage looks like:

`.\Change-R53ResourceRecords.ps1`
