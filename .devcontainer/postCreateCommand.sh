set -eu

echo 'Setting up Bash...'
cat <<-'EOF' >> $HOME/.bashrc
	if [ "$SHLVL" = 2 ]; then
	  script --flush ~/bashlog/script/`date "+%Y%m%d%H%M%S"`.log
	fi
	export PROMPT_COMMAND='history -a'
	export HISTFILE=~/bashlog/.bash_history
EOF
sudo chown -R $(whoami) $HOME/bashlog
mkdir -p $HOME/bashlog/script
touch $HOME/bashlog/.bash_history

echo 'Setting up GitHub CLI...'
gh auth login --with-token < ./.devcontainer/secrets/github-token.txt
gh config set editor 'code -w'

copy_and_ignore() {
	source_file="$1"
	target_dir="$2"
	file_name=$(basename "$source_file")
	ignore_path=$(
		echo "$target_dir/$file_name" \
		| sed -e "s:^./:/:; /^[^/]/s:^:/:; /\/\//s:^//:/:"
	)
	if ! grep -qx "$ignore_path" ./.git/info/exclude; then
		echo "$ignore_path" >> ./.git/info/exclude
	fi
	cp --update "$source_file" "$target_dir"
}

echo 'Setting up VSCode...'
copy_and_ignore ./.devcontainer/vscode/launch.json ./.vscode

echo 'Setting up Lefthook...'
copy_and_ignore ./.devcontainer/lefthook/lefthook-local.yml ./
yarn lefthook install
