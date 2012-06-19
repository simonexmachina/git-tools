#!/bin/bash

VERSION=$1
MESSAGE=$2

REALPATH=$(readlink $0)
DIR=`dirname $REALPATH`
source "$DIR/git-common.sh"

CHANGED_FILES=$(getChangedFiles)
if [ "$CHANGED_FILES" ]; then
	echo "ERROR: You have uncommitted changes - please commit first"
	exit 1
fi

echo "git pull && git co master && git pull && git co $CURRENT_BRANCH" \
	&& git pull && git co master && git pull && git co $CURRENT_BRANCH \
	&& echo "git flow release start $VERSION" \
	&& git flow release start $VERSION \
	&& echo $VERSION > $VERSION_FILE \
	&& prependToFile $CHANGELOG_FILE "## $VERSION\n\n$MESSAGE\n" \
	&& echo "git commit -a" \
	&& git commit -m "$VERSION: $MESSAGE" -a \
	&& echo "git flow release finish -mrelease/$VERSION $VERSION" \
	&& git flow release finish -mrelease/$VERSION $VERSION \
	&& echo "git push --all && git push --tags" \
	&& git push --all && git push --tags
