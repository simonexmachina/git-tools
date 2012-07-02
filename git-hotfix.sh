#!/bin/bash

HOTFIX=$1
ACTION=$2
VERSION=$3
MESSAGE=$4

printUsage() {
	echo "Usage: $0 <hotfix id> <start|finish> [new version] [message]"
}

REALPATH=$(readlink $0)
DIR=`dirname $REALPATH`
source "$DIR/git-common.sh"

if [ -z `echo $ACTION | egrep "^(start|finish)$"` ]; then
	echo "ERROR: Invalid action '$ACTION' specified"
	printUsage
	exit 1
fi
if [ -z "$HOTFIX" ]; then
	printUsage
	exit 1
fi

CHANGED_FILES=$(getChangedFiles)
CURRENT_BRANCH=$(getCurrentBranch)
ON_HOTFIX=`echo $CURRENT_BRANCH | grep '^hotfix/'`

if [ "$ACTION" = "start" ]; then
	if [ "$ON_HOTFIX" ]; then
		echo "ERROR: Already on a hotfix branch '$ON_HOTFIX'. Maybe you want to run:"
		echo "  $0 finish $2 $3 '$4'"
		exit 1
	fi
	echo "### Updating to avoid conflicts"
	echo "### git stash && git co develop && git pull && git co master && git pull"
	STASH_OUTPUT=`git stash`
	if [ "$STASH_OUTPUT" = "No local changes to save" ]; then
		STASHED=0
	else
		STASHED=1
	fi
	FAILED=0
	git pull && git co master && git pull \
		&& echo "### git flow hotfix start $HOTFIX" \
		&& git flow hotfix start $HOTFIX
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
elif [ $ACTION = "finish" ]; then
	if [ -z "$ON_HOTFIX" ]; then
		echo "ERROR: Not on a hotfix branch. Maybe you want to run:"
		echo "  $0 start $2 $3 '$4'"
		exit 1
	fi
	if [ -z "$VERSION" -o -z "$MESSAGE" ]; then
		printUsage
		updateVersion
		exit
	fi
	echo $VERSION > $VERSION_FILE \
		&& prependToFile $CHANGELOG_FILE "## $VERSION\n\n$MESSAGE\n" \
		&& echo "### git commit" \
		&& git add $VERSION_FILE $CHANGELOG_FILE \
		&& git commit -m "Hotfix $VERSION: $MESSAGE" $CHANGED_FILES $VERSION_FILE $CHANGELOG_FILE \
		&& echo "### git flow hotfix finish -mhotfix/$HOTFIX $HOTFIX" \
		&& git flow hotfix finish -mhotfix/$HOTFIX $HOTFIX \
		&& echo "### git push origin master --tags && git push origin develop" \
		&& git push origin master --tags && git push origin develop
fi