# BASH ALIASES

# Section: General
alias ..="cd .."
alias ...="cd ../.."
alias cdb="cd -"
alias c="clear"
alias h="history"
alias l="ls -alh"
alias l1="ls -A1 | _copy_and_print '\n'"
alias p='pwd | tr -d "\r\n" | _copy_and_print'
alias o="open"
alias cat='ccat -G Keyword="turquoise" -G Punctuation="green" -G Decimal="green" -G Type="blue" -G Literal="blue" -G String="lightgray" -G Plaintext="white"'
alias home="cd $HOME"
alias pss='ps axu | grep --invert-match grep | grep "$@" --ignore-case --color=auto'
alias man="gem man --system"

# Section: [Bash](https://www.gnu.org/software/bash)
alias bashe="$EDITOR $HOME/.bash/env.sh"
alias bashs="exec $SHELL"
alias bashv="bash --version"

# Section: Network
alias sshe="$EDITOR $HOME/.ssh/config"
alias key="open /Applications/Utilities/Keychain\ Access.app"
alias ipa='curl --silent checkip.dyndns.org | grep --extended-regexp --only-matching "[0-9\.]+" | _copy_and_print'
alias sniff="sudo ngrep -W byline -d 'en0' -t '^(GET|POST) ' 'tcp and port 80'"
alias dnsi="scutil --dns"
alias dnss="sudo dscacheutil -statistics"
alias dnsf="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder && printf 'DNS cache cleared.\n'"

# Section: [tmux](http://tmux.sourceforge.net)
alias tsl="tmux list-sessions"
alias tsa="tmux attach-session -t"
alias tsk="tmux kill-session -t"
alias tsr="tmux rename-session -t"

# Section: [Homebrew](http://brew.sh)
alias hb="brew"
alias hbi="brew install"
alias hbin="brew info"
alias hbu="brew uninstall"
alias hbl="brew list"
alias hbs="brew search"
alias hbsw="brew switch"
alias hbup="brew update --all"
alias hbug="brew upgrade --all"
alias hbp="brew pin"
alias hbpu="brew unpin"
alias hbd="brew doctor"
alias hbc="brew cleanup"
alias hbrb="brew uninstall ruby-build && brew install ruby-build"

