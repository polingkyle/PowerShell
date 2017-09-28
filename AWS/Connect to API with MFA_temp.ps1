param([string]$Environment)

Function ConnectToApiWithMfa($Environment){
    If (!(Get-Module AWSPowerShell -ErrorAction SilentlyContinue)) { Import-Module AWSPowerShell }
    
    Write-Host "Attempting to connect to $Environment"
    
    Set-AWSCredentials -ProfileName $Environment
    Set-DefaultAWSRegion -Region us-east-1
    
    #small change

    If (Get-IAMMFADevice){
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
            Write-Host "Previous session key for $EnvironmentKey is still valid." -ForegroundColor Black -BackgroundColor Green
        }
        Else {
            Remove-Variable -Name "$($Environment)_Session" -ErrorAction SilentlyContinue
            Write-Host "Please enter your multi-factor authentication code for $($Environment):" -ForegroundColor Yellow -BackgroundColor Black
            $MFA_Code = Read-Host
            New-Variable -Name "$($Environment)_Session" -Value "$(Get-STSSessionToken -SerialNumber "$((Get-IAMMFADevice).SerialNumber)" -TokenCode $MFA_Code | Select AccessKeyId,Expiration,SecretAccessKey,SessionToken,@{l="Environment";e={"$Environment"}})"
            $SessionToken = (Get-Variable | ? {$_.Name -like "$($Environment)_Session"}).Value -split "; "
            $AccessKeyId = "$($SessionToken[0] -replace "@{AccessKeyId=",'')"
            $Expiration = "$($SessionToken[1] -replace "Expiration=",'')"
            $SecretAccessKey = "$($SessionToken[2] -replace "SecretAccessKey=",'')"
            $SessionTokenVar = "$($SessionToken[3] -replace "SessionToken=",'')"
            $Environment = "$($SessionToken[4] -replace "Environment=",'' -replace '}','')"
        }
        Set-AWSCredentials -AccessKey $AccessKeyId -SecretKey $SecretAccessKey -SessionToken $SessionTokenVar
    }
    Write-Host "Connected as $(Get-IamUser | Select -expand Arn)..."
}

ConnectToApiWithMfa -Environment $Environment