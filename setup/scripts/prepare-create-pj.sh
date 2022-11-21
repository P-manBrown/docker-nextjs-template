set -e

if [ -e /.dockerenv ]; then
	printf '\e[31m%s\n\e[m' 'ERROR: This file must be run on the host.'
	exit 1
fi

sed -n 3p ./article.md | sed -e 's/（ //; s/）//' | pbcopy
if [ -z "$PROJECT_NAME" ]; then
	echo -n 'What is your project named? > '
	read PROJECT_NAME
fi

# Setting up Git/GitHub
set -u
echo 'Setting up Git/GitHub...'
GITHUB_USER_NAME="$(git config user.name)"
if [[ "$PROJECT_NAME" =~ 'frontend' ]]; then
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
	gh repo edit $GITHUB_USER_NAME/$PROJECT_NAME --delete-branch-on-merge
fi
## enable to commit inside a container without 'Dev Containers'
git config --local user.name "$GITHUB_USER_NAME"
git config --local user.email "$(git config user.email)"
# setting up 'commit message template'
git config --local commit.template ./.github/commit/gitmessage.txt

# Reflect project name
echo "Reflecting your project name($PROJECT_NAME)..."
grep -lr 'myapp-frontend' . | xargs sed -i "s/myapp-frontend/$PROJECT_NAME/g"

# Create secret file
echo 'Copying secret files...'
cd ./.devcontainer/secrets
cp ./github-token.txt.template ./github-token.txt
cd ../../
printf '\x1b[1m%s\e[m\n' \
	'Overwrite [.devcontainer/secrets/github-token.txt] with your GitHub PAT!'

rm -f ./setup/scripts/prepare-create-pj.sh

echo 'Done!!'
