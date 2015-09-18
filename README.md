# GradleCI

> NEW: support for `gw` (http://www.gdub.rocks/).

Continuous builds with [Gradle](http://gradle.org)! Adds a CI-like package to your status bar, showing you the last build-status and let you access the latest build-reports.

![Gradle-CI preview](http://g.recordit.co/h3qvD4D305.gif)

## How to use

GradleCI watches your current project and invokes builds, everytime you're saving a file.

### How GradleCI works

The previously released versions of GradleCI were unintenional buggy. After getting informed that my package will be deprecated during the 1.x-API-release, i took the opportunity to rewrite the mechanisms behind the scenes. During the rewrite i found out that my vision of the package-functionality is unlikely to become realized with the tools of the Atom-environment.

I was - for example - planning, that the builds will be invoked by Git-commit. Unfortunately there's currently no efficient and non-intrusive way to catch commit-events. For every functional aspect i tried and tested different approaches to find the best way to solve it. This is how GradleCI currently works:

#### Startup

During startup GradleCI tries to call all given build-commands (f.e. `gw`, `gradle`) via commandline to find out if Gradle is callable in general and which Version of Gradle will be invoked. The version-number might be used in the future to behave correctly - currently there is no known dependency on your Gradle-version.

If the invokation was successful, the statusbar-item is renamed to the version of Gradle and in the result pane the invoked build-command is being displayed.

#### Buildpath-Detection

After successful startup of the package and everytime you're changing the project-paths (f.e. by adding or removing a project-path), GradleCI tries to find and set the available build-paths.

Currently the identification of build-paths is limited, GradleCI takes every project-path and tries to access a build-file on its base-path. In other words, GradleCI does **not** recursively search for build-files (although this feature is planned for a future-release).

Every project-path which contains a build-file, which is readable by the current process is added to the list of available buildpaths (this is necessary to handle multiple project-files in a correct manner).

#### Build-Invokation

GradleCI observes every pane you have opened. Everytime you're saving a pane, GradleCI tries to get the corresponding build-path. If a build-path can be identified the build is scheduled. You're also able to invoke build manually by using the menu-entry.

GradleCI enqueues all builds after the FIFO-principle. If you're changing a file in a project-directory, which currently gets built, a second build is scheduled for that directory. This is done because GradleCI is not caching your project (for performance reasons) and i'm not able to predict if your file changes will be recognized by the actual build.

#### Presentation of the Build-Results

Every result of the run will be appended to a list of results, this list keeps 3 results as a default. You're able to change the number of results kept in the package-preferences.

If you already have some results you have the possibility to toggle the result-pane either by clicking on the statusbar-item, by invoking the command in the command-pane, by using the menu- or contextmenu-item and using the keyboard-shortcut.

After the result-pane is opened, you may change its size with drag'n'drop. You can close the result pane the same ways you used to open it.

## Release Notes

### 1.1.4
 - Fixed packaged-dependency which caused the package startup-failure.

### 1.1.0
 - :candy: Added support for custom build-commands - due to a feedback from [@lwis](https://github.com/lwis), thanks!

### 1.0.1
 - Modified require-statements to be more precise.
 - Removed testfiles which were synced accidentially.

### 1.0.0
 - Fixed API 1.x incompatibility.
 - Added support for multiple project-paths within a project.
 - :candy: Added menu-entry for manual invokation of builds.
 - :candy: Added fold-button to the result-pane.
 - :candy: Improved startup-speed by loading the most of the package asynchronously.
 - :candy: Added documentation to config-settings.
 - Improved overall code.
 - Dropped possibility to invoke builds by Git-commit-events.

### 0.2.0
 - Refactored package-architecture.
 - Fixed issue where the result-pane could get stuck being displayed wrong.
 - Fixed issue where the loading of the package could end in a fatal error.
 - Fixed several issues behind the curtain.
 - :candy: Added tooltips for the states (disabled & no builds) where the result-pane is inactive.
 - :candy: Added configuration-setting to customize the number of results being held in memory.
 - :candy: Added icon-coloring to make last build-state more visible (green/red), added corresponding configuration-setting.
 - :candy: Added relative time-stamps to the build-results.
 - 0.2.3 - Refactored the pane to use [Panetastic](https://www.npmjs.org/package/atom-panetastic), which fixes also the placement of the resize-handle during scrolling.
 - 0.2.2 - Added animated gif to this readme.
 - 0.2.1 - :candy: Added tooltip for the states where the result-pane is active.

### 0.1.3
 - Fixed project-path as command-line-option.

### 0.1.2
 - Fixed an issue which interrupted the update process. To force an update launch `apm upgrade` from your command-line.

## Configuring

All preferences of the package are elucidated in the preferences of the package.

## Limitations

 - Your build-command must be accessible in the "normal" environment.

## Roadmap

 - More robust gradle-execution, based on environment-vars
 - Displaying diffed build-results
 - Alternative triggers (it seems to be unlikely that this will ever happen)
 - Persistent results (between use-sessions)

## Contributing

Issues, suggestions and pull requests are more than welcome.
