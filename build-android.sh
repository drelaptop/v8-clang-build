#!/bin/bash

# exit this script if any commmand fails
set -e
#  

host_os=`uname -s | tr "[:upper:]" "[:lower:]"`
host_arch=`uname -m`

ANDROID_NDK_ROOT=/Users/laptop/android-ndk-r16b

rm -rf out.gn/armeabi-v7a
rm -rf out.gn/arm64-v8a
rm -rf out.gn/x86

rm -rf dist-android
mkdir dist-android

build_v8()
{
    ARM_VERSION_CONFIG=""
    if [ $ARM_VERSION ];then
        ARM_VERSION_CONFIG="arm_version=$ARM_VERSION"
        echo "arm version: $ARM_VERSION"
    else
        echo "can't find arm version!"
    fi

    # ./toolchains/llvm/prebuilt/darwin-x86_64/bin/clang++
    CLANG_BASE=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64
    BIN_DIR=$CLANG_BASE/bin
    AR=$BIN_DIR/llvm-ar
    #STRIP=$BIN_DIR/${TOOLNAME_PREFIX}-strip

    ARGS="is_debug=false \
          symbol_level=0 \
          target_os=\"android\" \
          target_cpu=\"$TARGET_CPU\" \
          v8_target_cpu=\"$TARGET_CPU\" \
          $ARM_VERSION_CONFIG \
          v8_use_snapshot=false \
          v8_enable_i18n_support=false \
          v8_use_external_startup_data=false \
          is_component_build=false \
          v8_static_library=true \
          android_ndk_root=\"$ANDROID_NDK_ROOT\" \
          clang_base_path=\"$CLANG_BASE\" \
          "

    gn gen $OUT_DIR --args="${ARGS}"
    # gn args $OUT_DIR --list
    ninja -C $OUT_DIR d8 -v # -j1


    rm -rf $OUT_DIR/libs
    mkdir $OUT_DIR/libs
    pushd $OUT_DIR/libs
    $AR rcs libv8_base.a ../obj/v8_base/*.o
    $AR rcs libv8_libbase.a ../obj/v8_libbase/*.o
    $AR rcs libv8_libsampler.a ../obj/v8_libsampler/*.o
    $AR rcs libv8_libplatform.a ../obj/v8_libplatform/*.o
    $AR rcs libv8_nosnapshot.a ../obj/v8_nosnapshot/*.o
    # $STRIP --strip-unneeded libv8_base.a
    # $STRIP --strip-unneeded libv8_libbase.a
    # $STRIP --strip-unneeded libv8_libsampler.a
    # $STRIP --strip-unneeded libv8_libplatform.a
    # $STRIP --strip-unneeded libv8_nosnapshot.a
    popd

    mkdir -p dist-android/$ANDROID_ARCH/include
    mkdir -p dist-android/$ANDROID_ARCH/libs
    cp -r include/* dist-android/$ANDROID_ARCH/include
    cp $OUT_DIR/libs/lib*.a dist-android/$ANDROID_ARCH/libs
}

ANDROID_ARCH=armeabi-v7a
OUT_DIR=out.gn/$ANDROID_ARCH
TARGET_CPU=arm
ARM_VERSION=7
build_v8

ANDROID_ARCH=arm64-v8a
OUT_DIR=out.gn/$ANDROID_ARCH
TARGET_CPU=arm64
ARM_VERSION=8
#build_v8

ANDROID_ARCH=x86
OUT_DIR=out.gn/$ANDROID_ARCH
TARGET_CPU=x86
ARM_VERSION=
#build_v8
