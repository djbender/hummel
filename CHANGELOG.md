# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-02-16

### Changed
- Update parser and encoder to HUML v0.2.0 spec
- Remove triple-backtick multiline string syntax
- Triple-quote `"""` multiline strings now preserve relative indentation (strip uniform indent)
- Enforce strict indentation for multiline vectors inside list items

### Internal
- Abort test suite early if `tests/` submodule is missing

## [0.1.1] - 2025-10-12

### Changed
- Improve code coverage and remove dead code
- Update README.md with naming scheme and fixes

### Fixed
- Fix README example

### Internal
- Achieve 100% code coverage
- Add code coverage tracking with SimpleCov
- Update CI workflow with permissions and coverage upload
- Add matrix.ruby to artifact naming
- Add workflow_dispatch trigger to CI

## [0.1.0] - 2025-10-12

- Initial release
