set -eu

if [ ! -e /.dockerenv ]; then
	printf '\e[31m%s\n\e[m' 'ERROR: This file must be run inside the container.'
	exit 1
fi

# create project
echo 'Creating your project...'
PROJECT_NAME=$(cat ./.env | grep 'COMPOSE_PROJECT_NAME' | cut -f 2 -d '=')
yarn create next-app $PROJECT_NAME --typescript --no-eslint
rm -rf ./$PROJECT_NAME/.git
mv -f ./$PROJECT_NAME/* ./$PROJECT_NAME/.[^\.]* ./
rmdir ./$PROJECT_NAME

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
SETTINGS_DIR='./setup/settings'
mv -f $SETTINGS_DIR/settings.json ./.vscode/settings.json
mv -f $SETTINGS_DIR/globals.css ./src/styles/globals.css
mv -f $SETTINGS_DIR/tsconfig.json ./tsconfig.json
cat $SETTINGS_DIR/.gitignore >> ./.gitignore
code ./.gitignore
cat $SETTINGS_DIR/package.json >> ./package.json
code ./package.json
if [[ "$PROJECT_NAME" =~ 'frontend' ]]; then
	mv -f $SETTINGS_DIR/lefthook-project.yml ./lefthook.yml
	mv -f $SETTINGS_DIR/dependabot.yml ./.github/dependabot.yml
fi
rm -rf $SETTINGS_DIR
rm -f ./.eslintrc.json
# add ignorepaths
cat <<-EOF >> ./.git/info/exclude
	/.vscode/setting.json
	/html_from_md
	.DS_Store
EOF

echo 'Done!!'

rm -rf ./setup
