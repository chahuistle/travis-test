#!/usr/bin/env bash

# rules of our build:
# 1. Only events (push, pull-request, tag) coming from either the master or development branches will trigger a build. 
# 2. When a build is triggered, Travis will run unit and integration tests. 
# 3. Travis will validate version as follows:
#    3.1 If a build has been triggered from the master branch, it will fail if the artifact has not been identified with a valid release version.
#    3.2 Similarly, if a build has been triggered from the development branch, Travis will enforce that the artifact has been identified with a valid snapshot version.
# 4. Travis will automatically upload artifacts to our maven repositories using the following rules:
#    4.1 Release artifacts will be uploaded after after a "tag" event on the master branch triggers a successful build.
#    4.2 Snapshot artifacts will be uploaded after a "push" event on the development branch triggers a successful build.
# 5. Travis will automatically install portlet artifacts from the development branch on our test instance.

export MASTER_BRANCH="master"
export DEVELOPMENT_BRANCH="development"

if [ -z "$1" ]; then
    export POM_FILE="pom.xml"
else
    export POM_FILE=$1
fi

# 2) build whatever it is, no questions asked
echo "[INFO] installing in local repository (compile, test, verify (integration tests), install)"
mvn --activate-profiles !development-build,!release-build --settings .travis.settings.xml --file $POM_FILE clean cobertura:cobertura install

# 3), 4) version validation, upload to maven
if [ ! -z "$TRAVIS_TAG" ] && [ "$TRAVIS_BRANCH" = "$MASTER_BRANCH" ]; then
    echo "[INFO] Validating version is properly formatted as a release"
    mvn --activate-profiles !development-build,release-build --settings .travis.settings.xml --file $POM_FILE deploy
elif [ "$TRAVIS_EVENT_TYPE" = "push" ] && [ "$TRAVIS_BRANCH" = "$DEVELOPMENT_BRANCH" ]; then
    echo "[INFO] Validating version is properly formatted as a SNAPSHOT"
    mvn --activate-profiles development-build,!release-build --settings .travis.settings.xml --file $POM_FILE deploy
    # 5) deploy
    rsync --verbose -e "ssh -o StrictHostKeyChecking=no" target/*.war $TESTING_USERNAME@$TESTING_SERVER:~/liferay*/deploy
fi