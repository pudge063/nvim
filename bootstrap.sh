#!/usr/bin/env bash
# One-shot installer for this nvim config. No Homebrew, no distro-specific
# package pinning for the tools nvim actually needs — everything (Neovim,
# ripgrep, fd, Node.js) is fetched as a prebuilt binary release and installed
# under ~/.local, so the exact same script works on macOS and on any Linux
# server (Debian/Ubuntu/RockyLinux and friends), with or without sudo.
#
# Usage:
#   curl -fsSL https://gl.pivlab.dev/rnd/nvim-config/-/raw/master/bootstrap.sh | bash
#
# or, if you already cloned the repo:
#   ~/.config/nvim/bootstrap.sh

set -euo pipefail

REPO_URL="git@gl.pivlab.dev:rnd/nvim-config.git"
REPO_HTTP_URL="https://gl.pivlab.dev/rnd/nvim-config.git"
CONFIG_DIR="$HOME/.config/nvim"
INSTALL_ROOT="$HOME/.local/opt"
BIN_DIR="$HOME/.local/bin"

# Node is pinned (parsing nodejs.org's version index without jq/python isn't
# worth the fragility) — bump by checking https://nodejs.org/dist/ for the
# current LTS and updating this one line.
NODE_VERSION="v24.19.0"

echo "--- nvim config bootstrap ---"
mkdir -p "$INSTALL_ROOT" "$BIN_DIR"

os="$(uname -s)"
arch="$(uname -m)"

case "$arch" in
    x86_64|amd64) arch_nvim="x86_64"; arch_rust="x86_64"; arch_node="x64" ;;
    arm64|aarch64) arch_nvim="arm64"; arch_rust="aarch64"; arch_node="arm64" ;;
    *) echo "Unsupported architecture: $arch"; exit 1 ;;
esac

gh_latest_tag() {
    # $1 = owner/repo
    # curl fully into a variable first: piping straight into `grep -m1`
    # makes grep close the pipe as soon as it matches, which makes curl
    # fail with "Failure writing output to destination" (exit 23).
    local json
    json="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")"
    # no -m1: it closes the pipe as soon as it matches, and since
    # "tag_name" appears exactly once in this payload anyway, plain
    # grep (reads to EOF, no early pipe close) is both correct and safe.
    printf '%s' "$json" | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
}

fetch_and_unpack() {
    # $1 = url  $2 = install dir name (under $INSTALL_ROOT)
    local url="$1" name="$2" dest tmp
    dest="$INSTALL_ROOT/$name"
    tmp="$(mktemp -d)"
    echo "  fetching $url"
    curl -fsSL "$url" -o "$tmp/pkg.tar.gz"
    rm -rf "$dest"
    mkdir -p "$dest"
    tar -xzf "$tmp/pkg.tar.gz" -C "$dest" --strip-components=1
    rm -rf "$tmp"
}

fetch_gz_binary() {
    # $1 = url  $2 = binary name to install into $BIN_DIR
    local url="$1" name="$2" tmp
    tmp="$(mktemp -d)"
    echo "  fetching $url"
    curl -fsSL "$url" -o "$tmp/pkg.gz"
    gunzip -c "$tmp/pkg.gz" > "$BIN_DIR/$name"
    chmod +x "$BIN_DIR/$name"
    rm -rf "$tmp"
}

link() { ln -sf "$1" "$BIN_DIR/$(basename "$1")"; }

echo "[1/6] Base prerequisites (git, C compiler — needed for treesitter parsers)"
case "$os" in
    Darwin)
        if ! command -v git >/dev/null 2>&1 || ! command -v cc >/dev/null 2>&1; then
            echo "  Xcode Command Line Tools missing — installing (no Homebrew)..."
            # Non-interactive CLT install trick (no GUI prompt, no brew).
            touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            clt_label="$(softwareupdate -l 2>/dev/null | grep -B1 -E '^\s*\*.*Command Line' | awk -F'"' '/Label:/{print $2}' | tail -1)"
            if [ -n "$clt_label" ]; then
                sudo softwareupdate -i "$clt_label" --verbose || true
            fi
            rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
            if ! command -v git >/dev/null 2>&1; then
                echo "  Automatic install didn't take. Run 'xcode-select --install' yourself, then re-run this script."
                exit 1
            fi
        else
            echo "  already present."
        fi
        ;;
    Linux)
        missing=()
        command -v git >/dev/null 2>&1 || missing+=(git)
        command -v curl >/dev/null 2>&1 || missing+=(curl)
        command -v tar >/dev/null 2>&1 || missing+=(tar)
        command -v cc >/dev/null 2>&1 || command -v gcc >/dev/null 2>&1 || missing+=(compiler)
        if [ ${#missing[@]} -eq 0 ]; then
            echo "  already present."
        else
            echo "  missing: ${missing[*]} — installing via system package manager (needs sudo)..."
            . /etc/os-release 2>/dev/null || true
            case "${ID:-}${ID_LIKE:-}" in
                *debian*|*ubuntu*)
                    sudo apt-get update
                    sudo apt-get install -y git curl tar build-essential
                    ;;
                *rhel*|*rocky*|*centos*|*fedora*)
                    sudo dnf install -y git curl tar gcc gcc-c++ make
                    ;;
                *)
                    echo "  Unrecognized distro (ID=${ID:-unknown}). Install git, curl, tar and a C compiler manually, then re-run."
                    exit 1
                    ;;
            esac
        fi
        ;;
    *) echo "Unsupported OS: $os"; exit 1 ;;
