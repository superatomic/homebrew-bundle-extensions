# frozen_string_literal: true

module Homebrew
    module_function

    def view_args
        Homebrew::CLI::Parser.new do
            description <<~EOS
                Displays a `Brewfile`.

                Uses `bat` instead of `cat` if `$HOMEBREW_BAT` is set.

                You can specify the `Brewfile` location using `--file`, `--global`,
                or by setting the `HOMEBREW_BUNDLE_FILE` environment variable.
            EOS

            switch "-g", "--global",
                description: "Read the `Brewfile` from `~/.Brewfile`."
            flag "--file=",
                description: "Read the `Brewfile` from this location. Use `--file=-` to pipe to stdin/stdout."

            conflicts "global", "file"
        end
    end

    def view
        args = view_args.parse

        # Require this file: https://github.com/Homebrew/homebrew-bundle/blob/master/lib/bundle.rb
        require_relative "../../../homebrew/homebrew-bundle/lib/bundle"

        brewfile = Bundle::Brewfile.path(global: args.global?, file: args.file)

        # Determine whether to use `bat` or `cat`.
        pager = if Homebrew::EnvConfig.bat?
            ENV["BAT_CONFIG_PATH"] = Homebrew::EnvConfig.bat_config_path
            ensure_executable!("bat", "bat", reason: "displaying Brewfile")
        else
            "cat"
        end

        system pager, brewfile
    end
end
