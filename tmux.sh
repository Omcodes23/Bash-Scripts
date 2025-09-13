#!/bin/bash

echo "🔍 Checking for tmux..."

# Install tmux if not present
if ! command -v tmux &> /dev/null; then
    echo "📦 Installing tmux..."
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y tmux git
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y tmux git
    else
        echo "❌ Unsupported OS. Please install tmux manually."
        exit 1
    fi
else
    echo "✅ tmux is already installed."
fi

# Ensure plugin directory exists safely
echo "📂 Setting up tmux plugin directory..."
if [ -f ~/.tmux ]; then
    echo "⚠️ Found a FILE named ~/.tmux — renaming it to ~/.tmux-backup"
    mv ~/.tmux ~/.tmux-backup
fi
mkdir -p ~/.tmux/plugins

# Install TPM (Tmux Plugin Manager)
echo "📥 Installing TPM (Tmux Plugin Manager)..."
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    echo "✅ TPM installed successfully."
else
    echo "✅ TPM already installed."
fi

# Create or update .tmux.conf with plugins & auto-restore settings
echo "⚙️ Creating/updating ~/.tmux.conf..."
cat <<EOL > ~/.tmux.conf
# === TPM Plugins ===
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# === Continuum Auto-Restore ===
set -g @continuum-restore 'on'          # Automatically restore tmux sessions on start
set -g @continuum-save-interval '15'    # Save sessions every 15 minutes

# === Resurrect Strategies ===
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-strategy-tmux 'session'

# Initialize TPM
run '~/.tmux/plugins/tpm/tpm'
EOL
echo "✅ ~/.tmux.conf configured."

# Install tmux plugins
echo "⚡ Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins

echo "🎉 Setup complete!"
echo "💡 Start tmux: 'tmux'"
echo "📝 Press PREFIX + I (Ctrl+b then I) to reload plugins manually if needed."
echo "🔄 Sessions will auto-save every 15 minutes and auto-restore on restart."
