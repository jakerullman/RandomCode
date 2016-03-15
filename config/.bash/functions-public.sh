# BASH FUNCTIONS (public)

#------------------#
# Section: General #
#------------------#

# Label: Tab to Space
# Description: Convert file from tab to space indendation.
# Parameters: $1 (required) - The file to convert, $2 (optional) - The number of spaces, default: 2.
t2s() {
  if [[ "$2" ]]; then
    local number_of_spaces=$2
  else
    local number_of_spaces=2
  fi

  if [[ "$1" ]]; then
    local temp_file=$(mktemp -t tabs_to_spaces) || { printf "\nERROR: Unable to create temporary file.\n"; return; }
    expand -t $number_of_spaces "$1" > $temp_file
    cat $temp_file > "$1"
    printf "Converted: $1.\n"
    rm -f $temp_file;
  else
    printf "ERROR: File must be supplied.\n"
    return 1
  fi
}

# Label: Colorized Type
# Description: Identical to "type" command functionality but with syntax highlighting.
# Parameters: $1 (required) - The alias or function to inspect source code for.
cype() {
  local name="$1"

  if [[ -z "$name" ]]; then
    printf "ERROR: Alias or function must be supplied.\n"
    return 1
  fi

  type "$1" | cat
}

# Label: Kill Process
# Description: Kill errant processes.
# Parameters: $1 (required) - The search query, $2 (optional) - The kill signal. Default: 15.
kilp() {
  local query="$1"
  local signal=${2:-15}

  if [[ -z "$query" ]]; then
    printf "ERROR: Search query must be supplied.\n"
    return 1
  fi

  ps axu | grep --invert-match grep | grep "$query" | awk '{print $2}' | xargs kill -$signal
}

#-----------------------------------------------------------#
# Section: [less](http://en.wikipedia.org/wiki/Less_(Unix)) #
#-----------------------------------------------------------#

# Label: Less Interactive
# Description: Inspect file, interactively.
# Parameters: $1 (required) - The file path.
lessi() {
  if [[ "$1" ]]; then
    less +F --LONG-PROMPT --LINE-NUMBERS --RAW-CONTROL-CHARS --QUIET --quit-if-one-screen -i "$1"
  else
    printf "ERROR: File path must be supplied.\n"
    printf "TIP: Use CONTROL+c to switch to VI mode, SHIFT+f to switch back, and CONTROL+c+q to exit.\n"
  fi
}

#-----------------------------------------#
# Section: [OpenSSL](https://openssl.org) #
#-----------------------------------------#

# Label: SSL Certificate Creation
# Description: Create SSL certificate.
# Parameters: $1 (required) - The domain name.
sslc() {
  local name="$1"

  if [[ -z "$name" ]]; then
    printf "ERROR: Domain name for SSL certificate must be supplied.\n"
    return 1
  fi

cat > "$name.cnf" <<-EOF
  [req]
  distinguished_name = req_distinguished_name
  x509_extensions = v3_req
  prompt = no
  [req_distinguished_name]
  CN = *."$name"
  [v3_req]
  keyUsage = keyEncipherment, dataEncipherment
  extendedKeyUsage = serverAuth
  subjectAltName = @alt_names
  [alt_names]
  DNS.1 = *."$name"
  DNS.2 = "$name"
EOF

  openssl req \
    -new \
    -newkey rsa:2048 \
    -sha256 \
    -days 3650 \
    -nodes \
    -x509 \
    -keyout "$name.key" \
    -out "$name.crt" \
    -config "$name.cnf"

  rm -f "$name.cnf"
}

#--------------------------------------#
# Section: [curl](http://curl.haxx.se) #
#--------------------------------------#

# Label: Curl Inspect
# Description: Inspect remote file with default editor.
# Parameters: $1 (required) - The URL.
curli() {
  if [[ "$1" ]]; then
    local file=$(mktemp -t suspicious_curl_file) || { printf "ERROR: Unable to create temporary file.\n"; return; }
    curl --location --fail --silent --show-error "$1" > $file || { printf "Failed to curl file.\n"; return; }
    $EDITOR -w $file || { printf "Unable to open temporary curl file.\n"; return; }
    rm -f $file;
  else
    printf "ERROR: URL must be supplied.\n"
    return 1
  fi
}

#--------------------------------------------------#
# Section: [lsof](http://people.freebsd.org/~abe/) #
#--------------------------------------------------#

# Label: Port
# Description: List file activity on given port.
# Parameters: $1 (required) - The port number.
port() {
  if [[ "$1" ]]; then
    sudo lsof -i :$1
  else
    printf "ERROR: Port number must be supplied.\n"
  fi
}

#------------------------------------#
# Section: [Git](http://git-scm.com) #
#------------------------------------#

# Label: Git Init (all)
# Description: Initialize/re-initialize repositories in current directory.
gia() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -d ".git" ]]; then
        printf "\033[36m${project:2}\033[m: " # Print project (cyan) and message (white).
        git init
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Root
# Description: Change to repository root directory regardless of current depth.
groot() {
  cd "$(dirname $(git rev-parse --git-dir))"
}

# Label: Git Info
# Description: Print repository overview information.
ginfo() {
  printf "$(_print_black_on_white ' Local Configuration (.git/config) ')\n\n"
  git config --local --list

  printf "\n$(_print_black_on_white ' Local Stashes ')\n\n"
  local stashes="$(gashl)"
  if [[ -n "$stashes" ]]; then
    printf "$stashes"
  else
    printf "None.\n"
  fi

  printf "\n$(_print_black_on_white ' Local Branches ')\n\n"
  git branch

  printf "\n$(_print_black_on_white ' Remote Branches ')\n\n"
  git branch --remotes

  printf "\n$(_print_black_on_white ' Remote URLs ')\n\n"
  git remote --verbose

  printf "\n$(_print_black_on_white ' File Churn (Top 25) ')\n\n"
  ghurn | head -n 25

  printf "\n$(_print_black_on_white ' Commits by Author ')\n\n"
  guthors

  printf "\n$(_print_black_on_white ' Total Commits ')\n\n"
  gount

  printf "\n$(_print_black_on_white ' Last Tag ')\n\n"
  printf "$(git describe --abbrev=0 --tags --always) ($(_git_commit_count_since_last_tag) commits since)\n"

  printf "\n$(_print_black_on_white ' Last Commit ')\n\n"
  git show --decorate --stat

  printf "\n$(_print_black_on_white ' Current Status ')\n\n"
  git status --short --branch
}

