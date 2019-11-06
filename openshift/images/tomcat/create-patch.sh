#!/usr/bin/env bash
set -e

THIS_DIR="$(dirname $0)"
cd "$THIS_DIR"

(cd contrib/patched && diff --new-file -ru ../original/ ./ > ../tomcat.patch || true)
(cd contrib/original && find . -type f -print0  | xargs -0 shasum > ../tomcat.sha1)