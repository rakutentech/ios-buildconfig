# Tools

1. [Version validation](#version-validation)

# Version validation

## Description
`version-validation.sh` is a shell script validating a version format.

## Usage

### Terminal

- Open a terminal

- Enter:
```bash
sh version-validation.sh [x.y.z]
```

### Bitrise

- Open your SDK Bitrise page

- Click on `Start/schedule build`

- Click on `Advanced` tab

- Select `version-validation` in `Workflow, Pipeline` section

- Add RELEASE_VERSION and a value(example: 3.2.1) in `Custom Environment Variables` section

- Click on `Add Environment Variable`

- Disable `Replace variables in input`

- Click on `Start Build`

## Example
- Command line:
```bash
sh version-validation.sh 10.0.0
```

- Result:
```
version input is valid
```
