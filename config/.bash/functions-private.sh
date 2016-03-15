# BASH FUNCTIONS (private)

#------------------#
# Section: General #
#------------------#

# Label: Print Black on White
# Description: Print black text on a white background.
# Parameters: $1 (required) - Content to print.
_print_black_on_white() {
  local content="$1"
  printf "\e[0;30m\e[48;5;255m$content\033[m"
}

# Label: Clip and Print
# Description: Copy input to clipboard and print what what was copied (best used with a pipe).
# Parameters: $1 (optional) - Displays "(copied to cliboard)" on a new line. Default: false.
_copy_and_print() {
  local delimiter=${1:-' '}
  local message="$delimiter(copied to clipboard)\n"

  pbcopy && printf "%s" "$(pbpaste)" && printf "$message"
}

# Label: Toggle Total Color
# Description: Format and conditionally color the total.
# Parameters: $1 (required) - The total, $2(required) - The label, $3 (required) - The color.
_toggle_total_color() {
  local total="$1"
  local label="$2"
  local color="$3"

  if [[ $total -gt 0 ]]; then
    printf "$color$total $label\033[m"
  else
    printf "$total $label"
  fi
}

#------------------------------------#
# Section: [Git](http://git-scm.com) #
#------------------------------------#

# Label: Git Log Line Format
# Description: Print single line log format.
_git_log_line_format() {
  printf "%s" "%C(yellow)%H%C(reset) %G? %C(bold blue)%an%C(reset) %s%C(bold cyan)%d%C(reset) %C(green)(%cr)%C(reset)"
}

# Label: Git Log Format
# Description: Prints default log format.
_git_log_details_format() {
  printf "%s" "$(_git_log_line_format) %n%b%n%N%-%n"
}

# Label: Git Show Details
# Description: Show commit/file change details in a concise format.
# Parameters: $1 (required) - The params to pass to git show.
_git_show_details() {
  git show --stat --pretty=format:"$(_git_log_details_format)" $@
}

# Label: Git Commits Since Last Tag
# Description: Answer commit history since last tag for project.
_git_commits_since_last_tag() {
  if [[ $(git tag) ]]; then
    git log --oneline --reverse --format='%C(yellow)%H%Creset %s' $(git describe --abbrev=0 --tags --always)..HEAD
  else
    git log --oneline --reverse --format='%C(yellow)%H%Creset %s'
  fi
}

# Label: Git Commit Count Since Last Tag
# Description: Answer commit count since last tag for project.
# Parameters: $1 (optional) - The output prefix. Default: null., $2 (optional) - The output suffix. Default: null.
_git_commit_count_since_last_tag() {
  local prefix="$1"
  local suffix="$2"
  local count=$(_git_commits_since_last_tag | wc -l | xargs -n 1)

  if [[ -n $count ]]; then
    # Prefix
    if [[ -n "$prefix" ]]; then
      printf "\033[36m${prefix:2}\033[m: " # Cyan.
    fi

    # Commit Count
    if [[ $count -ge 30 ]]; then
      printf "\033[31m$count\033[m" # Red.
    elif [[ $count -ge 20 && $count -le 29 ]]; then
      printf "\033[1;31m$count\033[m" # Light red.
    elif [[ $count -ge 10 && $count -le 19 ]]; then
      printf "\033[33m$count\033[m" # Yellow.
    else
      printf "$count" # White.
    fi

    # Suffix
    if [[ -n "$suffix" ]]; then
      printf "$suffix"
    fi
  fi
}

