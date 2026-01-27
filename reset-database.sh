#!/bin/bash

# CopyMan Database Reset Script
# Use this if you want to start with a fresh database

echo "=== CopyMan Database Reset ==="
echo ""

# Find the database location
DB_PATH="$HOME/.local/share/com.copyman.app/clipboard.db"

if [ ! -f "$DB_PATH" ]; then
    echo "No database found at: $DB_PATH"
    echo "Database will be created fresh on next run."
    exit 0
fi

echo "Found database at: $DB_PATH"
echo "Database size: $(du -h "$DB_PATH" | cut -f1)"
echo ""

read -p "Are you sure you want to delete this database? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup first
    BACKUP_PATH="${DB_PATH}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "Creating backup at: $BACKUP_PATH"
    cp "$DB_PATH" "$BACKUP_PATH"

    # Delete database
    rm "$DB_PATH"
    echo "✅ Database deleted successfully!"
    echo "Backup saved at: $BACKUP_PATH"
    echo ""
    echo "Next time you run the app, a fresh database will be created with the new schema."
else
    echo "Database reset cancelled."
fi
