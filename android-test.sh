#!/usr/bin/env bash
SCRIPT_DIR=$(dirname $0)

# NOTE: this script simply pushes the mpg123 binary to the device, and decodes
# an .mp3 file -> .wav file. it does NOT yet run any of the test binaries built
# by `make check`
LIB_NAME="libmpg123"

BUILD_DIR="$SCRIPT_DIR/build/android"
TEST_DIR="/data/local/tmp/$LIB_NAME/test"

if [ -z "$TEST_FILE" ]; then
    TEST_FILE="$SCRIPT_DIR/src/tests/sweep.mp3"
    echo "Test file not set: using default -> $TEST_FILE"
    echo "Set TEST_FILE variable and re-run to customize"
else
    echo "Using test file: $TEST_FILE"
fi
echo

TEST_FILE_IN_NAME=$(basename $TEST_FILE)
TEST_FILE_OUT_NAME="${TEST_FILE_IN_NAME%.mp3}.wav"

# make sure one device is accessible with parameters passed to script
ECHO=$(adb $@ shell echo 2>&1 )
if [ -n "$ECHO" ]; then
    echo "Error running adb (specify device with -d or -s if more than one device is connected): $ECHO"
    adb devices
    exit 1
fi

# remove existing test files
adb $@ shell "rm -r $TEST_DIR" > /dev/null
adb $@ shell "mkdir -p $TEST_DIR" > /dev/null

ABIS=`adb $@ shell getprop ro.product.cpu.abilist`

print_message() {
  echo "[==========================================================]"
  echo "| [$LIB_NAME]: $1"
  echo "[==========================================================]"
}

for ABI in $(echo $ABIS | tr "," "\n"); do
    if [ $ABI == "armeabi" ]; then
        print_message "skipping deprecated ABI: [$ABI]"; echo
        continue
    fi
    print_message "testing ABI [$ABI]"

    # create test directory for ABI on device
    TEST_ABI_DIR="$TEST_DIR/$ABI"
    adb $@ shell mkdir -p $TEST_ABI_DIR > /dev/null

    # creat test output directory
    OUTPUT_DIR="$BUILD_DIR/$ABI/test"
    mkdir -p $OUTPUT_DIR > /dev/null

    # push test binary to device
    pushd "$BUILD_DIR/$ABI/bin" > /dev/null
    adb $@ push mpg123 $TEST_ABI_DIR > /dev/null
    popd > /dev/null

    # push test libraries to device
    pushd "$BUILD_DIR/$ABI/lib" > /dev/null
    adb $@ push ./*.so $TEST_ABI_DIR > /dev/null
    popd > /dev/null

    # push test resources to device
    adb $@ push $TEST_FILE $TEST_ABI_DIR > /dev/null

    # run mpg123 to convert test file to .wav on device
    adb $@ shell -t "cd $TEST_ABI_DIR && LD_LIBRARY_PATH=. ./mpg123 -w $TEST_FILE_OUT_NAME $TEST_FILE_IN_NAME"

    # pull output file to test output directory
    adb $@ pull "$TEST_ABI_DIR/$TEST_FILE_OUT_NAME" "$OUTPUT_DIR/" > /dev/null

    echo "Test file output: $OUTPUT_DIR/$TEST_FILE_OUT_NAME"
    echo
done

print_message "tests finished for ABIS: [$ABIS]"; echo
echo "NOTE: make sure to verify the test file output manually."
