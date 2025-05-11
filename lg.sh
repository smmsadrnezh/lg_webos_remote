#!/bin/bash

# Check if lgtv command is installed
if ! command -v lgtv &> /dev/null; then
    echo "lgtv command is not installed. Installing instructions:"
    echo "1. Install using: pipx install git+https://github.com/klattimer/LGWebOSRemote.git"
    echo "2. Setup your TV with the following commands:"
    echo "   lgtv scan"
    echo "   lgtv --ssl auth [ip from previous command] lgtv"
    echo "   lgtv setDefault lgtv"
    echo ""
    read -p "Do you want to install lgtv now? (y/n): " choice
    if [[ $choice == "y" || $choice == "Y" ]]; then
        echo "Installing lgtv..."
        pipx install git+https://github.com/klattimer/LGWebOSRemote.git
        if [ $? -eq 0 ]; then
            echo "Installation successful. Please run the setup commands manually."
        else
            echo "Installation failed. Please install manually."
            exit 1
        fi
    else
        echo "Please install lgtv manually and run this script again."
        exit 1
    fi
fi

# Check if dialog is installed
if ! command -v dialog &> /dev/null; then
    echo "dialog utility is required but not installed."
    echo "Please install it using your package manager."
    echo "For example: sudo apt-get install dialog"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "jq utility is required but not installed."
    echo "Please install it using your package manager."
    echo "For example: sudo apt-get install jq"
    exit 1
fi

# Helper function to execute lgtv commands and display output
execute_lgtv_command() {
    local command="$1"
    local args="$2"
    local success_msg="$3"

    # Create a temporary file for the command output
    local output_file=$(mktemp)

    # Show a loading message
    dialog --infobox "Executing command..." 3 30

    # Execute the command and capture output
    if [ "$command" = "startApp" ]; then
        # For startApp, always pass the app ID directly without quotes
        lgtv --ssl startApp $args > "$output_file" 2>&1
    elif [ -z "$args" ]; then
        # For commands that don't need arguments, don't pass an empty argument
        lgtv --ssl "$command" > "$output_file" 2>&1
    else
        lgtv --ssl "$command" "$args" > "$output_file" 2>&1
    fi
    local exit_code=$?

    # Read the output
    local output=$(cat "$output_file")

    # Remove the temporary file
    rm -f "$output_file"

    # Check if the command was successful
    if [ $exit_code -eq 0 ]; then
        # Always show the command and its output
        local display_text
        if [ "$command" = "startApp" ]; then
            display_text="Command: lgtv --ssl startApp $args\n\nOutput:\n$output"
        elif [ -z "$args" ]; then
            display_text="Command: lgtv --ssl \"$command\"\n\nOutput:\n$output"
        else
            display_text="Command: lgtv --ssl \"$command\" \"$args\"\n\nOutput:\n$output"
        fi

        # Display the command and its output
        dialog --title "Command Output" --msgbox "$display_text" 20 70
    else
        # Check for specific error patterns
        if [[ "$output" == *"Connection reset by peer"* ]]; then
            # Connection error - TV might be off or unreachable
            local error_text
            if [ "$command" = "startApp" ]; then
                error_text="Command: lgtv --ssl startApp $args\n\nFailed to connect to the TV. The TV might be turned off, disconnected from the network, or unreachable.\n\nError details:\n$output"
            elif [ -z "$args" ]; then
                error_text="Command: lgtv --ssl \"$command\"\n\nFailed to connect to the TV. The TV might be turned off, disconnected from the network, or unreachable.\n\nError details:\n$output"
            else
                error_text="Command: lgtv --ssl \"$command\" \"$args\"\n\nFailed to connect to the TV. The TV might be turned off, disconnected from the network, or unreachable.\n\nError details:\n$output"
            fi
            dialog --title "Connection Error" --msgbox "$error_text" 15 70
        elif [[ "$output" == *"Invalid numeric literal"* || "$output" == *"parse error"* ]]; then
            # JSON parsing error
            local error_text
            if [ "$command" = "startApp" ]; then
                error_text="Command: lgtv --ssl startApp $args\n\nReceived invalid response from TV. The TV might be unreachable or the response format has changed.\n\nError details:\n$output"
            elif [ -z "$args" ]; then
                error_text="Command: lgtv --ssl \"$command\"\n\nReceived invalid response from TV. The TV might be unreachable or the response format has changed.\n\nError details:\n$output"
            else
                error_text="Command: lgtv --ssl \"$command\" \"$args\"\n\nReceived invalid response from TV. The TV might be unreachable or the response format has changed.\n\nError details:\n$output"
            fi
            dialog --title "Parse Error" --msgbox "$error_text" 15 70
        else
            # Generic error message
            local error_text
            if [ "$command" = "startApp" ]; then
                error_text="Command: lgtv --ssl startApp $args\n\nFailed with error:\n$output"
            elif [ -z "$args" ]; then
                error_text="Command: lgtv --ssl \"$command\"\n\nFailed with error:\n$output"
            else
                error_text="Command: lgtv --ssl \"$command\" \"$args\"\n\nFailed with error:\n$output"
            fi
            dialog --title "Error" --msgbox "$error_text" 15 70
        fi
    fi
}

