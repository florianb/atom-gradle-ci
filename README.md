# GradleCI

Continuous builds with [Gradle](gradle.org)! Adds a CI-like addon to your status bar, showing you the last build-status and let you access the last build-reports.

This package is inspired by Cliff Rowley's [atom-circle-ci](https://github.com/cliffrowley/atom-circle-ci)-package. I also snooped into MindscapeHQ's [atom-raygun](https://github.com/MindscapeHQ/atom-raygun)-package to learn more about atom-views. Thank you guys! :lollipop:

## How to use

Toggle the result-pane via the Packages-menu, the context-menu or through a click on the GradleCi-status-badge on the right side in your status-bar.

## Release Notes

### 0.2.1
 - :candy: Added tooltip for the states where the result-pane is active.

### 0.2.0
 - Refactored package-architecture.
 - Fixed issue where the result-pane could get stuck being displayed wrong.
 - Fixed issue where the loading of the package could end in a fatal error.
 - Fixed several issues behind the curtain.
 - :candy: Added tooltips for the states (disabled & no builds) where the result-pane is inactive.
 - :candy: Added configuration-setting to customize the number of results being held in memory.
 - :candy: Added icon-coloring to make last build-state more visible (green/red), added corresponding configuration-setting.
 - :candy: Added relative time-stamps to the build-results.

### 0.1.3
 - Fixed project-path as command-line-option.

### 0.1.2
 - Fixed an issue which interrupted the update process. To force an update launch `apm upgrade` from your command-line.

## Configuring

There are five settings - in your GradleCi's Atom package-settings - available.

### Color Status Icon

Lets you decide if the build-icon is colored or not. Only the two build-states "succeeded" (green) and "failed" (red) are colored to minimize disturbance.

### Maximum Result History

The result-history of build defaults to 3 results. You're able to change that number to every positive number. If the given number is invalid the setting defaults internally to 3 again.

> **Warning** A higher number results in higher memory consumption (depending on the output of your gradle-configuration), this may slow down the whole editor in general.

The result history is **not** perstisted between different use session. This feature is planned later on.

### Run As Daemon

Calls Gradle with the `--daemon'-option. Gradle then internally starts a daemon, which is able to cache a lot of work. This function is supposed to speed your build-process up to three times. As a Gradle standard the daemon dies automatically after three hours of inactivity.

### Run Task

This field may contain the task you'd like to call for your build. As a default the task `test` is defined. Since the content of that field is only appended to the commandline, you're free to use it to add options and arguments.

### Trigger Build After Save

This setting lets GradleCI listen to changes to the project-root-directory. The trigger may namely build after save but listens in fact on every change in the directory. So renaming, adding, deleting files will inoke a build, too.

> GradleCi uses a library to watch the directory via filesystem-notifications if possible. If not it falls back (namely on Mac OS) to a polling mechanism. The polling-interval is currently set to 500ms to lower the resource consumption.

## Limitations

There are currently many limitations for the moment - please be patient:

 - `gradle` must be accessible in the "normal" environment.
 - ~~The package only holds 3 reports in the memory.~~
 - There's currently only the file-modification trigger.
 - There's currently **no** associated version to your build.

## Roadmap

 - More robust gradle-execution, based on environment-vars
 - Displaying diffed build-results
 - Alternative triggers
 - Build-versions (does somebody need that?)
 - Persistent results (between use-sessions)

## Contributing

Issues, suggestions and pull requests are more than welcome.
