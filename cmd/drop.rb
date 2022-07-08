# frozen_string_literal: true

module Homebrew
    module_function

    def drop_args
        Homebrew::CLI::Parser.new do
            description <<~EOS
                Drop one or more <formula>e and/or <cask>s from a `Brewfile`.

                You can specify the `Brewfile` location using `--file`, `--global`,
                or by setting the `HOMEBREW_BUNDLE_FILE` environment variable.
            EOS

            switch "-g", "--global",
                description: "Read the `Brewfile` from `~/.Brewfile`."
            flag "--file=",
                description: "Read the `Brewfile` from this location. Use `--file=-` to pipe to stdin/stdout."

            conflicts "global", "file"

            switch "--formula", "--formulae", description: "Treat all named arguments as formulae."
            switch "--cask", "--casks", description: "Treat all named arguments as casks."

            conflicts "formula", "cask"

            named_args [:formula, :cask], min: 1
        end
    end

    def drop
        args = drop_args.parse
        silent = args.quiet?

        brews = args.named.to_formulae_and_casks

        # Require this file: https://github.com/Homebrew/homebrew-bundle/blob/master/lib/bundle.rb
        require_relative "../../../homebrew/homebrew-bundle/lib/bundle"

        brewfile = Bundle::Brewfile.path(global: args.global?, file: args.file)

        ohai "Using Brewfile at '#{brewfile}'" unless silent

        # Parse the Brewfile and create separate arrays for formulae, casks, and taps.
        parsed_entries = Bundle::Dsl.new(brewfile.read).entries
        bundle_taps, bundle_formulae, bundle_casks = [], [], []
        parsed_entries.each do |entry|
            case entry.type
                when :tap; bundle_taps
                when :brew; bundle_formulae
                when :cask; bundle_casks
                else; next # Matches `mas` and `whalebrew`.
            end << entry.name
        end

        # Open the Brewfile and drop the requested items from it.
        brews.each do |brew|

            # Get the corresponding reference list and terms for the given item.
            current_bundle_list, brewfile_prefix_type, display_type, brew_name, resolved_brew_name = if brew.is_a?(Formula)
                [bundle_formulae, "brew", "Formula", brew.name, Formulary.resolve(brew.name)]
            else
                [bundle_casks, "cask", "Cask", brew.token, Cask::CaskLoader.load(brew.token)]
            end

            # Check to see if the brew name (excluding tap) resolves to the full name (including tap).
            brew_name_resolves_to_full_name = resolved_brew_name.full_name == brew.full_name

            # Drop the formula/cask from the file if it exists.
            unless current_bundle_list.include?(brew.full_name) || (brew_name_resolves_to_full_name && current_bundle_list.include?(brew_name))
                opoo "#{display_type} '#{brew.full_name}' is not present in the Brewfile. Skipping." unless silent
            else

                # Get the correct regex to match for the brew name.
                regex_name = if brew_name_resolves_to_full_name
                    "#{brew.full_name}|#{brew_name}"
                else
                    brew.full_name
                end

                lines = []
                has_removed_line = false

                File.foreach(brewfile) do |line|
                    unless line.match(/^\s*#{brewfile_prefix_type}\s+["'](#{regex_name})["']/)
                        lines.push(line)
                    else
                        has_removed_line = true
                    end
                end

                # Check to see if any lines were dropped from the file. If not, that's an error!
                if has_removed_line
                    # Write back all lines that weren't dropped.
                    File.open(brewfile, "w+") do |f|
                        f.puts(lines)
                    end

                    oh1 "Dropped #{display_type} #{Formatter.identifier(brew.full_name)} from Brewfile" unless silent
                else
                    ofail <<~EOS
                        Couldn't remove #{display_type} #{Formatter.identifier(brew.full_name)} from Brewfile
                        Please open an issue on GitHub:
                            https://github.com/superatomic/homebrew-bundle-extensions
                    EOS
                end
            end
        end
    end
end
