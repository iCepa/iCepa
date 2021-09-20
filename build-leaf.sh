#!/usr/bin/env sh

# Get absolute path to this script.
DIR=$(cd `dirname $0` && pwd)/leaf

FILENAME="libleaf.a"

# See https://github.com/TimNN/cargo-lipo/issues/41#issuecomment-774793892
if [[ -n "${DEVELOPER_SDK_DIR:-}" ]]; then
  # Assume we're in Xcode, which means we're probably cross-compiling.
  # In this case, we need to add an extra library search path for build scripts and proc-macros,
  # which run on the host instead of the target.
  # (macOS Big Sur does not have linkable libraries in /usr/lib/.)
  export LIBRARY_PATH="${DEVELOPER_SDK_DIR}/MacOSX.sdk/usr/lib:${LIBRARY_PATH:-}"

  # The $PATH used by Xcode likely won't contain Cargo, fix that.
  # This assumes a default `rustup` setup.
  export PATH="${HOME}/.cargo/bin:{$PATH}"

  # Delete old build, if any.
  rm -f "${BUILT_PRODUCTS_DIR}/${FILENAME}"

  # --xcode-integ determines --release and --targets from Xcode's env vars.
  # Depending your setup, specify the rustup toolchain explicitly.
  cargo lipo --xcode-integ --manifest-path "${DIR}/Cargo.toml" -p leaf-ffi

  # cargo-lipo drops result in different folder, depending on the config.
  if [[ $CONFIGURATION = "Debug" ]]; then
    SOURCE="$DIR/target/universal/debug/${FILENAME}"
  else
    SOURCE="$DIR/target/universal/release/${FILENAME}"
  fi

  # Copy compiled library to BUILT_PRODUCTS_DIR. Use that in your Xcode project
  # settings under General -> Frameworks and Libraries.
  # You will also need to have tun2tor.h somewhere in your search paths!
  # (Easiest way: have it referenced in your project files list.)
  if [ -e "${SOURCE}" ]; then
    cp -a "${SOURCE}" "${BUILT_PRODUCTS_DIR}"
  fi

else

  # Direct command line usage.

  cargo lipo --manifest-path $DIR/Cargo.toml -p leaf-ffi

fi

cbindgen --config "${DIR}/leaf-ffi/cbindgen.toml" "${DIR}/leaf-ffi/src/lib.rs" > leaf.h