# Label: Git Churn
# Description: Answer commit churn for project files (sorted highest to lowest).
ghurn() {
  git log --all --find-renames --find-copies --name-only --format='format:' "$@" | \
    sort | \
    grep --invert-match '^$' | \
    uniq -c | \
    sort | \
    awk '{print $1 "\t" $2}' | \
    sort --general-numeric-sort --reverse | \
    more
}

# Label: Git Commit Count
# Description: Answer total number of commits for current project.
gount() {
  printf "Total Commits: "
  git rev-list --count HEAD
}

# Label: Git Log (interactive)
# Description: List commits with support to show/diff individual commits.
# Parameters: $1 (optional) - The commit limit. Default: 25.
gli() {
  local commit_limit=${1:-25}
  local commits=($(git rev-list --no-merges --max-count $commit_limit HEAD))
  local commit_total=${#commits[@]}
  local option_padding=${#commit_total}
  local counter=1

  printf "Commit Log:\n\n"

  for commit in ${commits[@]}; do
    local option="$(printf "%${option_padding}s" $counter)"
    printf "%s\n" "$option: $(git log --pretty=format:"$(_git_log_line_format)" -n1 $commit)"
    counter=$((counter + 1))
  done

  option_padding=$((option_padding + 1))
  printf "%${option_padding}s %s\n\n" "q:" "Quit/Exit."

  read -p "Enter selection: " response
  if [[ "$response" == 'q' ]]; then
    return
  fi

  printf "\n"
  local selected_commit=${commits[$((response - 1))]}
  _git_show_details $selected_commit

  printf "\n"
  read -p "View diff (y = yes, n = no)? " response
  if [[ "$response" == 'y' ]]; then
    gdt $selected_commit^!
  fi
}

# Label: Git Show
# Description: Show commit details with optional diff support.
# Parameters: $1 (optional) - The commit to show. Default: <last commit>, $2 (optional) - Launch difftool. Default: false.
ghow() {
  local commit="$1"
  local difftool="$2"

  if [[ -n "$commit" && -n "$difftool" ]]; then
    _git_show_details "$commit"
    git difftool "$commit^" "$commit"
  elif [[ -n "$commit" && -z "$difftool" ]]; then
    _git_show_details "$commit"
  else
    _git_show_details
  fi
}

# Label: Git File
# Description: Show file details for a specific commit (with optional diff support).
# Parameters: $1 (required) - The commit, $2 (required) - The file, $3 (optional) - Launch difftool. Default: false.
gile() {
  local file="$1"
  local commit="$2"
  local diff="$3"

  if [[ -z "$file" ]]; then
    printf "ERROR: File is missing.\n"
    return 1
  fi

  if [[ -z "$commit" ]]; then
    printf "ERROR: Commit SHA is missing.\n"
    return 1
  fi

  git show --stat --pretty=format:"$(_git_log_details_format)" "$commit" -- "$file"

  if [[ -n "$diff" ]]; then
    gdt $commit^! -- "$file"
  fi
}

# Label: Git File History
# Description: View file commit history (with optional diff support).
# Parameters: $1 (required) - The file path.
gistory() {
  if [[ -z "$1" ]]; then
    printf "ERROR: File must be supplied.\n"
    return 1
  fi

  local file="$1"
  local commits=($(git rev-list --reverse HEAD -- "$file"))

  _git_file_commits commits[@] "$file"
}

# Label: Git Blame History
# Description: View file commit history for a specific file and/or lines (with optional diff support).
# Parameters: $1 (required) - The file path, $2 (optional) - The file lines (<start>,<end>).
glameh() {
  if [[ -z "$1" ]]; then
    printf "ERROR: File must be supplied.\n"
    return 1
  fi

  local file="$1"
  local lines="$2"
  local commits=($(git blame -l -s -C -M -L "$lines" "$file" | awk '{print $1}' | sort -u))

  _git_file_commits commits[@] "$file"
}

# Label: Git Authors (all)
# Description: Answer author commit activity per project (ranked highest to lowest).
guthorsa() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -d ".git" ]]; then
        # Print project (cyan) and message (white).
        printf "\033[36m${project:2}\033[m:\n"
        git log --format="%an" | sort | uniq -c | sort --reverse
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Status (all)
# Description: Answer status of projects with uncommited/unpushed changes.
gsta() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -d ".git" ]]; then
        # Capture current project status info as an array.
        local results=($(git status --short --branch))
        local size=${#results[@]}

        # Print Git activity if Git activity detected (white).
        if [[ $size -gt 2 ]]; then
          # Remove first and second elements since they contain branch info.
          results=("${results[@]:1}")
          results=("${results[@]:1}")

          # Print project (cyan).
          printf "\033[36m${project:2}\033[m:\n"

          # Print results (white).
          for line in "${results[@]}"; do
            printf "%s" "$line "
            if [[ $newline == 1 ]]; then
              printf "\n"
              local newline=0
            else
              local newline=1
            fi
          done
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Update
# Description: Fetch commits, prune untracked references, review each commit (optional, with diff), and pull (optional).
gup() {
  git fetch --prune --quiet
  commits=($(git log --reverse --no-merges --pretty=format:"%H" ..@{upstream}))

  if [[ ${#commits[@]} == 0 ]]; then
    printf "All is quiet, nothing to update.\n"
    return 0
  fi

  printf "Commit Summary:\n"
  hr '-'
  git log --reverse --no-merges --pretty=format:"$(_git_log_line_format)" ..@{upstream}
  hr '-'

  printf "Commit Review (↓${#commits[@]}):\n"

  local counter=1
  for commit in "${commits[@]}"; do
    hr '-'
    printf "[$counter/${#commits[@]}] "
    counter=$((counter + 1))

    _git_show_details $commit

    printf "\n"
    read -p "View Diff (y = yes, n = no, q = quit)? " response

    case $response in
      'y')
        git difftool $commit^!;;
      'n')
        continue;;
      'q')
        break;;
      *)
        printf "ERROR: Invalid option.\n"
        break;;
    esac
  done

  hr '-'
  read -p "Commit Pull (y/n)? " response

  if [[ "$response" == 'y' ]]; then
    git pull
  fi
}

