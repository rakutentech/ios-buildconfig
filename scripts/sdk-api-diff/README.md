# sdk-api-diff tool

## Setup
1. Install Swift toolchain from https://swift.org/download/#releases
1. Install ModuleInterface from https://github.com/minuscorp/ModuleInterface
1. Install jq `brew install jq`
1. Install sourcekitten `brew install sourcekitten`

Ensure that `sdk-api-diff-request-template.yml` file is in the same directory as `sdk-api-diff.sh`

## Description
This tool compares API differences between two module versions by generating diff file of generated Swift interfaces and by printing API breakage summary.
The script requires 3 arguments - module name and two paths to directories containing .framework file or SPM project (when using `--spm` option).

Options:
* **--target**: Target platform and version e.g. *x86_64-apple-ios14.0-simulator* or *arm64-apple-ios14.0*
    (Default value: *x86_64-apple-ios14.0-simulator*)
* **--sdkpath**: Path to target's SDK.
    (Default value: output of `xcrun --sdk iphonesimulator --show-sdk-path` command)
* **--spm**: Use this option for Swift Module projects. Input paths must contain buildable SPM project.
* **--help**: Dispalys help content.

## Usage

#### .framework module
```bash
sh ~/sdk-api-diff.sh RInAppMessaging \
~/Library/Developer/Xcode/DerivedData/RInAppMessaging-1.0/Build/Products/Debug-iphonesimulator/RInAppMessaging \
~/Library/Developer/Xcode/DerivedData/RInAppMessaging-2.0/Build/Products/Debug-iphonesimulator/RInAppMessaging
```

#### Swift Package module
```bash
sh ~/sdk-api-diff.sh RSDKUtils ~/ios-sdkutils-v1 ~/ios-sdkutils-v2
```