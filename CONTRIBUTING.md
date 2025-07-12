# Contributing to Rails Flow Map

Thank you for your interest in contributing to Rails Flow Map! We welcome contributions from the community to help make this tool even better.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Style Guides](#style-guides)
- [Community](#community)

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Accept feedback gracefully
- Prioritize the community's best interests

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally
3. Set up your development environment
4. Create a branch for your changes
5. Make your changes and test them
6. Submit a pull request

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Steps to reproduce the behavior
- Expected behavior vs actual behavior
- Screenshots if applicable
- Your environment details (Ruby version, Rails version, OS)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- A clear and descriptive title
- Detailed description of the proposed feature
- Use cases and examples
- Any alternative solutions considered

### Code Contributions

#### First-Time Contributors

Look for issues labeled `good-first-issue` or `help-wanted`. These are great starting points for new contributors.

#### Development Process

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/rails-flow-map.git
   cd rails-flow-map
   ```

2. **Install Dependencies**
   ```bash
   bundle install
   ```

3. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **Make Your Changes**
   - Write clean, readable code
   - Add tests for new functionality
   - Update documentation as needed

5. **Run Tests**
   ```bash
   bundle exec rspec
   ```

6. **Commit Your Changes**
   ```bash
   git add .
   git commit -m "Add descriptive commit message"
   ```

## Development Setup

### Prerequisites

- Ruby 2.7.0 or higher
- Bundler
- Git

### Local Development

1. **Install Dependencies**
   ```bash
   bundle install
   ```

2. **Run Tests**
   ```bash
   bundle exec rspec
   ```

3. **Run Linter**
   ```bash
   bundle exec rubocop
   ```

4. **Test in a Sample Rails App**
   ```bash
   cd blog_sample
   bundle install
   bundle exec rails flow_map:generate
   ```

## Testing

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/rails_flow_map/analyzers/model_analyzer_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Writing Tests

- Write tests for all new functionality
- Maintain test coverage above 90%
- Follow RSpec best practices
- Use descriptive test names

Example:
```ruby
RSpec.describe RailsFlowMap::Analyzers::ModelAnalyzer do
  describe '#analyze' do
    it 'detects has_many associations' do
      # Test implementation
    end
  end
end
```

## Submitting Changes

### Pull Request Process

1. **Update Documentation**
   - Update README if needed
   - Add/update code comments
   - Update CHANGELOG.md

2. **Ensure Quality**
   - All tests pass
   - Code follows style guide
   - No linting errors

3. **Create Pull Request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Describe what changes were made and why
   - Include screenshots for UI changes

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
- [ ] All tests pass
- [ ] Added new tests
- [ ] Tested manually

## Checklist
- [ ] Code follows style guide
- [ ] Self-reviewed code
- [ ] Updated documentation
- [ ] No new warnings
```

## Style Guides

### Ruby Style Guide

We follow the standard Ruby style guide with some modifications:

- Use 2 spaces for indentation
- Limit lines to 80 characters when possible
- Use descriptive variable and method names
- Prefer `do...end` for multi-line blocks

### Git Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests

Example:
```
Add model association analyzer

- Implement detection of has_many relationships
- Add support for through associations
- Include polymorphic association handling

Fixes #123
```

### Documentation Style

- Use clear, concise language
- Include code examples
- Keep README sections organized
- Update CHANGELOG.md for user-facing changes

## Community

### Getting Help

- Check the [documentation](README.md)
- Search [existing issues](https://github.com/railsflowmap/rails-flow-map/issues)
- Ask questions in [discussions](https://github.com/railsflowmap/rails-flow-map/discussions)

### Communication Channels

- GitHub Issues for bugs and features
- GitHub Discussions for questions and ideas
- Pull Requests for code contributions

## Recognition

Contributors will be recognized in:
- The project README
- Release notes
- Our [contributors page](https://github.com/railsflowmap/rails-flow-map/contributors)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Rails Flow Map! Your efforts help make Rails development better for everyone. 🚀