#!/usr/bin/env bash
set -o xtrace

BUILD_DIR="./build/android"
rm -rf "$BUILD_DIR/"

./android-build.sh
./android-package.sh

ARTIFACT="mpg123-android-1.32.9-android-r1"

mvn deploy:deploy-file \
    -Durl="https://maven.pkg.github.com/jg-hot/libmpg123-android" \
    -DrepositoryId="gpr:libmpg123-android" \
    -Dfile="${BUILD_DIR}/$ARTIFACT.aar" \
    -DpomFile="./android/$ARTIFACT.pom" \
    -Dpackaging=aar \

# or if installing to maven local
# mvn install:install-file \
#     -Dfile="${BUILD_DIR}/$ARTIFACT.aar" \
#     -DpomFile="./android/$ARTIFACT.pom" \
#     -Dpackaging=aar \
