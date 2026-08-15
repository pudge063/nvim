#!/usr/bin/env bash
# Installs everything this nvim config needs on macOS or Linux, then
# syncs plugins + mason tools headlessly so first `nvim` launch is instant.
#
# Usage:
#   git clone <this-repo-url> ~/.config/nvim
#   ~/.config/nvim/bootstrap.sh

set -euo pipefail

NVIM_MIN_VERSION="0.11.0"
CONFIG_DIR="$HOME/.config/nvim"

echo "--- nvim config bootstrap ---"

os="$(uname -s)"

install_macos() {
    if ! command -v brew &>/dev/null; then
        echo "Homebrew not found. Install it first: https://brew.sh"
        exit 1
    fi
    echo "Installing packages via Homebrew..."
    brew install neovim git ripgrep fd
    brew install --cask font-jetbrains-mono-nerd-font || true
}

install_linux() {
    echo "Installing base packages via apt..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git curl ripgrep fd-find build-essential unzip python3-venv
        # Debian/Ubuntu ship `fdfind`, not `fd` — symlink so plugins that call `fd` work.
        if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
            sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
        fi
    else
        echo "Non-apt distro detected — install git, ripgrep, fd, a C compiler and python3-venv with your package manager, then re-run this script."
    fi

    # Distro-packaged Neovim is often too old (esp. Debian/Ubuntu LTS).
    # Always pull the official stable prebuilt binary instead.
    echo "Installing official Neovim stable release..."
    arch="$(uname -m)"
    case "$arch" in
        x86_64) nvim_asset="nvim-linux-x86_64.tar.gz" ;;
        aarch64) nvim_asset="nvim-linux-arm64.tar.gz" ;;
        *) echo "Unsupported architecture: $arch"; exit 1 ;;
    esac
    curl -Lo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/${nvim_asset}"
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf /tmp/nvim.tar.gz
    sudo mv "/opt/${nvim_asset%.tar.gz}" /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm /tmp/nvim.tar.gz
}

case "$os" in
    Darwin) install_macos ;;
    Linux) install_linux ;;
    *) echo "Unsupported OS: $os"; exit 1 ;;
esac

echo "Neovim version: $(nvim --version | head -n1)"

if [ "$CONFIG_DIR" != "$(cd "$(dirname "$0")" && pwd)" ]; then
    echo "NOTE: this script lives at $(cd "$(dirname "$0")" && pwd), not $CONFIG_DIR."
    echo "Make sure this repo is checked out at $CONFIG_DIR before continuing."
fi

echo "Syncing plugins (lazy.nvim)..."
nvim --headless "+Lazy! sync" +qa

echo "Installing LSP servers / formatters via mason (pyright, ruff, lua_ls, stylua)..."
nvim --headless "+MasonToolsInstallSync" +qa

echo "--- Done. Run 'nvim' to start. ---"
