set -e

if [ -e /.dockerenv ]; then
	printf '\e[31m%s\n\e[m' 'ERROR: This file must be run on the host.'
	exit 1
fi

if [ -z "$TPL_PROJECT_NAME" ]; then
	echo -n 'What is your project named? > '
	read PROJECT_NAME
	export TPL_PROJECT_NAME=$PROJECT_NAME
fi

# Setting up Git/GitHub
set -u
echo 'Setting up Git/GitHub...'
GITHUB_USER_NAME="$(git config user.name)"
if [[ "$TPL_PROJECT_NAME" =~ 'frontend' ]]; then
## checkout develop branch
	git checkout -b develop
## Protect main and develop branch
	owner="$GITHUB_USER_NAME"
	repo="$(basename -s .git `git remote get-url origin`)"
	repositoryId="$(
		gh api graphql \
		-f query='{repository(owner:"'$owner'",name:"'$repo'"){id}}' \
		-q .data.repository.id
	)"
	protected_branchs=(main develop)
	for b in "${protected_branchs[@]}"
	do
		gh api graphql -f query='
		mutation($repositoryId:ID!,$branch:String!,$requiredReviews:Int!) {
			createBranchProtectionRule(input: {
				repositoryId: $repositoryId
				pattern: $branch
				requiresApprovingReviews: true
				requiredApprovingReviewCount: $requiredReviews
				dismissesStaleReviews: true
				isAdminEnforced: true
			}) { clientMutationId }
		}' -f repositoryId="$repositoryId" -f branch="$b" -F requiredReviews=1
	done
## enable to automatically delete head branches
	gh repo edit $GITHUB_USER_NAME/$TPL_PROJECT_NAME --delete-branch-on-merge
fi
## enable to commit inside a container without 'Dev Containers'
git config --local user.name "$GITHUB_USER_NAME"
git config --local user.email "$(git config user.email)"

# Reflect project name
echo "Reflecting your project name(${TPL_PROJECT_NAME})..."
TEMPLATES_DIR='./setup/templates'
export DOLLAR='$'
envsubst < $TEMPLATES_DIR/.env > ./.env
envsubst < $TEMPLATES_DIR/.yarnrc.yml > ./.yarnrc.yml
envsubst < $TEMPLATES_DIR/devcontainer.json > ./.devcontainer/devcontainer.json
envsubst < $TEMPLATES_DIR/package.json > ./package.json
rm -rf $TEMPLATES_DIR

# Create secret file
echo 'Copying secret files...'
cd ./.devcontainer/secrets
cp ./github-token.txt.template ./github-token.txt
cd ../../
printf '\x1b[1m%s\e[m\n' \
	'Overwrite [.devcontainer/secrets/github-token.txt] with your GitHub PAT!'

rm -f ./setup/scripts/prepare-create-pj.sh

echo 'Done!!'
