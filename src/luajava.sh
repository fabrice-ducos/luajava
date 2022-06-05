#!/bin/bash

# the prefix is the parent directory of bin, lib, etc
DEFAULT_PREFIX=`dirname $0`/..
: "${LUAJAVA_PREFIX:=$DEFAULT_PREFIX}"
LIBDIR=${LUAJAVA_PREFIX}/lib
LUAJAVA_VERSION=__LUAJAVA_VERSION__

exec java -Djava.library.path=$LIBDIR -cp "$LIBDIR/luajava-${LUAJAVA_VERSION}.jar" org.keplerproject.luajava.Console "$@"
