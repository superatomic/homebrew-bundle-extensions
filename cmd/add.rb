# frozen_string_literal: true

module Homebrew
    module_function

    def add_args
        Homebrew::CLI::Parser.new do
            description <<~EOS
                Add one or more <formula>e and/or <cask>s to a `Brewfile`.

                You can specify the `Brewfile` location using `--file`, `--global`,
                or by setting the `HOMEBREW_BUNDLE_FILE` environment variable.

                To use single quotes instead of double quotes for Brewfile lines (e.g. `brew 'bat'` instead of `brew "bat"`),
                set the environment variable `HOMEBREW_BUNDLE_QUOTE_TYPE` to the value `single`.
            EOS

            switch "-g", "--global",
                description: "Read the `Brewfile` from `~/.Brewfile`."
            flag "--file=",
                description: "Read the `Brewfile` from this location. Use `--file=-` to pipe to stdin/stdout."

            conflicts "global", "file"

            switch "--formula", "--formulae", description: "Treat all named arguments as formulae."
            switch "--cask", "--casks", description: "Treat all named arguments as casks."
            switch "--describe",
                env:         :bundle_dump_describe,
                description: "Add a descriptive comment above each line, unless the " \
                             "package does not have a description. " \
                             "This is enabled by default if `HOMEBREW_BUNDLE_DUMP_DESCRIBE` is set."

            conflicts "formula", "cask"

            named_args [:formula, :cask], min: 1
        end
    end

    def add
        args = add_args.parse
        silent = args.quiet?

        brews = args.named.to_formulae_and_casks

        # Require this file: https://github.com/Homebrew/homebrew-bundle/blob/master/lib/bundle.rb
        require_relative "../../../homebrew/homebrew-bundle/lib/bundle"

        brewfile = Bundle::Brewfile.path(global: args.global?, file: args.file)

        # If the Brewfile doesn't end with a trailing newline, we need to add one ourselves.
        # Read the file to see if we need to add one.
        begin
            no_trailing_newline = File.read(brewfile)[-1] != "\n"
        rescue Errno::ENOENT # If the file doesn't exist, create a blank one.
            File.write(brewfile, "", mode: "a+")
            opoo "'#{brewfile}' did not exist and was created"
            no_trailing_newline = false # There's no previous content, so we don't need to add a newline.
        end

        ohai "Using Brewfile at '#{brewfile}'" unless silent

        # Parse the Brewfile and create separate arrays for formulae, casks, and taps.
        parsed_entries = Bundle::Dsl.new(brewfile.read).entries
        bundle_taps, bundle_formulae, bundle_casks = [], [], []
        parsed_entries.each do |entry|
            case entry.type
                when :tap; bundle_taps
                when :brew; bundle_formulae
                when :cask; bundle_casks
                else; next # Matches `mas` and `whalebrew`. This fixes issue #1.
            end << entry.name
        end

        # Use single quotes instead of double quotes in the Brewfile if the environment variable HOMEBREW_BUNDLE_QUOTE_TYPE is set to "single"
        quote_type = ENV['HOMEBREW_BUNDLE_QUOTE_TYPE'] != 'single' ? '"' : '\''

        # Open the Brewfile and add the requested items to it.
        File.open(brewfile, 'a+') do |file|
            # Add a newline to the end of the file if needed.
            file << "\n" if no_trailing_newline

            brews.each do |brew|

                # Get the corresponding reference list and terms for the given item.
                current_bundle_list, brewfile_prefix_type, display_type, brew_name, resolved_brew_name = if brew.is_a?(Formula)
                    [bundle_formulae, "brew", "Formula", brew.name, Formulary.resolve(brew.name)]
                else
                    [bundle_casks, "cask", "Cask", brew.token, Cask::CaskLoader.load(brew.token)]
                end

                # If the formula/cask is from a tap that isn't tapped yet in the file, add it first.
                # Make sure not to tap homebrew/core or homebrew/cask, since these formulae install from the API. (Fixes issue #12)
                unless bundle_taps.include?(brew.tap.name) || ['homebrew/core', 'homebrew/cask'].include?(brew.tap.name)
                    file << "tap #{quote_type}#{brew.tap.name}#{quote_type}" << "\n"
                    oh1 "Added Tap #{Formatter.identifier(brew.tap.name)} to Brewfile" unless silent

                    # Add the tap to the array for future iterations, so we don't add it to the Brewfile multiple times.
                    bundle_taps << brew.tap.name
                end

                # Check to see if the brew name (excluding tap) resolves to the full name (including tap).
                brew_name_resolves_to_full_name = resolved_brew_name.full_name == brew.full_name

                # Add the formula/cask to the file if it hasn't already been added.
                unless current_bundle_list.include?(brew.full_name) || (brew_name_resolves_to_full_name && current_bundle_list.include?(brew_name))
                    # Add a descriptive comment if requested.
                    # Adapted from `BrewDumper.dump`:
                    # https://github.com/Homebrew/homebrew-bundle/blob/e4798d8075e1a793f065be3e5e1674ec09193d17/lib/bundle/brew_dumper.rb#L59-L63
                    file << brew.desc.split("\n").map { |s| "# #{s}\n" }.join if args.describe? && brew.desc

                    file << "#{brewfile_prefix_type} #{quote_type}#{brew.full_name}#{quote_type}" << "\n"

                    oh1 "Added #{display_type} #{Formatter.identifier(brew.full_name)} to Brewfile" unless silent

                    # Add the formula/cask to the array for future iterations, so we don't add it to the Brewfile multiple times.
                    # This might not be necessary.
                    current_bundle_list << brew.full_name
                else
                    opoo "#{display_type} '#{brew.full_name}' is already in the Brewfile. Skipping." unless silent
                end
            end
        end
    end
end
