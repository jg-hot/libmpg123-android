#!/usr/bin/env bash
set -o xtrace

BUILD_DIR="./build/android"
rm -rf "$BUILD_DIR/"

./android-build.sh
./android-package.sh

ARTIFACT="mpg123-1.32.9-android-r1"

mvn install:install-file \
    -Dfile="${BUILD_DIR}/$ARTIFACT.aar" \
    -DpomFile="./android/$ARTIFACT.pom" \
    -Dpackaging=aar \
