#!/usr/bin/env sh

rm -rf ./target/release

# cargo build --target x86_64-apple-darwin --release
# cargo build --target aarch64-apple-darwin --release

# mkdir -p target/universal/release

# lipo -create \
#   target/x86_64-apple-darwin/release/libeasycomplete_util.dylib \
#   target/aarch64-apple-darwin/release/libeasycomplete_util.dylib \
#   -output target/debug/libeasycomplete_util.dylib


cargo rustc --release -- \
  -C link-arg=-undefined \
  -C link-arg=dynamic_lookup \
  -C opt-level=3 \
   -C debuginfo=0 \
  --target x86_64-apple-darwin
#
# -C profile-generate \
echo "dylib created!"
