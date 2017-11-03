# Calabash Launcher

Calabash Launcher is a macOS app that helps you run and manage Calabash tests on your Mac.


## Test Runner
![calabash-launcher](https://user-images.githubusercontent.com/18147900/32107640-8afc2c32-bb2f-11e7-83bf-857bb5b86709.png)
The Test Runner lets you run your tests using whatever configuration required. It supports:

- Running on simulator
- Running on a physical device
- Running in different languages
- Test tags
- Console

## Element Inspector
![calabash-launcher](https://user-images.githubusercontent.com/18147900/32107411-c7c68bd6-bb2e-11e7-8ae2-4d87b833c8fb.png)
With the Element Inspector you can "browse" your app via its elements. It supports:

- Device element highlighting
- Accessing an element's address
- Accessing an element's localized object
- Visual representation of the device


## Project Status

This project is actively under development, and it is used at XING.

## Prerequisites

- MacOS Sierra
- Xcode 9.0+
- iOS Simulators >= 10.1
- Ruby >= 2.0 (2.3.1 is preferred)
- `bundler` >= 1.15.0
- `calabash-ios` >= 0.20.5

## Usage

### Test Runner

1. When opening Calabash Launcher the first time, it will ask you to give the path to the repository with your Calabash tests and (optionally) your Cucumber profile.
2. After a restart you will be able to configure your testrun by choosing a simulator, language and cucumber tag you want to execute.
3. Click `Run Test` to start the tests. Results will appear in the output window.

### Element Inspector

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