# Section: [Git](http://git-scm.com)
alias gi="git init"
alias gcle="git config --local --edit"
alias gcge="git config --global --edit"
alias gget="git config"
alias gst="git status --short --branch"
alias gl='git log --graph --pretty=format:"$(_git_log_line_format)"'
alias gld='git log --stat --pretty=format:"$(_git_log_details_format)"'
alias glh='git log --pretty=format:%H -1 | _copy_and_print'
alias glf='git fetch && git log --reverse --no-merges --pretty=format:"$(_git_log_line_format)" ..@{upstream}'
alias glg='git log --pretty=format:"$(_git_log_line_format)" --grep'
alias gls='git log --pretty=format:"$(_git_log_line_format)" -S'
alias glt='git for-each-ref --sort=taggerdate --format="%(color:yellow)%(refname:short)%(color:reset)|%(taggerdate:short)|%(color:blue)%(color:bold)%(*authorname)%(color:reset)|%(subject)" refs/tags | column -s"|" -t'
alias grl="git reflog"
alias gg="git grep"
alias guthors="git log --format='%an' | sort | uniq -c | sort --reverse"
alias gd="git diff"
alias gdc="git diff --cached"
alias gdm="git diff origin/master"
alias gdw="git diff --color-words"
alias gdt="git difftool"
alias gdtc="git difftool --cached"
alias gdtm="git difftool origin/master"
alias glame="git blame"
alias gbi="git bisect"
alias gbis="git bisect start"
alias gbib="git bisect bad"
alias gbig="git bisect good"
alias gbir="git bisect reset"
alias gbisk="git bisect skip"
alias gbil="git bisect log"
alias gbire="git bisect replay"
alias gbiv='git bisect visualize --reverse --pretty=format:"$(_git_log_line_format)"'
alias gbih="git bisect help"
alias gb="git branch --verbose"
alias gbt="git show-branch --topics"
alias gba="git branch --all"
alias gbn="_git_branch_name | _copy_and_print"
alias gbr="git branch --move"
alias gm="git merge"
alias gms="git merge --squash"
alias gma="git merge --abort"
alias gcl="git clone"
alias gch="git checkout"
alias gchm="git checkout master"
alias ga="git add"
alias gau="git add --update"
alias gap="git add --patch"
alias gall="git add --all ."
alias gco="git commit"
alias gatch="git commit --patch"
alias gca="git commit --all"
alias gcm="git commit --message"
alias gcam="git commit --all --message"
alias gcf="git commit --fixup"
alias gcs="git commit --squash"
alias gamend="git commit --amend"
alias gamendh="git commit --all --amend --no-edit"
alias gcp="git cherry-pick"
alias gcpa="git cherry-pick --abort"
alias gashc="git stash clear"
alias gnl="git notes list"
alias gns="git notes show"
alias gna="git notes add"
alias gne="git notes edit"
alias gnd="git notes remove"
alias gnp="git notes prune"
alias gf="git fetch"
alias gfp="git fetch --prune"
alias gpu="git pull"
alias gpuo="git pull origin"
alias gpuom="git pull origin master"
alias grbc="git rebase --continue"
alias grbs="git rebase --skip"
alias grba="git rebase --abort"
alias ger="git rerere"
alias gp="git push"
alias gpf="git push --force-with-lease"
alias gpn="git push --no-verify"
alias gpo="git push --set-upstream origin"
alias gpr="git push review master"
alias gps="git push stage stage:master"
alias gpp="git push production production:master"
alias gtag="git tag"
alias gtagv="git tag --verify"
alias gtags="git push --tags"
alias gwp="git worktree prune"
alias gr="git reset" # Unstage staged files for commit.
alias grs="git reset --soft HEAD^" # Undo previous commit.
alias grh="git reset --hard HEAD" # Reset to HEAD, destroying all staged/unstaged changes. UNRECOVERABLE!
alias gdis="git reset --hard" # Reset to commit, destroying all previous commits. UNRECOVERABLE!
alias grm="git reset --merge ORIG_HEAD" # Reset to original HEAD prior to merge.
alias grom="git fetch --all && git reset --hard origin/master" # Reset local branch to origin/master branch. UNRECOVERABLE!
alias gel="git rm"
alias gelc="git rm --cached" # Removes previously tracked file from index after being added to gitignore.
alias grev="git revert" # Revert a commit.
alias grp="git remote prune origin"

# Section: [Tar](http://www.gnu.org/software/tar/tar.html)
alias bzc="tar --use-compress-program=pigz --create --preserve-permissions --bzip2 --verbose --file"
alias bzx="tar --extract --bzip2 --verbose --file"

# Section: [PostgreSQL](http://www.postgresql.org)
alias pgi="initdb /usr/local/var/postgres"
alias pgst="pg_ctl -D /usr/local/var/postgres -l /usr/local/var/postgres/server.log start &"
alias pgsp="pg_ctl -D /usr/local/var/postgres stop -s -m fast"

# Section: [Redis](http://redis.io)
alias reds="redis-server /usr/local/etc/redis.conf &"
alias redc="redis-cli"

# Section: [rbenv](https://github.com/rbenv/rbenv)
alias rb="rbenv"
alias rbg="rbenv global"
alias rbl="rbenv local"
alias rbs="rbenv shell"
alias rbh="rbenv rehash"
alias rbp="rbenv which"
alias rbw="rbenv whence"
alias rbv="rbenv versions"
alias rbi="rbenv install"
alias rbil="rbenv install --list"
alias rbu="rbenv uninstall"
alias rbvars="rbenv vars"

# Section: [Ruby](https://www.ruby-lang.org)
alias rd="rdoc -a -o tmp/doc/rdoc"
alias rdo="open tmp/doc/rdoc/index.html"
alias rdd="rm -rf tmp/doc/rdoc"

# Section: [Ruby Gems](https://rubygems.org)
alias geml="gem list"
alias gemi="gem install"
alias gemup="gem update"
alias gemu="gem uninstall"
alias gemc="gem cleanup"
alias gems="gem server"
alias gemp="gem pristine"
alias geme="gem environment"
alias gemuc="gem update --system && gem update && gem cleanup"

