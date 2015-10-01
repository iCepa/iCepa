#!/bin/bash
if [[ ${ACTION:-build} = "build" ]]; then
    cargo build --release --lib --target x86_64-apple-darwin
elif [[ ${ACTION:-build} = "clean" ]]; then
    cargo clean
fi
