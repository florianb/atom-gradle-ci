# Gradle CI

Builds your [Gradle](gradle.org)-project, shows the status of the last build in Atom's status bar and gives you access to the 3 previous Gradle-build-outputs.

This package is inspired by Cliff Rowley's [atom-circle-ci](https://github.com/cliffrowley/atom-circle-ci)-package. I also snooped into MindscapeHQ's [atom-raygun](https://github.com/MindscapeHQ/atom-raygun)-package to learn more about atom-views. Thank you guys! :lollipop:

## Release Notes

 - **0.1.3:** Fixed project-path as command-line-option.
 - **0.1.2:** Fixed an issue which interrupted the update process. To force an update launch `apm upgrade` from your command-line.

## Configuring

Currently there are three available options in Atom's settings:

 - Run As Daemon: this setting adds `--daemon` to the gradle-cli and is supposed to speed your build-time up (recommended). The daemon dies after 3 hours of inactivity.
 - Run Tasks: here you may specify the tasks you'd like to run. As default-value the `test`-task is run.
 - Trigger Build After Saves: this setting activates the build-trigger after a project-change. Since there's currently only this trigger, GradleCI won't do anything if disable this trigger.

 In future i plan to add a commit-based trigger and other features to give you more control about the trigger-mechanism.

## How to use

Well just activate the package - during initialization the package will test if gradle is executable. If it's working it will show up in the status-bar with a little symbol showing that there weren't any builds yet and the result of the check which contains the version of Gradle.

> To work the `gradle`-command must be available through `$PATH`- i'll add a possibility to specify custom execution-paths later-on.

After your first file-modification the package should get triggered. If the build is successful you'll get a :beer:, if not you'll face the :bug:. You have now your first pending build-report. Access it through **click on the symbol in the status-bar**, which is not working if you don't have any builds, yet (yeah - i'll change that, too later on..).

Your able to resize the appearing pane by dragging the little dot at the upper end.

## Limitations

There are currently many limitations for the moment - please be patient:

 - `gradle` must be accessible in the "normal" environment.
 - The package only holds 3 reports in the memory.
 - There's currently only the file-modification trigger.
 - There's currently **no** associated version to your build.

## Contributing

Issues, sugestions and pull requests are more than welcome.
