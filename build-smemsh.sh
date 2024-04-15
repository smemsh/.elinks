#!/usr/bin/env bash

set -x
set -e

bomb () { echo "meson $@ failed" >&2; false; exit; }

[[ ${PWD##*/} == elinks ]] || bomb "must be in elinks root dir"
test -f meson_options.txt  || bomb "no meson options file present"

### libcss ###

if ! test -d netsurf
then
	printf "netsurf dne, cloning..."

	set -x
	mkdir netsurf
	git -C netsurf clone -q git://git.netsurf-browser.org/netsurf.git
	set +x

	echo done
fi

nsbuilddir=netsurf/nsbuild
nsnsdir=netsurf/netsurf
if ! test -d $nsbuilddir
then (
	echo "nsbuild dne, cloning libs..."

	set -x
	mkdir $nsbuilddir
	export TARGET_WORKSPACE=$PWD/$nsbuilddir
	source $nsnsdir/docs/env.sh
	ns-clone
	set +x

	echo done
); nsbuild=1
fi

if ! ((nsbuild))
then
	read -s -n1 -p 'update netsurf libs (y/N)? ' r
	echo $r
	if [[ ! $r || $r == n ]]; then nsbuild=0
	elif [[ $r == y ]]; then nsbuild=1
	else bomb "bad nsbuild yn response"
	fi
fi

if ((nsbuild))
then (
	echo "updating netsurf build..."

	set -x
	export TARGET_WORKSPACE=$PWD/$nsbuilddir
	source $nsnsdir/docs/env.sh
	ns-pull-install
	set +x

	cat <<- %
	build done
	sudo cp -uvr netsurf/nsbuild/inst-x86_64-linux-gnu/* /usr/local/
	%
	read -n1 -p 'waiting for key to continue when done...'
	echo
); fi

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
	-D test-mailcap=true \
build || bomb configure

ninja -C build || bomb ninja

set +x

echo "completed."
echo "to install: sudo ninja -C build install"
echo "then: sudo cp build/src/mime/backend/mailcap-cache /usr/local/bin/"