# Label: Git File Commits
# Description: Print file commit history (with optional diff support).
# Parameters: $1 (required) - The file path.
_git_file_commits() {
  local commits=("${!1}")
  local file="$2"
  local commit_total=${#commits[@]}
  local option_padding=${#commit_total}
  local counter=1

  if [[ ${#commits[@]} == 0 ]]; then
    printf "No file history detected.\n"
    return
  fi

  printf "Commit History ($file):\n\n"

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
    gdt $selected_commit^! -- "$file"
  fi
}

# Label: Git Branch Name
# Description: Print Git branch name.
_git_branch_name() {
  git rev-parse --abbrev-ref HEAD | tr -d '\n'
}

# Label: Git Branch List
# Description: List branches (local/remote) including author and relative time.
# Parameters: $1 (optional) - The output format.
_git_branch_list() {
  local format=${1:-"%(refname) %(color:blue bold)%(authorname) %(color:green)(%(authordate:relative))"}

  git for-each-ref --sort="-authordate:iso8601" --format="$format" refs/heads refs/remotes/origin | \
                   sed '/HEAD/d' | \
                   sed 's/refs\/heads\///g' | \
                   sed 's/refs\/remotes\/origin\///g' | \
                   sort --unique
}

# Label: Git Branch Delete (local)
# Description: Delete local branch.
# Parameters: $1 (required) - The local branch to delete.
_git_branch_delete_local() {
  local branch="$1"

  printf "\033[31m" # Switch to red font.
  read -p "Delete \"$branch\" local branch (y/n)?: " response
  printf "\033[m" # Switch to white font.

  if [[ "$response" == 'y' ]]; then
    if [[ -n "$(git branch --list $branch)" ]]; then
      git branch -D "$branch"
    else
      printf "Local branch not found.\n"
    fi
  else
    printf "Local branch deletion aborted.\n"
  fi
}

# Label: Git Branch Delete (remote)
# Description: Delete remote branch.
# Parameters: $1 (required) - The remote branch to delete.
_git_branch_delete_remote() {
  local branch="$1"

  printf "\033[31m" # Switch to red font.
  read -p "Delete \"$branch\" remote branch (y/n)?: " response
  printf "\033[m" # Switch to white font.

  if [[ "$response" == 'y' ]]; then
    if [[ -n "$(git branch --remotes --list origin/$branch)" ]]; then
      git push origin --delete "$branch"
    else
      printf "Remote branch not found.\n"
    fi
  else
    printf "Remote branch deletion aborted.\n"
  fi
}

# Label: Git Stash
# Description: Enhance default git stash behavior by prompting for input (multiple) or using last stash (single).
# Parameters: $1 (required) - The Git stash command to execute, $2 (required) - The prompt label (for multiple stashes).
_process_git_stash() {
  local stash_command="$1"
  local stash_index=0
  local prompt_label="$2"
  local ifs_original=$IFS
  IFS=$'\n'

  # Store existing stashes (if any) as an array. See public, "gashl" for details.
  stashes=($(gashl))

  if [[ ${#stashes[@]} == 0 ]]; then
    printf "Git stash is empty. Nothing to do.\n"
    return 0
  fi

  # Ask which stash to show when multiple stashes are detected, otherwise show the existing stash.
  if [[ ${#stashes[@]} -gt 1 ]]; then
    printf "$prompt_label:\n"
    for ((index = 0; index < ${#stashes[*]}; index++)); do
      printf "  $index: ${stashes[$index]}\n"
    done
    printf "  q: Quit/Exit.\n\n"

    read -p "Enter selection: " response

    local match="^[0-9]{1}$"
    if [[ "$response" =~ $match ]]; then
      printf "\n"
      stash_index="$response"
    else
      return 0
    fi
  fi

  IFS=$ifs_original
  eval "$stash_command stash@{$stash_index}"
}

#---------------------------------------#
# Section: [GitHub](https://github.com) #
#---------------------------------------#

# Label: GitHub URL
# Description: Answer GitHub URL for current project.
_gh_url() {
  git remote -v | \
    grep git@github.com | \
    grep fetch | \
    head -1 | \
    cut -f2 | \
    cut -d' ' -f1 | \
    sed -e 's/:/\//' -e 's/git@/https:\/\//' -e 's/\.git//'
}

# Label: GitHub Pull Request List
# Description: List pull requests (local/remote) including subject, author, and relative time.
# Parameters: $1 (optional) - The output format.
_gh_pr_list() {
  local format=${1:-"%(refname) %(color:yellow)%(refname)%(color:reset) %(subject) %(color:blue bold)%(authorname) %(color:green)(%(committerdate:relative))"}

  git for-each-ref --format="$format" refs/remotes/pull_requests | \
                   sed 's/refs\/remotes\/pull_requests\///g' | \
                   sort --numeric-sort | \
                   cut -d' ' -f2-
}

# Label: Process GitHub Commit Option
# Description: Process GitHub commit option for remote repository viewing.
# Parameters: $1 (optional) - The commit hash.
_process_gh_commit_option() {
  local commit="$1"

  if [[ "$commit" ]]; then
    open "$(_gh_url)/commit/$commit"
  else
    open "$(_gh_url)/commits"
  fi
}

# Label: Process GitHub Branch Option
# Description: Process GitHub branch option for remote repository viewing.
# Parameters: $1 (optional) - The option.
_process_gh_branch_option() {
  local option="$1"

  if [[ "$option" == 'c' ]]; then
    open "$(_gh_url)/tree/$(_git_branch_name)"
  else
    open "$(_gh_url)/branches"
  fi
}

# Label: Process GitHub Pull Request Option
# Description: Process GitHub pull request option for remote repository viewing.
# Parameters: $1 (optional) - The option.
_process_gh_pull_request_option() {
  local option="$1"
  local number_match="^[0-9]+$"

  if [[ "$option" =~ $number_match ]]; then
    open "$(_gh_url)/pull/$option"
  elif [[ "$option" == 'l' ]]; then
    _gh_pr_list
  else
    open "$(_gh_url)/pulls"
  fi
}

# Label: Process GitHub URL Option
# Description: Processes GitHub URL option for remote repository viewing.
# Parameters: $1 (optional) - The commit/option.
_process_gh_url_option() {
  local commit="$1"
  local commit_match="^([0-9a-f]{40}|[0-9a-f]{7})$"

  if [[ "$commit" =~ $commit_match ]]; then
    printf "$(_gh_url)/commit/$commit" | _copy_and_print
  elif [[ "$commit" == 'l' ]]; then
    printf "$(_gh_url)/commit/$(git log --pretty=format:%H -1)" | _copy_and_print
  else
    _gh_url | _copy_and_print
  fi
}

# Label: Process GitHub Option
# Description: Processes GitHub option for remote repository viewing.
# Parameters: $1 (optional) - The first option, $2 (optional) - The second option.
_process_gh_option() {
  case $1 in
    'o')
      open $(_gh_url)
      break;;
    'i')
      open "$(_gh_url)/issues"
      break;;
    'c')
      _process_gh_commit_option "$2"
      break;;
    'b')
      _process_gh_branch_option "$2"
      break;;
    't')
      open "$(_gh_url)/tags"
      break;;
    'r')
      _process_gh_pull_request_option "$2"
      break;;
    'w')
      open "$(_gh_url)/wiki"
      break;;
    'p')
      open "$(_gh_url)/pulse"
      break;;
    'g')
      open "$(_gh_url)/graphs"
      break;;
    's')
      open "$(_gh_url)/settings"
      break;;
    'u')
      _process_gh_url_option "$2"
      break;;
    'q')
      break;;
    *)
      printf "ERROR: Invalid option.\n"
      break;;
  esac
}

#--------------------------------------------------#
# Section: [Ruby on Rails](http://rubyonrails.org) #
#--------------------------------------------------#

# Label: Run Rails Command
# Description: Run Rails command with smart detection of current environment.
# Parameters: $1 (required) - The command to run, $2(optional) - Additional arguments
_run_rails_command() {
  local rails_command=$1
  local rails_options=$2

  # Rails 4.x.x.
  if [[ -e bin/rails ]]; then
    bin/rails $rails_command $rails_options
  # Rails 3.x.x.
  elif [[ -e script/rails ]]; then
    script/rails $rails_command $rails_options
  # Unsupported version.
  else
    printf "ERROR: Unsupported Rails version.\n"
    return 1
  fi
}

# Label: Create Rails Skeleton
# Description: Create new Rails application skeleton.
# Parameters: $1 (required) - The application name, $2 (optional) - The build options to apply.
_create_rails_skeleton() {
  printf "rails new $1 $2\n"
  rails new $1 $2
}

# Label: Process Rew Option
# Description: Process option for constructing new Rails application skeletons with custom build settings.
# Parameters: $1 (required) - The application name, $2 (required) - The template to apply, $3 (optional) - The branch. Default: master.
_process_rew_option() {
  local branch="${3:-master}"
  local flags="--skip-bundle --database sqlite3 --skip-test-unit --force --skip-keeps --template"
  local rails_slim_options="$flags https://raw.github.com/bkuhlmann/rails_slim_template/$branch/template.rb"
  local rails_api_options="$flags https://raw.github.com/bkuhlmann/rails_api_template/$branch/template.rb"
  local rails_setup_options="$flags https://raw.github.com/bkuhlmann/rails_setup_template/$branch/template.rb"

  case $2 in
    "default")
      _create_rails_skeleton "$1"
      break;;
    "slim")
      _create_rails_skeleton "$1" "$rails_slim_options"
      break;;
    "api")
      _create_rails_skeleton "$1" "$rails_api_options"
      break;;
    "setup")
      _create_rails_skeleton "$1" "$rails_setup_options"
      break;;
    'q')
      break;;
    *)
      printf "ERROR: Invalid option.\n"
      break;;
  esac
}