# Section: [Ruby Gems Whois](https://github.com/jnunemaker/gemwhois)
alias gemw="gem whois"

# Section: [Bundler](http://bundler.io)
alias b="bundle"
alias bl="bundle lock"
alias bi="bundle install"
alias bu="bundle update"
alias bo="bundle outdated"
alias bce="$EDITOR $HOME/.bundle/config"
alias bcon="bundle console"
alias be="bundle exec"
alias bch="rm -f Gemfile.lock; bundle check"

# Section: [Tocer](https://github.com/bkuhlmann/tocer)
alias tocg="tocer --generate"
alias toce="tocer --edit"
alias tocv="tocer --version"

# Section: [Milestoner](https://github.com/bkuhlmann/milestoner)
alias ms="milestoner"
alias msc='milestoner --commits | _copy_and_print "\n"'
alias mst="milestoner --tag"
alias msp="milestoner --publish"
alias mse="milestoner --edit"
alias msv="milestoner --version"

# Section: [Gemsmith](https://github.com/bkuhlmann/gemsmith)
alias gs="gemsmith"
alias gse="gemsmith --edit"
alias gsr="gemsmith --read"
alias gso="gemsmith --open"

# Section: [RSpec](http://rspec.info)
alias bess="bes spec"
alias besn="bess --next-failure"
alias besf="bess --only-failures"
alias besb="bess --seed 2112 --bisect"

# Section: [ByeBug](https://github.com/deivid-rodriguez/byebug)
alias bbr="bundle exec byebug --remote localhost:1048"

# Section: [Ruby on Rails](http://rubyonrails.org)
alias scs="sc --sandbox"
alias sgc="sg controller"
alias sgm="sg model"
alias sgh="sg helper"
alias sgs="sg scaffold"
alias dbd="ber db:drop"
alias dbc="ber db:create"
alias dbm="ber db:migrate"
alias dbmt="ber db:migrate && ber db:rollback && ber db:migrate"
alias assp="ber assets:precompile"
alias assc="ber assets:clean"
alias notest="ber notes:custom ANNOTATION=TODO"
alias notesf="ber notes:custom ANNOTATION=FIX"
alias taild="tail -f log/development.log"
alias tailt="tail -f log/test.log"
alias res="touch tmp/restart.txt"

# Section: [Ember](http://emberjs.com)
alias em="ember"
alias emg="ember generate"
alias ems="ember server"

# Section: [Jasmine](http://jasmine.github.io)
alias berj="ber jasmine"
alias berjci="ber jasmine:ci"

# Section: [Rubocop](https://github.com/bbatsov/rubocop)
alias cop="rubocop --display-cop-names"
alias copc="rubocop --auto-gen-config"
alias copo="rubocop --display-cop-names --only"
alias copf="rubocop --auto-correct"
alias cops="rubocop --show-cops"

# Section: [Rails Best Practices](https://github.com/railsbp/rails_best_practices)
alias rbest="rails_best_practices"

# Section: [Foreman](https://github.com/ddollar/foreman)
alias fms="foreman start"

# Section: [Capistrano](https://github.com/capistrano/capistrano)
alias caps="bec stage deploy"
alias capp="bec production deploy"

# Section: [Swift](https://developer.apple.com/swift)
alias swift="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift"

# Section: [Silver Surfer](https://github.com/ggreer/the_silver_searcher)
alias agf="ag --hidden --files-with-matches --file-search-regex"

# Section: [Z](https://github.com/rupa/z)
alias ez="$EDITOR $HOME/.z"

# Section: [Path Finder](http://www.cocoatech.com/pathfinder)
alias pfo='open -a "Path Finder.app" "$PWD"'

# Section: [Vim](http://www.vim.org)
alias v="vim"

# Section: [Sublime Text](http://www.sublimetext.com)
alias e="sublime"

# Section: [Marked 2](http://marked2app.com)
alias mo="open -a Marked\ 2"

# Section: [asciinema](https://asciinema.org)
alias cin="asciinema"
alias cinp="asciinema play"
alias cinu="asciinema upload"
alias cinv="asciinema --version"
