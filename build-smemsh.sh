#!/usr/bin/env bash

declare -A options=(

# non-defaults from meson_options.txt
#
prefix            /usr/local
sysconfdir        /etc/elinks
ipv6              false
bittorrent        false
mouse             false
88-colors         true
256-colors        true
exmode            true
html-highlight    true
fastmem           true
gpm               false
terminfo          true
zstd              true
brotli            true
python            true
libevent          false
libev             false
no-root           true
apidoc            false
htmldoc           false
pdfdoc            false
test-mailcap      true

###

); opts=$(
	for key in "${!options[@]}"
	do echo "-D $key=${options[$key]}"; done
)

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

set -x
test -d build && rm -rf build
meson setup build || bomb setup
meson configure $opts build || bomb configure
ninja -C build || bomb build
set +x

cat << %
build complete
install: sudo ninja -C build install
then: sudo cp build/src/mime/backend/mailcap-cache /usr/local/bin/
%