esac

echo "[2/6] Neovim (official release binary)"
case "$os" in
    Darwin) nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-macos-${arch_nvim}.tar.gz" ;;
    Linux)  nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${arch_nvim}.tar.gz" ;;
esac
fetch_and_unpack "$nvim_url" nvim
link "$INSTALL_ROOT/nvim/bin/nvim"

echo "[3/6] ripgrep + fd (needed by Telescope)"
rg_tag="$(gh_latest_tag BurntSushi/ripgrep)"
fd_tag="$(gh_latest_tag sharkdp/fd)"
case "$os" in
    Darwin)
        rg_target="${arch_rust}-apple-darwin"
        fd_target="${arch_rust}-apple-darwin"
        ;;
    Linux)
        rg_target="${arch_rust}-unknown-linux-musl"
        fd_target="${arch_rust}-unknown-linux-musl"
        ;;
esac
fetch_and_unpack "https://github.com/BurntSushi/ripgrep/releases/download/${rg_tag}/ripgrep-${rg_tag}-${rg_target}.tar.gz" ripgrep
fetch_and_unpack "https://github.com/sharkdp/fd/releases/download/${fd_tag}/fd-${fd_tag}-${fd_target}.tar.gz" fd
link "$INSTALL_ROOT/ripgrep/rg"
link "$INSTALL_ROOT/fd/fd"

echo "[4/6] tree-sitter CLI (nvim-treesitter's main branch needs it to compile parsers)"
ts_tag="$(gh_latest_tag tree-sitter/tree-sitter)"
case "$os" in
    Darwin) ts_target="macos-${arch_node}" ;;
    Linux)  ts_target="linux-${arch_node}" ;;
esac
fetch_gz_binary "https://github.com/tree-sitter/tree-sitter/releases/download/${ts_tag}/tree-sitter-${ts_target}.gz" tree-sitter

echo "[5/6] Node.js (mason needs it to install pyright)"
case "$os" in
    Darwin) node_url="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-darwin-${arch_node}.tar.gz" ;;
    Linux)  node_url="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-${arch_node}.tar.gz" ;;
esac
fetch_and_unpack "$node_url" node
link "$INSTALL_ROOT/node/bin/node"
link "$INSTALL_ROOT/node/bin/npm"
link "$INSTALL_ROOT/node/bin/npx"

export PATH="$BIN_DIR:$PATH"
for rc in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.profile"; do
    if [ -f "$rc" ] && ! grep -qs "$BIN_DIR" "$rc"; then
        printf '\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$rc"
        echo "  added $BIN_DIR to PATH in $rc"
    fi
done
if [ ! -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.profile" ]; then
    printf 'export PATH="%s:$PATH"\n' "$BIN_DIR" > "$HOME/.profile"
    echo "  created $HOME/.profile with $BIN_DIR on PATH"
fi

echo "nvim: $(nvim --version | head -n1)"

echo "[6/6] Config + plugins + LSP tools"
if [ ! -d "$CONFIG_DIR/.git" ]; then
    if [ -d "$CONFIG_DIR" ] && [ -n "$(ls -A "$CONFIG_DIR" 2>/dev/null)" ]; then
        echo "  $CONFIG_DIR already exists and isn't this repo — not touching it."
        echo "  move it aside and re-run, or clone manually:"
        echo "  git clone $REPO_URL $CONFIG_DIR"
        exit 1
    fi
    echo "  cloning config..."
    if ! git clone "$REPO_URL" "$CONFIG_DIR" 2>/dev/null; then
        echo "  SSH clone failed (no SSH key on this machine for gl.pivlab.dev?) — trying HTTPS..."
        git clone "$REPO_HTTP_URL" "$CONFIG_DIR"
    fi
fi

# `+Lazy! sync` as a bare ex-command does NOT reliably block headless nvim
# until build hooks (like nvim-treesitter's parser compilation) finish, and
# calling `require('nvim-treesitter').install()` again from a second nvim
# process to force it is itself flaky (races the plugin's own module/rtp
# setup right after a fresh clone, intermittently throwing "attempt to call
# field 'install' (a nil value)"). The build hook genuinely does finish the
# job on its own in the background — it just needs a bit more time than
# `sync()` waits for — so: kick sync off, then poll the filesystem in plain
# bash for the actual compiled .so files. No further nvim/Lua involved,
# nothing left to race.
nvim --headless -c "lua require('lazy').sync({ wait = true, show = false })" -c "qa"

ts_langs=(python lua vim vimdoc bash markdown markdown_inline json yaml toml)
# nvim-treesitter's default install_dir is stdpath('data')/site, not its
# own plugin directory under .../lazy/nvim-treesitter.
parser_dir="$HOME/.local/share/nvim/site/parser"
echo "  waiting for treesitter parsers to finish compiling..."
waited=0
while [ "$waited" -lt 180 ]; do
    missing=0
    for lang in "${ts_langs[@]}"; do
        [ -f "$parser_dir/$lang.so" ] || missing=1
    done
    [ "$missing" -eq 0 ] && break
    sleep 3
    waited=$((waited + 3))
done
if [ "$missing" -eq 1 ]; then
    echo "  warning: some treesitter parsers still missing after ${waited}s — they'll finish installing next time you open nvim."
fi
nvim --headless "+MasonToolsInstallSync" +qa

echo "--- Done. Open a new shell (for PATH) and run 'nvim'. ---"
