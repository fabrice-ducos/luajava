luajava
=======

This is a fork a luajava 2019, updated for Lua 5.4 and modern JDKs.

Starting from JDK 10, the `javah` tool required for JNI is not available anymore, making it impossible
to build old versions of luajava with recent JDKs. This fork makes luajava compatible with JDK 10+,
but still uses `javah` when it is available. Support of JDK 4- has been dropped, in order to get rid
of many obsolete constructs issuing warnings after Java 5.

Another motivation for this work is to make luajava compatible with recent versions of the Lua language.
The low level Lua API has evolved a bit in Lua 5.2, 5.3 and 5.4, making it necessary to update the
Java bindings in order to keep luajava working.

You will need to have a modern JDK (at least JDK 5+, preferrably JDK 8+) and a modern version of Lua (at least 5.4).
Lua must be properly installed, and the environment variable JAVA_HOME must be set to a proper JDK root directory.

This version of LuaJava has been built successfully with Tcl 5.4 and OpenJDK 17.2 on a MacOSX system.
Work is in progress for testing it in other environments (at least one flavour of Linux and one flavour of Windows).

For testing:
`make`
`./build/bin/luajava`

Original README
===============

LuaJava is a scripting tool for Java. The goal of this tool is to allow scripts written in Lua to manipulate components developed in Java. 

It allows Java components to be accessed from Lua using the same syntax that is used for accessing Lua`s native objects, without any need 
for declarations or any kind of preprocessing.  LuaJava also allows Java to implement an interface using Lua. This way any interface can be
implemented in Lua and passed as parameter to any method, and when called, the equivalent function will be called in Lua, and it's result 
passed back to Java.
