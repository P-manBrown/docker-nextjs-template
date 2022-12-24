#!/bin/bash
set -eu

err() {
	printf '\e[31m%s\n\e[m' "ERROR: $*" >&2
}

if [[ ! -e /.dockerenv ]]; then
	err 'This file must be run inside the container.'
	exit 1
fi

PROJECT_NAME="$(grep 'COMPOSE_PROJECT_NAME' ./.env | cut -f 2 -d '=')"
PACKAGE_MANAGER="$(grep '"packageManager"' ./package.json)"

# create project
echo 'Creating your project...'
yarn create next-app "${PROJECT_NAME}" --typescript --no-eslint
mv -f "./${PROJECT_NAME}"/{*,.[^\.]*} ./
rmdir "./${PROJECT_NAME}"

# adding file contents to the index
echo 'Adding file contents to the index...'
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
rm -rf "${CONFIG_DIR}"

rm ./setup/scripts/create-pj.sh

echo 'Done!!'
