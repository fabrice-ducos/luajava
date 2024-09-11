luajava 2.5
===========

This is a fork a luajava 2019, updated for Lua 5.4 and modern JDKs.

Starting from JDK 10, the `javah` tool required for JNI is not available anymore, making it impossible
to build old versions of luajava with recent JDKs. This fork makes luajava compatible with JDK 10+,
but still uses `javah` when it is available. Support of JDK 4- has been dropped, in order to get rid
of many obsolete constructs issuing warnings after Java 5, and even errors in more recent versions of the JDK.

Another motivation for this work is to make luajava compatible with recent versions of the Lua language.
The low level Lua API has evolved a bit in Lua 5.2, 5.3 and 5.4, making it necessary to update the
Java bindings in order to keep luajava working.

You will need to have a modern JDK (at least JDK 5+, preferrably JDK 8+) and a modern version of Lua (at least 5.4).
Lua must be properly installed, and the environment variable JAVA_HOME must be set to a proper JDK root directory.

*Since version 2.5, the luajava native library is stored in the jar file, making it easier to maintain and deploy.*

For testing:
```
make
./build/bin/luajava
```

For installing (a installation path can be provided, /usr/local by default)
```
[sudo] make install [PREFIX=/usr/local]
```

For installing the jar in the local maven repository (requires maven):
```
make maven-install
```

## Test luajava with jrunscript

*jrunscript is the official JDK script runner for JSR223 compliant languages. The JSR223 support of luajava is still partial and in development, therefore you may experience errors when trying this solution for the moment.*

If jrunscript is available with your JDK, you can use it.

With luajava's default system-wide installation (assuming the installation prefix was set to `PREFIX = /usr/local`):

`jrunscript -cp /usr/local/lib/luajava-2.3.jar -Djava.library.path=/usr/local/lib -l luajava`

With the maven installation (on MSYS2/Windows, replace $HOME by $HOMEDRIVE$HOMEPATH):

`jrunscript -cp $HOME/.m2/repository/org/keplerproject/luajava/2.3/luajava-2.3.jar -Djava.library.path=$HOME/.m2/repository/org/keplerproject/luajava/2.3 -l luajava`

CAVEAT: there seems to be a bug in at least some implementations on MacOSX: the `-Djava.library.path` flag has no effect on these implementations, and the JDK only looks for native libraries in some fixed paths, e.g. `/Library/Java/Extensions` and `/Users/username/Library/Java/Extensions`. If you experience an UnsatisfiedLinkError despite of providing the proper java.library.path, you should set the DYLD_LIBRARY_PATH environment variable to the same value as java.library.path (or extend it depending on your needs), or alternatively store your native library (libluajava-x.y.dylib) in one of the Java/Extensions directories.

This bug wasn't observed on other systems (e.g. Linux/Ubuntu or Windows/MSYS2).

## COMPATIBILITY

Version of Lua: 5.4

This distribution has been successfully built on the following systems:
  - MacOSX Monterey (12.4) with OpenJDK Zulu 17.32.13 (JDK 17.0.2)
  - Ubuntu on Windows 10 with AdoptOpenJDK 11.0.6
  - MSYS2 on Windows 10 with OpenJDK 17.0.3 Server VM Temurin
  - Ubuntu 21.10 with OpenJDK 17.0.3 Server VM

Original README
===============

LuaJava is a scripting tool for Java. The goal of this tool is to allow scripts written in Lua to manipulate components developed in Java. 

It allows Java components to be accessed from Lua using the same syntax that is used for accessing Lua`s native objects, without any need 
for declarations or any kind of preprocessing.  LuaJava also allows Java to implement an interface using Lua. This way any interface can be
implemented in Lua and passed as parameter to any method, and when called, the equivalent function will be called in Lua, and it's result 
passed back to Java.
