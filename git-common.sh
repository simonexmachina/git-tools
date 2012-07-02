#!/bin/bash

export CHANGELOG_FILE="CHANGELOG.md"
export VERSION_FILE="VERSION"
CHANGE_FILE="._changed-files.txt"

prependToFile() {
	echo -e $2 | cat - $1 > .git-hotfix-tmp
	mv .git-hotfix-tmp $1
}
getChangedFiles() {
	(git diff --name-only --diff-filter=ACDMRTUX > $CHANGE_FILE \
		&& git diff --cached --name-only --diff-filter=ACDMRTUX >> $CHANGE_FILE) \
		|| exit $?
	CHANGED_FILES=`cat $CHANGE_FILE`
	rm $CHANGE_FILE
	echo $CHANGED_FILES
}
getCurrentBranch() {
	git branch | sed -n -e 's/^\* \(.*\)/\1/p'
}
updateVersion() {
	echo "### Current VERSION file has version `cat VERSION`"
	echo "### Calling git pull to update VERSION..."
	CURRENT_BRANCH=`getCurrentBranch`
	git co master && git pull
	echo "### Current version: `cat $VERSION_FILE`"
	git co $CURRENT_BRANCH
}

if [ "$1" = "-h" ]; then
	printUsage
	exit
fi
if [ -f $CHANGE_FILE ]; then
	echo "ERROR: $CHANGE_FILE exists"
	exit 1
fi
if [ ! -f $CHANGELOG_FILE -o ! -f $VERSION_FILE ]; then
	echo "ERROR: $VERSION_FILE and $CHANGELOG_FILE must exist"
	exit 1
fi