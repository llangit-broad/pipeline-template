#!/usr/bin/env bash

set -eu

GIT_ROOT="$(git rev-parse --show-toplevel)"
VERSION_FILE="VERSION"

# CHECKING OUT LATEST VERSION OF DEVELOP
cd $GIT_ROOT
echo "Checking out develop"
git checkout develop
echo "Get latest develop branch"
git pull origin develop

# CHECKING IF PIPELINE IS READY FOR RELEASE
echo "Check if all submodules are tagged"
git submodule foreach --recursive \
bash -c 'if [ "$(git tag --contains)" == "" ] ; \
then echo "Untagged submodule found. Please make sure all submodules are released. Aborting release procedure." && exit 1 ;\
else echo "contains tag: $(git tag --contains)" ;\
fi'

# MERGING INTO MASTER
echo "Merge develop into master"
git checkout master
git pull origin master
git merge origin/develop

# Another check to see if after merging everything still is okay.
echo "Check if all submodules are tagged"
git submodule foreach --recursive \
bash -c 'if [ "$(git tag --contains)" == "" ] ; \
then echo "Untagged submodule found. Please make sure all submodules are released. Aborting release procedure." && exit 1 ;\
else echo "contains tag: $(git tag --contains)" ;\
fi'
# TODO: Add command that does a quick test of the pipeline.
# Womtool validate maybe?

# SET RELEASE VERSION
if [ -f $VERSION_FILE ]
then
    CURRENT_VERSION="$(cat $VERSION_FILE)"
    read -p "To be released version is $CURRENT_VERSION. Type a different version if required (Leave empty for no)" CURRENT_VERSION_OVERRIDE
    if [ "$CURRENT_VERSION_OVERRIDE" != "" ]
    then
        CURRENT_VERSION="$CURRENT_VERSION_OVERRIDE"
    fi
else
    read -p "No version file at location '$VERSION_FILE' was found. What version do you want to release?" CURRENT_VERSION
fi

echo "Version to be released = $CURRENT_VERSION"
RELEASE_TAG="v$CURRENT_VERSION"
echo "Tagging release: $RELEASE_TAG"
git tag -a $RELEASE_TAG

echo "Tagging successfull"
echo "push release to remote repository?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) git push origin master && git push origin $RELEASE_TAG; break;;
        No ) echo "release aborted" && exit 1;;
    esac
done

git checkout develop
git merge master
echo "Released version was: $CURRENT_VERSION"
read -p "What should be the next version? " NEXT_VERSION
echo "Setting next version to be: $NEXT_VERSION"
echo "$NEXT_VERSION" > $VERSION_FILE
git add $VERSION_FILE
git commit -m "setting next version"

echo "push develop with new version '$NEXT_VERSION' to remote repository?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) git push origin develop; break;;
        No ) echo "remote push aborted" && exit 1;;
    esac
done
echo "release procedure successful"


