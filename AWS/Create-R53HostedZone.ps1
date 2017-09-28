#region Script Info/Changelog 
######################################################################################
# Written by Kyle Poling                                                             #
# September 27, 2017                                                                 #
#                                                                                    #
# Create-R53HostedZone.ps1                                                           #
#            Version 1 (09/27/2017)                                                  #
#                                                                                    #
# Allow users to create a Hosted Zone and records                                    #
#     within AWS Route 53.                                                           #
#                                                                                    #
# CHANGELOG:                                                                         #
#   V1  (09/27/17) - Initial script creation                                         #
#                                                                                    #
######################################################################################
#endregion Script Info/Changelog


#region Script Validation Testing
#    |------------------------------------------------------------------------------------| #
#    |   Zones   |  Environments  |  Records  | CSV |      Note           |  Test Result  | #
#    |====================================================================================| #
# 1  |  Single   |    Single      |   No      | No  |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 2  |  Single   |    Single      |   No      | Yes |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 3  |  Single   |    Single      |   Yes     | Yes |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 4  | Multiple  |    Single      |   No      | Yes |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 5  | Multiple  |    Single      |   Yes     | Yes |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 6  | Multiple  |    Multiple    |   No      | Yes |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 7  | Multiple  |    Multiple    |   Yes     | Yes |                     |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 8  | Single    |    Single      |   No      | No  | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 9  | Single    |    Single      |   No      | Yes | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 10 | Single    |    Single      |   Yes     | Yes | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 11 | Multiple  |    Single      |   No      | Yes | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 12 | Multiple  |    Single      |   Yes     | Yes | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 13 | Multiple  |    Multiple    |   No      | Yes | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 14 | Multiple  |    Multiple    |   Yes     | Yes | Zone already exists |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 15 | Single    |    Single      |   No      | Yes | Missing CSV Data    |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 16 | Single    |    Single      |   Yes     | Yes | Missing CSV Data    |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 17 | Multiple  |    Single      |   No      | Yes | Missing CSV Data    |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 18 | Multiple  |    Single      |   Yes     | Yes | Missing CSV Data    |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 19 | Multiple  |    Multiple    |   No      | Yes | Missing CSV Data    |   GOOD        | #
#    |-----------|----------------|-----------|-----|---------------------|---------------| #
# 20 | Multiple  |    Multiple    |   Yes     | Yes | Missing CSV Data    |   GOOD        | #
#    |------------------------------------------------------------------------------------| #
#endregion Script Validation Testing

#region Script

#region Verify script validity
$currentUser = $env:USERNAME
$Script = $MyInvocation.MyCommand.Definition
$Email = "Kyle.Poling@coxinc.com"
If ((Get-AuthenticodeSignature $Script).Status -ne "Valid") {
    Send-MailMessage -SmtpServer mail.coxmediagroup.com -Subject "$Script tampered with and will not run on $env:computername - $currentUser" -From $Email -To $Email
#    BREAK
#    EXIT
}
#endregion Verify script validity

#region Set PoSh Window Details
Clear-Host
Write-Host "Setting up script parameters..."
Write-Host "Please wait..."
$pshost = get-host
$pswindow = $pshost.ui.rawui
$pswindow.ForegroundColor = "White"
$pswindow.BackgroundColor = "Black"
$pswindow.windowtitle = "Create Route 53 Hosted Zone"
$newsize = $pswindow.buffersize
$newsize.height = 3000
$newsize.width = 130
$pswindow.buffersize = $newsize
$newsize = $pswindow.windowsize
$newsize.height = 55
$newsize.width = 130
$pswindow.windowsize = $newsize
$colors = $host.PrivateData
$colors.WarningForegroundColor = "White"
$colors.WarningBackgroundColor = "Black"
$WarningActionPreference="SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
If (!(Get-Module AWSPowerShell -ErrorAction SilentlyContinue)) { 
    Write-Host "Importing AWSPowerShell module..."
    Import-Module AWSPowerShell -ErrorAction SilentlyContinue
    If (!(Get-Module AWSPowerShell -ErrorAction SilentlyContinue)) { 
        Write-Host "AWSPowerShell module is not installed."
        Write-Host "Installing now..."
        Install-Package -Name AWSPowerShell -Force
        Write-Host "Importing AWSPowerShell module..."
        Import-Module AWSPowerShell 
    }
}
If (!(Get-Module AWSPowerShell -ErrorAction SilentlyContinue)) { 
    Write-Host "AWSPowerShell Module could not be found" -Background Black -Foreground Red
    Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    BREAK
}
#endregion Set PoSh Window Details

