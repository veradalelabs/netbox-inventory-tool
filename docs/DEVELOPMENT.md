# Development Guide

## Project Structure
netbox-inventory-tool/
├── scripts/           # Main scripts
├── docs/             # Documentation
├── examples/         # Sample outputs
├── output/           # Generated files (gitignored)
├── README.md
└── .gitignore

## Adding New Features

1. Create feature branch: `git checkout -b feature/new-feature`
2. Implement changes
3. Test thoroughly
4. Update documentation
5. Commit with descriptive message
6. Create pull request

## Coding Standards

- Use `set -euo pipefail` for safety
- Implement proper error handling
- Add logging for all major operations
- Test with various system configurations

## Testing

Test the script on different systems:
- Various Linux distributions
- Different hardware configurations
- With/without optional tools

## Version Management

- Update `SCRIPT_VERSION` in script
- Tag releases: `git tag v1.0.0`
- Update README.md with new features
