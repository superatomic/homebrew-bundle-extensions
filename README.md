# Homebrew Bundle Extensions

**Homebrew Bundle Extensions** adds command extensions to [Homebrew] that allow for easy modification of [brew bundles].

## Installation

Install [Homebrew] first if it isn't already installed, then run:

```shell
brew tap superatomic/bundle-extensions
```

Alternatively, you can add `homebrew-bundle-extensions` to your `Brewfile` by adding this line:

```ruby
tap "superatomic/bundle-extensions"
```

## Commands

- **`brew add [FORMULA/CASK...]`**

  Intelligently adds one or more provided formulae and/or casks to a `Brewfile`.

  You can specify multiple formulae and casks at once, just like the `brew install` command.

  To use single quotes instead of double quotes for Brewfile lines (e.g. `brew 'bat'` instead of `brew "bat"`),
  set the environment variable `HOMEBREW_BUNDLE_QUOTE_TYPE` to the value `single`.

- **`brew drop [FORMULA/CASK...]`**

  Removes one or more provided formulae and/or casks from a `Brewfile`.

  You can specify multiple formulae and casks at once, just like the `brew uninstall` command.

- **`brew file`**

  Opens the `Brewfile` in the default editor (respects the chosen homebrew editor).

  Configure by setting `$HOMEBREW_EDITOR` or `$EDITOR`.

- **`brew view`**

  Displays the `Brewfile`.
  Uses [`bat`][bat] instead of `cat` if `$HOMEBREW_BAT` is set.

All commands support specifying a Brewfile's location using `--file`, `--global`,
or by setting the `$HOMEBREW_BUNDLE_FILE` environment variable.

## License

This project is duel-licensed under the [BSD 2-Clause "Simplified" License](LICENSE-BSD) and the [MIT License](LICENSE-MIT).

[Homebrew]: https://brew.sh
[brew bundles]: https://github.com/Homebrew/homebrew-bundle
[bat]: https://github.com/sharkdp/bat

<!-- Project inspired by cargo-edit. Thank you. https://github.com/killercup/cargo-edit -->
