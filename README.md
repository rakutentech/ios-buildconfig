# Shared iOS build configuration
This repository hosts our (Rakuten MAG SDK Team) shared build configuration and tooling for iOS SDK development.

## Usage

### Shared Fastlane configuration
In your `Fastfile`, simply add the following line at the top:

    import_from_git(url: '<URL-for-this-repo>.git')
    
Run `fastlane lanes` for a description of the functionality available.


