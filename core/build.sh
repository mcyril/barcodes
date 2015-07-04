#/bin/sh

USE_ZXING=1
USE_ZBAR=0

#simulator

echo "preparing simulator library environment..."

TARGET_BUILD_DIR=`xcodebuild -sdk iphonesimulator -arch i386 -arch x86_64 -showBuildSettings | /usr/bin/sed -n -e 's/^.*TARGET_BUILD_DIR = //p'`
EXECUTABLE_NAME=`xcodebuild -sdk iphonesimulator -arch i386 -arch x86_64 -showBuildSettings | /usr/bin/sed -n -e 's/^.*EXECUTABLE_NAME = //p'`

echo "building simulator library..."

xcodebuild -sdk iphonesimulator -arch i386 -arch x86_64 GCC_PREPROCESSOR_DEFINITIONS_BASE="UMBARCODE_SCAN_ZXING=$USE_ZXING UMBARCODE_SCAN_ZBAR=$USE_ZBAR" clean build > /dev/null

SIMULATOR_TARGET_PATH="$TARGET_BUILD_DIR/$EXECUTABLE_NAME"

# device

echo "preparing device library environment..."

TARGET_BUILD_DIR=`xcodebuild -sdk iphoneos -arch armv7 -arch arm64 -showBuildSettings | /usr/bin/sed -n -e 's/^.*TARGET_BUILD_DIR = //p'`
EXECUTABLE_NAME=`xcodebuild -sdk iphoneos -arch armv7 -arch arm64 -showBuildSettings | /usr/bin/sed -n -e 's/^.*EXECUTABLE_NAME = //p'`

echo "building device library..."

xcodebuild -sdk iphoneos -arch armv7 -arch arm64 GCC_PREPROCESSOR_DEFINITIONS_BASE="UMBARCODE_SCAN_ZXING=$USE_ZXING UMBARCODE_SCAN_ZBAR=$USE_ZBAR" clean build > /dev/null

DEVICE_TARGET_PATH="$TARGET_BUILD_DIR/$EXECUTABLE_NAME"

# build FAT

echo "building FAT library..."

lipo -create $SIMULATOR_TARGET_PATH $DEVICE_TARGET_PATH -output $EXECUTABLE_NAME

echo "done."
