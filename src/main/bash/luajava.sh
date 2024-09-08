#!/bin/bash

LUAJAVA_VERSION=__LUAJAVA_VERSION__
quiet_mode=false

if [ "$1" = '-q' ] ; then
  quiet_mode=true
  shift
fi 

# the prefix is the parent directory of bin, lib, etc
DEFAULT_PREFIX=`dirname $0`/..
: "${LUAJAVA_PREFIX:=$DEFAULT_PREFIX}"

JAR_FILE=luajava-${LUAJAVA_VERSION}.jar
MAVEN_REPO=__M2_ROOT__/repository/org/keplerproject/luajava/${LUAJAVA_VERSION}/
LIBDIR=${LUAJAVA_PREFIX}/lib

if [ -f "${LIBDIR}/${JAR_FILE}" ] ; then
   JAR_PATH="${LIBDIR}/${JAR_FILE}"
fi

if [ -f "${MAVEN_REPO}/${JAR_FILE}" ] ; then
  if [[ -f "$JAR_PATH" && $quiet_mode = false ]] ; then
    echo "$0: warning: two copies of ${JAR_FILE} have been found:" 1>&2 ;
    echo "$0: warning: - ${LIBDIR}/${JAR_FILE}" 1>&2 ;
    echo "$0: warning: - ${MAVEN_REPO}/${JAR_FILE}" 1>&2 ;
    echo "$0: warning: I will choose ${MAVEN_REPO}/${JAR_FILE}" 1>&2 ;
    echo "$0: warning: in order to remove this warning, run this command in quiet mode (-q)"
    echo "$0: warning: or delete the unwanted copy" 1>&2
  fi
  
  LIBDIR=${MAVEN_REPO}
  JAR_PATH="${LIBDIR}/${JAR_FILE}"
fi

exec java -Djava.library.path="${LIBDIR}" -cp "${JAR_PATH}" org.keplerproject.luajava.Console "$@"
