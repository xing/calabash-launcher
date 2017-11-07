# Calabash Launcher

Calabash Launcher is a macOS app that helps you run and manage Calabash iOS tests on your Mac. 
- Instead of having to run and configure test runs in console, you can use a simple user interface which helps you to pick up needed devices, languages, tags, builds and other parameters. 
- Instead of having to search elements by quering view hierarchy again and again, you can click on the element under search and get its class name, accessibility label and/or accessibility id.

## Test Runner
![calabash-launcher](https://user-images.githubusercontent.com/18147900/32107640-8afc2c32-bb2f-11e7-83bf-857bb5b86709.png)
The Test Runner runs tests on a variety of configurations. It supports:

- Running tests on simulator
- Running tests on a physical device
- Running tests in different languages
- Test tags
- Console output

## Element Inspector
![calabash-launcher](https://user-images.githubusercontent.com/18147900/32107411-c7c68bd6-bb2e-11e7-8ae2-4d87b833c8fb.png)
With the Element Inspector you can inspect your apps view hierarchy to get elements query strings in hierarchy tree representation.
It supports:

- Device element highlighting
- Accessing an element's address
- Accessing an element's localized object
- The visual representation of the device

## Project Status

This project is under active development, and it is heavily used at [XING SE](www.xing.com).

## Prerequisites
In order to run the application you have to make sure that your machine meets the following requirements.

- MacOS Sierra
- Xcode 9.0+
- iOS Simulators >= 10.1
- Ruby >= 2.2.0 (2.3.1 is preferred)
- `bundler` >= 1.15.0
- `calabash-ios` >= 0.20.5

## Using the Test Runner

When opening Calabash Launcher the first time, it will ask you to give the path to the repository with your Calabash tests and (optionally) your Cucumber profile. After a restart of the Calabash Launcher, you will be able to configure your testrun by choosing a simulator, language and Cucumber tag you want to execute.

## Using the Element Inspector

⚠️ **Currently the Element Inspector is limited to iPhone 6, iPhone 7 and iPhone 8. Please make sure that one of these devices is launched when you search for elements.** ⚠️

- Clicking on the right window in the view will sync the Inspector with the simulator (and it will be automatic synced every 5 seconds)
- Clicking on an element in the synchronised window will show the element's `class`, `accessibility id` and `accessibility label`.
- Clicking on a nested menu of an element will show you the element hierarchy.

## Troubleshooting

- Calabash Launcher will not work if you cannot run `bundle exec calabash-ios console` from your terminal. 
Sometimes the problem could live in the Ruby installation and/or conflicts with `readline`. To fix the problem, please re-install Ruby.
- You can reset Calabash Launcher's settings by pressing the `Reset to Defaults Settings` menu item.

## Contributing
Want to help improving Calabash Launcher? We could really use your help!

Open source isn't just writing code. You can help by doing any of the following:

- Reporting bugs
- Reviewing pull requests
- Bringing ideas for the new features
- Answering questions on issues
- Documentation improvements
- Fixing bugs
- Adding new features

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant code](http://contributor-covenant.org/) of conduct.

## License

Calabash Launcher is released under an MIT license. See [LICENSE](LICENSE) for more information.
