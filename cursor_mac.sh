#!/bin/bash

# Define variables
APP_PATH="/Applications/Cursor.app"
CLI_BIN="$APP_PATH/Contents/Resources/app/bin/cursor"
CLI_LINK="/opt/homebrew/bin/cursor"
BUNDLE_ID="com.todesktop.230313mzl4w4u92"

# Function to quit Cursor if it is running
quitCursor() {
    if pgrep -xq "Cursor"; then
        echo "Cursor is currently running. Quitting it..."
        osascript -e 'quit app "Cursor"' 2>/dev/null

        # Wait up to 15 seconds for a graceful shutdown
        for _ in $(seq 1 15); do
            pgrep -xq "Cursor" || break
            sleep 1
        done

        if pgrep -xq "Cursor"; then
            echo "Cursor did not quit gracefully. Forcing it to close..."
            pkill -x "Cursor"
            sleep 2
        fi
    fi
}
    
# Function to install or update Cursor AI IDE
installCursor() {
    # Fetch the latest version from GitHub repository
    echo "Fetching latest Cursor version information..."
    local GITHUB_INFO=$(curl -s "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md")
    # Get latest version by finding the first Linux AppImage file name (versions are listed per release)
    local CURSOR_VERSION=$(echo "$GITHUB_INFO" | grep -o 'Cursor-[0-9.]\+-x86_64.AppImage' | head -1 | cut -d'-' -f2)
    # Extract the Apple Silicon (arm64) DMG download link
    local CURSOR_URL=$(echo "$GITHUB_INFO" | grep -o 'https://downloads.cursor.com/production/[^") ]*/darwin/arm64/Cursor-darwin-arm64\.dmg' | head -1)

    if [ -z "$CURSOR_URL" ]; then
        echo "Error: Failed to fetch download URL. Please check your internet connection."
        exit 1
    fi

    echo "Found latest Cursor version: $CURSOR_VERSION"
    echo "Download URL: $CURSOR_URL"

    echo "Checking for existing Cursor installation..."

    # Notify if updating an existing installation
    if [ -d "$APP_PATH" ]; then
        local INSTALLED_VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)
        echo "Cursor AI IDE is already installed (version $INSTALLED_VERSION)."
        if [ "$INSTALLED_VERSION" = "$CURSOR_VERSION" ]; then
            echo "You already have the latest version. Nothing to do."
            exit 0
        fi
        echo "Updating existing installation..."
    else
        echo "Performing a fresh installation of Cursor AI IDE..."
    fi

    # Download DMG
    local DMG_PATH=$(mktemp -t cursor).dmg
    echo "Downloading Cursor DMG..."
    curl -L "$CURSOR_URL" -o "$DMG_PATH" || { echo "Failed to download DMG."; exit 1; }

    # Mount the DMG
    echo "Mounting DMG..."
    local MOUNT_POINT=$(mktemp -d -t cursor-mount)
    if ! hdiutil attach "$DMG_PATH" -nobrowse -readonly -mountpoint "$MOUNT_POINT" >/dev/null; then
        echo "Failed to mount DMG."
        rm -f "$DMG_PATH"
        exit 1
    fi

    # Make sure Cursor is not running while we replace the app bundle
    quitCursor

    # Replace the app bundle
    echo "Installing Cursor.app to /Applications..."
    rm -rf "$APP_PATH"
    if ! ditto "$MOUNT_POINT/Cursor.app" "$APP_PATH"; then
        echo "Failed to copy Cursor.app to /Applications."
        hdiutil detach "$MOUNT_POINT" -quiet
        rm -f "$DMG_PATH"
        exit 1
    fi

    # Unmount and clean up
    echo "Cleaning up..."
    hdiutil detach "$MOUNT_POINT" -quiet
    rm -f "$DMG_PATH"

    # Link the bundled CLI into Homebrew's bin so 'cursor' works in the terminal
    echo "Linking 'cursor' command to $CLI_LINK..."
    ln -sfn "$CLI_BIN" "$CLI_LINK"

    # Inform the user about the installation completion
    echo "Installation complete! You can now run Cursor by:"
    echo "1. Opening it from /Applications or Spotlight"
    echo "2. Running 'cursor' in the terminal"

    echo "Cursor AI IDE installation or update complete."
}

# Function to uninstall Cursor AI IDE
uninstallCursor() {
    echo "Uninstalling Cursor AI IDE..."

    # Make sure Cursor is not running
    quitCursor

    # Remove the app bundle
    echo "Removing application files..."
    rm -rf "$APP_PATH"

    # Remove the CLI symlink
    echo "Removing 'cursor' command..."
    rm -f "$CLI_LINK"

    # Remove configuration and cache
    echo "Removing user configuration and cache..."
    rm -rf "$HOME/Library/Application Support/Cursor"
    rm -rf "$HOME/Library/Caches/$BUNDLE_ID"*
    rm -rf "$HOME/Library/Saved Application State/$BUNDLE_ID.savedState"
    rm -f "$HOME/Library/Preferences/$BUNDLE_ID.plist"
    rm -rf "$HOME/Library/Logs/Cursor"
    rm -rf "$HOME/.cursor"

    echo "Cursor AI IDE has been completely uninstalled."
}

# Dialog to choose between install/update or uninstall
echo "Choose an option:"
echo "1. Install/Update Cursor AI IDE"
echo "2. Uninstall Cursor AI IDE"
read -p "Enter your choice [1-2]: " choice

case $choice in
    1)
        installCursor
        ;;
    2)
        uninstallCursor
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