# Function to display the power control menu
show_power_menu() {
    local options=(
        "1" "TV Power"
        "2" "Screen Power"
    )

    local choice=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Power Controls" \
        --menu "Select a power control:" 10 40 10 \
        "${options[@]}" \
        2>&1 >/dev/tty)

    case $choice in
        1)
            # TV Power submenu
            local tv_options=(
                "1" "Turn TV On"
                "2" "Turn TV Off"
            )
            local tv_choice=$(dialog --clear --backtitle "LG TV Remote Control" \
                --title "TV Power" \
                --menu "Select an option:" 10 40 10 \
                "${tv_options[@]}" \
                2>&1 >/dev/tty)

            case $tv_choice in
                1) execute_lgtv_command "on" "" "TV turned on successfully." ;;
                2) execute_lgtv_command "off" "" "TV turned off successfully." ;;
                *) return ;;
            esac
            ;;
        2)
            # Screen Power submenu
            local screen_options=(
                "1" "Turn Screen On"
                "2" "Turn Screen Off"
            )
            local screen_choice=$(dialog --clear --backtitle "LG TV Remote Control" \
                --title "Screen Power" \
                --menu "Select an option:" 10 40 10 \
                "${screen_options[@]}" \
                2>&1 >/dev/tty)

            case $screen_choice in
                1) execute_lgtv_command "screenOn" "" "Screen turned on successfully." ;;
                2) execute_lgtv_command "screenOff" "" "Screen turned off successfully." ;;
                *) return ;;
            esac
            ;;
        *) return ;;
    esac
}

# Function to display the volume control menu
show_volume_menu() {
    local options=(
        "1" "Volume Up"
        "2" "Volume Down"
        "3" "Set Volume"
    )

    local choice=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Volume Controls" \
        --menu "Select a volume control:" 10 40 10 \
        "${options[@]}" \
        2>&1 >/dev/tty)

    case $choice in
        1) execute_lgtv_command "volumeUp" "" "Volume increased." ;;
        2) execute_lgtv_command "volumeDown" "" "Volume decreased." ;;
        3) set_volume ;;
        *) return ;;
    esac
}

# Function to display the media control menu
show_media_menu() {
    local options=(
        "1" "Play"
        "2" "Pause"
        "3" "Rewind"
    )

    local choice=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Media Controls" \
        --menu "Select a media control:" 10 40 10 \
        "${options[@]}" \
        2>&1 >/dev/tty)

    case $choice in
        1) execute_lgtv_command "inputMediaPlay" "" "Media playback started." ;;
        2) execute_lgtv_command "inputMediaPause" "" "Media playback paused." ;;
        3) execute_lgtv_command "inputMediaRewind" "" "Media rewind started." ;;
        *) return ;;
    esac
}

