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

# update Yarn to the latest version
echo 'Updating Yarn to the latest version...'
yarn set version stable

CONFIG_DIR='./setup/config'
PACKAGE_MANAGER="$(grep '"packageManager"' ./package.json)"

# create project
echo 'Creating your project...'
project_name="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -f 2 -d '=')"
yarn create next-app "${project_name}" \
	--typescript \
	--no-eslint \
	--no-tailwind \
	--app \
	--src-dir \
	--import-alias '@/*'
mv -f "./${project_name}"/{*,.[^\.]*} ./
rmdir "./${project_name}"

# adding file contents to the index
echo 'Adding file contents to the index...'
repo_root="$(git rev-parse --show-toplevel)"
git config --global --add safe.directory "${repo_root}"
git add .

# install packages
echo 'Installing packages...'
## Yarn plugin
yarn plugin import typescript
## commitlint
yarn add --dev @commitlint/cli @commitlint/config-conventional
## ESLint
yarn add --dev --exact eslint eslint-config-next
yarn add --dev \
	eslint-config-prettier \
	eslint-plugin-jest \
	eslint-plugin-storybook \
	eslint-plugin-unused-imports
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
## Yarn SDKs (must be run AFTER the package is installed)
yarn dlx @yarnpkg/sdks vscode

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
## mv setting files
mv -f "${CONFIG_DIR}/globals.css" ./src/styles/globals.css
mv -f "${CONFIG_DIR}/tailwind.config.js" ./tailwind.config.js
cp -f ./.gitignore /tmp/.gitignore
sed -i -e "/.pnp/d; /# dependencies/r ${CONFIG_DIR}/.gitignore" /tmp/.gitignore
cp -f /tmp/.gitignore ./.gitignore
cp -f ./package.json /tmp/package.json
while read -r npm_script; do
	npm_script_name="$(echo "${npm_script}" | cut -d ':' -f 1)"
	if grep -q "${npm_script_name}" ./package.json; then
		sed -i "/${npm_script_name}/c \    ${npm_script}" /tmp/package.json
	else
		sed -i "/\"lint\"/a \    ${npm_script}" /tmp/package.json
	fi
done < <(tac "${CONFIG_DIR}/npm-scripts")
sed -i -e "s/  }$/  },/" -e "/^}$/i \\${PACKAGE_MANAGER}" /tmp/package.json
cp -f /tmp/package.json ./package.json
printf '\x1b[1m%s\e[m\n' 'Check the contents of .gitignore and package.json'

## remove settings added in extensions.json
removed_vscode_extensions="$(
	git diff -U0 ./.vscode/extensions.json \
		| grep '^+' \
		| grep -Ev '^\+\+\+ b/' \
		| tail -n +2 \
		| sed 's/^+//'
)"
git restore --worktree ./.vscode/extensions.json
cat <<-EOF
	The following descriptions have been removed from ./.vscode/extensions.json
	${removed_vscode_extensions}
EOF

rm -rf "${CONFIG_DIR}"

rm ./setup/scripts/create-pj.sh

echo 'Done!!'
