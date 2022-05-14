# frozen_string_literal: true

module Homebrew
    module_function

    def file_args
        Homebrew::CLI::Parser.new do
            description <<~EOS
                Opens a `Brewfile` in the default editor.

                Configure by setting `$HOMEBREW_EDITOR` or `$EDITOR`.

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

    def file
        args = file_args.parse

        # Require this file: https://github.com/Homebrew/homebrew-bundle/blob/master/lib/bundle.rb
        require_relative "../../../homebrew/homebrew-bundle/lib/bundle"

        brewfile = Bundle::Brewfile.path(global: args.global?, file: args.file)

        ohai "Opened '#{brewfile}'" unless args.quiet?

        system which_editor, brewfile
    end
end