# Function to display the main menu
show_main_menu() {
    local options=(
        "1" "Power Controls"
        "2" "Volume Controls"
        "3" "Media Controls"
        "4" "Set Input"
        "5" "Open URL"
        "6" "Start App"
        "7" "Send Notification"
    )

    local choice=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Main Menu" \
        --menu "Select an option:" 18 40 15 \
        "${options[@]}" \
        2>&1 >/dev/tty)

    case $choice in
        1) show_power_menu ;;
        2) show_volume_menu ;;
        3) show_media_menu ;;
        4) show_input_menu ;;
        5) open_url ;;
        6) start_app ;;
        7) send_notification ;;
        *)
            echo "Exiting..."
            exit 0
            ;;
    esac
}

# Function to set volume
set_volume() {
    local volume=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Set Volume" \
        --inputbox "Enter volume level (0-100):" 8 40 \
        2>&1 >/dev/tty)

    if [[ $? -eq 0 && $volume =~ ^[0-9]+$ && $volume -ge 0 && $volume -le 100 ]]; then
        execute_lgtv_command "setVolume" "$volume" "Volume set to $volume"
    else
        dialog --msgbox "Invalid volume level. Please enter a number between 0 and 100." 6 50
    fi
}

# Function to show input menu
show_input_menu() {
    # Create a temporary file for the command output
    local output_file=$(mktemp)

    # Show a loading message
    dialog --infobox "Loading inputs list..." 3 30

    # Get the list of inputs and save to a temporary file
    lgtv --ssl listInputs > "$output_file" 2>&1

    # Read the output
    local cmd_output=$(cat "$output_file")

    # Check if the command was successful
    if [ $? -ne 0 ]; then
        local error_output=$(cat "$output_file")
        rm -f "$output_file"
        dialog --msgbox "Failed to get inputs list: $error_output" 10 60
        return
    fi

    # Copy the output to the expected location
    cp "$output_file" /tmp/lg_inputs.json
    rm -f "$output_file"

    # Create a temporary file for the menu options
    > /tmp/lg_inputs_menu.txt

    # Parse the JSON and extract input IDs and labels
    # Format: "input_id" "input_label"
    if [ -s /tmp/lg_inputs.json ]; then
        # Check if the file contains valid JSON
        if head -1 /tmp/lg_inputs.json | jq . &>/dev/null; then
            head -1 /tmp/lg_inputs.json | jq -r '.payload.devices[] | "\(.id) \(.label)"' 2>/dev/null | \
            while read -r id label; do
                echo "\"$id\" \"$label\"" >> /tmp/lg_inputs_menu.txt
            done
        else
            dialog --msgbox "Error: Invalid JSON response from TV. The TV might be unreachable or the response format has changed." 8 60
            rm -f /tmp/lg_inputs.json /tmp/lg_inputs_menu.txt
            return
        fi
    fi

    # Check if we have any inputs
    if [ ! -s /tmp/lg_inputs_menu.txt ]; then
        dialog --msgbox "No inputs found or error parsing inputs list." 6 50
        rm -f /tmp/lg_inputs.json /tmp/lg_inputs_menu.txt
        return
    fi

    # Create the dialog menu command
    cmd=(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Select Input" \
        --menu "Choose an input source:" 20 60 15)

    # Add the options from the file
    options=()
    while read -r line; do
        eval "options+=($line)"
    done < /tmp/lg_inputs_menu.txt

    # Display the menu and get the selected input ID
    input_id=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    # Check if an input was selected
    if [ $? -eq 0 ] && [ -n "$input_id" ]; then
        # Set the selected input
        execute_lgtv_command "setInput" "$input_id" "Input set to: $input_id"
    fi

    # Clean up temporary files
    rm -f /tmp/lg_inputs.json /tmp/lg_inputs_menu.txt
}

# Function to open URL (detects if it's a YouTube URL)
open_url() {
    local url=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Open URL" \
        --inputbox "Enter URL to open:" 8 60 \
        2>&1 >/dev/tty)

    if [[ $? -eq 0 && -n "$url" ]]; then
        # Check if it's a YouTube URL
        if [[ "$url" == *"youtube.com"* || "$url" == *"youtu.be"* ]]; then
            execute_lgtv_command "openYoutubeURL" "$url" "URL opened in YouTube app: $url"
        else
            execute_lgtv_command "openBrowserAt" "$url" "URL opened in browser: $url"
        fi
    fi
}


# Function to send a notification to the TV
send_notification() {
    local message=$(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Send Notification" \
        --inputbox "Enter notification message:" 8 60 \
        2>&1 >/dev/tty)

    if [[ $? -eq 0 && -n "$message" ]]; then
        execute_lgtv_command "notification" "$message" "Notification sent: $message"
    fi
}

# Function to start an app
start_app() {
    # Create a temporary file for the command output
    local output_file=$(mktemp)

    # Show a loading message
    dialog --infobox "Loading apps list..." 3 30

    # Get the list of apps and save to a temporary file
    lgtv --ssl listApps > "$output_file" 2>&1

    # Read the output
    local cmd_output=$(cat "$output_file")

    # Check if the command was successful
    if [ $? -ne 0 ]; then
        local error_output=$(cat "$output_file")
        rm -f "$output_file"
        dialog --msgbox "Failed to get apps list: $error_output" 10 60
        return
    fi

    # Copy the output to the expected location
    cp "$output_file" /tmp/lg_apps.json
    rm -f "$output_file"

    # Create a temporary file for the menu options
    > /tmp/lg_apps_menu.txt

    # Parse the JSON and extract app names and IDs
    # Format: "app_name" "app_id"
    if [ -s /tmp/lg_apps.json ]; then
        # Check if the file contains valid JSON
        if head -1 /tmp/lg_apps.json | jq . &>/dev/null; then
            head -1 /tmp/lg_apps.json | jq -r '.payload.apps[] | "\(.title)|\(.id)"' 2>/dev/null | sort | \
            while IFS='|' read -r title id; do
                echo "\"$title\" \"$id\"" >> /tmp/lg_apps_menu.txt
            done
        else
            dialog --msgbox "Error: Invalid JSON response from TV. The TV might be unreachable or the response format has changed." 8 60
            rm -f /tmp/lg_apps.json /tmp/lg_apps_menu.txt
            return
        fi
    fi

    # Check if we have any apps
    if [ ! -s /tmp/lg_apps_menu.txt ]; then
        dialog --msgbox "No apps found or error parsing apps list." 6 50
        rm -f /tmp/lg_apps.json /tmp/lg_apps_menu.txt
        return
    fi

    # Create the dialog menu command
    cmd=(dialog --clear --backtitle "LG TV Remote Control" \
        --title "Select App to Start" \
        --menu "Choose an app:" 20 60 15)

    # Add the options from the file
    options=()
    while read -r line; do
        eval "options+=($line)"
    done < /tmp/lg_apps_menu.txt

    # Display the menu and get the selected app name
    selected_app_name=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    # Check if an app was selected
    if [ $? -eq 0 ] && [ -n "$selected_app_name" ]; then
        # Find the app ID corresponding to the selected app name
        app_id=""
        while read -r line; do
            eval "option=($line)"
            if [ "${option[0]}" = "$selected_app_name" ]; then
                app_id="${option[1]}"
                break
            fi
        done < /tmp/lg_apps_menu.txt

        # Start the selected app using the execute_lgtv_command function
        # Use app_id directly for all apps
        execute_lgtv_command "startApp" "$app_id" "App started: $app_id (${selected_app_name})"
    fi

    # Clean up temporary files
    rm -f /tmp/lg_apps.json /tmp/lg_apps_menu.txt
}

# Show the interactive menu
# Main loop
while true; do
    show_main_menu

    # Ask if user wants to continue
    dialog --yesno "Do you want to perform another action?" 7 60
    if [[ $? -ne 0 ]]; then
        break
    fi
done

echo "Thank you for using LG TV Remote Control!"
echo "You can scroll up to see the history of your commands and their outputs."
exit 0
