source ~/.zshrc_custom
export GOROOT=/usr/lib/go
if [[ "$(uname)" == "Darwin" ]]; then
    export GOROOT=/usr/local/go
fi
export GOPATH=$HOME/go
export ZSH="$HOME/.oh-my-zsh"
export PATH="/opt/homebrew/bin:$PATH:$MAVEN_HOME/bin:$HOME/go/bin:$GOROOT/bin:$GOPATH/bin"
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
alias vi='nvim -u ~/.virc --noplugin'
alias yz='yazi'
alias vim="nvim"
alias runpsql=/Library/PostgreSQL/16/scripts/runpsql.sh
alias unzip="unzip -O gb18030"

alias gitcheckout="git checkout \$(git branch | fzf | awk '{ if (\$1 == \"*\") print \$2 ; else print \$1 }')"
alias gitco="git checkout \$(git branch | fzf | awk '{ if (\$1 == \"*\") print \$2 ; else print \$1 }')"
alias gitm="git merge \$(git branch | fzf | awk '{ if (\$1 == \"*\") print \$2 ; else print \$1 }')"
alias gitpush="git push origin \$(git branch | awk '{ if (\$1 == \"*\") print \$2 }')"
alias gitpull="git pull origin \$(git branch | awk '{ if (\$1 == \"*\") print \$2 }')"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
alias lower="tr A-Z a-z"
alias upper="tr a-z A-Z"
alias nohyphen="sed -e s/-//g"
alias jdc="java -jar ~/cfr-0.151.jar "
alias vimc="vimc(){java -jar ~/cfr-0.151.jar \$1| vim -c 'set ft=java'; unset -f vimc;}; vimc"
alias vic="vic(){java -jar ~/cfr-0.151.jar \$1| vi -c 'set ft=java'; unset -f vic;}; vic"
alias fj="touch mvnw"
alias vj="vj(){export JAVA=1; vim \$@; export JAVA=0;}; vj"

eval "$(zoxide init zsh)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
