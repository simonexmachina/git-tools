#!/bin/bash

VERSION=$1
MESSAGE=$2

CHANGELOG_FILE="CHANGELOG.md"
VERSION_FILE="VERSION"

if [ ! -f $CHANGELOG_FILE -o ! -f $VERSION_FILE ]; then
	echo "Aborting: $VERSION_FILE and $CHANGELOG_FILE must exist"
	exit 1
fi

if [ -z "$VERSION" -o -z "$MESSAGE" ]; then
	echo "Usage: $0 <new version> <message>"
	echo "Current version: `cat $VERSION_FILE`"
	exit
fi

prependToFile() {
	echo -e $2 | cat - $1 > .git-hotfix-tmp
	mv .git-hotfix-tmp $1
}

FILE="._changed-files.txt"
if [ -f $FILE ]; then
	echo "Aborting: $FILE exists"
	exit 1
fi

git ls-files -md > $FILE
git diff --name-only --diff-filter=A HEAD >> $FILE
CHANGED_FILES=`cat $FILE`
rm $FILE

if [ $? -ne 0 ]; then
	exit $?
elif [ -z "$CHANGED_FILES" ]; then
	echo "You have no uncommitted changes"
	exit 1
fi

CURRENT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
echo "git stash && git pull && git co master && git pull && git co $CURRENT_BRANCH" \
	&& STASH_OUTPUT=`git stash`
if [ "$STASH_OUTPUT" = "No local changes to save" ]; then
	NO_STASH=1
else
	NO_STASH=0
fi
git pull && git co master && git pull && git co $CURRENT_BRANCH \
	&& echo "git flow hotfix start $VERSION" \
	&& git flow hotfix start $VERSION
if [ $? -ne 0 ]; then
	FAILED=1
fi
if [ $NO_STASH -ne 1 ]; then
	echo "git stash pop" \
		&& git stash pop
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi
if [ $FAILED -eq 1 ]; then
	exit 1
else
	echo $VERSION > $VERSION_FILE \
		&& prependToFile $CHANGELOG_FILE "# Hotfix $VERSION\n\n$MESSAGE\n" \
		&& echo "git commit" \
		&& git add $VERSION_FILE $CHANGELOG_FILE \
		&& git commit -m "Hotfix $VERSION: $MESSAGE" $CHANGED_FILES $VERSION_FILE $CHANGELOG_FILE \
		&& echo "git flow hotfix finish -mhotfix/$VERSION $VERSION" \
		&& git flow hotfix finish -mhotfix/$VERSION $VERSION \
		&& echo "git push --all && git push --tags" \
		&& git push --all && git push --tags
fi