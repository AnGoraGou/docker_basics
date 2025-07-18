#!/bin/bash

# Usage: ./backup_python_single.sh <user>@<host> <port> <project_list_file> <local_backup_dir>

REMOTE_USER_HOST=$1
SSH_PORT=$2
PROJECT_LIST=$3
LOCAL_BACKUP_ROOT=$4

if [[ -z "$REMOTE_USER_HOST" || -z "$SSH_PORT" || -z "$PROJECT_LIST" || -z "$LOCAL_BACKUP_ROOT" ]]; then
    echo "Usage: $0 <user>@<host> <port> <project_list_file> <local_backup_dir>"
    exit 1
fi

mkdir -p "$LOCAL_BACKUP_ROOT"

while read -r REMOTE_DIR; do
    if [[ -z "$REMOTE_DIR" ]]; then continue; fi

    echo "📦 Backing up from $REMOTE_USER_HOST:$REMOTE_DIR (port $SSH_PORT)"

    DIR_NAME=$(basename "$REMOTE_DIR")
    LOCAL_DIR="$LOCAL_BACKUP_ROOT/${REMOTE_USER_HOST//[@.]/_}_$DIR_NAME"
    mkdir -p "$LOCAL_DIR"

    # Step 1: Back up .py and .ipynb files using rsync
    echo "📁 Syncing .py and .ipynb files..."
    rsync -avz -e "ssh -p $SSH_PORT" \
        --include '*/' \
        --include '*.py' \
        --include '*.ipynb' \
        --exclude '*' \
        "$REMOTE_USER_HOST:$REMOTE_DIR/" "$LOCAL_DIR/"

    # Step 2: Back up .pth files modified in the last 14 days using find + scp
    echo "🔍 Looking for .pth files modified in last 14 days..."

    TMP_FILE_LIST=$(mktemp)

    ssh -p "$SSH_PORT" "$REMOTE_USER_HOST" "find \"$REMOTE_DIR\" -type f -name '*.pth' -mtime -14" > "$TMP_FILE_LIST"

    while read -r REMOTE_PTH_FILE; do
        if [[ -z "$REMOTE_PTH_FILE" ]]; then continue; fi

        REL_PATH="${REMOTE_PTH_FILE#$REMOTE_DIR/}"  # remove base dir
        LOCAL_PTH_DEST="$LOCAL_DIR/$REL_PATH"

        echo "📄 Copying: $REMOTE_PTH_FILE"
        mkdir -p "$(dirname "$LOCAL_PTH_DEST")"
        scp -P "$SSH_PORT" "$REMOTE_USER_HOST:\"$REMOTE_PTH_FILE\"" "$LOCAL_PTH_DEST"

    done < "$TMP_FILE_LIST"

    rm "$TMP_FILE_LIST"

done < "$PROJECT_LIST"

echo "✅ Full backup from $REMOTE_USER_HOST completed."

