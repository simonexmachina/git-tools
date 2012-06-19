#!/bin/bash

VERSION=$1
MESSAGE=$2

REALPATH=$(readlink $0)
DIR=`dirname $REALPATH`
source "$DIR/git-common.sh"

CHANGED_FILES=$(getChangedFiles)
if [ -z "$CHANGED_FILES" ]; then
	echo "You have no uncommitted changes"
	exit 1
fi

echo "git stash && git pull && git co master && git pull && git co $CURRENT_BRANCH" \
	&& STASH_OUTPUT=`git stash`
if [ "$STASH_OUTPUT" = "No local changes to save" ]; then
	STASHED=0
else
	STASHED=1
fi
FAILED=0
git pull && git co master && git pull && git co $CURRENT_BRANCH \
	&& echo "git flow hotfix start $VERSION" \
	&& git flow hotfix start $VERSION
if [ $? -ne 0 ]; then
	FAILED=1
fi
if [ $STASHED -eq 1 ]; then
	echo "git stash pop" \
		&& git stash pop
	if [ $? -ne 0 ]; then
		FAILED=1
	fi
fi
if [ "$FAILED" -eq 1 ]; then
	exit 1
else
	echo $VERSION > $VERSION_FILE \
		&& prependToFile $CHANGELOG_FILE "## $VERSION\n\n$MESSAGE\n" \
		&& echo "git commit" \
		&& git add $VERSION_FILE $CHANGELOG_FILE \
		&& git commit -m "$VERSION: $MESSAGE" $CHANGED_FILES $VERSION_FILE $CHANGELOG_FILE \
		&& echo "git flow hotfix finish -mhotfix/$VERSION $VERSION" \
		&& git flow hotfix finish -mhotfix/$VERSION $VERSION \
		&& echo "git push --all && git push --tags" \
		&& git push --all && git push --tags
fi
