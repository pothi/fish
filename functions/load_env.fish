function load_env --description 'Load environment variables from a file (defaults to ./.env then ~/.env)'
    # 1. Determine which file to target
    set -l target_file ""

    if test (count $argv) -ge 1
        # Explicit file path supplied by user
        set target_file $argv[1]
    else if test -f .env
        # Fallback 1: Current directory .env
        set target_file .env
    else if test -f ~/.env
        # Fallback 2: Home directory .env
        set target_file ~/.env
    else
        echo "load_env: No .env file found in current directory or ~/" >&2
        return 1
    end

    # 2. Validate that the targeted file actually exists/is readable
    if not test -f "$target_file"
        echo "load_env: File '$target_file' not found" >&2
        return 1
    end

    # 3. Parse file line by line using native input redirection
    while read -l line
        # Clean up whitespace and skip empty lines or comments
        set -l trimmed (string trim -- $line)
        if test -z "$trimmed"; or string match -q -- '#*' $trimmed
            continue
        end

        # Split on the first '=' character only (safely handles keys starting with hyphens)
        set -l item (string split -m 1 -- '=' $trimmed)

        if test (count $item) -ge 1
            set -l key (string trim -- $item[1])

            if test -n "$key"
                # Validate variable name pattern
                if not string match -q -r '^[a-zA-Z_][a-zA-Z0-9_]*$' -- $key
                    echo "load_env: Skipping invalid key '$key'" >&2
                    continue
                end

                # Extract and clean the value
                set -l value (string trim -- $item[2])

                # Strip surrounding single or double quotes natively
                if string match -q -- '"*"' $value; or string match -q -- "'*'" $value
                    # Drops the first and last character safely
                    set value (string sub -s 2 -l (math (string length -- $value) - 2) -- $value)
                end

                # Export globally to the environment
                set -gx $key $value
            end
        end
    end < $target_file
end
