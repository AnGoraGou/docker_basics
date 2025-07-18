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

    echo "🔄 Backing up from $REMOTE_USER_HOST:$REMOTE_DIR (port $SSH_PORT)"

    DIR_NAME=$(basename "$REMOTE_DIR")
    LOCAL_DIR="$LOCAL_BACKUP_ROOT/${REMOTE_USER_HOST//[@.]/_}_$DIR_NAME"
    mkdir -p "$LOCAL_DIR"

    rsync -avz -e "ssh -p $SSH_PORT" \
        --include '*/' \
        --include '*.py' \
        --include '*.ipynb' \
        --exclude '*' \
        "$REMOTE_USER_HOST:$REMOTE_DIR/" "$LOCAL_DIR/"

done < "$PROJECT_LIST"

echo "✅ Backup from $REMOTE_USER_HOST completed."

