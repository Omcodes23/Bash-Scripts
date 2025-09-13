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
echo "📂 Checking tmux plugin directory..."
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

# Create default .tmux.conf with all plugin configurations
if [ ! -f ~/.tmux.conf ]; then
    echo "⚙️ Creating default ~/.tmux.conf..."
    cat <<EOL > ~/.tmux.conf
# === TPM Plugins ===
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# === Continuum Auto-Restore ===
# Automatically restore tmux sessions on tmux start
set -g @continuum-restore 'on'
# Save sessions every 15 minutes
set -g @continuum-save-interval '15'

# === Resurrect Options ===
# Save Vim, Neovim, and tmux session layout
set -g @resurrect-strategy-vim 'session'
set -g @resurrect-strategy-nvim 'session'
set -g @resurrect-strategy-tmux 'session'

# Initialize TPM (Tmux Plugin Manager)
run '~/.tmux/plugins/tpm/tpm'
EOL
    echo "✅ Default ~/.tmux.conf created."
else
    echo "⚙️ ~/.tmux.conf already exists, skipping creation."
fi

# Install tmux plugins
echo "⚡ Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins

echo "🎉 Setup complete!"
echo "👉 Start tmux. Press PREFIX + I (Ctrl+b then I) to ensure plugins are loaded."
echo "💡 Your sessions will now auto-save every 15 minutes and auto-restore on restart."
