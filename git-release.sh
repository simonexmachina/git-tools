#!/bin/bash

VERSION=$1
MESSAGE=$2

printUsage() {
	echo "Usage: $0 <new version> <message>"
}

REALPATH=$(readlink $0)
DIR=`dirname $REALPATH`
source "$DIR/git-common.sh"

if [ -z "$VERSION" -o -z "$MESSAGE" ]; then
	printUsage
	updateVersion
	exit
fi

CHANGED_FILES=$(getChangedFiles)
if [ "$CHANGED_FILES" ]; then
	echo "ERROR: You have uncommitted changes - please commit first"
	exit 1
fi

echo "### git co develop && git pull && git co master && git pull && git co develop" \
	&& git co develop && git pull && git co master && git pull && git co develop \
	&& echo "### git flow release start $VERSION" \
	&& git flow release start $VERSION \
	&& echo $VERSION > $VERSION_FILE \
	&& prependToFile $CHANGELOG_FILE "# Release $VERSION\n\n$MESSAGE\n" \
	&& echo "### git commit -a" \
	&& git commit -m "Release $VERSION: $MESSAGE" -a \
	&& echo "### git flow release finish -mrelease/$VERSION $VERSION" \
	&& git flow release finish -mrelease/$VERSION $VERSION \
	&& echo "### git push origin master --tags && git push origin develop" \
	&& git push origin master --tags && git push origin develop
