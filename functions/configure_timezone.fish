function configure_timezone --description "Configure server timezone with validation and fallback to .env"
    # 1. Determine the target timezone
    set -l target_tz $argv[1]

    # If not provided as an argument, look for a .env file
    if test -z "$target_tz"
        # Try using your existing load_env function if it exists
        if functions -q load_env
            load_env
            # Assuming the variable inside .env is named TIMEZONE or TZ
            if test -n "$TIMEZONE"
                set target_tz $TIMEZONE
            else if test -n "$TZ"
                set target_tz $TZ
            end
        # Backup solution if load_env is missing and ~/.env exists
        else if test -f ~/.env
            # Parse key=value pairs, stripping potential quotes
            set -l env_tz (string match -r '^[^#]*?\b(?:TIMEZONE|TZ)\s*=\s*["\']?([^"\']+)["\']?' < ~/.env)
            if test -n "$env_tz[2]"
                set target_tz $env_tz[2]
            end
        end
    end

    # Default to UTC if no timezone was provided or found in .env
    if test -z "$target_tz"
        set target_tz "UTC"
    end

    # 2. Get the current system timezone
    # timedatectl show -p Timezone --value is clean and fast
    set -l current_tz (timedatectl show -p Timezone --value)

    # 3. Check if it's already set to the target
    if test "$current_tz" = "$target_tz"
        echo "Timezone is already set to $target_tz."
        return 0
    end

    # 4. Validate the target timezone against system list
    if not contains -- "$target_tz" (timedatectl list-timezones)
        echo "Error: '$target_tz' is not a valid timezone on this system." >&2
        return 1
    end

    # 5. Apply the timezone change (requires sudo)
    echo "Updating system timezone from $current_tz to $target_tz..."
    if sudo timedatectl set-timezone "$target_tz"
        echo "Timezone successfully updated to $target_tz."
        return 0
    else
        echo "Error: Failed to set timezone. Check sudo privileges." >&2
        return 1
    end
end
