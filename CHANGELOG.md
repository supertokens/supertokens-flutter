# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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