# Label: Git Set Config Value (all)
# Description: Set key value for projects in current directory.
# Parameters: $1 (required) - The key name, $2 (required) - The key value.
gseta() {
  if [[ "$1" && "$2" ]]; then
    # Iterate project directories located in root directory.
    while read project; do
      (
        cd "$project"
        # Only process projects that are Git enabled.
        if [[ -d ".git" ]]; then
          # Set key value for current project.
          git config "$1" "$2"
          # Print project (cyan) and email (white).
          printf "\033[36m${project:2}\033[m: $1 = $2\n"
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Key and value must be supplied.\n"
    return 1
  fi
}

# Label: Git Get Config Value (all)
# Description: Answer key value for projects in current directory.
# Parameters: $1 (required) - The key name.
ggeta() {
  if [[ "$1" ]]; then
    # Iterate project directories located in root directory.
    while read project; do
      (
        cd "$project"
        # Only process projects that are Git enabled.
        if [[ -d ".git" ]]; then
          # Get Git config value for given key.
          local result=$(git config "$1")

          # Print project (cyan).
          printf "\033[36m${project:2}\033[m: "

          # Print result.
          if [[ -n "$result" ]]; then
            printf "$1 = $result\n" # White
          else
            printf "\033[31mKey not found.\033[m\n" # Red
          fi
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Key must be supplied.\n"
    return 1
  fi
}

# Label: Git Unset (all)
# Description: Unset key value for projects in current directory.
# Parameters: $1 (required) - The key name.
gunseta() {
  if [[ "$1" ]]; then
    # Iterate project directories located in root directory.
    while read project; do
      (
        cd "$project"
        # Only process projects that are Git enabled.
        if [[ -d ".git" ]]; then
          # Unset key for current project with error output suppressed.
          git config --unset "$1" &> /dev/null

          # Print project (cyan).
          printf "\033[36m${project:2}\033[m: \"$1\" key removed.\n"
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Key must be supplied.\n"
    return 1
  fi
}

# Label: Git Email Set (all)
# Description: Sets user email for projects in current directory.
# Parameters: $1 (required) - The email address.
gailsa() {
  gseta "user.email" "$1"
}

# Label: Git Email Get
# Description: Answer user email for current project.
gail() {
  if [[ -d ".git" ]]; then
    git config user.email
  fi
}

# Label: Git Email Get (all)
# Description: Answer user email for projects in current directory.
gaila() {
  ggeta "user.email"
}

# Label: Git Since
# Description: Answer summarized list of activity since date/time for projects in current directory.
# Parameters: $1 (required) - The date/time since value, $2 (optional) - The date/time until value, $3 (optional) - The commit author.
gince() {
  if [[ "$1" ]]; then
    # Iterate project directories located in root directory.
    while read project; do
      (
        cd "$project"
        # Only process projects that are Git enabled.
        if [[ -d ".git" ]]; then
          # Capture git log activity.
          local results=$(git log --oneline --format="$(_git_log_line_format)" --since "$1" --until "$2" --author "$3" --reverse)
          # Print project name (cyan) and Git activity (white) only if Git activity was detected.
          if [[ -n "$results" ]]; then
            printf "\033[36m${project:2}:\n$results\n"
          fi
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Date/time must be supplied.\n"
    return 1
  fi
}

# Label: Git Day
# Description: Answer summarized list of current day activity for projects in current directory.
gday() {
  gince "12am"
}

# Label: Git Week
# Description: Answer summarized list of current week activity for projects in current directory.
gweek() {
  gince "last Monday 12am"
}

# Label: Git Month
# Description: Answer summarized list of current month activity for projects in current directory.
gmonth() {
  gince "month 1 12am"
}

# Label: Git Standup
# Description: Answer summarized list of activity since yesterday for projects in current directory.
gsup() {
  gince "yesterday.midnight" "midnight" $(git config user.name)
}

# Label: Git Tail
# Description: Answer commit history since last tag for current project (copies results to clipboard).
gtail() {
  if [[ ! -d ".git" ]]; then
    printf "ERROR: Not a Git repository.\n"
    return 1
  fi

  if [[ $(_git_commits_since_last_tag) ]]; then
    _git_commits_since_last_tag | _copy_and_print "\n"
  else
    printf "No commits since last tag.\n"
  fi
}

# Label: Git Tail (all)
# Description: Answer commit history count since last tag for projects in current directory.
gtaila() {
  # Iterate through root project directories.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git-enabled.
      if [[ -d ".git" ]]; then
        local info=$(_git_commit_count_since_last_tag "$project")
        if [[ ! "$info" == *": 0"* ]]; then
          printf "$info\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Stash
# Description: Creates stash.
# Parameters: $1 (optional) - Label. Default: "Last Actions (YYYY-MM-DD HH:MM:SS AM|PM Z)."
gash() {
  local label=${1:-"Last Actions ($(date '+%Y-%m-%d %r %Z'))."}
  git stash save --include-untracked "$label"
}

# Label: Git Stash List
# Description: List stashes.
gashl() {
  git stash list --pretty=format:'%C(magenta)%gd%C(reset) %C(yellow)%H%C(reset) %s %C(green)(%cr)%C(reset)'
}

# Label: Git Stash Show
# Description: Show stash or prompt for stash to show.
# Parameters: $1 (optional) - Show git diff. Default: skipped.
gashs() {
  local stash=($(git stash list))
  local diff_option="$1"

  if [[ -n "$diff_option" ]]; then
    case "$diff_option" in
      'd')
        _process_git_stash "git stash show -p" "Git Stash Diff Options (select stash to diff)";;
      't')
        _process_git_stash "gdt" "Git Stash Diff Options (select stash to diff)";;
      *)
        printf "Usage: gashs OPTION\n\n"
        printf "Available options:\n"
        printf "  d: Git diff.\n"
        printf "  t: Git difftool.\n"
        return;;
    esac
  else
    _process_git_stash "_git_show_details" "Git Stash Show Options (select stash to show)"
  fi
}

# Label: Git Stash Pop
# Description: Pop stash or prompt for stash to pop.
gashp() {
  _process_git_stash "git stash pop" "Git Stash Pop Options (select stash to pop)"
}

# Label: Git Stash Drop
# Description: Drop stash or prompt for stash to drop.
gashd() {
  _process_git_stash "git stash drop" "Git Stash Drop Options (select stash to drop)"
}

# Label: Git Stash (all)
# Description: Answer stash count for projects in current directory.
gasha() {
  # Iterate through root project directories.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git-enabled.
      if [[ -d ".git" ]]; then
        # Count outstanding commits.
        local size=$(git stash list | wc -l | xargs -n 1)
        # Print project name and Git activity only if Git activity is detected.
        if [[ -n $size && $size != 0 ]]; then
          printf "\033[36m${project:2}\033[m: $size\n" # Outputs in cyan color.
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Upstream Commit Count (all)
# Description: Answer upstream commit count since last pull for projects in current directory.
gucca() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -d ".git" ]]; then
        # Capture upstream project commit count.
        git fetch --quiet
        local count=$(git log ..@{upstream} --pretty=format:"%H" | wc -l | tr -d ' ')

        if [[ $count -gt '0' ]]; then
          # Print project (cyan) and commit count (white).
          printf "\033[36m${project:2}\033[m: $count\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Pull (all)
# Description: Pull new changes from remote branch for projects in current directory.
gpua() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -d ".git" ]]; then
        # Capture current project status.
        local results=$(git pull | tail -1)
        # Print project name and Git activity only if Git activity was detected.
        printf "\033[36m${project:2}\033[m: " # Outputs in cyan color.
        if [[ -n "$results" && "$results" != "Already up-to-date." ]]; then
          printf "\n  $results\n"
        else
          printf "✓\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Push (all)
