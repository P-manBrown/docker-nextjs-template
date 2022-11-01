set -eux

# setup GitHub CLI
gh auth login --with-token < ./.devcontainer/secrets/github-token.txt

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

# setup VSCode
copy_and_ignore ./.devcontainer/vscode/launch.json ./.vscode

# setup Lefthook
copy_and_ignore ./.devcontainer/lefthook/lefthook-local.yml ./
yarn lefthook install
