#!/usr/bin/env sh

rm -rf ./target/release

# cargo build --target x86_64-apple-darwin --release
# cargo build --target aarch64-apple-darwin --release

# mkdir -p target/universal/release

# lipo -create \
#   target/x86_64-apple-darwin/release/libeasycomplete_util.dylib \
#   target/aarch64-apple-darwin/release/libeasycomplete_util.dylib \
#   -output target/debug/libeasycomplete_util.dylib

####################### dev #######################

# cargo rustc -- \
#   -C link-arg=-undefined \
#   -C link-arg=dynamic_lookup \
#   -C opt-level=3 \
#   --target x86_64-apple-darwin

# cd ./target
# ln -s debug release

####################### release #######################

rm -rf ./target/debug
cargo rustc --release -- \
  -C link-arg=-undefined \
  -C link-arg=dynamic_lookup \
  -C opt-level=3 \
  -C debuginfo=0 \
  --target x86_64-apple-darwin
rm ./target/CACHEDIR.TAG
rm ./target/.rustc_info.json
rm ./target/release/libeasycomplete_rust_speed.d
rm -rf ./target/release/incremental
rm -rf ./target/release/examples
rm -rf ./target/release/deps
rm -rf ./target/release/build
rm -rf ./target/release/.fingerprint
rm ./target/release/.cargo-lock
#
# -C profile-generate \
echo "dylib created!"
