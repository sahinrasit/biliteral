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

### ios tests

```sh
[bundle exec] fastlane ios tests
```

Unit and UI tests

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Register the bundle ID and create the App Store Connect record

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

App Store screenshots for every locale

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload texts, URLs, categories and review information (no screenshots, no binary)

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload the framed screenshots from build/framed (see scripts/frame_screenshots.swift)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build and upload to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit the latest build for App Review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
