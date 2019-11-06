#!/usr/bin/env bash
set -e

THIS_DIR="$(dirname $0)"
cd "$THIS_DIR"
THIS_DIR="$(pwd)"
mkdir -p contrib/patched/
cp -R contrib/original/ contrib/patched/
patch --batch --quiet --forward --unified --strip=1 --directory=contrib/patched "--input=$(pwd)/contrib/tomcat.patch"
