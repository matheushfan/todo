#!/usr/bin/env zsh
# todo installer

set -e

INSTALL_DIR="${TODO_INSTALL_DIR:-$HOME/.todo-cli}"
BIN_LINK="/usr/local/bin/todo"

echo "Installing todo to $INSTALL_DIR..."

# Clone or update
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  git clone https://github.com/matheushfan/todo.git "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR/bin/todo"

# Symlink
if [[ -w "$(dirname "$BIN_LINK")" ]]; then
  ln -sf "$INSTALL_DIR/bin/todo" "$BIN_LINK"
  echo "Linked to $BIN_LINK"
else
  echo "Cannot write to $(dirname "$BIN_LINK"). Add to PATH manually:"
  echo "  export PATH=\"$INSTALL_DIR/bin:\$PATH\""
fi

echo ""
echo "Done! Run 'todo' to get started."
