#!/usr/bin/env bash

set -x
bomb () { echo "meson $@ failed" >&2; false; exit; }

test -d build && rm -rf build
meson setup build || bomb build

# see meson_options.txt, these are only non-default vaules
meson configure \
	-D prefix=/usr/local \
	-D sysconfdir=/etc/elinks \
	-D ipv6=false \
	-D bittorrent=false \
	-D mouse=false \
	-D 88-colors=true \
	-D 256-colors=true \
	-D exmode=true \
	-D html-highlight=true \
	-D fastmem=true \
	-D gpm=false \
	-D terminfo=true \
	-D zstd=true \
	-D brotli=true \
	-D python=true \
	-D libevent=false \
	-D libev=false \
	-D no-root=true \
build || bomb configure

cd build && ninja && cd - || bomb ninja

echo "completed."
echo "to install: sudo ninja -C build install"
