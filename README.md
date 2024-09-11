# HelloID-Conn-SA-Full-AD-AFAS-Update-Phone

> [!IMPORTANT]
> This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.

<p align="center">
  <img src="https://github.com/Tools4everBV/HelloID-Conn-SA-Full-AD-AFAS-Update-Phone/blob/main/Logo.png?raw=true">
</p>

## Table of contents

- [HelloID-Conn-SA-Full-AD-AFAS-Update-Phone](#helloid-conn-sa-full-ad-afas-update-phone)
  - [Table of contents](#table-of-contents)
  - [Requirements](#requirements)
  - [Remarks](#remarks)
  - [Introduction](#introduction)
      - [Description](#description)
      - [Endpoints](#endpoints)
      - [Form Options](#form-options)
      - [Task Actions](#task-actions)
  - [Connector Setup](#connector-setup)
    - [Variable Library - User Defined Variables](#variable-library---user-defined-variables)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Requirements
1. **HelloID Environment**:
   - Set up your _HelloID_ environment.
   - Install the _HelloID_ Service Automation agent (on-prem).
2. **Active Directory**:
   - Service account that is running the agent has `Account Operators` rights
3. **AFAS Profit**:
   - AFAS tennant id
   - AppConnector token
   - Loaded AFAS GetConnector
     - Tools4ever - HelloID - T4E_HelloID_Users_v2.gcn
     - https://github.com/Tools4everBV/HelloID-Conn-Prov-Target-AFAS-Profit-Employees
   - Build-in Profit update connector: KnEmployee

## Remarks
- None at this time.

## Introduction

#### Description
_HelloID-Conn-SA-Full-AD-AFAS-Update-Phone_ is a template designed for use with HelloID Service Automation (SA) Delegated Forms. It can be imported into HelloID and customized according to your requirements. 

By using this delegated form, you gain the ability to update the mobile and fixed phone numbers in Active Directory and AFAS Profit. The following options are available:
 1. Search and select the target AD user account
 2. Enter new values for the following AD user account attributes: OfficePhone and MobilePhone
 3. AD user account [OfficePhone and MobilePhone] and AFAS employee [TeNr and MbNr] attributes are updated with new values

#### Endpoints
AFAS Profit provides a set of REST APIs that allow you to programmatically interact with its data.. The API endpoints listed in the table below are used.

| Endpoint                      | Description   |
| ----------------------------- | ------------- |
| profitrestservices/connectors | AFAS endpoint |

#### Form Options
The following options are available in the form:

1. **Lookup user**:
   - This Powershell data source runs an Active Directory query to search for matching AD user accounts. It uses an array of Active Directory OU's specified as HelloID user-defined variable named _"ADusersSearchOU"_ to specify the search scope. This data source returns additional attributes the receive the current values for OfficePhone and MobilePhone.

#### Task Actions
The following actions will be performed based on user selections:

1. **Update OfficePhone and MobilePhone in Active Directory**:
   - On the AD user account the attributes OfficePhone and MobilePhone will be updated.
2. **Update TeNr and MbNr in AFAS Profit Employee**:
   - On the AFAS employee the attributes TeNr and MbNr will be updated.

## Connector Setup
### Variable Library - User Defined Variables
The following user-defined variables are used by the connector. Ensure that you check and set the correct values required to connect to the API.

| Setting           | Description                                                                                                                                                                                                               |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ADusersSearchOU` | Array of Active Directory OUs for scoping AD user accounts in the search result of this form. For example, `[{ "OU": "OU=Disabled Users,OU=Training,DC=domain,DC=com"},{ "OU": "OU=Users,OU=Training,DC=domain,DC=com"}]` |
| `AFASBaseUrl`     | The URL to the AFAS environment REST service. For example, `https://yourtennantid.rest.afas.online/profitrestservices`                                                                                                    |
| `AFASToken`       | The AppConnector token to connect to AFAS. For example, `< token>< version>1< /version>< data>yourtoken< /data>< /token>`                                                                                                 |

## Getting help
> [!TIP]
> _For more information on Delegated Forms, please refer to our [documentation](https://docs.helloid.com/en/service-automation/delegated-forms.html) pages_.

> [!TIP]
>  _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_.

## HelloID docs
The official HelloID documentation can be found at: https://docs.helloid.com/