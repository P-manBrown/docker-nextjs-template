#!/usr/bin/env bash
set -eu

echo 'Setting up Shell...'
cat <<-'EOF' | tee -a "${HOME}/.bashrc" >> "${HOME}/.zshrc"
	export HISTFILE="${HOME}/shell_log/.${SHELL##*/}_history"
	if [[ ${SHLVL} -eq 2 ]]; then
	  mkdir -p "${HOME}/shell_log/${SHELL##*/}"
	  create_date="$(date '+%Y%m%d%H%M%S')"
	  script -f "${HOME}/shell_log/${SHELL##*/}/${create_date}.log"
	fi
EOF
echo "export PROMPT_COMMAND='history -a && precmd'" >> "${HOME}/.bashrc"
git clone \
	https://github.com/zsh-users/zsh-autosuggestions \
	"${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
oh_my_plugins="(gh git yarn zsh-autosuggestions)"
sed -i "s/^plugins=(.*)/plugins=${oh_my_plugins}/" "${HOME}/.zshrc"
sudo chown -R "${USER}" "${HOME}/shell_log"

echo 'Setting up Git...'
git config --global core.editor 'code --wait'

echo 'Setting up GitHub CLI...'
gh config set editor 'code --wait'

echo 'Setting up Lefthook...'
yarn lefthook install
