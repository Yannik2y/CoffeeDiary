fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Print how to use Xcode Cloud + Fastlane together

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload metadata, attach latest processed build, submit for App Review

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Dry-run: push metadata only (no submit for review)

### ios screenshots_iphone

```sh
[bundle exec] fastlane ios screenshots_iphone
```

Capture iPhone App Store screenshots only (de-DE)

### ios screenshots_ipad

```sh
[bundle exec] fastlane ios screenshots_ipad
```

Capture iPad App Store screenshots only (de-DE)

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Capture iPhone then iPad screenshots, frame, and size for App Store (de-DE)

### ios screenshots_upload

```sh
[bundle exec] fastlane ios screenshots_upload
```

Replace App Store Connect screenshots for the current version (de-DE only)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