Do {
    #region Set Initial variables
    $CurrentUser = $env:username
    $More = "Yes"
    $InitialOption = $NULL
    $CreationChoice = $NULL
    $EnvOption = $NULL
    $Environment = $NULL
    $ZoneName = $NULL
    $Zone = $NULL
    $R53Data = @()
    $AllR53Records = @()
    $Date = Get-Date -Format "MMddyy_HHmmss"
    $DelegationContinue = $NULL
    $DelegContinue = $NULL
    $R53ZonesAndEnv = @()
    #endregion Set Initial variables
    
    #region Gather Variables
    #region Initial Menu
    Clear-Host
    Write-Host "`r"
    Write-Host "  ****************************************************************`r"
    Write-Host "                Create Route 53 Hosted Zone`r"
    Write-Host "  ****************************************************************`r"
    Write-Host "`r"
    Write-Host "    Would you like to create Resource Records while `r"
    Write-Host "           creating the Hosted Zone? `r"
    Write-Host "`r"
    Write-Host "`r"
    Write-Host "       1 -   Yes (CSV required) `r"
    Write-Host "       2 -   No [Default] `r"
    Write-Host "`r"
    Write-Host "`r"
    Write-Host "  ****************************************************************`r"
    Write-Host "Type your choice -  1/2 `r" -ForegroundColor Yellow
    $InitialOption = Read-Host
    Write-Host "`r"
    If ($InitialOption -eq "1"){
        $CreationChoice = "CreateRecords"
    }
    ElseIf ($InitialOption -eq "2" -or $InitialOption -eq "" -or $InitialOption -eq $NULL){
        $CreationChoice = "ZoneOnly"
    }
    Else {
        Write-Host "`r"
        Write-Host " Non-option selected`r"
        Write-Host " Ending Program...`r"
        Write-Host "`r"
        Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        BREAK
    }
    Write-Host "`r"
    Clear-Host
    #endregion Initial Menu
    
    #region Zone-only Creation 
    If ($CreationChoice -eq "ZoneOnly") {
        #region Account Selection Menu 
        Write-Host "`r"
        Write-Host "  ****************************************************************`r"
        Write-Host "                Create Route 53 Hosted Zone`r"
        Write-Host "  ****************************************************************`r"
        Write-Host "`r"
        Write-Host "    Which AWS environment will you be working in? `r"
        Write-Host "`r"
        Write-Host "`r"
        Write-Host "       1 -   CMGSandbox [Default] `r"
        Write-Host "       2 -   CMG-DST (Prod) `r"
        Write-Host "       3 -   VideaSandbox `r"
        Write-Host "       4 -   VideaDev `r"
        Write-Host "       5 -   VideaRnD `r"
        Write-Host "       6 -   VideaQA `r"
        Write-Host "       7 -   VideaProd `r"
        Write-Host "       8 -   AJCNewsApp `r"
        Write-Host "`r"
        Write-Host "`r"
        Write-Host "  ****************************************************************`r"
        Write-Host "Type your choice -  1/2/3/4/5/7/8 `r" -ForegroundColor Yellow
        $EnvOption = Read-Host
        Write-Host
        If ($EnvOption -eq "1" -or $EnvOption -eq "CMGSandbox" -or $EnvOption -eq "" -or $EnvOption -eq $NULL){
            $Environment = "CMGSandbox"
        }
        ElseIf ($EnvOption -eq "2" -or $EnvOption -eq "CMG-DST" -or $EnvOption -eq "CMGDST"){
            $Environment = "CMG-DST"
        }
        ElseIf ($EnvOption -eq "3" -or $EnvOption -eq "VideaSandbox"){
            $Environment = "VideaSandbox"
        }
        ElseIf ($EnvOption -eq "4" -or $EnvOption -eq "VideaDev"){
            $Environment = "VideaDev"
        }
        ElseIf ($EnvOption -eq "5" -or $EnvOption -eq "VideaRnD"){
            $Environment = "VideaRnD"
        }
        ElseIf ($EnvOption -eq "6" -or $EnvOption -eq "VideaQA"){
            $Environment = "VideaQA"
        }
        ElseIf ($EnvOption -eq "7" -or $EnvOption -eq "VideaProd"){
            $Environment = "VideaProd"
        }
        ElseIf ($EnvOption -eq "8" -or $EnvOption -eq "AJCNewsApp"){
            $Environment = "AJCNewsApp"
        }
        Else {
            Write-Host "`r"
            Write-Host " Non-option selected`r"
            Write-Host " Ending Program...`r"
            Write-Host "`r"
            Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            BREAK
        }
        Write-Host "`r"
        Clear-Host
        #endregion Account Selection Menu 
        
        #region AWS Credential Profile Selection/Creation
        If (Get-AWSCredentials -ProfileName $Environment){
            Set-AWSCredentials -ProfileName $Environment
            #region MFA
            Set-DefaultAWSRegion -Region us-east-1
            If (Get-IAMMFADevice){
                DO
                {
                    $SessionToken = $NULL
                    $AccessKeyId = $NULL
                    $Expiration = $NULL
                    $SecretAccessKey = $NULL
                    $SessionToken = $NULL
                    $EnvironmentKey = $NULL
                    $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                    $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                    $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                    $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                    $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                    $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                    If ($Expiration -gt "$(Get-Date)"){
                        #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                    }
                    Else {
                        Remove-Variable -Name "$($Environment)_Session"
                        Write-Host "`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "                Create Route 53 Hosted Zone`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "`r"
                        Write-Host "    Please enter your multi-factor authentication code.`r"
                        Write-Host "`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "Type your answer `r" -ForegroundColor Yellow
                        $MFA_Code = Read-Host
                        Write-Host ""
                        New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                        $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                        $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                        $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                        $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                        $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                        $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                    }
                    Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                    #Clear-Host
                } Until ($Expiration -gt "$(Get-Date)")
            }
            #endregion MFA
        }
        #region Create AWS Credential Profile 
        Else {
            DO
            {
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "                Create Route 53 Hosted Zone`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "`r"
                Write-Host "    Please enter your AWS Access Key ID.`r"
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "Type your answer `r" -ForegroundColor Yellow
                $AccKey = Read-Host
                Write-Host ""
                DO
                {
                    If ($AccKey -eq $NULL){
                        #Clear-Host
                        Write-Host ""
                        Write-Host " Access key cannot be blank..." -Background Black -Foreground Magenta
                        Write-Host " Please Try Again." -Background Black -Foreground Magenta
                        Write-Host "`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "                Create Route 53 Hosted Zone`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "`r"
                        Write-Host "    Please enter your AWS Access Key ID.`r"
                        Write-Host "`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "Type your answer `r" -ForegroundColor Yellow
                        $AccKey = Read-Host
                        Write-Host ""
                        #Clear-Host
                    }
                } Until ($AccKey -ne $NULL)
                Write-Host ""
                #Clear-Host
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "                Create Route 53 Hosted Zone`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "`r"
                Write-Host "    Please enter your AWS Secret Access Key.`r"
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "Type your answer `r" -ForegroundColor Yellow
                $SecAccKey = Read-Host
                Write-Host ""
                DO
                {
                    If ($SecAccKey -eq $NULL){
                        #Clear-Host
                        Write-Host ""
                        Write-Host " Secret Access key cannot be blank..." -Background Black -Foreground Magenta
                        Write-Host " Please Try Again." -Background Black -Foreground Magenta
                        Write-Host "`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "                Create Route 53 Hosted Zone`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "`r"
                        Write-Host "    Please enter your AWS Secret Access Key.`r"
                        Write-Host "`r"
                        Write-Host "  ****************************************************************`r"
                        Write-Host "Type your answer `r" -ForegroundColor Yellow
                        $SecAccKey = Read-Host
                        Write-Host ""
                        #Clear-Host
                    }
                } Until ($SecAccKey -ne $NULL)
                Set-AWSCredentials -AccessKey $AccKey -SecretKey $SecAccKey -StoreAs $Environment
                Set-AWSCredentials -ProfileName $Environment
                Write-Host ""
                #Clear-Host
                #region MFA
                Set-DefaultAWSRegion -Region us-east-1
                If (Get-IAMMFADevice){
                    DO
                    {
                        $SessionToken = $NULL
                        $AccessKeyId = $NULL
                        $Expiration = $NULL
                        $SecretAccessKey = $NULL
                        $SessionToken = $NULL
                        $EnvironmentKey = $NULL
                        $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                        $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                        $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                        $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                        $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                        $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        If ($Expiration -gt "$(Get-Date)"){
                            #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                        }
                        Else {
                            Remove-Variable -Name "$($Environment)_Session"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your multi-factor authentication code.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $MFA_Code = Read-Host
                            Write-Host ""
                            New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $Environment = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        }
                        Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                        #Clear-Host
                    } Until ($Expiration -gt "$(Get-Date)")
                }
                #endregion MFA
            } Until (Get-AWSCredentials -ProfileName $Environment)
        }
        Clear-Host
        #endregion AWS Credential Profile Selection/Creation
        
        #region Zone-only Creation Delegation Set
        $DelegationIds = Get-R53ReusableDelegationSets | Select -expand ID
        If ($DelegationIds -like "*N18N50NBKFEPNZ*"){
            $DelegationSetId = "N18N50NBKFEPNZ" # CMGSandbox
        }
        ElseIf ($DelegationIds -like "*N1YMNW8L35WDKO*"){
            $DelegationSetId = "N1YMNW8L35WDKO"  # CMG-DST (PROD)
        }
        Else{
            Write-Host "`r"
            Write-Host "  ****************************************************************`r"
            Write-Host "                Create Route 53 Hosted Zone`r"
            Write-Host "  ****************************************************************`r"
            Write-Host "`r"
            Write-Host "    Delegation Set not found in $Environment.  Would you  `r"
            Write-Host "        like to continue with the zone creation?`r"
            Write-Host "`r"
            Write-Host "`r"
            Write-Host "       1 -   Yes `r"
            Write-Host "       2 -   No [Default] `r"
            Write-Host "`r"
            Write-Host "`r"
            Write-Host "  ****************************************************************`r"
            Write-Host "Type your choice -  1/2 `r" -ForegroundColor Yellow
            $DelegationContinue = Read-Host
            Write-Host
            If ($DelegationContinue -eq "1" -or $DelegationContinue -eq "Yes"){
                $DelegContinue = "Yes"
            }
            Else {
                Write-Host "`r"
                Write-Host " Ending Program...`r"
                Write-Host "`r"
                Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
                $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                BREAK
            }
            Write-Host "`r"
            Clear-Host
        }
        #endregion Zone-only Creation Delegation Set
    
        #region Zone-only Creation Menu
        Write-Host "`r"
        Write-Host "  ****************************************************************`r"
        Write-Host "                Create Route 53 Hosted Zone`r"
        Write-Host "  ****************************************************************`r"
        Write-Host "`r"
        Write-Host "    What is the name of the zone being created? (for example, ajc.com.)`r"
        Write-Host "`r"
        Write-Host "  ****************************************************************`r"
        Write-Host "Type your answer `r" -ForegroundColor Yellow
        $ZoneName = Read-Host
        Write-Host ""
        If ($ZoneName -notlike "*."){
            $ZoneName = "$ZoneName."
        }
        DO
        {
            $Zone = $NULL
            $Zone = Get-R53HostedZones | ? {$_.Name -like "$ZoneName"} | Select *
            If ($Zone -ne $NULL){
                Clear-Host
                Write-Host ""
                Write-Host " Zone already exists..." -Background Black -Foreground Magenta
                Write-Host " Please Try Again." -Background Black -Foreground Magenta
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "                Create Route 53 Hosted Zone`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "`r"
                Write-Host "    What is the name of the zone being created? (for example, ajc.com.)`r"
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "Type your answer `r" -ForegroundColor Yellow
                $ZoneName = Read-Host
                Write-Host ""
                If ($ZoneName -notlike "*."){
                    $ZoneName = "$ZoneName."
                }
            }
        } Until ($Zone -eq $NULL)
        Write-Host ""
        Clear-Host
        #endregion Zone-only Creation Menu
    
        #region Create Hosted Zone
        Write-Host "Creating $ZoneName in $Environment..."
        New-R53HostedZone -Name $ZoneName -CallerReference (Get-Date -format "MM-dd-yyyy-HH.mm.ss") -DelegationSetId $DelegationSetId
        #endregion Create Hosted Zone
    
        #region Update comment for Hosted Zone
        $R53ZoneID = Get-R53HostedZones | ? {$_.Name -eq "$ZoneName"} | Select -expand ID
        Update-R53HostedZoneComment -Id $R53ZoneID -Comment "Created on $(Get-Date -format "MM-dd-yy @ HH:mm:ss") by $CurrentUser"
        #endregion Update comment for Hosted Zone
    
        #region Fix SOA record
        If ($Environment -eq "CMGSandbox"){
            $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
            $resourceRecordSet.Name = $ZoneName
            $resourceRecordSet.Type = "SOA"
            $resourceRecordSet.ResourceRecords = New-Object Amazon.Route53.Model.ResourceRecord ("ns1.cmgdnstest.com. cmgdomainregadmins.coxinc.com. 1 7200 900 1209600 86400")
            $resourceRecordSet.TTL = "3600"
            $action = [Amazon.Route53.ChangeAction]::UPSERT
            $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
            Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change
        }
        Else {
            $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
            $resourceRecordSet.Name = $ZoneName
            $resourceRecordSet.Type = "SOA"
            $resourceRecordSet.ResourceRecords = New-Object Amazon.Route53.Model.ResourceRecord ("ns1.cmgdns.com. cmgdomainregadmins.coxinc.com. 1 7200 900 1209600 86400")
            $resourceRecordSet.TTL = "3600"
            $action = [Amazon.Route53.ChangeAction]::UPSERT
            $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
            Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change
        }
        #endregion Fix SOA record
        
        #region Fix NS records        
        If ($Environment -eq "CMGSandbox"){
            $nsServers = "ns1.cmgdnstest.com.","ns2.cmgdnstest.com.","ns3.cmgdnstest.com.","ns4.cmgdnstest.com."
            $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
            $resourceRecordSet.Name = $ZoneName
            $resourceRecordSet.Type = "NS"
            $resourceRecordSet.ResourceRecords = $nsServers
            $resourceRecordSet.TTL = "3600"
            $action = [Amazon.Route53.ChangeAction]::UPSERT
            $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
            Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change 
        }
        Else {
            $nsServers = "ns1.cmgdns.com.","ns2.cmgdns.com.","ns3.cmgdns.com.","ns4.cmgdns.com."
            $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
            $resourceRecordSet.Name = $ZoneName
            $resourceRecordSet.Type = "NS"
            $resourceRecordSet.ResourceRecords = $nsServers
            $resourceRecordSet.TTL = "3600"
            $action = [Amazon.Route53.ChangeAction]::UPSERT
            $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
            Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change 
        }
        #endregion Fix NS records

        $ArrObject = New-Object PSObject
        $ArrObject | Add-Member -MemberType NoteProperty -Name ZoneName -value $ZoneName
        $ArrObject | Add-Member -MemberType NoteProperty -Name Environment -value $Environment
        $R53ZonesAndEnv += $ArrObject
    }
    #endregion Zone-only Creation 
    
    #region Zone and Record Creation 
    ElseIf ($CreationChoice -eq "CreateRecords") {
        #region Prompt user to choose a CSV file to import
        Add-Type –AssemblyName System.Windows.Forms 
        Add-Type –AssemblyName System.Drawing
        $pshost = get-host
        $pswindow = $pshost.ui.rawui
        $InFileDirectory = "C:\Users\" + $CurrentUser
        $DialogBox1 = New-Object system.windows.forms.openfiledialog
        $DialogBox1.InitialDirectory = $InFileDirectory
        $DialogBox1.MultiSelect = $FALSE
        $DialogBox1.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*" 
        $DialogBox1.Title = "Select CSV File to Import:"
        $DialogBox1.ShowHelp = $TRUE
        $DialogBox1.showdialog()
        $CsvPath = $DialogBox1.FileName
        If ($CsvPath -eq "" -or $CsvPath -eq $NULL) {
            Write-Host "`r"
            Write-Host " No CSV selected`r"
            Write-Host " Ending Program...`r"
            Write-Host "`r"
            Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            BREAK
        }
        #endregion Prompt user to choose a CSV file to import
    
        #region Import CSV and Create Hosted Zone and records.
        Write-Host "Importing CSV file for zone and record creation..." -ForegroundColor Black -BackgroundColor Yellow
        $ImportCSV = Import-Csv $CsvPath
    
        #region Create Hosted Zones
        $ImportCSV | Sort ZoneName,Environment -Unique | % {
            $ZoneName = $NULL
            $RecordName = $NULL
            $RecordType = $NULL
            $RecordTTL = $NULL
            $RecordData = $NULL
            $Environment = $NULL
            $ZoneName = $_.ZoneName
            $RecordName = $_.RecordName
            $RecordType = $_.RecordType
            $RecordTTL = $_.RecordTTL
            $RecordData = $_.RecordData
            $Environment = $_.Environment

            #region Verify CSV columns and headers
            If (!($ZoneName) -or !($Environment)){
                Write-Host "`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "                Create Route 53 Hosted Zone`r"
                Write-Host "  ****************************************************************`r"
                Write-Host "`r"
                Write-Host "Variables not set:  Please check the CSV file. $Environment - $ZoneName" -Background Black -Foreground Red
                Write-Host "Please be sure the CSV file has the following columns populated:" -Background Black -Foreground Magenta
                Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                Write-Host "| ZoneName | RecordName | RecordType | RecordTTL | RecordData | Environment |" -Background Black -Foreground Magenta
                Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                Write-Host "`r"
                Write-Host "`r"
                If ($R53ZonesAndEnv) {
                    Write-Host "  The following Route 53 Hosted Zones have been created: `r"
                    Write-Host "`r"
                    $R53ZonesAndEnv | % {
                        Write-Host "      $($_.Environment) - $($_.ZoneName)  `r"
                    }
                    Write-Host "`r"
                    Write-Host "`r"
                }
                Write-Host "  ****************************************************************`r"
                Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
                $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                BREAK
            }
            #endregion Verify CSV columns and headers

            If (Get-AWSCredentials -ProfileName $Environment){
                Set-AWSCredentials -ProfileName $Environment
                #region MFA
                Set-DefaultAWSRegion -Region us-east-1
                If (Get-IAMMFADevice){
                    DO
                    {
                        $SessionToken = $NULL
                        $AccessKeyId = $NULL
                        $Expiration = $NULL
                        $SecretAccessKey = $NULL
                        $SessionToken = $NULL
                        $EnvironmentKey = $NULL
                        $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                        $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                        $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                        $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                        $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                        $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        If ($Expiration -gt "$(Get-Date)"){
                            #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                        }
                        Else {
                            Remove-Variable -Name "$($Environment)_Session"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your multi-factor authentication code.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $MFA_Code = Read-Host
                            Write-Host ""
                            New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        }
                        Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                        Clear-Host
                    } Until ($Expiration -gt "$(Get-Date)")
                }
                #endregion MFA
            }
            #region Create AWS Credential Profile 
            Else {
                DO
                {
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "    Please enter your AWS Access Key ID.`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your answer `r" -ForegroundColor Yellow
                    $AccKey = Read-Host
                    Write-Host ""
                    DO
                    {
                        If ($AccKey -eq $NULL){
                            Clear-Host
                            Write-Host ""
                            Write-Host " Access key cannot be blank..." -Background Black -Foreground Magenta
                            Write-Host " Please Try Again." -Background Black -Foreground Magenta
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your AWS Access Key ID.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $AccKey = Read-Host
                            Write-Host ""
                            Clear-Host
                        }
                    } Until ($AccKey -ne $NULL)
                    Write-Host ""
                    Clear-Host
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "    Please enter your AWS Secret Access Key.`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your answer `r" -ForegroundColor Yellow
                    $SecAccKey = Read-Host
                    Write-Host ""
                    DO
                    {
                        If ($SecAccKey -eq $NULL){
                            Clear-Host
                            Write-Host ""
                            Write-Host " Secret Access key cannot be blank..." -Background Black -Foreground Magenta
                            Write-Host " Please Try Again." -Background Black -Foreground Magenta
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your AWS Secret Access Key.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $SecAccKey = Read-Host
                            Write-Host ""
                            Clear-Host
                        }
                    } Until ($SecAccKey -ne $NULL)
                    Set-AWSCredentials -AccessKey $AccKey -SecretKey $SecAccKey -StoreAs $Environment
                    Set-AWSCredentials -ProfileName $Environment
                    Write-Host ""
                    Clear-Host
                    #region MFA
                    Set-DefaultAWSRegion -Region us-east-1
                    If (Get-IAMMFADevice){
                        DO
                        {
                            $SessionToken = $NULL
                            $AccessKeyId = $NULL
                            $Expiration = $NULL
                            $SecretAccessKey = $NULL
                            $SessionToken = $NULL
                            $EnvironmentKey = $NULL
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                            If ($Expiration -gt "$(Get-Date)"){
                                #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                            }
                            Else {
                                Remove-Variable -Name "$($Environment)_Session"
                                Write-Host "`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "                Create Route 53 Hosted Zone`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "`r"
                                Write-Host "    Please enter your multi-factor authentication code.`r"
                                Write-Host "`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "Type your answer `r" -ForegroundColor Yellow
                                $MFA_Code = Read-Host
                                Write-Host ""
                                New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                                $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                                $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                                $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                                $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                                $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                                $Environment = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                            }
                            Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                            Clear-Host
                        } Until ($Expiration -gt "$(Get-Date)")
                    }
                    #endregion MFA
                } Until (Get-AWSCredentials -ProfileName $Environment)
            }
            Clear-Host
            #endregion Create AWS Credential Profile 

            If ($ZoneName -notlike "*."){
                $ZoneName = "$ZoneName."
            }
            $Zone = $NULL
            $Records = $NULL
    
            #region Verify Zone does not already exist
            $Zone = Get-R53HostedZones | ? {$_.Name -like "$ZoneName"} | Select *
            If ($Zone -ne $NULL){
                Clear-Host
                Write-Host ""
                Write-Host " Zone already exists..." -Background Black -Foreground Magenta
                Write-Host " Please correct the CSV file and try again..." -Background Black -Foreground Magenta
                Write-Host "`r"
                Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
                $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                BREAK
            }
            #endregion Verify Zone does not already exist
            
            #region Create Hosted Zone
            Write-Host "Creating $ZoneName in $Environment..."
            Start-Sleep -s 1
            New-R53HostedZone -Name $ZoneName -CallerReference (Get-Date -format "MM-dd-yyyy-HH.mm.ss") -DelegationSetId $DelegationSetId
            #endregion Create Hosted Zone
    
            #region Update comment for Hosted Zone
            $R53ZoneID = Get-R53HostedZones | ? {$_.Name -eq "$ZoneName"} | Select -expand ID
            Update-R53HostedZoneComment -Id $R53ZoneID -Comment "Created on $(Get-Date -format "MM-dd-yy @ HH:mm:ss") by $env:USERNAME"
            #endregion Update comment for Hosted Zone

            $ArrObject = New-Object PSObject
            $ArrObject | Add-Member -MemberType NoteProperty -Name ZoneName -value $ZoneName
            $ArrObject | Add-Member -MemberType NoteProperty -Name Environment -value $Environment
            $R53ZonesAndEnv += $ArrObject
        }
        #endregion Create Hosted Zones
    
        #region Create records for new Hosted Zones
        $ContinueCSV = "No"
        $ImportCSV | % {
            $ZoneName = $NULL
            $RecordName = $NULL
            $RecordType = $NULL
            $RecordTTL = $NULL
            $RecordData = $NULL
            $Environment = $NULL
            $ZoneName = $_.ZoneName
            $RecordName = $_.RecordName
            $RecordType = $_.RecordType
            $RecordTTL = $_.RecordTTL
            $RecordData = $_.RecordData
            $Environment = $_.Environment

            #region Verify CSV columns and headers
            If (!($ZoneName) -or !($RecordName) -or !($RecordType) -or !($RecordTTL) -or !($RecordData) -or !($Environment)){
                If (!($ZoneName) -or !($Environment)){
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "Variables not set:  Please check the CSV file. $Environment - $ZoneName" -Background Black -Foreground Red
                    Write-Host "Please be sure the CSV file has the following columns populated:" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "| ZoneName | RecordName | RecordType | RecordTTL | RecordData | Environment |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
                    $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                    BREAK
                }
                If ($ContinueCSV -eq "No"){
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "Some variables are not set:  Please check the CSV file. $Environment - $ZoneName" -Background Black -Foreground Red
                    Write-Host "Please be sure the CSV file has the following columns populated:" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "| ZoneName | RecordName | RecordType | RecordTTL | RecordData | Environment |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "|          |            |            |           |            |             |" -Background Black -Foreground Magenta
                    Write-Host "|----------|------------|------------|-----------|------------|-------------|" -Background Black -Foreground Magenta
                    Write-Host "`r"
                    Write-Host "`r"
                    Write-Host "  What would you like to do?`r"
                    Write-Host "`r"
                    Write-Host "       1 -   Exit the script and fix the CSV file. [Default] `r"
                    Write-Host "       2 -   Create blank zone without records. `r"
                    Write-Host "`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your choice -  1/2 `r" -ForegroundColor Yellow
                    $CSVContinueOption = Read-Host
                    Write-Host
                    If ($CSVContinueOption -eq "1" -or $CSVContinueOption -eq "Exit" -or $CSVContinueOption -eq "Quit" -or $CSVContinueOption -eq "" -or $CSVContinueOption -eq $NULL){
                        Write-Host "`r"
                        If ($R53ZonesAndEnv) {
                            Write-Host "  The following Route 53 Hosted Zones have been created: `r"
                            Write-Host "`r"
                            $R53ZonesAndEnv | % {
                                Write-Host "      $($_.Environment) - $($_.ZoneName)  `r"
                            }
                            Write-Host "`r"
                            Write-Host "`r"
                        }
                        Write-Host " Ending Program...`r"
                        Write-Host "`r"
                        Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
                        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        BREAK
                    }
                    ElseIf ($CSVContinueOption -eq "2" -or $CSVContinueOption -eq "Continue"){
                        $ContinueCSV = "Yes"
                    }
                    Else {
                        Write-Host "`r"
                        Write-Host " Non-option selected`r"
                        Write-Host " Ending Program...`r"
                        Write-Host "`r"
                        Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
                        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                        BREAK
                    }
                    Write-Host "`r"
                    Clear-Host
                }
            }
            #endregion Verify CSV columns and headers

            If (Get-AWSCredentials -ProfileName $Environment){
                Set-AWSCredentials -ProfileName $Environment
                #region MFA
                Set-DefaultAWSRegion -Region us-east-1
                If (Get-IAMMFADevice){
                    DO
                    {
                        $SessionToken = $NULL
                        $AccessKeyId = $NULL
                        $Expiration = $NULL
                        $SecretAccessKey = $NULL
                        $SessionToken = $NULL
                        $EnvironmentKey = $NULL
                        $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                        $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                        $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                        $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                        $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                        $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        If ($Expiration -gt "$(Get-Date)"){
                            #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                        }
                        Else {
                            Remove-Variable -Name "$($Environment)_Session"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your multi-factor authentication code.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $MFA_Code = Read-Host
                            Write-Host ""
                            New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        }
                        Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                        Clear-Host
                    } Until ($Expiration -gt "$(Get-Date)")
                }
                #endregion MFA
            }
            #region Create AWS Credential Profile 
            Else {
                DO
                {
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "    Please enter your AWS Access Key ID.`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your answer `r" -ForegroundColor Yellow
                    $AccKey = Read-Host
                    Write-Host ""
                    DO
                    {
                        If ($AccKey -eq $NULL){
                            Clear-Host
                            Write-Host ""
                            Write-Host " Access key cannot be blank..." -Background Black -Foreground Magenta
                            Write-Host " Please Try Again." -Background Black -Foreground Magenta
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your AWS Access Key ID.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $AccKey = Read-Host
                            Write-Host ""
                            Clear-Host
                        }
                    } Until ($AccKey -ne $NULL)
                    Write-Host ""
                    Clear-Host
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "    Please enter your AWS Secret Access Key.`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your answer `r" -ForegroundColor Yellow
                    $SecAccKey = Read-Host
                    Write-Host ""
                    DO
                    {
                        If ($SecAccKey -eq $NULL){
                            Clear-Host
                            Write-Host ""
                            Write-Host " Secret Access key cannot be blank..." -Background Black -Foreground Magenta
                            Write-Host " Please Try Again." -Background Black -Foreground Magenta
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your AWS Secret Access Key.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $SecAccKey = Read-Host
                            Write-Host ""
                            Clear-Host
                        }
                    } Until ($SecAccKey -ne $NULL)
                    Set-AWSCredentials -AccessKey $AccKey -SecretKey $SecAccKey -StoreAs $Environment
                    Set-AWSCredentials -ProfileName $Environment
                    Write-Host ""
                    Clear-Host
                    #region MFA
                    Set-DefaultAWSRegion -Region us-east-1
                    If (Get-IAMMFADevice){
                        DO
                        {
                            $SessionToken = $NULL
                            $AccessKeyId = $NULL
                            $Expiration = $NULL
                            $SecretAccessKey = $NULL
                            $SessionToken = $NULL
                            $EnvironmentKey = $NULL
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                            If ($Expiration -gt "$(Get-Date)"){
                                #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                            }
                            Else {
                                Remove-Variable -Name "$($Environment)_Session"
                                Write-Host "`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "                Create Route 53 Hosted Zone`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "`r"
                                Write-Host "    Please enter your multi-factor authentication code.`r"
                                Write-Host "`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "Type your answer `r" -ForegroundColor Yellow
                                $MFA_Code = Read-Host
                                Write-Host ""
                                New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                                $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                                $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                                $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                                $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                                $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                                $Environment = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                            }
                            Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                            Clear-Host
                        } Until ($Expiration -gt "$(Get-Date)")
                    }
                    #endregion MFA
                } Until (Get-AWSCredentials -ProfileName $Environment)
            }
            Clear-Host
            
            #region Fix Domain Name variable
            If ($ZoneName -like "*."){
                $DomainNameDot = $ZoneName
                $DomainName = $ZoneName.Substring(0,$ZoneName.Length-1)
            }
            Else{
                $DomainNameDot = "$($ZoneName)."
                $DomainName = $ZoneName
            }
            #endregion Fix Domain Name variable
            
            $R53ZoneID = Get-R53HostedZones | ? {$_.Name -eq "$DomainNameDot"} | Select -expand ID
            $resourceType = $NULL
            $resourceName = $NULL
            $resourceData = $NULL
            $resourceTTL = $NULL
            $resourceType = $RecordType
            $resourceName = $RecordName
            $resourceData = $RecordData
            $resourceTTL = $RecordTTL
    
            If ($ZoneName -and $RecordName -and $RecordType -and $RecordTTL -and $RecordData -and $Environment){
                #region Fix Resource Name variable
                If ($resourceName -like "*$DomainNameDot"){
                    $resourceName = $resourceName
                }
                ElseIf ($resourceName -like "*$DomainName"){
                    $resourceName = "$($resourceName)."
                }
                ElseIf ($resourceName -eq '@'){
                    $resourceName = "$DomainNameDot"
                }
                ElseIf (($resourceName -notlike "*$DomainNameDot") -and ($resourceName -notlike "*$DomainName") -and ($resourceName -notlike "*.")){
                    $resourceName = "$($resourceName).$($DomainNameDot)"
                }
                ElseIf (($resourceName -notlike "*$DomainNameDot") -and ($resourceName -like "*.")){
                    $resourceName = "$($resourceName)$($DomainNameDot)"
                }
                #endregion Fix Resource Name variable
                
                #region Setup new resource record sets
                #region Create DNS Record
                $RecordDataArray = $NULL
                $RecordDataArray1 = $NULL
                $RecordDataArr = $NULL
                
                If ($RecordData -like "*`n*"){
                    $RecordDataArr = ($RecordData -split "`n").trim()
                }
                ElseIf ($RecordData -like "*,*"){
                    $RecordDataArr = ($RecordData -split ",").trim()            
                }
                ElseIf ($RecordData -like "*;*"){
                    $RecordDataArr = ($RecordData -split ";").trim()
                }
                Else {
                    $RecordDataArr = ($RecordData -split " ").trim()
                }
                $resourceRecordSet = $NULL
                $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
                $resourceRecordSet.Name = $resourceName
                $resourceRecordSet.Type = $RecordType
                $resourceRecordSet.TTL = $RecordTTL
                
                #region Create array for new Record Data
                If ($RecordDataArr.count -gt 1){
                    $i = 0
                    Do {
                        $RecordDataArray += "$($RecordDataArr[$i]),"
                        $i++
                    }
                    Until ($i -eq $RecordDataArr.count)
                    $RecordDataArray1 = ($RecordDataArray.Substring(0,$RecordDataArray.Length-1) -split ",").Trim()
                    $resourceRecordSet.ResourceRecords = $RecordDataArray1
                }
                Else {
                    $resourceRecordSet.ResourceRecords = New-Object Amazon.Route53.Model.ResourceRecord ("$RecordDataArr")
                }
                #endregion Create array for new Record Data

                If (((Get-R53ResourceRecordSet -HostedZoneId $R53ZoneID).ResourceRecordSets | where Name -eq $resourceName | measure).Count -eq 0) {
                    $action = [Amazon.Route53.ChangeAction]::CREATE
                }
                else {
                    $action = [Amazon.Route53.ChangeAction]::UPSERT
                }
                $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
                Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change
            }
            #endregion Setup new resource record sets
        }
    
        #region Fix NS and SOA records
        $ImportCSV | Sort ZoneName,Environment -Unique | % {
            $ZoneName = $NULL
            $RecordName = $NULL
            $RecordType = $NULL
            $RecordTTL = $NULL
            $RecordData = $NULL
            $Environment = $NULL
            $ZoneName = $_.ZoneName
            $RecordName = $_.RecordName
            $RecordType = $_.RecordType
            $RecordTTL = $_.RecordTTL
            $RecordData = $_.RecordData
            $Environment = $_.Environment
            If (Get-AWSCredentials -ProfileName $Environment){
                Set-AWSCredentials -ProfileName $Environment
                #region MFA
                Set-DefaultAWSRegion -Region us-east-1
                If (Get-IAMMFADevice){
                    DO
                    {
                        $SessionToken = $NULL
                        $AccessKeyId = $NULL
                        $Expiration = $NULL
                        $SecretAccessKey = $NULL
                        $SessionToken = $NULL
                        $EnvironmentKey = $NULL
                        $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                        $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                        $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                        $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                        $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                        $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        If ($Expiration -gt "$(Get-Date)"){
                            #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                        }
                        Else {
                            Remove-Variable -Name "$($Environment)_Session"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your multi-factor authentication code.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $MFA_Code = Read-Host
                            Write-Host ""
                            New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                        }
                        Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                        Clear-Host
                    } Until ($Expiration -gt "$(Get-Date)")
                }
                #endregion MFA
            }
            #region Create AWS Credential Profile 
            Else {
                DO
                {
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "    Please enter your AWS Access Key ID.`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your answer `r" -ForegroundColor Yellow
                    $AccKey = Read-Host
                    Write-Host ""
                    DO
                    {
                        If ($AccKey -eq $NULL){
                            Clear-Host
                            Write-Host ""
                            Write-Host " Access key cannot be blank..." -Background Black -Foreground Magenta
                            Write-Host " Please Try Again." -Background Black -Foreground Magenta
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your AWS Access Key ID.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $AccKey = Read-Host
                            Write-Host ""
                            Clear-Host
                        }
                    } Until ($AccKey -ne $NULL)
                    Write-Host ""
                    Clear-Host
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "                Create Route 53 Hosted Zone`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "`r"
                    Write-Host "    Please enter your AWS Secret Access Key.`r"
                    Write-Host "`r"
                    Write-Host "  ****************************************************************`r"
                    Write-Host "Type your answer `r" -ForegroundColor Yellow
                    $SecAccKey = Read-Host
                    Write-Host ""
                    DO
                    {
                        If ($SecAccKey -eq $NULL){
                            Clear-Host
                            Write-Host ""
                            Write-Host " Secret Access key cannot be blank..." -Background Black -Foreground Magenta
                            Write-Host " Please Try Again." -Background Black -Foreground Magenta
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "                Create Route 53 Hosted Zone`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "`r"
                            Write-Host "    Please enter your AWS Secret Access Key.`r"
                            Write-Host "`r"
                            Write-Host "  ****************************************************************`r"
                            Write-Host "Type your answer `r" -ForegroundColor Yellow
                            $SecAccKey = Read-Host
                            Write-Host ""
                            Clear-Host
                        }
                    } Until ($SecAccKey -ne $NULL)
                    Set-AWSCredentials -AccessKey $AccKey -SecretKey $SecAccKey -StoreAs $Environment
                    Set-AWSCredentials -ProfileName $Environment
                    Write-Host ""
                    Clear-Host
                    #region MFA
                    Set-DefaultAWSRegion -Region us-east-1
                    If (Get-IAMMFADevice){
                        DO
                        {
                            $SessionToken = $NULL
                            $AccessKeyId = $NULL
                            $Expiration = $NULL
                            $SecretAccessKey = $NULL
                            $SessionToken = $NULL
                            $EnvironmentKey = $NULL
                            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                            $EnvironmentKey = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                            If ($Expiration -gt "$(Get-Date)"){
                                #Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
                            }
                            Else {
                                Remove-Variable -Name "$($Environment)_Session"
                                Write-Host "`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "                Create Route 53 Hosted Zone`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "`r"
                                Write-Host "    Please enter your multi-factor authentication code.`r"
                                Write-Host "`r"
                                Write-Host "  ****************************************************************`r"
                                Write-Host "Type your answer `r" -ForegroundColor Yellow
                                $MFA_Code = Read-Host
                                Write-Host ""
                                New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
                                $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
                                $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
                                $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
                                $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
                                $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
                                $Environment = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
                            }
                            Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
                            Clear-Host
                        } Until ($Expiration -gt "$(Get-Date)")
                    }
                    #endregion MFA
                } Until (Get-AWSCredentials -ProfileName $Environment)
            }
            Clear-Host
            #endregion Create AWS Credential Profile 

            If ($ZoneName -notlike "*."){
                $ZoneName = "$ZoneName."
            }
            
            $R53ZoneID = Get-R53HostedZones | ? {$_.Name -eq "$ZoneName"} | Select -expand ID
    
            #region Fix SOA record
            If ($Environment -eq "CMGSandbox"){
                $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
                $resourceRecordSet.Name = $ZoneName
                $resourceRecordSet.Type = "SOA"
                $resourceRecordSet.ResourceRecords = New-Object Amazon.Route53.Model.ResourceRecord ("ns1.cmgdnstest.com. cmgdomainregadmins.coxinc.com. 1 7200 900 1209600 86400")
                $resourceRecordSet.TTL = "3600"
                $action = [Amazon.Route53.ChangeAction]::UPSERT
                $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
                Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change
            }
            Else {
                $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
                $resourceRecordSet.Name = $ZoneName
                $resourceRecordSet.Type = "SOA"
                $resourceRecordSet.ResourceRecords = New-Object Amazon.Route53.Model.ResourceRecord ("ns1.cmgdns.com. cmgdomainregadmins.coxinc.com. 1 7200 900 1209600 86400")
                $resourceRecordSet.TTL = "3600"
                $action = [Amazon.Route53.ChangeAction]::UPSERT
                $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
                Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change
            }
            #endregion Fix SOA record
            
            #region Fix NS records        
            If ($Environment -eq "CMGSandbox"){
                $nsServers = "ns1.cmgdnstest.com.","ns2.cmgdnstest.com.","ns3.cmgdnstest.com.","ns4.cmgdnstest.com."
                $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
                $resourceRecordSet.Name = $ZoneName
                $resourceRecordSet.Type = "NS"
                $resourceRecordSet.ResourceRecords = $nsServers
                $resourceRecordSet.TTL = "3600"
                $action = [Amazon.Route53.ChangeAction]::UPSERT
                $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
                Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change 
            }
            Else {
                $nsServers = "ns1.cmgdns.com.","ns2.cmgdns.com.","ns3.cmgdns.com.","ns4.cmgdns.com."
                $resourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
                $resourceRecordSet.Name = $ZoneName
                $resourceRecordSet.Type = "NS"
                $resourceRecordSet.ResourceRecords = $nsServers
                $resourceRecordSet.TTL = "3600"
                $action = [Amazon.Route53.ChangeAction]::UPSERT
                $change = New-Object Amazon.Route53.Model.Change ($action, $resourceRecordSet)
                Edit-R53ResourceRecordSet -HostedZoneId $R53ZoneID -ChangeBatch_Change $change 
            }
            #endregion Fix NS records
        }
        #endregion Fix NS and SOA records
    }
    #endregion Zone and Record Creation 

    #region Ask if the script should run again
    Clear-Host
    Write-Host "`r"
    Write-Host "  ****************************************************************`r"
    Write-Host "                Create Route 53 Hosted Zone`r"
    Write-Host "  ****************************************************************`r"
    Write-Host "`r"
    Write-Host "  The following Route 53 Hosted Zones have been created: `r"
    Write-Host "`r"
    $R53ZonesAndEnv | % {
        Write-Host "      $($_.Environment) - $($_.ZoneName)  `r"
    }
    Write-Host "`r"
    Write-Host "`r"
    Write-Host "     Do you have more zones to create? `r"
    Write-Host "`r"
    Write-Host "       1 -   Yes `r"
    Write-Host "       2 -   No [Default] `r"
    Write-Host "`r"
    Write-Host "`r"
    Write-Host "  ****************************************************************`r"
    Write-Host "Type your choice -  1/2 `r" -ForegroundColor Yellow
    $MoreOption = Read-Host
    Write-Host "`r"
    If ($MoreOption -eq "2" -or $MoreOption -eq "No" -or $MoreOption -eq "" -or $MoreOption -eq $NULL){
        $More = "No"
        Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        BREAK
    }
    ElseIf ($MoreOption -eq "1" -or $MoreOption -eq "Yes"){
        $More = "Yes"
        $Date = Get-Date -Format "MMddyy_HHmmss"
    }
    Else {
        Write-Host "`r"
        Write-Host " Non-option selected`r"
        Write-Host " Ending Program...`r"
        Write-Host "`r"
        Write-Host "Press any key to exit ...`r" -Background Black -Foreground Yellow
        $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        BREAK
    }
    Write-Host "`r"
    Clear-Host
    #endregion Ask if the script should run again
} Until ($More -eq "No")
#endregion Script

$WarningActionPreference="Continue"
$ErrorActionPreference = "Continue"

# SIG # Begin signature block
# MIIEYAYJKoZIhvcNAQcCoIIEUTCCBE0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAsjH3YmFsorKELL9z2OwpuEZ
# XCKgggJqMIICZjCCAdOgAwIBAgIQxQYONs60z45G2jr/d8iMxTAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0xNzA5MjcxNjQxMjVaFw0zOTEyMzEyMzU5NTlaMEcxRTBDBgNVBAMePABhAGQA
# bQBuAF8AawBwAG8AbABpAG4AZwAgAFAAbwB3AGUAcgBTAGgAZQBsAGwAIABDAGUA
# cgB0ACAAMjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAsKFtD5RQsODzv+Jb
# YDqdEzkLfzM880CFNIiy6AYq5eDLj5Y0b97nGEhZHZCxpQTcARFODR05W6dS+Fy5
# N14oOt1TW/P1HvhgJguPsuUIoKMhSrS6jW8GIKWvLnRQAxHRMxhe1eSjXmoL8uWq
# iabavypUZk+1XugPYdfIOzzELl0CAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYBBQUH
# AwMwXQYDVR0BBFYwVIAQMbF4nC2tTERkJasHUT0UxaEuMCwxKjAoBgNVBAMTIVBv
# d2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQnAa2ntdWCr1LYZ61wGDQ
# KDAJBgUrDgMCHQUAA4GBAFU41m0ijaO0q4iwM44I0AjXUZnlHMKm/4PRdgBGOzc0
# o6OwOGs5x84VUyjpj0RROpbhl3odPVbdMqGL8buxngdKyyqsAGyHb9uPsS44tuCX
# Z2GcXho6p+8JQ8LqqO4XpUOuAdyqiMjMHMSHRF3BUn2bS8qCUB4lcTJc2vsYqj4t
# MYIBYDCCAVwCAQEwQDAsMSowKAYDVQQDEyFQb3dlclNoZWxsIExvY2FsIENlcnRp
# ZmljYXRlIFJvb3QCEMUGDjbOtM+ORto6/3fIjMUwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFHuJ
# OJ1rzn+1EbQ3LCWDO+lqSci0MA0GCSqGSIb3DQEBAQUABIGAieWQKZk3l6X9ABna
# AtCM+jSbiJl3/h+mcR2gUCiwyLIMvUYe+h8JmoeVrsuBGgsOa53LvXDzKpfVgFt0
# dgesEMZIjI2cIov4CToTpX/3A5QGgv52JMxBxwwGoQEP7K16bhtlq9m6pF4kEin5
# fU8+SSOIWR+eUm6AFfeC3mCF760=
# SIG # End signature block
