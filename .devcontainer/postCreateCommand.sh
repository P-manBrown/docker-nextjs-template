#!/usr/bin/env bash
set -eu

echo 'Setting up Shell...'
cat <<-'EOF' | tee -a "${HOME}/.bashrc" >> "${HOME}/.zshrc"
	SHELL="$(readlink "/proc/$$/exe")"
	export HISTFILE="${HOME}/shell_log/.${SHELL##*/}_history"
	if [[ ${SHLVL} -eq 2 ]]; then
	  mkdir -p "${HOME}/shell_log/${SHELL##*/}"
	  create_date="$(date '+%Y%m%d%H%M%S')"
	  script -f "${HOME}/shell_log/${SHELL##*/}/${create_date}.log"
	fi
EOF
echo "export PROMPT_COMMAND='history -a'" >> "${HOME}/.bashrc"
git clone \
	https://github.com/zsh-users/zsh-autosuggestions \
	"${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
oh_my_plugins="(gh git yarn zsh-autosuggestions)"
sed -i "s/^plugins=(.*)/plugins=${oh_my_plugins}/" "${HOME}/.zshrc"
sudo chown -R "${USER}" "${HOME}/shell_log"

echo 'Setting up Git...'
set +e
repo_root="$(git rev-parse --show-toplevel)"
set -e
sudo git config --system --add safe.directory "${repo_root:-${PWD}}"
git config --local core.editor 'code --wait'

echo 'Setting up GitHub CLI...'
gh config set editor 'code --wait'
