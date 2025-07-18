#!/bin/bash

# Usage: ./backup_python.sh projects.txt <remote_user>@<remote_host> <local_backup_dir>

PROJECT_LIST=$1
REMOTE=$2
LOCAL_DIR=$3

if [[ -z "$PROJECT_LIST" || -z "$REMOTE" || -z "$LOCAL_DIR" ]]; then
    echo "Usage: $0 <project_list_file> <user@remote_host> <local_backup_directory>"
    exit 1
fi

# Create local backup dir if it doesn't exist
mkdir -p "$LOCAL_DIR"

while read -r REMOTE_DIR; do
    if [[ -z "$REMOTE_DIR" ]]; then continue; fi

    echo "Backing up .py and .ipynb files from $REMOTE:$REMOTE_DIR"

    # Get just the name of the last directory in the path for naming locally
    RELATIVE_DIR=$(basename "$REMOTE_DIR")
    LOCAL_PROJECT_DIR="$LOCAL_DIR/$RELATIVE_DIR"
    mkdir -p "$LOCAL_PROJECT_DIR"

    # Use rsync to copy only .py and .ipynb files, preserving directory structure
    rsync -avz -e ssh \
      --include '*/' \
      --include '*.py' \
      --include '*.ipynb' \
      --exclude '*' \
      "$REMOTE:$REMOTE_DIR/" "$LOCAL_PROJECT_DIR/"

done < "$PROJECT_LIST"

echo "✅ Backup completed."

