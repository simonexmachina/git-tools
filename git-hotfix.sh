#!/bin/bash

VERSION=$1
ACTION=$2
MESSAGE=$3

printUsage() {
	echo "Usage: $0 <version> <start|finish|both> [message]"
}

REALPATH=$(readlink $0)
DIR=`dirname $REALPATH`
source "$DIR/git-common.sh"

if [ -z "$VERSION" ]; then
	printUsage
	updateVersion
	exit 1
fi
if [ -z `echo $ACTION | egrep "^(start|finish|both)$"` ]; then
	echo "ERROR: Invalid action '$ACTION' specified"
	printUsage
	exit 1
fi

CHANGED_FILES=$(getChangedFiles)
CURRENT_BRANCH=$(getCurrentBranch)
ON_HOTFIX=`echo $CURRENT_BRANCH | grep '^hotfix/'`
PREVIOUS_VERSION_FILE=".$VERSION_FILE.prev"

if [ "$ACTION" = "start" -o "$ACTION" = "both" ]; then
	if [ "$ON_HOTFIX" ]; then
		echo "ERROR: Already on a hotfix branch '$ON_HOTFIX'. Maybe you want to run:"
		echo "  $0 finish $2 $3 '$4'"
		exit 1
	fi
	if [ -f $PREVIOUS_VERSION_FILE ]; then
		echo "ERROR: $PREVIOUS_VERSION_FILE already exists"
		exit 1;
	fi
	
	echo "### Updating to avoid conflicts"
	echo "### git stash && git co master && git pull"
	STASH_OUTPUT=`git stash`
	FAILED=$?
	if [ $FAILED -ne 0 ]; then
		exit $FAILED
	fi
	if [ "$STASH_OUTPUT" = "No local changes to save" ]; then
		STASHED=0
	else
		STASHED=1
	fi
	git pull && git co master && git pull \
		&& cp $VERSION_FILE $PREVIOUS_VERSION_FILE \
		&& echo "### git flow hotfix start $VERSION" \
		&& git flow hotfix start $VERSION
	if [ $? -ne 0 ]; then
		FAILED=1
	fi
	if [ $STASHED -eq 1 ]; then
		echo "### git stash pop" \
			&& git stash pop
		if [ $? -ne 0 ]; then
			FAILED=1
		fi
	fi
	if [ "$FAILED" -eq 1 ]; then
		exit 1
	fi
fi
if [ $ACTION = "finish" -o "$ACTION" = "both" ]; then
	if [ ! -f $PREVIOUS_VERSION_FILE ]; then
		echo "ERROR: $PREVIOUS_VERSION_FILE doesn't exist"
		exit 1;
	fi
	PREVIOUS_VERSION=`cat $PREVIOUS_VERSION_FILE`
	
	CURRENT_BRANCH=$(getCurrentBranch)
	ON_HOTFIX=`echo $CURRENT_BRANCH | grep '^hotfix/'`
	if [ -z "$ON_HOTFIX" ]; then
		echo "ERROR: Not on a hotfix branch. Maybe you want to run:"
		echo "  $0 $VERSION $ACTION '$MESSAGE'"
		echo "or:"
		echo "  git co hotfix/$VERSION"
		exit 1
	fi
	if [ -z "$VERSION" -o -z "$MESSAGE" ]; then
		echo "ERROR: Invalid usage"
		printUsage
		updateVersion
		exit
	fi
	echo "### git commit" \
		&& [ -z "$CHANGED_FILES" ] || git commit -m "$MESSAGE" -a \
		&& echo $VERSION > $VERSION_FILE \
		&& prependToFile $CHANGELOG_FILE "## Hotfix $VERSION\n\n$(getCommitMessagesSince $PREVIOUS_VERSION)\n" \
		&& rm $PREVIOUS_VERSION_FILE \
		&& git add $VERSION_FILE $CHANGELOG_FILE \
		&& git commit -m "Updated $VERSION_FILE and $CHANGELOG_FILE" $VERSION_FILE $CHANGELOG_FILE \
		&& echo "### git flow hotfix finish -mhotfix/$VERSION $VERSION" \
		&& git flow hotfix finish -mhotfix/$VERSION $VERSION \
		&& echo "### git push origin master --tags && git push origin develop" \
		&& git push origin master --tags && git push origin develop
fi
