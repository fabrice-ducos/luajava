#!/bin/bash

usage() {
    echo "usage: $0 <jar_file> <directory_to_append>" 1>&2
    echo "  jar_file: the path to the JAR file" 1>&2
    echo "  directory_to_append: the path to the directory containing the native libraries" 1>&2
    echo "example: $0 myapp.jar natives" 1>&2
    echo "This script adds the native libraries in the specified directory to the JAR file." 1>&2
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
