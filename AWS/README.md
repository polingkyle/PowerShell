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

<sub>ZoneName | RecordName | RecordType | RecordTTL | RecordData              | Environment </sub>
----------|------------|------------|-----------|-------------------------|-------------
 <sub>abcd.com</sub> | @          | A          | 3600      | 192.168.1.1,192.168.1.2 | CMG-DST     
 <sub>abcd.com | www        | CNAME      | 3600      | abcd.com                | CMG-DST  </sub>   
 <sub>abcd.com | www        | CNAME      | 3600      | abcd.com                | CMGSandbox  </sub>

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

ZoneName | RecordName | RecordType | RecordTTL | RecordData              | Environment | RecordAction | ConflictAction 
----------|------------|------------|-----------|-------------------------|-------------|--------------|----------------
 abcd.com | @          | A          | 3600      | 192.168.1.1,192.168.1.2 | CMG-DST     | Create       | Overwrite      
 abcd.com | www        | CNAME      | 3600      | abcd.com                | CMG-DST     | Create       | Overwrite      
 abcd.com | testrecord | CNAME      |           |                         | CMG-DST     | Delete       |                
 abcd.com | record1    | A          | 3600      | 192.168.1.13            | CMG-DST     | Create       | Append         
 abcd.com | record2    | CNAME      | 3600      | www.abcd.com            | CMG-DST     | Create       | Overwrite      
 test.com | @          | A          | 3600      | 192.168.1.1,192.168.1.2 | CMGSandbox  | Create       | Skip           
 test.com | www        | A          | 3600      | 192.168.1.1,192.168.1.2 | CMGSandbox  | Create       | Skip           
 test.com | record5    | A          |           |                         | CMGSandbox  | Delete       |                
   
	
The Change-R53ResourceRecords.ps1 usage looks like:

`.\Change-R53ResourceRecords.ps1`