#-------------------#
# Section: Dotfiles #
#-------------------#

# Label: Print Section
# Description: Print section.
# Parameters: $1 (required) - The string from which to parse the section from.
_print_section() {
  if [[ "$1" == "# Section:"* ]]; then
    local section=$(printf "$1" | sed 's/# Section://' | sed 's/^ *//g' | tr -d '#')
    printf "##### $section\n"
  fi
}

# Label: Print Alias
# Description: Print alias.
# Parameters: $1 (required) - The string from which to parse the alias from.
_print_alias() {
  echo "$1" | sed 's/alias //' | sed 's/="/ = "/' | sed "s/='/ = '/"
}

# Label: Print Aliases
# Description: Print aliases.
_print_aliases() {
  while read line; do
    _print_section "$line"

    if [[ "$line" == "alias"* ]]; then
      printf "    "
      _print_alias "$line"
    fi
  done < "$HOME/.bash/aliases.sh"
}

# Label: Print Function Name
# Description: Print function name.
# Parameters: $1 (required) - The string from which to parse the function name from.
_print_function_name() {
  local name=$(printf "$1" | sed 's/() {//')
  printf "$name = $2 - $3\n"
}

# Label: Set Function Label
# Description: Set function label.
# Parameters: $1 (required) - The string from which to parse the function label from.
_set_function_label() {
  if [[ "$1" == "# Label:"* ]]; then
    label=$(printf "$1" | sed 's/# Label://' | sed 's/^ *//g')
  fi
}

