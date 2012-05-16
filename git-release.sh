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
	echo -e $2 | cat - $1 > .git-release-tmp
	mv .git-release-tmp $1
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
elif [ "$CHANGED_FILES" ]; then
	echo "You have uncommitted changes - please commit first"
	exit 1
fi

CURRENT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
echo "git pull && git co master && git pull && git co $CURRENT_BRANCH" \
	&& git pull && git co master && git pull && git co $CURRENT_BRANCH \
	&& echo "git flow release start $VERSION" \
	&& git flow release start $VERSION \
	&& echo $VERSION > $VERSION_FILE \
	&& prependToFile $CHANGELOG_FILE "# Release $VERSION\n\n$MESSAGE\n" \
	&& echo "git commit -a" \
	&& git commit -m "Release $VERSION: $MESSAGE" -a \
	&& echo "git flow release finish -mrelease/$VERSION $VERSION" \
	&& git flow release finish -mrelease/$VERSION $VERSION \
	&& echo "git push --all && git push --tags" \
	&& git push --all && git push --tags
