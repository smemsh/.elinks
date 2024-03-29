#!/usr/bin/env bash

set -x
bomb () { echo "meson $@ failed" >&2; false; exit; }

### libcss ###

# mkdir -p netsurf
# cd netsurf
# git clone git://git.netsurf-browser.org/netsurf.git
#
test -d netsurf/netsurf || bomb "checkout netsurf to netsurf/netsurf"

# mkdir -p netsurf/nsbuild
# export TARGET_WORKSPACE=$PWD/netsurf/nsbuild
# source netsurf/netsurf/docs/env.sh
# ns-clone
#
test -d netsurf/nsbuild || bomb "no nsbuild dir, run ns-clone"
export TARGET_WORKSPACE=$PWD/netsurf/nsbuild
source netsurf/netsurf/docs/env.sh
ns-pull-install

echo sudo cp -r netsurf/nsbuild/inst-x86_64-linux-gnu/* /usr/local/
read -n1 -p 'waiting for key to continue when done...'
echo

### elinks ###

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