# Description: Push changes for projects in current directory.
gpa() {
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git-enabled.
      if [[ -d ".git" ]]; then
        # Only process projects that have changes.
        if [[ "$(git status --short --branch)" == *"[ahead"*"]" ]]; then
          printf "\033[36m${project:2}\033[m:\n" # Outputs in cyan color.
          git push
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Add (all)
# Description: Apply file changes (including new files) for projects in current directory.
galla() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -d ".git" ]]; then
        # Apply all changes to Git.
        local results=$(git add --verbose --all .)
        # Print project name (cyan) and Git activity (white) only if Git activity was detected.
        if [[ -n "$results" ]]; then
          printf "\033[36m${project:2}\033[m:\n$results\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Commit and Message (all)
# Description: Commit changes (modified and new), with message, for projects in current directory.
# Parameters: $1 (required) - The commit message.
gcama() {
  if [[ "$1" ]]; then
    # Iterate project directories located in root directory.
    while read project; do
      (
        cd "$project"
        # Only process projects that are Git-enabled.
        if [[ -d ".git" ]]; then
          # Only process projects that have changes.
          if [[ "$(git status --short)" ]]; then
            printf "\033[36m${project:2}\033[m:\n" # Outputs in cyan color.
            git commit --all --message "$1"
          fi
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Commit message must be supplied.\n"
    return 1
  fi
}

# Label: Git Commit and Push (all)
# Description: Commit and push changes for projects in current directory.
# Parameters: $1 (required) - The commit message.
gcap() {
  if [[ "$1" ]]; then
    # Iterate project directories located in root directory.
    while read project; do
      (
        cd "$project"
        # Only process projects that are Git-enabled.
        if [[ -d ".git" ]]; then
          # Only process projects that have changes.
          if [[ "$(git status --short)" ]]; then
            printf "\033[36m${project:2}\033[m:\n" # Outputs in cyan color.
            git commit --all --message "$1" && git push
          fi
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Commit message must be supplied.\n"
    return 1
  fi
}

# Label: Git Rebase (interactive)
# Description: Rebase commits, interactively.
# Parameters: $1 (optional) - The number of commits or branch to rebase to. Default: upstream or root.
gri() {
  local value="$1"
  local number_regex="^[0-9]+$"
  local branch_regex="^[0-9a-zA-Z\-\_]+$"

  if [[ $(git config remote.origin.url) ]]; then
    if [[ "$value" =~ $number_regex ]]; then
      git rebase --interactive "@~${value}"
    elif [[ "$value" =~ $branch_regex ]]; then
      git rebase --interactive "$value"
    else
      git rebase --interactive @{upstream}
    fi
  else
    git rebase --interactive --root
  fi
}

# Label: Git Branch List
# Description: List local and remote branch details.
gbl() {
  local format="%(refname)|%(color:yellow)%(objectname)|%(color:reset)|%(color:blue bold)%(authorname)|%(color:green)|%(committerdate:relative)"
  _git_branch_list "$format" | column -s'|' -t
}

# Label: Git Branch Create
# Description: Create and switch to branch.
# Parameters: $1 (required) - The branch name.
gbc() {
  local name="$1"

  if [[ "$name" ]]; then
    git branch "$name"
    git checkout "$name"
    printf "$name" | _copy_and_print
  else
    printf "ERROR: Branch name must be supplied.\n"
    return 1
  fi
}

# Label: Git Branch Switch
# Description: Switch between branches.
gbs() {
  # Only process projects that are Git-enabled.
  if [[ -d ".git" ]]; then
    local branches=()
    local ifs_original=$IFS
    IFS=$'\n'

    branches=($(_git_branch_list))

    # Proceed only if there is more than one branch to select from.
    if [[ ${#branches[@]} -gt 1 ]]; then
      printf "\nSelect branch to switch to:\n"

      for ((index = 0; index < ${#branches[*]}; index++)); do
        printf "  $index: ${branches[$index]##*/}\n"
      done

      printf "  q: Quit/Exit.\n\n"

      read -p "Enter selection: " response
      printf "\n"

      local match="^([0-9]{1,2})$"
      if [[ "$response" =~ $match ]]; then
        local branch="$(printf "${branches[$response]##*/}" | awk '{print $1}')"
        git checkout $branch
        printf "\n"
      fi
    else
      printf "Sorry, only one branch to switch to and you're on it!\n"
    fi
  else
    printf "Sorry, no branches to switch to.\n"
  fi

  IFS=$ifs_original
}

# Label: Git Branch Delete
# Description: Select local and/or remote branches to delete.
gbd() {
  # Only process projects that are Git-enabled.
  if [[ -d ".git" ]]; then
    local branches=()
    local ifs_original=$IFS
    IFS=$'\n'

    branches=($(_git_branch_list))

    # Proceed only if there is more than one branch to select from.
    if [[ ${#branches[@]} -gt 1 ]]; then
      printf "\nSelect branch to delete:\n"

      for ((index = 0; index < ${#branches[*]}; index++)); do
        printf "  $index: ${branches[$index]##*/}\n"
      done

      printf "  q: Quit/Exit.\n\n"

      read -p "Enter selection: " response
      local branch="$(printf "${branches[$response]##*/}" | awk '{print $1}')"
      printf "\n"

      local match="^([0-9]{1,2})$"
      if [[ "$response" =~ $match ]]; then
        _git_branch_delete_local "$branch"
        _git_branch_delete_remote "$branch"
      fi
    else
      printf "Sorry, only the master branch exists and it can't be deleted.\n"
    fi
  else
    printf "Sorry, no branches to delete.\n"
  fi

  IFS=$ifs_original
}

# Label: Git Branch Delete Merged
# Description: Delete locally merged branches.
gbdm() {
  if [[ $(_git_branch_name) != "master" ]]; then
    printf "ERROR: Whoa, switch to master branch first.\n"
    return 1
  fi

  local branches=($(git branch --merged | grep --invert-match "\* master" | xargs -n 1))

  if [[ ${#branches[@]} > 0 ]]; then
    for branch in $branches; do
      git branch -D "$branch"
    done
  else
    printf "All clear, no merged branches to delete.\n"
  fi
}

# Label: Git Branch Name (all)
# Description: List current branch for projects in current directory.
gbna() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git-enabled.
      if [[ -d ".git" ]]; then
        printf "\033[36m${project:2}\033[m: " # Output in cyan color.
        local branch="$(_git_branch_name)"

        if [[ "$branch" == "master" ]]; then
          printf "$branch\n"
        else
          printf "\033[31m$branch\033[m\n" # Output in red color.
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Tag Delete
# Description: Delete local and remote tag (if found).
# Parameters: $1 (required) - The tag name.
gtagd() {
  if [[ -z "$1" ]]; then
    printf "ERROR: Tag name must be supplied.\n"
    return 1
  fi

  read -p "Delete '$1' tag from local and remote repositories. Continue (y/n)?: " response

  if [[ "$response" == 'y' ]]; then
    printf "Local: "
    if [[ -n "$(git tag --list $1)" ]]; then
      git tag --delete "$1"
    else
      printf "No tag found.\n"
    fi

    printf "Remote: "
    if [[ $(git config remote.origin.url) && -n "$(git ls-remote --tags origin | grep $1)" ]]; then
      git push --delete origin "$1"
    else
      printf "No tag found.\n"
    fi
  else
    printf "Tag deletion aborted.\n"
  fi
}

# Label: Git Worktree Add
# Description: Create and switch to new worktree.
# Parameters: $1 (required) - The worktree/branch name, $2 (optional) - Create branch ("y" or "n"). Default: "n".
gwa() {
  local name="$1"
  local project_name="$(basename $(pwd))"
  local worktree_path="../$project_name-$name"
  local branch="${2:-n}"

  if [[ -z "$name" ]]; then
    printf "ERROR: Git worktree name is missing.\n"
    return 1
  fi

  if [[ "$branch" == "y" ]]; then
    git worktree add -b "$name" "$worktree_path" master
  else
    git worktree add --detach "$worktree_path" HEAD
  fi

  printf "Syncing project files...\n"
  git ls-files --others | rsync --compress --links --files-from - "$(pwd)/" "$worktree_path/"
  cd "$worktree_path"
}

# Label: Git Hook Delete
# Description: Delete hooks for current project.
ghd() {
  if [[ -d ".git" ]]; then
    (
      cd .git/hooks
      rm -rf *
    )
    printf "Git hooks deleted.\n"
  fi
}

# Label: Git Hook Delete (all)
# Description: Delete hooks for projects in current directory.
ghda() {
  while read project; do
    (
      cd "$project"
      printf "\n\033[36m${project:2}\033[m: " # Outputs in cyan color.

      # Only process projects that are Git-enabled.
      if [[ -d ".git" ]]; then
        ghd
      else
        printf "Not a Git project.\n"
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Verify and Clean
# Description: Verify and clean objects for current project.
gvac() {
  printf "Verifying connectivity and validity of the objects in Git repository...\n\n"
  git fsck

  printf "\nCleaning unnecessary files and optimizing local Git repository...\n\n"
  git gc

  printf "\nPruning rerere records of older conflicting merges...\n\n"
  git rerere gc
}

# Label: Git Verify and Clean (all)
# Description: Verify and clean objects for projects in current directory.
gvaca() {
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git-enabled.
      if [[ -d ".git" ]]; then
        printf "\n\033[36m${project:2}\033[m:\n" # Outputs in cyan color.
        git fsck && git gc && git rerere gc
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Git Nuke
# Description: Permanently destroy and erase a file from history. UNRECOVERABLE!
# Parameters: $1 (optional) - The file to destroy.
guke() {
  local file="$1"

  if [[ -z "$file" ]]; then
    printf "ERROR: File to nuke must be supplied.\n"
    return 1
  fi

  printf "\033[31m" # Switch to red font.
  read -p "Permanently delete '$file' from the local repository. Continue (y/n)?: " response
  printf "\033[m" # Switch to white font.

  if [[ "$response" == 'y' ]]; then
    git filter-branch --force --index-filter "git rm -r --cached '$file' --ignore-unmatch" --prune-empty --tag-name-filter cat -- --all
  else
    printf "Nuke aborted.\n"
  fi
}

#---------------------------------------#
# Section: [GitHub](https://github.com) #
#---------------------------------------#

# Label: GitHub
# Description: View GitHub details for current project.
# Parameters: $1 (optional) - The option selection, $2 (optional) - The option input.
gh() {
  if [[ -d ".git" ]]; then
    while true; do
      if [[ $# == 0 ]]; then
        printf "\nUsage: gh OPTION\n"
        printf "\nGitHub Options (default browser):\n"
        printf "  o: Open repository.\n"
        printf "  i: Open repository issues.\n"
        printf "  c: Open repository commits. Options:\n"
        printf "     HASH: Open commit.\n"
        printf "  b: Open repository branches. Options:\n"
        printf "     c: Open current branch.\n"
        printf "  t: Open repository tags (releases).\n"
        printf "  r: Open repository pull requests.\n"
        printf "     NUMBER: Open pull request.\n"
        printf "     l: List pull requests.\n"
        printf "  w: Open repository wiki.\n"
        printf "  p: Open repository pulse.\n"
        printf "  g: Open repository graphs.\n"
        printf "  s: Open repository settings.\n"
        printf "  u: Print and copy (to clipboard) repository URL. Options:\n"
        printf "     HASH: Print and copy commit URL.\n"
        printf "     l: Print and copy last commit URL.\n"
        printf "  q: Quit/Exit.\n\n"
        read -p "Enter selection: " response
        printf "\n"
        _process_gh_option $response "$2"
      else
        _process_gh_option "$1" "$2"
      fi
    done
  else
    printf "ERROR: Not a Git repository!\n"
    return 1
  fi
}

#--------------------------------------------------#
# Section: [PostgreSQL](http://www.postgresql.org) #
#--------------------------------------------------#

# Label: PostgreSQL User Create
# Description: Create PostgreSQL user.
# Parameters: $1 (required) - The username.
pguc() {
  local user="$1"

  if [[ -n "$user" ]]; then
    createuser --interactive "$user" -P
  else
    printf "ERROR: PostgreSQL username must be supplied.\n"
    return 1
  fi
}

# Label: PostgreSQL User Drop
# Description: Drop PostgreSQL user.
# Parameters: $1 (required) - The username.
pgud() {
  local user="$1"

  if [[ -n "$user" ]]; then
    dropuser --interactive "$user"
  else
    printf "ERROR: PostgreSQL username must be supplied.\n"
    return 1
  fi
}

# Label: PostgreSQL Template
# Description: Edit PostgreSQL template.
# Parameters: $1 (required) - The username.
pgt() {
  local user="$1"

  if [[ -n "$user" ]]; then
    psql -U "$user" template1
  else
    printf "ERROR: PostgreSQL username must be supplied.\n"
    return 1
  fi
}

#--------------------------------------------#
# Section: [Ruby](https://www.ruby-lang.org) #
#--------------------------------------------#

# Label: Ruby Upgrade (all)
# Description: Upgrade Ruby projects in current directory with new Ruby version.
# Parameters: $1 (required) - The new version to upgrade to. Example: 2.2.3.
rua() {
  if [[ "$1" ]]; then
    while read project; do
      (
        cd "$project"
        # Only process projects which have ruby version information.
        if [[ -e ".ruby-version" ]]; then
          local old_version=$(head -n 1 .ruby-version)
          local new_version="$1"

          printf "\033[36m${project:2}\033[m: " # Outputs project in cyan color.

          # Update only if current version is not equal to new version.
          if [[ "$old_version" != "$new_version" ]]; then
            printf "$new_version\n" > .ruby-version
            printf "$old_version --> $new_version\n"
          else
            printf "✓\n"
          fi
        fi
      )
    done < <(find . -type d -depth 1)
  else
    printf "ERROR: Version must be supplied.\n"
    return 1
  fi
}

# Label: Ruby Server
# Description: Serve web content from current directory via WEBrick.
# Parameters: $1 (optional) - The custom port. Default: 3030.
rserv() {
  local default_port=3030
  local custom_port=$1

  ruby -run -e httpd . --port ${custom_port:-$default_port}
}

#-------------------------------------#
# Section: [RSpec](http://rspec.info) #
#-------------------------------------#

# Label: Bundle Execute RSpec
# Description: Run RSpec via binstub or Bundler.
bes() {
  if [[ -e bin/rspec ]]; then
    bin/rspec $@
  else
    bundle exec rspec $@
  fi
}

# Label: Bundle Execute Rake (all)
# Description: Run default Rake tasks via binstub or Bundler for projects in current directory.
bera() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that support Bundler and RSpec.
      if [[ -f "Gemfile.lock" && -f "Rakefile" ]]; then
        # Prints project (cyan).
        printf "\033[36m${project:2}\033[m: "

        SUPPRESS_STDOUT=enabled SUPPRESS_STDERR=enabled ber > /dev/null
        printf "\n"
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Bundle Execute RSpec (all)
# Description: Run RSpec via binstub or Bundler for projects in current directory.
bessa() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that support Bundler and RSpec.
      if [[ -f "Gemfile.lock" && -d "spec" ]]; then
        local json=$(SUPPRESS_STDOUT=enabled SUPPRESS_STDERR=enabled bess --format json)
        local examples=$(printf "%s" "$json" | jq ".summary.example_count" )
        local failures=$(printf "%s" "$json" | jq ".summary.failure_count" )
        local pending=$(printf "%s" "$json" | jq ".summary.pending_count" )
        local duration=$(printf "%s" "$json" | jq ".summary.duration" )

        # Prints project (cyan).
        printf "\033[36m${project:2}\033[m: "

        # Prints total examples (white).
        printf "$examples examples, "

        # Prints total failures (red).
        _toggle_total_color "$failures" "failures" "\033[31m"
        printf ", "

        # Prints total pending (yellow).
        _toggle_total_color "$pending" "pending" "\033[33m"
        printf ", "

        # Prints total duration (white).
        printf "$duration seconds.\n"
      fi
    )
  done < <(find . -type d -depth 1)
}

#---------------------------------------#
# Section: [Bundler](http://bundler.io) #
#---------------------------------------#

# Label: Bundler Jobs
# Description: Answer maximum Bundler job limit for current machine or automatically set it.
bj() {
  if command -v sysctl > /dev/null; then
    local computer_name=$(scutil --get ComputerName)
    local max_jobs=$((`sysctl -n hw.ncpu` - 1))
    local bundler_config="$HOME/.bundle/config"

    printf "$computer_name's maximum Bundler job limit is: $max_jobs.\n"

    if command -v ag > /dev/null && [[ -e "$bundler_config" ]]; then
      local current_jobs=$(ag "JOBS" $bundler_config | awk '{print $2}' | tr -d "'")

      if [[ $current_jobs != $max_jobs ]]; then
        bundle config --global jobs $max_jobs
        printf "Automatically updated Bundler to use maximum job limit. Details: $bundler_config.\n"
      else
        printf "$computer_name is using maximum job limit. Kudos!\n"
      fi
    fi
  else
    printf "ERROR: Operating system must be OSX."
    return 1
  fi
}

# Label: Bundler Ignore Post-Install Message
# Description: Update Bundler to ignore install messages for specified gem.
# Parameters: $1 (required) - The gem name.
bcim() {
  local gem_name=$1

  if [[ ! $gem_name ]]; then
    printf "ERROR: Gem name must be supplied!\n"
    return 1
  fi

  bundle config ignore_messages.$gem_name true

  printf "Bundler post-install messages are ignored for \"$gem_name\".\n"
}

# Label: Bundle Outdated (all)
# Description: Answer outdated gems for projects in current directory.
boa() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that are Git enabled.
      if [[ -f "Gemfile.lock" ]]; then
        printf "\033[36m${project:2}\033[m: " # Outputs project in cyan color.

        # Capture current project status: Search for bullets (*, outdated gems) or missing (not found) gems.
        local results=$(bundle outdated | egrep "(\*.+|.+not\sfind.+)")

        # Print project status if Bundler activity is detected, otherwise a checkmark for passing status.
        if [[ -n "$results" ]]; then
          printf "\n$results\n"
        else
          printf "✓\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Bundle Update (all)
# Description: Update gems for projects in current directory.
bua() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that support Bundler.
      if [[ -f "Gemfile.lock" ]]; then
        rm -f Gemfile.lock
        bundle install --quiet

        # Print project status if Bundler activity is detected, otherwise a checkmark for passing status.
        printf "\033[36m${project:2}\033[m: " # Outputs project in cyan color.
        if [[ $(git diff | wc -l | tr -d ' ') -gt 0 ]]; then
          printf "↑\n"
        else
          printf "✓\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Bundle Clean (all)
# Description: Clean projects of gem artifacts (i.e. pkg folder).
bca() {
  # Iterate project directories located in root directory.
  while read project; do
    (
      cd "$project"
      # Only process projects that support Bundler.
      if [[ -f "Gemfile.lock" ]]; then
        printf "\033[36m${project:2}\033[m: " # Outputs project in cyan color.

        # Print status if found, otherwise a checkmark for passing status.
        if [[ -d "pkg" ]]; then
          rm -rf pkg
          printf "Cleaned gem artifacts.\n"
        else
          printf "✓\n"
        fi
      fi
    )
  done < <(find . -type d -depth 1)
}

# Label: Bundle Execute Rake
# Description: Run Rake via binstub or Bundler.
ber() {
  if [[ -e bin/rake ]]; then
    bin/rake $@
  else
    bundle exec rake $@
  fi
}

# Label: Bundle Execute Guard
# Description: Run Guard via binstub or Bundler.
beg() {
  if [[ -e bin/guard ]]; then
    bin/guard $@
  else
    bundle exec guard $@
  fi
}

# Label: Bundle Execute Capistrano
# Description: Run Capistrano via binstub or Bundler.
bec() {
  if [[ -e bin/cap ]]; then
    bin/cap $@
  else
    bundle exec cap $@
  fi
}

#--------------------------------------------------#
# Section: [Ruby on Rails](http://rubyonrails.org) #
#--------------------------------------------------#

# Label: Rails New
# Description: Create new Rails application from selected template.
# Parameters: $1 (required) - The Rails application name, $2 (optional) - The template to apply.
rew() {
  if [[ "$1" ]]; then
    while true; do
      if [[ $2 ]]; then
        _process_rew_option "$1" "$2" "$3"
      else
        printf "\nUsage: rew NAME TEMPLATE\n"
        printf "\nAvailable Ruby on Rails Templates:\n\n"
        printf "  default: Rails Default Template\n"
        printf "     slim: Rails Slim Template\n"
        printf "    setup: Rails Setup Template\n"
        printf "\n"
        read -p "Please pick one (or type 'q' to quit): " response
        printf "\n"
        _process_rew_option "$1" $response "$3"
      fi
    done
  else
    printf "ERROR: Rails application name must be supplied.\n"
    return 1
  fi
}

# Label: Rails Script Console
# Description: Run Rails console.
sc() {
  _run_rails_command "console" "$*"
}

# Label: Rails Script Server
# Description: Run Rails server.
ss() {
  _run_rails_command "server" "$*"
}

# Label: Rails Script Generator
# Description: Run Rails generator.
sg() {
  _run_rails_command "generate" "$*"
}

# Label: Rails Script Database Console
# Description: Run Rails database console.
sdb() {
  _run_rails_command "dbconsole" "$*"
}

#--------------------------------------------------------------#
# Section: [Rails ERD](https://github.com/voormedia/rails-erd) #
#--------------------------------------------------------------#

# Label: Rails ERD
# Description: Generate Rails Entity Relationship Diagram (ERD).
erd() {
  local doc_dir="tmp/doc"

  mkdir -p "$doc_dir"
  ber erd attributes=primary_keys,foreign_keys,timestamps,inheritance,content inheritance=true orientation=vertical filename="$doc_dir/models"
  printf "$(pwd)/$doc_dir/models.pdf" | _copy_and_print
}

#------------------------------------------------------------#
# Section: [RailRoady](https://github.com/preston/railroady) #
#------------------------------------------------------------#

# Label: RailRoady Models
# Description: Generate diagrams for Rails models, controllers, or states.
# Parameters: $1 (required) - The kind of diagram to generate.
rr() {
  local kind="$1"
  local doc_dir="tmp/doc"

  case $kind in
    'm')
      railroady --label --inheritance --specify --all-columns --join --transitive --output "$doc_dir/models.dot" --models
      printf "$(pwd)/$doc_dir/models.dot" | _copy_and_print;;
    'c')
      railroady --label --inheritance --output "$doc_dir/controllers.dot" --controllers
      printf "$(pwd)/$doc_dir/controllers.dot" | _copy_and_print;;
    's')
      railroady --label --inheritance --output "$doc_dir/state.dot" --aasm
      printf "$(pwd)/$doc_dir/state.dot" | _copy_and_print;;
    *)
      printf "\nUsage: rr KIND\n\n"
      printf "RailRoady Options:\n"
      printf "  m: Generate Rails Entity Relationship Diagram (ERD).\n"
      printf "  c: Generate Rails controller hierarchy diagram.\n"
      printf "  s: Generate Rails state machine transitions.\n\n";;
  esac
}

#----------------------------------------------#
# Section: [Travis CI](https://travis-ci.org/) #
#----------------------------------------------#

# Label: Travis CI Encrypt (all)
# Description: Encrypt string for Travis CI-enabled projects in current directory.
# Parameters: $1 (required) - The key to add, $2 (require) - The value to encrypt.
tcie() {
  if [[ -z "$1" ]]; then
    printf "ERROR: Encryption key must be supplied. Example: notifications.slack.\n"
    return 1
  fi

  if [[ -z "$2" ]]; then
    printf "ERROR: Encryption value must be supplied. Example: ra:B35GH59594BKDK.\n"
    return 1
  fi

  while read project; do
    (
      cd "$project"
      # Only process projects which have ruby version information.
      if [[ -e ".travis.yml" ]]; then
        travis encrypt "$2" --add "$1"
        printf "\033[36m${project:2}\033[m: ✓\n" # Outputs in cyan color.
      fi
    )
  done < <(find . -type d -depth 1)
}

#----------------------------------------------------------------------------#
# Section: [Site Validator](https://github.com/sitevalidator/site_validator) #
#----------------------------------------------------------------------------#

# Label: Site Validator
# Description: Generate site validation report using W3C Validator.
# Parameters: $1 (required) - The site URL, $2 (optional) - The report file path/name.
sv() {
  if [[ $(command -v site_validator) ]]; then
    if [[ "$1" ]]; then
      if [[ "$2" ]]; then
        local report="$2"
      else
        local report="report.html"
      fi

      site_validator "$1" "$report" && open "$report"
    else
      printf "ERROR: Missing web site URL. Usage: sv http://www.example.com output.html.\n"
      return 1
    fi
  else
    printf "ERROR: Site Validator not found. To install, run: gem install site_validator.\n"
    return 1
  fi
}

#-----------------------------------------------------#
# Section: [Image Magick](http://www.imagemagick.org) #
#-----------------------------------------------------#

# Label: Sketch
# Description: Convert photo into a sketch. Inspired by [Whiteboard Cleaner Gist](https://gist.github.com/lelandbatey/8677901).
# Parameters: $1 (required) - The input image path, $2 (optional) - The output image path. Default: sketch.jpg.
sketch() {
  local input_path="$1"
  local output_path="$2"

  if [[ -z "$input_path" ]]; then
    printf "ERROR: Input image path must be supplied.\n"
    return 1
  fi

  if [[ -z "$output_path" ]]; then
    local output_path="sketch.jpg"
  fi

  printf "\nProcessing image: $input_path...\n"
  convert "$input_path" -morphology Convolve DoG:15,100,0 -negate -normalize -blur 0x1 -channel RBG -level 60%,91%,0.1 "$output_path"
  printf "\nSketch image ready: $output_path.\n"
}

#------------------------------------------#
# Section: [FFmpeg](http://www.ffmpeg.org) #
#------------------------------------------#

# Label: Gifize
# Description: Convert video to animated GIF.
# Parameters: $1 (required) - The video input file path.
gifize() {
  local input_path="$1"
  local output_path="${1%.*}.gif"
  local temp_dir="/tmp/gifize"
  local temp_pattern="$temp_dir/static-%05d.png"

  if ! command -v convert > /dev/null; then
    printf "ERROR: ImageMagick not installed.\n"
    return 1
  fi

  if ! command -v ffmpeg > /dev/null; then
    printf "ERROR: FFMPEG not installed.\n"
    return 1
  fi

  if ! command -v gifsicle > /dev/null; then
    printf "ERROR: Gifsicle not installed.\n"
    return 1
  fi

  if [[ -n "$input_path" ]]; then
    printf "Rendering $input_path as $output_path...\n"
    mkdir -p "$temp_dir"
    ffmpeg -loglevel panic -i "$input_path" -r 10 -vcodec png "$temp_pattern"
    time convert +dither -layers Optimize -resize 600x600\> "$temp_dir/static*.png"  GIF:- | gifsicle --colors 128 --delay=5 --loop --optimize=3 --multifile - > "$output_path"
    rm -rf "$temp_dir"
    printf "\nGIF Complete: $output_path\n"
  else
    printf "Usage: gifize example.mov.\n"
  fi
}

#---------------------------------------------#
# Section: [asciinema](https://asciinema.org) #
#---------------------------------------------#

# Label: asciinema Record
# Description: Create new asciinema recording.
# Parameters: $1 (required) - The recording title, $2 (required) - The recording file name.
cinr() {
  local title="$1"
  local name="$2"

  if [[ -z "$title" ]]; then
    printf "ERROR: Recording title is missing.\n"
    return 1
  fi

  if [[ -z "$name" ]]; then
    printf "ERROR: Recording file name is missing.\n"
    return 1
  fi

  asciinema rec --max-wait 1 --title "$title" "$name"
}

#-------------------#
# Section: Dotfiles #
#-------------------#

# Label: Dotfiles
# Description: Learn about dotfile aliases, functions, etc.
# Parameters: $1 (optional) - The option selection, $2 (optional) - The option input.
dots() {
  while true; do
    if [[ $# == 0 ]]; then
      printf "\nUsage: dots OPTION\n"
      printf "\nDotfile Options:\n"
      printf "  a: Print aliases.\n"
      printf "  f: Print functions.\n"
      printf "  g: Print Git hooks.\n"
      printf "  p: Print all.\n"
      printf "  s: Search for alias/function.\n"
      printf "  q: Quit/Exit.\n\n"
      read -p "Enter selection: " response
      printf "\n"
      _process_dots_option $response "$2"
    else
      _process_dots_option $1 "$2"
    fi
  done
}
