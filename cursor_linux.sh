#!/bin/bash

# Define variables
APPIMAGE_PATH="/opt/cursor.appimage"
ICON_PATH="/opt/cursor.png"
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"


# Determine the shell and RC file
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    bash)
        RC_FILE="$HOME/.bashrc"
        ;;
    zsh)
        RC_FILE="$HOME/.zshrc"
        ;;
    fish)
        RC_FILE="$HOME/.config/fish/config.fish"
        ;;
    *)
        echo "Unsupported shell: $SHELL_NAME"
        exit 1
        ;;
esac

# Function to install or update Cursor AI IDE
installCursor() {
    # Fetch the latest version from GitHub repository
    echo "Fetching latest Cursor version information..."
    local GITHUB_INFO=$(curl -s "https://raw.githubusercontent.com/oslook/cursor-ai-downloads/main/README.md")
    # Get latest version by finding the first Linux AppImage file name
    local CURSOR_VERSION=$(echo "$GITHUB_INFO" | grep -o 'Cursor-[0-9.]\+-x86_64.AppImage' | head -1 | cut -d'-' -f2)
    # Extract clean URL by looking for the download link that ends with AppImage
    local CURSOR_URL=$(echo "$GITHUB_INFO" | grep -o 'https://downloads.cursor.com/production/[^"]*\.AppImage' | head -1)
    
    if [ -z "$CURSOR_URL" ]; then
        echo "Error: Failed to fetch download URL. Please check your internet connection."
        exit 1
    fi
    
    echo "Found latest Cursor version: $CURSOR_VERSION"
    echo "Download URL: $CURSOR_URL"
    
    local ICON_URL="https://registry.npmmirror.com/@lobehub/icons-static-png/1.13.0/files/light/cursor.png"

    echo "Checking for existing Cursor installation..."

    # Notify if updating an existing installation
    if [ -f "$APPIMAGE_PATH" ]; then
        echo "Cursor AI IDE is already installed. Updating existing installation..."
    else
        echo "Performing a fresh installation of Cursor AI IDE..."
    fi

    # Ensure required packages are installed
    for package in curl libfuse2; do
        if ! dpkg -s $package >/dev/null 2>&1; then
            echo "$package is not installed. Installing..."
            if ! sudo apt-get update; then
                echo "Failed to update package list."
                exit 1
            fi
            if ! sudo apt-get install -y $package; then
                echo "Failed to install $package."
                exit 1
            fi
        fi
    done

    # Download AppImage and Icon
    echo "Downloading Cursor AppImage..."
    curl -L "$CURSOR_URL" -o /tmp/cursor.appimage || { echo "Failed to download AppImage."; exit 1; }

    echo "Downloading Cursor icon..."
    curl -L "$ICON_URL" -o /tmp/cursor.png || { echo "Failed to download icon."; exit 1; }

    # Move to final destination
    echo "Installing Cursor files..."
    sudo mv /tmp/cursor.appimage "$APPIMAGE_PATH"
    sudo chmod +x "$APPIMAGE_PATH"
    sudo mv /tmp/cursor.png "$ICON_PATH"

    # Create a .desktop entry
    echo "Creating .desktop entry..."
    sudo bash -c "cat > $DESKTOP_ENTRY_PATH" <<EOL
[Desktop Entry]
Name=Cursor AI IDE
Exec=$APPIMAGE_PATH --no-sandbox
Icon=$ICON_PATH
Type=Application
Categories=Development;
EOL

    # Add alias to the appropriate RC file
    echo "Adding cursor alias to $RC_FILE..."
    if [ "$SHELL_NAME" = "fish" ]; then
        # Fish shell uses a different syntax for functions
        if ! grep -q "function cursor" "$RC_FILE"; then
            echo "function cursor" >> "$RC_FILE"
            echo "    /opt/cursor.appimage --no-sandbox \$argv > /dev/null 2>&1 & disown" >> "$RC_FILE"
            echo "end" >> "$RC_FILE"
        else
            echo "Alias already exists in $RC_FILE."
        fi
    else
        if ! grep -q "function cursor" "$RC_FILE"; then
            cat >> "$RC_FILE" <<EOL
function cursor() {
    /opt/cursor.appimage --no-sandbox "\$@" > /dev/null 2>&1 & disown
}
EOL
        else
            echo "Alias already exists in $RC_FILE."
        fi
    fi
    
    # Inform the user about the installation completion
    echo "Installation complete! You can now run Cursor by:"
    echo "1. Using the application launcher"
    echo "2. Running 'cursor' in terminal (after restarting your shell)"
    
    # Inform the user to reload the shell
    echo "To apply changes, please restart your terminal or run the following command:"
    echo "    source $RC_FILE"

    # Clean up unused dependencies
    sudo apt autoremove -y

    echo "Cursor AI IDE installation or update complete. You can find it in your application menu."
}

# Function to uninstall Cursor AI IDE
uninstallCursor() {
    echo "Uninstalling Cursor AI IDE..."

    # Remove AppImage and icon
    echo "Removing application files..."
    sudo rm -f "$APPIMAGE_PATH"
    sudo rm -f "$ICON_PATH"

    # Remove .desktop entry
    echo "Removing desktop entry..."
    sudo rm -f "$DESKTOP_ENTRY_PATH"

    # Remove configuration and cache
    echo "Removing user configuration and cache..."
    rm -rf ~/.config/Cursor
    rm -rf ~/.cache/cursor-updater

    # Remove alias from the appropriate RC file
    echo "Removing shell integration..."
    if [ "$SHELL_NAME" = "fish" ]; then
        sed -i '/function cursor/,/end/d' "$RC_FILE"
    else
        sed -i '/function cursor {/,/}/d' "$RC_FILE"
    fi

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
