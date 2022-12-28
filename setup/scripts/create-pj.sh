#!/usr/bin/env bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ ! -e /.dockerenv ]]; then
	err 'This file must be run inside the container.'
	exit 1
fi

if ! ps -p "$$" | grep -q 'bash'; then
	err 'This file must be run with Bash.'
	exit 1
fi

PROJECT_NAME="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -f 2 -d '=')"
PACKAGE_MANAGER="$(grep '"packageManager"' ./package.json)"

# update Yarn to the latest version
echo 'Updating Yarn to the latest version...'
yarn set version stable

# create project
echo 'Creating your project...'
yarn create next-app "${PROJECT_NAME}" --typescript --no-eslint
mv -f "./${PROJECT_NAME}"/{*,.[^\.]*} ./
rmdir "./${PROJECT_NAME}"

# adding file contents to the index
echo 'Adding file contents to the index...'
repo_root="$(git rev-parse --show-toplevel)"
git config --global --add safe.directory "${repo_root}"
git add .

# install packages
echo 'Installing packages...'
## Yarn
yarn dlx @yarnpkg/sdks vscode
yarn plugin import typescript
## commitlint
yarn add --dev @commitlint/cli @commitlint/config-conventional
## ESLint
yarn add --dev --exact eslint eslint-config-next
yarn add --dev eslint-config-prettier eslint-plugin-unused-imports
## Jest
yarn add --dev jest jest-environment-jsdom ts-jest
## Lefthook
yarn add --dev @evilmartians/lefthook
yarn lefthook install
## markdownlint-cli
yarn add --dev markdownlint-cli
## Prettier
yarn add --dev --exact prettier
yarn add --dev prettier-plugin-tailwindcss
## Storybook
yes 'n' | yarn dlx storybook init
yarn add --dev webpack require-from-string
## Tailwind CSS
yarn add --dev tailwindcss postcss autoprefixer
yarn dlx tailwindcss init -p
## Testing Library
yarn add --dev @testing-library/react @testing-library/jest-dom

# setting up project
echo 'Setting up your project...'
## setting up Lefthook
yarn lefthook install
post_create_command='.devcontainer/postCreateCommand.sh'
set +u
if [[ "${REMOTE_CONTAINERS}" == 'true' ]]; then
	echo '' >> "${post_create_command}"
	cat <<-EOF >> "${post_create_command}"
		echo 'Setting up Lefthook...'
		yarn lefthook install
	EOF
fi
set -u
## create ./src
mkdir ./src
mv ./{pages,styles} ./src
## mv setting files
CONFIG_DIR='./setup/config'
mv -f "${CONFIG_DIR}/globals.css" ./src/styles/globals.css
mv -f "${CONFIG_DIR}/tsconfig.json" ./tsconfig.json
sed -i -e "/.pnp/d; /# dependencies/r ${CONFIG_DIR}/.gitignore" ./.gitignore
while read -r npm_script; do
	npm_script_name="$(echo "${npm_script}" | cut -d ':' -f 1)"
	if grep -q "${npm_script_name}" ./package.json; then
		sed -i "/${npm_script_name}/c \    ${npm_script}" ./package.json
	else
		sed -i "/\"lint\"/a \    ${npm_script}" ./package.json
	fi
done < <(tac "${CONFIG_DIR}/npm-scripts.txt")
sed -i -e "s/  }$/  },/" -e "/^}$/i \\${PACKAGE_MANAGER}" ./package.json
printf '\x1b[1m%s\e[m\n' 'Check the contents of .gitignore and package.json'
if [[ "${PROJECT_NAME}" == *'frontend'* ]]; then
	sed -i 's/main/develop/' ./.github/dependabot.yml
else
	sed -i '/protect-branch:$/,/fail_text:.*branch\."$/d' ./lefthook.yml
fi
## delete settings added in extensions.json
added_vscode_extensions="$(
	git diff -U0 ./.vscode/extensions.json \
		| grep '^+' \
		| grep -Ev '^\+\+\+ b/' \
		| tail -n +2 \
		| sed 's/^+//'
)"
git restore --worktree ./.vscode/extensions.json
cat <<-EOF
	The following descriptions have been removed from .vscode/extensions.json
	${added_vscode_extensions}
EOF
## delete settings added in settings.json
added_vscode_settings="$(
	git diff -U0 ./.vscode/settings.json \
		| grep '^+' \
		| grep -Ev '^\+\+\+ b/' \
		| tail -n +2 \
		| sed 's/^+//'
)"
git restore --worktree ./.vscode/settings.json
cat <<-EOF
	The following descriptions have been removed from ./.vscode/settings.json
	${added_vscode_settings}
EOF

rm -rf "${CONFIG_DIR}"

rm ./setup/scripts/create-pj.sh

echo 'Done!!'
