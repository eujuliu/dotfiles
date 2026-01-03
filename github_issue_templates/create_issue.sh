#!/usr/bin/env bash

if ! command -v gh &> /dev/null; then
    echo "Error: 'gh' (GitHub CLI) is not installed."
    exit 1
fi

if ! command -v task &> /dev/null; then
    echo "Error: 'task' (Taskwarrior) is not installed."
    exit 1
fi

read -p "Enter Title: " TITLE
if [[ -z "$TITLE" ]]; then
    echo "Error: Title is required."
    exit 1
fi

echo "Select Type:"
echo "1) bug"
echo "2) feature"
echo "3) question"
read -p "Choice [1-3]: " TYPE_CHOICE
case $TYPE_CHOICE in
    1) TYPE="bug"; TEMPLATE="bug.md" ;;
    2) TYPE="enhancement"; TEMPLATE="feature.md" ;;
    3) TYPE="question"; TEMPLATE="question.md" ;;
    *) echo "Error: Invalid choice."; exit 1 ;;
esac

read -p "Enter Estimate (0-N): " ESTIMATE
if [[ ! "$ESTIMATE" =~ ^[0-9]+$ ]]; then
    echo "Error: Estimate must be a number."
    exit 1
fi

read -p "Enter Priority (H, M, L): " PRIORITY
PRIORITY=${PRIORITY^^}
if [[ ! "$PRIORITY" =~ ^[HML]$ ]]; then
    echo "Error: Priority must be H, M, or L."
    exit 1
fi

echo "Existing Projects:"
task _unique project
read -p "Enter Project: " PROJECT
if [[ -z "$PROJECT" ]]; then
    echo "Error: Project is required."
    exit 1
fi

read -p "Enter Due date (e.g., YYYY-MM-DD, tomorrow, monday) [optional]: " DUE

TEMP_FILE=$(mktemp /tmp/issue_body.XXXXXX.md)

cp "$TEMPLATE" "$TEMP_FILE"

INITIAL_HASH=$(md5sum "$TEMP_FILE" | awk '{print $1}')

nvim "$TEMP_FILE"

CURRENT_HASH=$(md5sum "$TEMP_FILE" | awk '{print $1}')

if [ "$INITIAL_HASH" == "$CURRENT_HASH" ]; then
    echo "No changes detected in the body. Aborting."
    rm "$TEMP_FILE"
    exit 0
fi

echo "Creating GitHub issue..."
if ISSUE_URL=$(gh issue create --title "$TITLE" --label "$TYPE" --body-file "$TEMP_FILE"); then
    echo "Issue created: $ISSUE_URL"
    ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -oE '[0-9]+$')

    echo "Creating Taskwarrior task..."
    if [[ -n "$DUE" ]]; then
        task add "+E$ESTIMATE" "+I#$ISSUE_NUMBER" "$TITLE" priority:"$PRIORITY" due:"$DUE" project:"$PROJECT"
    else
        task add "+E$ESTIMATE" "+I#$ISSUE_NUMBER" "$TITLE" priority:"$PRIORITY" project:"$PROJECT"
    fi
else
    echo "Error: Failed to create GitHub issue."
    rm "$TEMP_FILE"
    exit 1
fi

rm "$TEMP_FILE"
