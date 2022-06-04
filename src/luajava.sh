#!/bin/bash

DEFAULT_PREFIX=`dirname $0`/..
: "${LUAJAVA_PREFIX:=$DEFAULT_PREFIX}"
LIBDIR=${LUAJAVA_PREFIX}/lib

exec java -Djava.library.path=$LIBDIR -cp "$LIBDIR/luajava-1.1.jar" org.keplerproject.luajava.Console "$@"
