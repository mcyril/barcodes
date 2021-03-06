#!/bin/bash

echo "### BARCODES"

# ---------------------------------------------------------------------------------------

# default build configurations
builds=("system" "qr" "aztec") # possible values ("system" "zxing" "zbar" "zint" "qr" "aztec")
if [ "$#" -eq 0 ]; then
	set -- ${builds[*]}
fi
builds=( $@ )

# ---------------------------------------------------------------------------------------

barcodes_config="Release"
temp_dir=$(mktemp -d "/tmp/barcodes.XXXXXXXX")

arch_device=(-sdk iphoneos -arch armv7 -arch arm64)
arch_simulator=(-sdk iphonesimulator -arch i386 -arch x86_64)

# ---------------------------------------------------------------------------------------

# accepts list of build arguments
function get_target_build_dir
{
	echo `xcodebuild -configuration $barcodes_config $@ -showBuildSettings BUILD_DIR="$temp_dir" | /usr/bin/sed -n -e 's/^.*TARGET_BUILD_DIR = //p'`
}

# accepts list of build arguments
function get_executable_name
{
	echo `xcodebuild -configuration $barcodes_config $@ -showBuildSettings BUILD_DIR="$temp_dir" | /usr/bin/sed -n -e 's/^.*EXECUTABLE_NAME = //p'`
}

# accepts library scheme name of barcodes
function get_device_library
{
	echo $(get_target_build_dir ${arch_device[@]} -scheme $1)/$(get_executable_name ${arch_device[@]} -scheme $1)
}

# accepts library scheme name of barcodes
function get_simulator_library
{
	echo $(get_target_build_dir ${arch_simulator[@]} -scheme $1)/$(get_executable_name ${arch_simulator[@]} -scheme $1)
}

# ---------------------------------------------------------------------------------------
# device library
# ---------------------------------------------------------------------------------------

echo "###   configuring device library..."

