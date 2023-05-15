#######################################################################
# Template: RHo HelloID SA Delegated form task
# Name:     AD-AFAS-account-update-phone
# Date:     15-05-2023
#######################################################################

# For basic information about delegated form tasks see:
# https://docs.helloid.com/en/service-automation/delegated-forms/delegated-form-powershell-scripts/add-a-powershell-script-to-a-delegated-form.html

# Service automation variables:
# https://docs.helloid.com/en/service-automation/service-automation-variables/service-automation-variable-reference.html

#region init
# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

$VerbosePreference = "SilentlyContinue"
$InformationPreference = "Continue"
$WarningPreference = "Continue"

# global variables (Automation --> Variable libary):
# $globalVar = $globalVarName

# variables configured in form:
$userPrincipalName = $form.gridUsers.UserPrincipalName
$phoneMobile = $form.mobilePhone
$phoneFixed = $form.officePhone
$employeeID = $form.gridUsers.employeeID
$displayName = $form.gridUsers.displayName
#endregion init

#region global functions
function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
            ScriptStackTrace      = $ErrorObject.ScriptStackTrace
            ErrorMessage          = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorMessage = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $httpErrorObj.ErrorMessage = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        }
        Write-Output $httpErrorObj
    }
}
#endregion global functions

#region AD
try {
    Write-Information "Querying AD user [$userPrincipalName]"
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } 
    Write-Information "Found AD user [$userPrincipalName]"
} catch {
    Write-Error "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)"    
    $Log = @{
        Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
        System            = "ActiveDirectory" # optional (free format text) 
        Message           = "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)" # required (free format text) 
        IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
        TargetDisplayName = $displayName # optional (free format text) 
        TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
    }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log  
}
try {
    Write-Information "Start updating AD user [$userPrincipalName]"
    if([String]::IsNullOrEmpty($phoneMobile) -eq $true) {
        Set-ADUser -Identity $adUSer -MobilePhone $null
    } else {
        Set-ADUser -Identity $adUSer -MobilePhone $phoneMobile
    }

    if([String]::IsNullOrEmpty($phoneFixed) -eq $true) {
        Set-ADUser -Identity $adUSer -OfficePhone $null
    } else {
        Set-ADUser -Identity $adUSer -OfficePhone $phoneFixed
    }
    
    Write-Information "Finished update attribute [phoneMobile] of AD user [$userPrincipalName] to [$phoneMobile] and/or [officePhone] to [$phoneFixed]"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Successfully updated attribute [phoneMobile] of AD user [$userPrincipalName] to [$phoneMobile] and/or [officePhone] to [$phoneFixed]" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log    
} catch {
    Write-Error "Could not update attribute [phoneMobile] of AD user [$userPrincipalName] to [$phoneMobile] and/or [officePhone] to [$phoneFixed]. Error: $($_.Exception.Message)"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Failed to update attribute [phoneMobile] of AD user [$userPrincipalName] to [$phoneMobile] and/or [officePhone] to [$phoneFixed]" # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log      
}
#endregion AD

#region AFAS
function Resolve-AFASErrorMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        try {
            $errorObjectConverted = $ErrorObject | ConvertFrom-Json -ErrorAction Stop

            if ($null -ne $errorObjectConverted.externalMessage) {
                $errorMessage = $errorObjectConverted.externalMessage
            }
            else {
                $errorMessage = $errorObjectConverted
            }
        }
        catch {
            $errorMessage = "$($ErrorObject.Exception.Message)"
        }

        Write-Output $errorMessage
    }
}

# Used to connect to AFAS API endpoints
$BaseUri = $AFASBaseUrl
$Token = $AFASToken
$getConnector = "T4E_HelloID_Users_v2"
$updateConnector = "KnEmployee"

#Change mapping here
$account = [PSCustomObject]@{
    'AfasEmployee' = @{
        'Element' = @{
            'Objects' = @(
                @{
                    'KnPerson' = @{
                        'Element' = @{
                            'Fields' = @{
                                # # Telefoonnr. werk
                                'TeNr'        = $phoneFixed                     
                                # Mobiel werk
                                'MbNr'        = $phoneMobile
                            }
                        }
                    }
                }
            )
        }
    }
}

$filterfieldid = "Medewerker"
$filtervalue = $employeeID # Has to match the AFAS value of the specified filter field ($filterfieldid)

