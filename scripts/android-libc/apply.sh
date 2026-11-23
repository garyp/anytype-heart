#!/usr/bin/env bash
# Builds a patched copy of modernc.org/libc and points go.mod at it, for the Android library only.
#
# modernc.org/libc (pure-Go SQLite's C library, generated from musl) makes the legacy x86_64
# syscalls lstat, access, unlink, mkdir, rmdir and rename. Android's app seccomp filter blocks
# them on x86_64, so heart crashes with SIGSYS (or, with SIGSYS ignored, fails with "unable to
# open database file") on x86_64 emulators. The patch swaps each one for its *at form, which the
# kernel uses for them anyway. It only touches ccgo_linux_amd64.go, built for linux/android amd64.
# Upstream: https://gitlab.com/cznic/libc/-/issues/41
#
# Run from anywhere; it edits go.mod in place (a replace to build/modernc-libc). CI runs it right
# before "Compile android lib", after the desktop and iOS builds.
set -euo pipefail
cd "$(dirname "$0")/../.."

want=v1.66.8
patch_file=scripts/android-libc/modernc-libc-${want}-android-amd64.patch
dest=build/modernc-libc

have=$(go list -m -f '{{.Version}}' modernc.org/libc)
if [ "$have" != "$want" ]; then
  echo "modernc.org/libc is $have, but $patch_file is for $want; regenerate the patch" >&2
  exit 1
fi

# The module cache copy, not .Dir: after a first run, .Dir is the patched copy itself.
src=$(go mod download -json "modernc.org/libc@$want" | sed -n 's/^[[:space:]]*"Dir": "\(.*\)",$/\1/p')
[ -d "$src" ] || { echo "could not locate modernc.org/libc@$want in the module cache" >&2; exit 1; }
rm -rf "$dest"
mkdir -p "$(dirname "$dest")"
cp -R "$src" "$dest"
chmod -R u+w "$dest"
patch -p1 --forward -d "$dest" < "$patch_file"
go mod edit -replace "modernc.org/libc=./$dest"
echo "modernc.org/libc $want patched for Android x86_64 in $dest"
