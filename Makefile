#
# Makefile for LuaJava Distribution
#

include ./config

#############################################################
JAVAC=$(JDK)/bin/javac
JAVAH=$(JDK)/bin/javah

# ref. https://stackoverflow.com/questions/714100/os-detecting-makefile
MAIN_TARGET=failed
ifeq ($(OS),Windows_NT)
    # system not yet supported
    MAIN_TARGET=failed
else
    UNAME_S := $(shell uname -s)
    UNAME_P := $(shell uname -p)
    OS=$(UNAME_S)
    ifeq ($(UNAME_S),Darwin)
      LIB_LUA=-L$(LUA_LIBDIR) -llua
      LIB_EXT=.dylib
      LIB_OPTION=-shared
      JDK_INC_FLAGS=-I$(JDK)/include -I$(JDK)/include/darwin
      MAIN_TARGET=run
    endif
    ifeq ($(UNAME_S),Linux)
      LIB_LUA=-L$(LUA_LIBDIR) -llua -lm -ldl
      LIB_EXT=.so
      LIB_OPTION=-shared
      JDK_INC_FLAGS=-I$(JDK)/include -I$(JDK)/include/linux
      MAIN_TARGET=run
    endif
endif

LIB_PREFIX=lib
CC= gcc
WARN= -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings
NOWARN= -Wno-unused-parameter -Wno-nested-externs
INCS= $(JDK_INC_FLAGS) -I$(LUA_INCLUDES)
CFLAGS= $(WARN) $(NOWARN) $(INCS)

PKG= luajava-$(VERSION)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
JAR_FILE= $(PKG).jar
SO_FILE= $(LIB_PREFIX)$(PKG)$(LIB_EXT)
DIST_DIR= $(PKG)

PKGTREE=org/keplerproject/luajava
PKGHEAD=org_keplerproject_luajava
SRCDIR=src/java/$(PKGTREE)
CLASSDIR=src/java/$(PKGTREE)
EXAMPLES_DIR=examples

CLASSES     = \
	$(CLASSDIR)/CPtr.class \
	$(CLASSDIR)/JavaFunction.class \
	$(CLASSDIR)/LuaException.class \
	$(CLASSDIR)/LuaInvocationHandler.class \
	$(CLASSDIR)/LuaJavaAPI.class \
	$(CLASSDIR)/LuaObject.class \
	$(CLASSDIR)/LuaState.class \
	$(CLASSDIR)/LuaStateFactory.class \
	$(CLASSDIR)/Console.class

DOC_CLASSES	= \
	$(SRCDIR)/JavaFunction.java \
	$(SRCDIR)/LuaException.java \
	$(SRCDIR)/LuaInvocationHandler.java \
	$(SRCDIR)/LuaObject.java \
	$(SRCDIR)/LuaState.java \
	$(SRCDIR)/LuaStateFactory.java \
	$(SRCDIR)/Console.java

OBJS        = src/c/luajava.o
.SUFFIXES: .java .class

.PHONY: run examples build cleanh cleanb clean checkjdk dist dist_dir

#
# Targets
#

start: $(MAIN_TARGET)

failed:
	@echo "System $(OS) not recognized or not supported for the time being"

run: examples
	@echo ------------------
	@echo Build Complete
	@echo ------------------

examples: $(EXAMPLES_DIR)

$(EXAMPLES_DIR): build
	cd $(EXAMPLES_DIR) && $(MAKE)

build: checkjdk $(JAR_FILE) apidoc $(SO_FILE)
	mkdir -p $(BUILD_DIR)/lib && mv $(JAR_FILE) $(SO_FILE) $(BUILD_DIR)/lib
	mkdir -p $(BUILD_DIR)/bin && cp src/luajava.sh $(BUILD_DIR)/bin/luajava

#
# Build .class files.
#
.java.class:
	$(JAVAC) $(JAVAC_FLAGS) -sourcepath ./src/java $*.java

#
# Create the JAR
#
$(JAR_FILE): $(CLASSES)
	cd src/java; \
	$(JDK)/bin/jar cvf ../../$(JAR_FILE) $(PKGTREE)/*.class; \
	cd ../..;
  
#
# Create the API Documentation
#
apidoc:
	$(JDK)/bin/javadoc -public -classpath src/java/ -quiet -d "doc/us/API" $(DOC_CLASSES)

#
# Build .c files.
#
#$(SO_FILE): $(OBJS)
#	export MACOSX_DEPLOYMENT_TARGET=10.3; $(CC) $(LIB_OPTION) -o $@ $? $(LIB_LUA)

$(SO_FILE): $(OBJS)
	$(CC) $(LIB_OPTION) -o $@ $? $(LIB_LUA)

src/c/luajava.c: src/c/luajava.h

src/c/luajava.h:
	test -x $(JAVAH) && $(JAVAH) -o src/c/luajava.h -classpath "$(JAR_FILE)" org.keplerproject.luajava.LuaState || \
	( $(JAVAC) -cp "$(JAR_FILE)" -h src/c $(SRCDIR)/LuaState.java && mv src/c/$(PKGHEAD)_LuaState.h src/c/luajava.h )
  

## regras implicitas para compilacao

$(OBJDIR)/%.o:  %.c
	$(CC) -c $(CFLAGS) -o $@ $<

#
# Check that the user has a valid JDK install.  This will cause a
# premature death if JDK is not defined.
#
checkjdk: $(JDK)/bin/java

#
# Cleanliness.
#
cleanh:
	rm -f src/c/luajava.h

cleanb:
	rm -rf ./$(BUILD_DIR)

clean: cleanh cleanb
	rm -f $(JAR_FILE)
	rm -f $(SO_FILE)
	rm -rf doc/us/API
	rm -f $(CLASSDIR)/*.class src/c/*.o
	rm -f $(TAR_FILE) $(ZIP_FILE)
	cd $(EXAMPLES_DIR) && $(MAKE) clean

dist:	dist_dir
	tar -czf $(TAR_FILE) --exclude \*CVS\* --exclude *.class --exclude *.o --exclude *.h --exclude $(TAR_FILE) --exclude $(ZIP_FILE) $(DIST_DIR)
	zip -qr $(ZIP_FILE) $(DIST_DIR)/* -x ./\*CVS\* *.class *.o *.h ./$(TAR_FILE) ./$(ZIP_FILE)

dist_dir:	apidoc
	mkdir -p $(DIST_DIR)
	cp -R src $(DIST_DIR)
	cp -R doc $(DIST_DIR)
	cp -R test $(DIST_DIR)
	cp config License.txt Makefile config.win Makefile.win $(DIST_DIR)

