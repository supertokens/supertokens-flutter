# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.2] - 2024-09-27

- Adds support for debug logs using a `debug` option in the init() method of the SDK.

## [0.6.1] - 2024-07-12

### Changes

- Removed redundant calls to `removeToken`

## [0.6.0] - 2024-06-05

### Changes

- Fixed the session refresh loop in all the request interceptors that occurred when an API returned a 401 response despite a valid session. Interceptors now attempt to refresh the session a maximum of ten times before throwing an error. The retry limit is configurable via the `maxRetryAttemptsForSessionRefresh` option.

## [0.5.1] - 2024-05-28

- Adds FDI 2.0 and 3.0 to the list of supported versions

## [0.5.0] - 2024-05-08

### Fixes
- Fixed missing payload encoding conversion (from UTF-8 to UTF-16)

### Breaking changes

The `shouldDoInterceptions` function now returns true: 
- If `sessionTokenBackendDomain` is a valid subdomain of the URL's domain. This aligns with the behavior of browsers when sending cookies to subdomains.
- Even if the ports of the URL you are querying are different compared to the `apiDomain`'s port ot the `sessionTokenBackendDomain` port (as long as the hostname is the same, or a subdomain of the `sessionTokenBackendDomain`): https://github.com/supertokens/supertokens-website/issues/217


## [0.4.0] - 2024-03-25
- Relaxes dependency on `http` to be anything below `2.0.0`

## [0.3.1] - 2024-03-14
- New FDI version support: 1.19

## [0.3.0] - 2023-11-13

- Added Dio extension for interceptor setup
- Updated the mutex package to version ^3.1.0

### Breaking Changes

- Updated the dio package to version ^5.0.0

## [0.2.8] - 2023-09-13

- Adds 1.18 to the list of supported FDI versions
- Fixes an issue where requests to the refresh endpoint would always send auth mode as cookies in the headers for http

## [0.2.7] - 2023-07-31

- Updates supported FDI versions to include

## [0.2.6] - 2023-07-27

- Updates package dependencies to use ranges for `shared_preferences` and `http`

## [0.2.5] - 2023-07-10

### Fixes

- Fixed an issue where the Authorization header was getting removed unnecessarily

## [0.2.4] - 2023-06-08

- Refactors session logic to delete access token and refresh token if the front token is removed. This helps with proxies that strip headers with empty values which would result in the access token and refresh token to persist after signout

## [0.2.3] - 2023-05-03

- Adds tests based on changes in the session management logic in the backend SDKs and SuperTokens core

## [0.2.2] - 2023-03-17

### Fixes
- Moved `SuperTokensTokenTransferMethod` from utilities to supertokens for cleaner imports

## [0.2.1] - 2023-03-16

- Fixes an issues that caused reference documentaiotn regeneration to fail
## [0.2.0] - 2023-03-13

### Breaking Changes

- Properties passed when calling SuperTokens.init have been renamed:
    - `cookieDomain` -> `sessionTokenBackendDomain`
    - `userDefaultdSuiteName` -> removed (unused variable)

### Added

- The SDK now supports managing sessions via headers (using `Authorization` bearer tokens) instead of cookies
- A new property has been added when calling SuperTokens.init: `tokenTransferMethod`. This can be used to configure whether the SDK should use cookies or headers for session management (`header` by default). Refer to https://supertokens.com/docs/thirdpartyemailpassword/common-customizations/sessions/token-transfer-method for more information

## [0.1.2] - 2023-02-14

- Added fix for dio Interceptors `Bad State: Future already completed` error

## [0.1.1] - 2023-02-09

- Updates dependency declaration to support correct minor versions of packages

## [0.1.0] - 2023-02-01

### Breaking Changes

- The SDK now only supports FDI version 1.16
- The backend SDK should be updated to a version supporting the header-based sessions!
    - supertokens-node: >= 13.0.0
    - supertokens-python: >= 0.12.0
    - supertokens-golang: >= 0.10.0

## [0.0.1] - 2023-01-23
- Updates session management logic to be compatible with the latest version of SuperTokens core and backend SDKs
- Updates FDI version support
- Adds support for Dio by exposing an interceptor that handles session management
- General fixes