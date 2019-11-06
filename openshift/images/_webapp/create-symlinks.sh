#!/usr/bin/env bash
set -e
function _symlink {
  local line;
  local slashes;
  local prefix;
  while read -r line ; do
    prefix="$1"
    slashes="$(grep -o '/' <<< "$line" | wc -l)"
    while (( --slashes >= 0 )); do
      prefix="$prefix/.."
      #slashes=$((slashes-1))
    done
    
    mkdir -p "$(dirname $line)"
    echo ln -fs "$prefix/$line" "$line"
    ln -fs "$prefix/$line" "$line"
  done
}
THIS_DIR="$(dirname $0)"
GIT_WORKDIR="$(git rev-parse --show-toplevel)"

mkdir -p "${THIS_DIR}/contrib/src"
cd "${THIS_DIR}/contrib/src"
REL_GIT_WORKDIR='../../../../..'
find $REL_GIT_WORKDIR -type f -name 'pom.xml' -maxdepth 2 | sed 's|\.\.\/||g' | _symlink $REL_GIT_WORKDIR
find $REL_GIT_WORKDIR -type f -name '.keep' | sed 's|\.\.\/||g' | sed 's|\.\.\/||g' | _symlink $REL_GIT_WORKDIR
find $REL_GIT_WORKDIR -type f -name 'web.xml' | grep -v '/target/' | sed 's|\.\.\/||g' | sed 's|\.\.\/||g' | _symlink $REL_GIT_WORKDIR
