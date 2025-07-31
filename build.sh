#!#!/usr/bin/env sh

cargo rustc -- -C link-arg=-undefined -C link-arg=dynamic_lookup
