#!/bin/bash

export PATH="${HOME}/.cargo/bin:${PATH}"

mkdir -p ${BUILT_PRODUCTS_DIR}

if [[ ${ACTION:-build} = "build" ]]; then
    if [[ $PLATFORM_NAME = "macosx" ]]; then
        RUST_TARGET_OS="darwin"
    else
        RUST_TARGET_OS="ios"
    fi

    for ARCH in $ARCHS
    do
        if [[ $(lipo -info "${BUILT_PRODUCTS_DIR}/libtun2tor.a" 2>&1) != *"${ARCH}"* ]]; then
            rm -f "${BUILT_PRODUCTS_DIR}/libtun2tor.a"
        fi
    done

    if [[ $CONFIGURATION = "Debug" ]]; then
        RUST_CONFIGURATION="debug"
        RUST_CONFIGURATION_FLAG=""
    else
        RUST_CONFIGURATION="release"
        RUST_CONFIGURATION_FLAG="--release"
    fi

    LIBRARIES=()
    for ARCH in $ARCHS
    do
        RUST_ARCH=$ARCH
        if [[ $RUST_ARCH = "arm64" ]]; then
            RUST_ARCH="aarch64"
        fi
        cargo build --lib $RUST_CONFIGURATION_FLAG --target "${RUST_ARCH}-apple-${RUST_TARGET_OS}"
        LIBRARIES+=("target/${RUST_ARCH}-apple-${RUST_TARGET_OS}/${RUST_CONFIGURATION}/libtun2tor.a")
    done

    xcrun --sdk $PLATFORM_NAME lipo -create "${LIBRARIES[@]}" -output "${BUILT_PRODUCTS_DIR}/libtun2tor.a"
elif [[ $ACTION = "clean" ]]; then
    cargo clean
    rm -f "${BUILT_PRODUCTS_DIR}/libtun2tor.a"
fi
