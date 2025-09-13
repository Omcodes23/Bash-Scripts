#!/usr/bin/env bash

set -e

echo "🔍 Checking for tmux..."
if ! command -v tmux &> /dev/null; then
    echo "📦 Installing tmux..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get update && sudo apt-get install -y tmux
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install tmux
    else
        echo "❌ Unsupported OS. Please install tmux manually."
        exit 1
    fi
else
    echo "✅ tmux is already installed."
fi

# Install TPM
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "📥 Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "✅ TPM already installed."
fi

# Update ~/.tmux.conf
TMUX_CONF="$HOME/.tmux.conf"

echo "⚙️ Configuring ~/.tmux.conf ..."
if ! grep -q "tmux-plugins/tmux-resurrect" "$TMUX_CONF" 2>/dev/null; then
    cat << 'EOF' >> "$TMUX_CONF"

### >>> Added by setup script for tmux-resurrect & continuum ###
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Continuum auto-save every 15 minutes
set -g @continuum-save-interval '15'
# Continuum auto-restore on start
set -g @continuum-restore 'on'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
### <<< End of script section ###
EOF
    echo "✅ Plugins added to ~/.tmux.conf"
else
    echo "ℹ️ Plugins already configured in ~/.tmux.conf"
fi

# Reload tmux config if inside tmux
if [ -n "$TMUX" ]; then
    echo "🔄 Reloading tmux config..."
    tmux source-file ~/.tmux.conf
fi

echo "🎉 Setup complete!"
echo "👉 Start tmux and press 'prefix + I' (capital i) to install plugins."