preprocessor_defs=("UMBARCODE_SCAN_SIMULATOR=0")
inx_preprocessor_defs=${#preprocessor_defs[@]}

extra_libraries=()
inx_libraries=${#extra_libraries[@]}

# with system scanner/generator
if [[ " ${builds[@]} " =~ " system " ]]; then
	echo "###     preparing System built-in scanner/generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_SYSTEM=1"
	let "inx_preprocessor_defs+=1"
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_SYSTEM=1"
	let "inx_preprocessor_defs+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_SYSTEM=0"
	let "inx_preprocessor_defs+=1"
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_SYSTEM=0"
	let "inx_preprocessor_defs+=1"
fi

# with zxing scanner/generator
if [[ " ${builds[@]} " =~ " zxing " ]]; then
	echo "###     preparing ZXing 3rd-party scanner/generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_ZXING=1"
	let "inx_preprocessor_defs+=1"
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZXING=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_device_library ZXingObjC-iOS)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_ZXING=0"
	let "inx_preprocessor_defs+=1"
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZXING=0"
	let "inx_preprocessor_defs+=1"
fi

# with zbar scanner
if [[ " ${builds[@]} " =~ " zbar " ]]; then
	echo "###     preparing ZBar 3rd-party scanner..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_ZBAR=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_device_library zbar)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_ZBAR=0"
	let "inx_preprocessor_defs+=1"
fi

# with zint generator
if [[ " ${builds[@]} " =~ " zint " ]]; then
	echo "###     preparing ZInt 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZINT=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_device_library zint)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZINT=0"
	let "inx_preprocessor_defs+=1"
fi

# with QR stand-alone generator
if [[ " ${builds[@]} " =~ " qr " ]]; then
	echo "###     preparing QR stand-alone 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_QR=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_device_library qrencode)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_QR=0"
	let "inx_preprocessor_defs+=1"
fi

# with Aztec stand-alone generator
if [[ " ${builds[@]} " =~ " aztec " ]]; then
	echo "###     preparing Aztec stand-alone 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_AZTEC=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_device_library aztec)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_AZTEC=0"
	let "inx_preprocessor_defs+=1"
fi

extra_libraries_list=${extra_libraries[@]}
#extra_libraries_list=$(printf " '%s'" "${extra_libraries[@]}") # TODO: do some work for spaces in paths maybe?

preprocessor_defs_list=${preprocessor_defs[@]}

echo "###   done."

# ---------------------------------------------------------------------------------------

echo "###   building device library..."
xcodebuild -configuration $barcodes_config ${arch_device[@]} -scheme barcodes BUILD_DIR="$temp_dir" GCC_PREPROCESSOR_DEFINITIONS_BASE="$preprocessor_defs_list" OTHER_LIBTOOLFLAGS_BASE="$extra_libraries_list" clean build > /dev/null
if [ $? != 0 ]; then
	echo "### ...failed..."
	exit $?
fi

# ---------------------------------------------------------------------------------------
# simulator library
# ---------------------------------------------------------------------------------------

echo "###   configuring simulator library..."

preprocessor_defs=("UMBARCODE_SCAN_SIMULATOR=1")
inx_preprocessor_defs=${#preprocessor_defs[@]}

extra_libraries=()
inx_libraries=${#extra_libraries[@]}

# with system scanner/generator
if [[ " ${builds[@]} " =~ " system " ]]; then
	echo "###     bypassing System built-in scanner..."
	echo "###     preparing System built-in generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_SYSTEM=1"
	let "inx_preprocessor_defs+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_SYSTEM=0"
	let "inx_preprocessor_defs+=1"
fi

preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_SYSTEM=0"
let "inx_preprocessor_defs+=1"

# with zxing scanner/generator
if [[ " ${builds[@]} " =~ " zxing " ]]; then
	echo "###     bypassing ZXing 3rd-party scanner..."
	echo "###     preparing ZXing 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZXING=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_simulator_library ZXingObjC-iOS)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZXING=0"
	let "inx_preprocessor_defs+=1"
fi

preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_ZXING=0"
let "inx_preprocessor_defs+=1"

# with zbar scanner
if [[ " ${builds[@]} " =~ " zbar " ]]; then
	echo "###     bypassing ZBar 3rd-party scanner..."
fi

preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_SCAN_ZBAR=0"
let "inx_preprocessor_defs+=1"

# with zint generator
if [[ " ${builds[@]} " =~ " zint " ]]; then
	echo "###     preparing ZInt 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZINT=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_simulator_library zint)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_ZINT=0"
	let "inx_preprocessor_defs+=1"
fi

# with QR stand-alone generator
if [[ " ${builds[@]} " =~ " qr " ]]; then
	echo "###     preparing QR stand-alone 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_QR=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_simulator_library qrencode)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_QR=0"
	let "inx_preprocessor_defs+=1"
fi

# with Aztec stand-alone generator
if [[ " ${builds[@]} " =~ " aztec " ]]; then
	echo "###     preparing Aztec stand-alone 3rd-party generator..."
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_AZTEC=1"
	let "inx_preprocessor_defs+=1"
	extra_libraries[${inx_libraries}]=$(get_simulator_library aztec)
	let "inx_libraries+=1"
else
	preprocessor_defs[${inx_preprocessor_defs}]="UMBARCODE_GEN_AZTEC=0"
	let "inx_preprocessor_defs+=1"
fi

extra_libraries_list=${extra_libraries[@]}
#extra_libraries_list=$(printf " '%s'" "${extra_libraries[@]}") # TODO: do some work for spaces in paths maybe?

preprocessor_defs_list=${preprocessor_defs[@]}

echo "###   done."

# ---------------------------------------------------------------------------------------

echo "###   building simulator library..."
xcodebuild -configuration $barcodes_config ${arch_simulator[@]} -scheme barcodes BUILD_DIR="$temp_dir" GCC_PREPROCESSOR_DEFINITIONS_BASE="$preprocessor_defs_list" OTHER_LIBTOOLFLAGS_BASE="$extra_libraries_list" clean build > /dev/null
if [ $? != 0 ]; then
	echo "### ...failed..."
	exit $?
fi

# ---------------------------------------------------------------------------------------
# universal library
# ---------------------------------------------------------------------------------------

executable_name=$(get_executable_name ${arch_simulator[@]} -scheme barcodes)

# ---------------------------------------------------------------------------------------

echo "###   building universal library..."
lipo -create $(get_device_library barcodes) $(get_simulator_library barcodes) -output $executable_name

# ---------------------------------------------------------------------------------------

if [[ ! " ${builds[@]} " =~ " bitcode " ]]; then
	echo "###   stripping bitcode..."
	xcrun bitcode_strip $executable_name -r -o $executable_name
fi

# ---------------------------------------------------------------------------------------

if [[ ! " ${builds[@]} " =~ " debug " ]]; then
	echo "###   stripping debugging symbol table entries..."
	strip -S $executable_name
fi

# ---------------------------------------------------------------------------------------
ranlib $executable_name
# ---------------------------------------------------------------------------------------

echo "### all done."
