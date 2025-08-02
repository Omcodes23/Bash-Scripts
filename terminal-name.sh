#!/bin/bash

# ==== Validate Input ====
if [ -z "$1" ]; then
    echo "❌ Please provide a name to display. Example: ./install-omega.sh OMEGA"
    exit 1
fi

DISPLAY_NAME="$1"
FONT_NAME="ANSI_Shadow.flf"
ORIGINAL_FONT_NAME="ANSI Shadow.flf"
FONT_DIR="$HOME/.figlet-fonts"
REPO_URL="https://github.com/xero/figlet-fonts"

echo "[+] Display name will be: $DISPLAY_NAME"

# ==== Install Required Packages ====
echo "[+] Installing figlet and lolcat..."
sudo apt update
sudo apt install -y figlet lolcat git

# ==== Clone Figlet Fonts ====
if [ ! -d "$FONT_DIR" ]; then
    echo "[+] Cloning custom figlet fonts..."
    git clone "$REPO_URL" "$FONT_DIR"
else
    echo "[=] Font repo already exists."
fi

# ==== Rename Problematic Font ====
if [ -f "$FONT_DIR/$ORIGINAL_FONT_NAME" ]; then
    echo "[+] Renaming '$ORIGINAL_FONT_NAME' to '$FONT_NAME'..."
    mv "$FONT_DIR/$ORIGINAL_FONT_NAME" "$FONT_DIR/$FONT_NAME"
fi

# ==== Add Font Path and Alias to .bashrc ====
if ! grep -q "FIGLET_FONTDIR" ~/.bashrc; then
    echo "[+] Adding font path and alias to ~/.bashrc"
    echo "export FIGLET_FONTDIR=$FONT_DIR" >> ~/.bashrc
    echo "alias figlet='figlet -d \$FIGLET_FONTDIR'" >> ~/.bashrc
fi

# ==== Remove Previous Art Block ====
sed -i '/# OMEGA ASCII Art/,+1d' ~/.bashrc

# ==== Add Centered Banner to .bashrc ====
echo "" >> ~/.bashrc
echo "# OMEGA ASCII Art" >> ~/.bashrc
echo "figlet -d \$FIGLET_FONTDIR -f $FONT_NAME -c \"$DISPLAY_NAME\" | lolcat" >> ~/.bashrc

echo "[✔] Done! Restart terminal or run: source ~/.bashrc"
