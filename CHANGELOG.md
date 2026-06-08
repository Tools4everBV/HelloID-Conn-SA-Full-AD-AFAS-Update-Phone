# Change Log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [2.0.0] - 2026-03-10

### Added

- Added AFAS request header `IntegrationId` to task logic.

### Changed

- Changed AD lookup filtering:
  - Search by `Name`, `DisplayName`, `UserPrincipalName`, and `mail`
  - Use semicolon-separated OU values in `ADusersSearchOU`
- Changed dynamic form grid and dependencies to use the current property set (`Mobile`, `telephoneNumber`, `ObjectGuid`).
- Changed delegated form task to use `$form.gridUsers` object values directly and update AD by `ObjectGuid`.
- Changed AFAS/AD logging and error-handling flow to the current standardized pattern.
- Changed datasource naming to the current standardized pattern
- Updated default sample values in all-in-one setup for `AFASBaseUrl` and `ADusersSearchOU`.
- Updated README with detailed permission assignment documentation

### Removed

- User details grid in multistep form

## [1.0.0] - 15-05-2023

Initial release