# Calabash Launcher

Calabash Launcher is a macOS app that helps you run and manage Calabash tests on your Mac.

![calabash-launcher](https://user-images.githubusercontent.com/4190298/31447991-9ea646a2-aea3-11e7-9b4e-353399805409.png)

## Test Runner

The Test Runner lets you run your tests using whatever configuration required. It supports:

- Running on simulator
- Running on a physical device
- Running in different languages
- Test tags
- Console

## Element Inspector

With the Element Inspector you can "browse" your app via its elements. It supports:

- Device element highlighting
- Accessing an element's address
- Accessing an element's localized object
- Visual representation of the device

## Project Status

This project is actively under development, and it is used at XING.

## Prerequisites

- MacOS Sierra
- Xcode 8.3+
- iOS Simulators >= 10.1
- ruby >= 2.0 (2.3.1 is preferred)
- bundler >= 1.15.0
- calabash-ios >= 0.20.5

## Usage

### Test Runner

1. After start **Calabash Launcher** will ask you to give the path to the repository with your Calabash tests and Cucumber profile(leave it empty if you don't use any).
2. After restart you will be able to configure your test run by choosing Simulator, Language and Cucumber tag you want to execute.
3. Click "Run Test" button to start tests. Check the output window for the results.

### Element Inspector

(!) Inspector is limited by working only using iPhone 6, iPhone 7 or iPhone 8. Please make sure that one of these devices is launched when you search for elements.

- Clicking on the right window in the view will sync your Inspector with the simulator (automatic sync will be performed every 5 seconds)
- Clicking on any element in the synchronised window will show the element Class + id or label if they exist.
- Clicking on nested menu of the appeared element will show you the element hierarchy.

## Troubleshooting

- **Calabash Launcher** not going to work if you cannot run `bundle exec calabash-ios console` from your terminal. 
Sometimes the problem could live in Ruby installation and conflicts with `readline`. To fix the problem re-install Ruby.

- You can reset APP Settings to defaults by pressing `Command + R` on your keyboard.

## Contributing
Want to help improving Calabash Launcher? We could really use your help!

Open source isn't just writing code. You could help by any of the following:

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
