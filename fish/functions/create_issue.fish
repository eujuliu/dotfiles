function create_issue
  if not type -q gh
      echo "Error: 'gh' (GitHub CLI) is not installed."
      return 1
  end

  if not type -q task
      echo "Error: 'task' (Taskwarrior) is not installed."
      return 1
  end

  read -P "Enter Title: " TITLE; or return
  if test -z "$TITLE"
      echo "Error: Title is required."
      return 1
  end

  echo "Select Type:"
  echo "1) bug"
  echo "2) feature"
  echo "3) question"
  read -P "Choice [1-3]: " TYPE_CHOICE; or return

  set -l TYPE ""
  set -l TEMPLATE ""
  set -l TEMPLATES_FOLDER "$HOME/.config/github_issue_templates"

  switch "$TYPE_CHOICE"
      case 1
          set TYPE "bug"
          set TEMPLATE "$TEMPLATES_FOLDER/bug.md"
      case 2
          set TYPE "enhancement"
          set TEMPLATE "$TEMPLATES_FOLDER/feature.md"
      case 3
          set TYPE "question"
          set TEMPLATE "$TEMPLATES_FOLDER/question.md"
      case '*'
          echo "Error: Invalid choice."
          return 1
  end

  read -P "Enter Estimate (0-N): " ESTIMATE; or return
  if not string match -qr '^[0-9]+$' "$ESTIMATE"
      echo "Error: Estimate must be a number."
      return 1
  end

  read -P "Enter Priority (H, M, L): " PRIORITY; or return
  set PRIORITY (string upper "$PRIORITY")
  if not string match -qr '^[HML]$' "$PRIORITY"
      echo "Error: Priority must be H, M, or L."
      return 1
  end

  echo "Existing Projects:"
  task _unique project
  read -P "Enter Project: " PROJECT; or return
  if test -z "$PROJECT"
      echo "Error: Project is required."
      return 1
  end

  read -P "Enter Due date (e.g., YYYY-MM-DD, tomorrow, monday) [optional]: " DUE; or return

  set -l TEMP_FILE (mktemp /tmp/issue_body.XXXXXX.md)

  function __create_issue_cleanup --on-event fish_cancel --on-event fish_exit --inherit-variable TEMP_FILE
      if test -f "$TEMP_FILE"
          rm -f "$TEMP_FILE"
      end
      functions -e __create_issue_cleanup
  end

  if test -f "$TEMPLATE"
      cp "$TEMPLATE" "$TEMP_FILE"
  else
      touch "$TEMP_FILE"
  end

  set -l INITIAL_HASH (md5sum "$TEMP_FILE" | awk '{print $1}')

  nvim "$TEMP_FILE"

  set -l CURRENT_HASH (md5sum "$TEMP_FILE" | awk '{print $1}')

  if test "$INITIAL_HASH" = "$CURRENT_HASH"
      echo "No changes detected in the body. Aborting."
      rm -f "$TEMP_FILE"
      functions -e __create_issue_cleanup
      return 0
  end

  echo "Creating GitHub issue..."
  set -l ISSUE_URL (gh issue create --title "$TITLE" --label "$TYPE" --body-file "$TEMP_FILE")

  if test $status -eq 0
      echo "Issue created: $ISSUE_URL"
      set -l ISSUE_NUMBER (echo "$ISSUE_URL" | grep -oE '[0-9]+$')

      echo "Creating Taskwarrior task..."
      if test -n "$DUE"
          task add "+E$ESTIMATE" "+I$ISSUE_NUMBER" "#$ISSUE_NUMBER:$TITLE" priority:"$PRIORITY" due:"$DUE" project:"$PROJECT"
      else
          task add "+E$ESTIMATE" "+I$ISSUE_NUMBER" "#$ISSUE_NUMBER:$TITLE" priority:"$PRIORITY" project:"$PROJECT"
      end
  else
      echo "Error: Failed to create GitHub issue."
      rm -f "$TEMP_FILE"
      functions -e __create_issue_cleanup
      return 1
  end

  rm -f "$TEMP_FILE"
  functions -e __create_issue_cleanup
end
