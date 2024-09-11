#!/bin/bash

usage() {
    echo "usage: $0 <jar_file> <directory>" 1>&2
    echo "  jar_file: the path to the JAR file" 1>&2
    echo "  directory: a directory to add to the JAR file" 1>&2
    echo "example: $0 build/lib/luajava-x.y.jar native" 1>&2
    echo "This example adds the native libraries to the JAR file." 1>&2
    exit 1
}

if [ $# -lt 1 ] ; then
    usage
fi

jar_file=$1
directory_to_append=$2

if [ ! -f "$jar_file" ] ; then
    echo "error: file $jar_file does not exist" 1>&2
    exit 1
fi

if [ ! -d "$directory_to_append" ] ; then
    echo "error: directory $directory_to_append does not exist" 1>&2
    exit 1
fi

jar -uf $jar_file $directory_to_append
