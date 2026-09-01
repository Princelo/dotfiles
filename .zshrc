source ~/.zshrc_custom
export GOROOT=/usr/lib/go
if [[ "$(uname)" == "Darwin" ]]; then
    export GOROOT=/usr/local/go
    export PATH="/opt/homebrew/opt/trash/bin:$PATH"
    alias posting="TERM_PROGRAM=Apple_Terminal posting"
fi
export GOPATH=$HOME/go
plugins=(
  git
  sudo
  history
  macos
  qrcode
)
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:/opt/homebrew/bin:$PATH:$M2_HOME/bin:$HOME/go/bin:$GOROOT/bin:$GOPATH/bin:$HOME/.cargo/bin"
export PATH="$PATH:$JAVA_HOME/bin"
ZSH_THEME="playstation"
source $ZSH/oh-my-zsh.sh
export LANG=en_US.UTF-8
export HISTSIZE=100000
export SAVEHIST=100000
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY
alias vf='vim $(fzf)'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export LANGUAGE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export EDITOR='nvim'
alias proxy="export https_proxy=http://127.0.0.1:$PROXY_PORT;export http_proxy=http://127.0.0.1:$PROXY_PORT;export all_proxy=socks5://127.0.0.1:$PROXY_PORT"
alias unproxy='unset https_proxy;unset http_proxy;unset all_proxy'
alias ts="python3 $HOME/Tools/ts.py"
alias urlenc="python3 $HOME/Tools/urlenc.py"
alias urldec="python3 $HOME/Tools/urldec.py"
alias vi='nvim -u ~/.vimrc --noplugin'
alias yz='yazi'
alias vim="nvim"
alias runpsql=/Library/PostgreSQL/16/scripts/runpsql.sh
alias unzip="unzip -O gb18030"
alias latin="nvim \"+e ++enc=cp1252\""
alias gbk="nvim \"+e ++enc=cp936\""
alias big5="nvim \"+e ++enc=big5\""
alias utf8="nvim \"+e ++enc=utf8\""

alias gitcheckout="git checkout \$(git branch | fzf | awk '{ if (\$1 == \"*\") print \$2 ; else print \$1 }')"
alias gitco="git checkout \$(git branch | fzf | awk '{ if (\$1 == \"*\") print \$2 ; else print \$1 }')"
alias gitm="git merge \$(git branch | fzf | awk '{ if (\$1 == \"*\") print \$2 ; else print \$1 }')"
alias gitpush="git push origin \$(git branch | awk '{ if (\$1 == \"*\") print \$2 }')"
alias gitpull="git pull origin \$(git branch | awk '{ if (\$1 == \"*\") print \$2 }')"
if [[ "$(uname)" == "Darwin" ]]; then
    alias copygiturl="git remote -v | grep push | awk '{print \$2}' | pbcopy"
fi
alias giturl="git remote -v | grep push | awk '{print \$2}'"
alias 1st="awk '{print \$1}'"
alias 2nd="awk '{print \$2}'"
alias 3rd="awk '{print \$3}'"
alias 4th="awk '{print \$4}'"
alias 5th="awk '{print \$5}'"
alias 6th="awk '{print \$6}'"
alias 7th="awk '{print \$7}'"
alias 8th="awk '{print \$8}'"
alias 9th="awk '{print \$9}'"
alias git-set-identity='export GIT_AUTHOR_NAME="Princelo";export GIT_AUTHOR_EMAIL="lamkimcheung@gmail.com";export GIT_COMMITTER_NAME="Princelo";export GIT_COMMITTER_EMAIL="lamkimcheung@gmail.com"'
alias git-clear-identity='unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL'

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}
alias lower="tr A-Z a-z"
alias upper="tr a-z A-Z"
alias nohyphen="sed -e s/-//g"
alias jdc="java -jar ~/cfr-0.151.jar "
alias vimc="vimc(){java -jar ~/cfr-0.151.jar \$1| vim -c 'set ft=java'; unset -f vimc;}; vimc"
alias vic="vic(){java -jar ~/cfr-0.151.jar \$1| vi -c 'set ft=java'; unset -f vic;}; vic"
alias fj="touch mvnw"
alias vj="vj(){export JAVA=1; vim \$@; export JAVA=0;}; vj"
alias mvnnew="mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.5 -DinteractiveMode=false"
alias rm='printf "\033[1;31m⚠️ rm is disabled for safety; use /bin/rm if you really mean it\033[0m\n"'

eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

mjson() {
    jq < "$1" | micro
}
hjson() {
    jq < "$1" | hx
}
json() {
    jq < "$1" | nvim -c 'set ft=json' -c 'Light' -c 'set nornu'
}