# Get current AFAS employee and verify if a user must be either [created], [updated and correlated] or just [correlated]
try {
    Write-Information "Querying AFAS employee with $($filterfieldid) $($filtervalue)"

    # Create authorization headers
    $encodedToken = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Token))
    $authValue = "AfasToken $encodedToken"
    $Headers = @{ Authorization = $authValue }

    $splatWebRequest = @{
        Uri             = $BaseUri + "/connectors/" + $getConnector + "?filterfieldids=$filterfieldid&filtervalues=$filtervalue&operatortypes=1"
        Headers         = $headers
        Method          = 'GET'
        ContentType     = "application/json;charset=utf-8"
        UseBasicParsing = $true
    }        
    $currentAccount = (Invoke-RestMethod @splatWebRequest -Verbose:$false).rows

    if ($null -eq $currentAccount.Medewerker) {
        throw "No AFAS employee found with $($filterfieldid) $($filtervalue)"
    }
    Write-Information "Found AFAS employee [$($currentAccount.Medewerker)]"
    # Check if current TeNr or MbNr has a different value from mapped value. AFAS will throw an error when trying to update this with the same value
    if ([string]$currentAccount.Telefoonnr_werk -ne $account.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'TeNr' -and $null -ne $account.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'TeNr') {
        $propertiesChanged += @('TeNr')
    }
    if ([string]$currentAccount.Mobielnr_werk -ne $account.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'MbNr' -and $null -ne $account.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'MbNr') {
        $propertiesChanged += @('MbNr')
    }
    if ($propertiesChanged) {
        Write-Verbose "Account property(s) required to update: [$($propertiesChanged -join ",")]"
        $updateAction = 'Update'
    }
    else {
        $updateAction = 'NoChanges'
    }

}
catch {
    $ex = $PSItem
    if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObject = Resolve-HTTPError -Error $ex

        $verboseErrorMessage = $errorObject.ErrorMessage

        $auditErrorMessage = Resolve-AFASErrorMessage -ErrorObject $errorObject.ErrorMessage
    }

    # If error message empty, fall back on $ex.Exception.Message
    if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
        $verboseErrorMessage = $ex.Exception.Message
    }
    if ([String]::IsNullOrEmpty($auditErrorMessage)) {
        $auditErrorMessage = $ex.Exception.Message
    }

    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"

    if ($auditErrorMessage -Like "No AFAS employee found with $($filterfieldid) $($filtervalue)") {
        Write-Error "Failed to update attribute [MbNr] of AFAS emplyee [$employeeID] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]: No AFAS employee found with $($filterfieldid) $($filtervalue)"
        Write-Information "Failed to update attribute [MbNr] of AFAS emplyee [$employeeID] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]: No AFAS employee found with $($filterfieldid) $($filtervalue)"
        $Log = @{
                Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                System            = "AFAS Employee" # optional (free format text) 
                Message           = "Failed to update attribute [MbNr] of AFAS employee [$employeeId] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]: No AFAS employee found with $($filterfieldid) $($filtervalue)" # required (free format text) 
                IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $displayName # optional (free format text) 
                TargetIdentifier  = $([string]$employeeID) # optional (free format text) 
            }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log 
    }
    else {
        Write-Error "Failed to update attribute [MbNr] of AFAS emplyee [$employeeID] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]: Error querying AFAS employee found with $($filterfieldid) $($filtervalue). Error Message: $auditErrorMessage"
        Write-Information "Failed to update attribute [MbNr] of AFAS emplyee [$employeeID] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]: Error querying AFAS employee found with $($filterfieldid) $($filtervalue). Error Message: $auditErrorMessage"
        $Log = @{
                Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                System            = "AFAS Employee" # optional (free format text) 
                Message           = "Failed to update attribute [MbNr] of AFAS employee [$employeeId] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]: Error querying AFAS employee found with $($filterfieldid) $($filtervalue). Error Message: $auditErrorMessage" # required (free format text) 
                IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                TargetDisplayName = $displayName # optional (free format text) 
                TargetIdentifier  = $([string]$employeeID) # optional (free format text) 
            }
        #send result back  
        Write-Information -Tags "Audit" -MessageData $log  
    }
}

