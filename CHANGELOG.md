# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2024-07-12

### Added
- Initial release of Rails Flow Map
- Support for multiple visualization formats:
  - Mermaid diagrams (GitHub-friendly)
  - PlantUML class diagrams
  - GraphViz network diagrams
  - Interactive D3.js visualizations
  - OpenAPI specifications
  - Sequence diagrams
  - ERD diagrams
  - Metrics reports
  - Git diff visualizations
- Enterprise-grade security features:
  - Path traversal protection
  - XSS prevention
  - Input validation
  - Security event logging
- Performance and reliability:
  - Structured logging with performance metrics
  - Robust error handling with context
  - Retry logic for transient failures
  - Memory optimization for large applications
- Developer experience:
  - Zero configuration setup
  - Rake tasks integration
  - VS Code task definitions
  - Comprehensive documentation
- Rail Engine integration
- Configurable analysis options
- Comprehensive test suite with security tests
- YARD documentation for all public APIs
- Usage examples and quick reference guides
- Multi-language documentation (English, Japanese, Chinese)

### Dependencies
- Ruby >= 2.7.0
- Rails >= 6.0
- parser gem for AST analysis

[Unreleased]: https://github.com/railsflowmap/rails-flow-map/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/railsflowmap/rails-flow-map/releases/tag/v0.1.0