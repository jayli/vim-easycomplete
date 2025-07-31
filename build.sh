#!#!/usr/bin/env sh

rm -rf ./target/release
cargo rustc -- -C link-arg=-undefined -C link-arg=dynamic_lookup