# Update AFAS Employee
try {
    Write-Information "Start updating AFAS employee [$($currentAccount.Medewerker)]"
    switch ($updateAction) {
        'Update' {
            # Create custom account object for update
            $updateAccount = [PSCustomObject]@{
                'AfasEmployee' = @{
                    'Element' = @{
                        '@EmId'   = $currentAccount.Medewerker
                        'Objects' = @(@{
                                'KnPerson' = @{
                                    'Element' = @{
                                        'Fields' = @{
                                            # Zoek op BcCo (Persoons-ID)
                                            'MatchPer' = 0
                                            # Nummer
                                            'BcCo'     = $currentAccount.Persoonsnummer
                                        }
                                    }
                                }
                            })
                    }
                }
            }
            if ('TeNr' -in $propertiesChanged) {
                # Telefoonnr. werk
                $updateAccount.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'TeNr' = $account.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'TeNr'
                Write-Information "Updating TeNr '$($currentAccount.Telefoonnr_werk)' with new value '$($updateAccount.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'TeNr')'"
            }

            if ('MbNr' -in $propertiesChanged) {
                # Mobiel werk
                $updateAccount.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'MbNr' = $account.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'MbNr'
                Write-Information "Updating MbNr '$($currentAccount.Mobielnr_werk)' with new value '$($updateAccount.'AfasEmployee'.'Element'.Objects[0].'KnPerson'.'Element'.'Fields'.'MbNr')'"
            }

            $body = ($updateAccount | ConvertTo-Json -Depth 10)
            $splatWebRequest = @{
                Uri             = $BaseUri + "/connectors/" + $updateConnector
                Headers         = $headers
                Method          = 'PUT'
                Body            = ([System.Text.Encoding]::UTF8.GetBytes($body))
                ContentType     = "application/json;charset=utf-8"
                UseBasicParsing = $true
            }

            $updatedAccount = Invoke-RestMethod @splatWebRequest -Verbose:$false
            Write-Information "Successfully updated attribute [MbNr] of AFAS emplyee [$employeeID] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]"
            $Log = @{
                    Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                    System            = "AFAS Employee" # optional (free format text) 
                    Message           = "Successfully updated attribute [MbNr] of AFAS employee [$employeeId] to [$phoneMobile] and/or [TeNr] to [$phoneFixed]" # required (free format text) 
                    IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                    TargetDisplayName = $displayName # optional (free format text) 
                    TargetIdentifier  = $([string]$employeeID) # optional (free format text) 
                }
            #send result back  
            Write-Information -Tags "Audit" -MessageData $log  
            break
        }
        'NoChanges' {
            Write-Information "Successfully checked attribute [MbNr] of AFAS emplyee [$employeeID] with value [$phoneMobile] and/or [TeNr] with value [$phoneFixed], nog changes needed"
            $Log = @{
                    Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
                    System            = "AFAS Employee" # optional (free format text) 
                    Message           = "Successfully checked attribute [MbNr] of AFAS emplyee [$employeeID] with value [$phoneMobile] and/or [TeNr] with value [$phoneFixed], nog changes needed" # required (free format text) 
                    IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
                    TargetDisplayName = $displayName # optional (free format text) 
                    TargetIdentifier  = $([string]$employeeID) # optional (free format text) 
                }
            #send result back  
            Write-Information -Tags "Audit" -MessageData $log  
            break
        }
    }
}
catch {
    $ex = $PSItem
    if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObject = Resolve-HTTPError -Error $ex

        $verboseErrorMessage = $errorObject.ErrorMessage

        $auditErrorMessage = Resolve-AFASErrorMessage -ErrorObject $errorObject.ErrorMessage
    }

    # If error message empty, fall back on $ex.Exception.Message
    if ([String]::IsNullOrEmpty($verboseErrorMessage)) {
        $verboseErrorMessage = $ex.Exception.Message
    }
    if ([String]::IsNullOrEmpty($auditErrorMessage)) {
        $auditErrorMessage = $ex.Exception.Message
    }

    $ex = $PSItem
    $verboseErrorMessage = $ex
    
    Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($verboseErrorMessage)"
    Write-Error "Error updating AFAS employee $($currentAccount.Medewerker). Error Message: $auditErrorMessage"
    Write-Information "Error updating AFAS employee $($currentAccount.Medewerker). Error Message: $auditErrorMessage"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "AFAS Employee" # optional (free format text) 
            Message           = "Error updating AFAS employee $($currentAccount.Medewerker). Error Message: $auditErrorMessage" # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $displayName # optional (free format text) 
            TargetIdentifier  = $([string]$employeeID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log 
}
#endregion AFAS