# Label: Set Function Description
# Description: Set function description.
_set_function_description() {
  if [[ "$line" == "# Description:"* ]]; then
    description=$(printf "$line" | sed 's/# Description://' | sed 's/^ *//g')
  fi
}

# Label: Print Functions
# Description: Print functions.
_print_functions() {
  local path="${1:-$HOME/.bash/functions-public.sh}"

  while read line; do
    _print_section "$line"
    _set_function_label "$line"
    _set_function_description "$line"

    if [[ "$line" == *"() {" && "$line" != "_"* ]]; then
      printf "    "
      _print_function_name "$line" "$label" "$description"
      unset label
      unset description
    fi
  done < "$path"
}

# Label: Print Git Hooks
# Description: Print Git hooks.
_print_git_hooks() {
  for file in $(find "$HOME/.git_template/hooks/extensions" -type l); do
    _print_functions "$file"
  done
}

# Label: Print All
# Description: Print aliases, functions, and Git hooks.
_print_all() {
  printf "#### Aliases\n\n"
  _print_aliases
  printf "\n#### Functions\n\n"
  _print_functions
  printf "\n#### Git Hooks\n\n"
  _print_git_hooks
}

# Label: Find Alias
# Description: Find and print matching alias.
# Parameters: $1 (required) - The alias to search for.
_find_alias() {
  while read line; do
    if [[ "$line" == "alias "*"$1"* ]]; then
      printf "    Alias: "
      _print_alias "$line"
    fi
  done < "$HOME/.bash/aliases.sh"
}

# Label: Find Function
# Description: Find and print matching function.
# Parameters: $1 (required) - The function to search for.
_find_function() {
  while read line; do
    _set_function_label "$line"
    _set_function_description "$line"

    if [[ "$line" == *"$1"*"()"* ]]; then
      printf "    Function: "
      _print_function_name "$line" "$label" "$description"
      unset label
      unset description
    fi
  done < "$HOME/.bash/functions-public.sh"
}

# Label: Find Command
# Description: Find and print matching alias or function.
# Parameters: $1 (required). The alias or function to search for.
_find_command() {
  if [[ "$1" ]]; then
    printf "\"$1\" Search Results:\n"

    _find_alias "$1"
    _find_function "$1"
  else
    printf "ERROR: Nothing to search for. Criteria must be supplied.\n"
  fi
}

# Label: Process Dotfiles Option
# Description: Process option for learning about dotfile aliases/functions.
# Parameters: $1 (optional) - The option selection, $2 (optional) - The option input.
_process_dots_option() {
  case $1 in
    'a')
      _print_aliases | more
      break;;
    'f')
      _print_functions | more
      break;;
    'g')
      _print_git_hooks | more
      break;;
    'p')
      _print_all | more
      break;;
    's')
      _find_command "$2" | more
      break;;
    'q')
      break;;
    *)
      printf "ERROR: Invalid option.\n"
      break;;
  esac
}
