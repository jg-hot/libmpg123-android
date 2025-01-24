#!/usr/bin/env bash
LIB_NAME="libmpg123"
ABIS=("armeabi-v7a" "arm64-v8a" "x86" "x86_64")

BUILD_DIR="./build/android"

rm -r "$BUILD_DIR/aar/prefab/"
mkdir -vp "$BUILD_DIR/aar/prefab/"

# copy metadata files
cp -vrt "$BUILD_DIR/aar/prefab/" android/prefab-template/*

# make prefab package
pushd "$BUILD_DIR"
    # copy headers
    mkdir -vp "aar/prefab/modules/$LIB_NAME/include/"
    cp -vt "aar/prefab/modules/$LIB_NAME/include/" \
        include/mpg123.h \
        include/fmt123.h

    # copy libraries
    for ABI in ${ABIS[@]}; do
        cp -vt "aar/prefab/modules/$LIB_NAME/libs/android.$ABI/" "$ABI/lib/libmpg123.so"
    done

    # verify prefab package
    for ABI in ${ABIS[@]}; do
        (set -x; prefab \
            --build-system cmake \
            --platform android \
            --os-version 21 \
            --ndk-version 27 \
            --stl none \
            --abi ${ABI} \
            --output "$(pwd)/tmp/prefab-verification" \
            "$(pwd)/aar/prefab")

        RESULT=$?; if [[ $RESULT == 0 ]]; then
            echo "$ABI: prefab package verified"
        else
            echo "$ABI: package package verification failed"
            exit 1
        fi

        rm -r tmp/
    done
popd

AAR_NAME="mpg123-android-1.32.9-android-r1.aar"
rm -f "$BUILD_DIR/$AAR_NAME"

# zip prefab/ and AndroidManifest.xml into an .aar
cp -vt "$BUILD_DIR/aar/" android/AndroidManifest.xml

pushd "$BUILD_DIR/aar"
    zip -r "../$AAR_NAME" . > /dev/null
popd

# verify .aar and print output path to console
unzip -t "$BUILD_DIR/$AAR_NAME"
