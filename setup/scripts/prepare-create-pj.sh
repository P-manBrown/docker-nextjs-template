set -e

if [ -e /.dockerenv ]; then
	printf '\e[31m%s\n\e[m' 'ERROR: This file must be run on the host.'
	exit 1
fi

# Setting up GitHub
if [ -z "$TLP_PROJECT_NAME" ]; then
	echo -n 'What is your project named? > '
	read PROJECT_NAME
	export TLP_PROJECT_NAME=$PROJECT_NAME
fi
set -ux
GITHUB_USER_NAME="$(git config user.name)"
if [[ "$TPL_PROJECT_NAME" =~ 'frontend' ]]; then
	owner="$GITHUB_USER_NAME"
	repo="$TPL_PROJECT_NAME"
	repositoryId="$(\
		gh api graphql \
		-f query='{repository(owner:"'$owner'",name:"'$repo'"){id}}' \
		-q .data.repository.id \
	)"
	protected_branchs=(main, develop)
	for b in "${protected_branchs[@]}"
	do
		gh api graphql -f query='
		mutation($repositoryId:ID!,$branch:String!,$requiredReviews:Int!) {
			createBranchProtectionRule(input: {
				repositoryId: $repositoryId
				pattern: $branch
				requiresApprovingReviews: true
				requiredApprovingReviewCount: $requiredReviews
				isAdminEnforced: true
			}) { clientMutationId }
		}' -f repositoryId="$repositoryId" -f branch="$b" -F requiredReviews=1
	done
	gh repo edit $GITHUB_USER_NAME/$TPL_PROJECT_NAME --delete-branch-on-merge
fi
git config --local user.name "$GITHUB_USER_NAME"
git config --local user.email "$(git config user.email)"

# Overwite project name
TEMPLATES_DIR='./setup/templates'
export DOLLAR='$'
envsubst < $TEMPLATES_DIR/.env > ./.env
envsubst < $TEMPLATES_DIR/.yarnrc.yml > ./.yarnrc.yml
envsubst < $TEMPLATES_DIR/devcontainer.json > ./.devcontainer/devcontainer.json
envsubst < $TEMPLATES_DIR/package.json > ./package.json
rm -rf $TEMPLATES_DIR

# Create secret file
touch ./.devcontainer/secrets/github-token.txt

rm -f ./setup/scripts/prepare-create-pj.sh
