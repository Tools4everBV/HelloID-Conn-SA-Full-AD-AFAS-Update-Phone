# HelloID-Conn-SA-Full-AD-AFAS-Update-Phone

| :information_source: Information |
| :------------------------------- |
| This repository contains the connector and configuration code only. The implementer is responsible for acquiring the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

## Description
_HelloID-Conn-SA-Full-AD-AFAS-Update-Phone_ is a template designed for use with HelloID Service Automation (SA) Delegated Forms. It can be imported into HelloID and customized according to your requirements.

By using this delegated form, you can manage phone attributes across your connected systems. The following options are available:
 1. Search and select the Active Directory user
 2. Enter new values for the user phone attributes
 3. The entered values are validated
 4. Active Directory and AFAS attributes are updated with new values across connected systems
 5. Writing back values will be handled according to system-specific rules and configurations

## Getting started
### Requirements

#### Active Directory setup

Before implementing this connector, make sure the HelloID Agent runs under an account with sufficient rights to update Active Directory user attributes.

Recommended permissions:
- Account Operators rights (or equivalent delegated rights) to update:
   - mobile
   - telephoneNumber

#### AFAS setup

Ensure AFAS Profit is configured with:
- AFAS AppConnector token
- Loaded AFAS GetConnector:
   - Tools4ever - HelloID - T4E_HelloID_Users_v2.gcn
   - https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-AFAS-Profit-Employees
- Built-in Profit update connector: KnEmployee

#### HelloID-specific configuration

Once you have completed the Active Directory and AFAS setup, configure the following HelloID-specific requirements:
- Configure the user-defined variables listed in Connection settings
- Import and configure the delegated form and task scripts

### Connection settings

The following user-defined variables are used by the connector.

| Setting                 | Description                                                                                                               | Mandatory |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------- | --------- |
| AdUsersDisabledSearchOu | The organizational units (OUs) to search for disabled AD users. Multiple OUs can be specified separated by semicolons (;) | Yes       |
| AFASBaseUrl             | The base URL to the AFAS Profit REST API                                                                                  | Yes       |
| AFASToken               | The AppConnector token for AFAS Profit authentication                                                                     | Yes       |


## Remarks

### Active Directory Agent Permissions Required
- Active Directory updates are performed by the HelloID Agent using Set-ADUser. Ensure the agent service account has rights to update the mobile and office phone attributes.

### AFAS Employee Matching
- Employee ID correlation: The connector correlates Active Directory users with AFAS employees using the Employee ID field. If no matching AFAS employee is found, the AFAS update is skipped while the Active Directory update still proceeds.

### Phone Number Validation
- Pattern validation: The form includes RegEx pattern validation for mobile and fixed phone numbers. The default patterns are:
   - Mobile Phone: `^\\+316\\d{8}$` (format: +31612345678)
   - Business Phone: `^(088-123)+[0-9]{4}$` (format: 088-123xxxx)

   These patterns should be adjusted according to your organization's phone number format requirements.

### No Changes Detection
- Skip unnecessary updates: The connector checks if the phone numbers in AFAS are already set to the requested values. If no changes are detected, the update operation is skipped to avoid unnecessary API calls and potential errors.

## Development resources

### Endpoints and operations

The following operations are used by the connector.W

| Endpoint/Operation                            | Description                                   |
| --------------------------------------------- | --------------------------------------------- |
| Active Directory (Get-ADUser)                 | Search and retrieve Active Directory users    |
| Active Directory (Set-ADUser)                 | Update Active Directory user phone attributes |
| {AFASBaseUrl}/connectors/T4E_HelloID_Users_v2 | Retrieve AFAS employee information            |
| {AFASBaseUrl}/connectors/KnEmployee           | Update AFAS employee phone numbers            |

### API and cmdlet documentation

- Active Directory Set-ADUser:
   https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser
- AFAS Profit REST API Documentation:
   https://help.afas.nl/help/NL/SE/App_Cnr_Rest_Updconnectors.htm

## Getting help
> :bulb: **Tip:**
> _For more information on Delegated Forms, please refer to our [documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html) pages_.

## HelloID docs
The official HelloID documentation can be found at: https://docs.helloid.com/