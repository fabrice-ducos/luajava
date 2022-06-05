#
# Makefile for LuaJava Distribution
#

include version.cfg

ifeq (, $(wildcard build.cfg))
$(error build.cfg was not found. It is probably a fresh installation. Please copy build.cfg.dist to build.cfg, check up the file and edit it if necessary, then retry)
endif

include $(shell pwd)/build.cfg

ifeq (, $(wildcard $(JAVA_HOME)/bin/javac))
$(error JAVA_HOME=$(JAVA_HOME) doesn't appear to be set a valid JDK path. Please configure JAVA_HOME in build.cfg, then retry)
endif

#############################################################
JAVAC=$(JAVA_HOME)/bin/javac
JAVAH=$(JAVA_HOME)/bin/javah

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
      LIB_EXT=.dylib
      LIB_OPTION=-shared
      JDK_INC_FLAGS=-I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/darwin
      MAIN_TARGET=run
    endif
    ifeq ($(UNAME_S),Linux)
      LIB_EXT=.so
      LIB_OPTION=-shared
      JDK_INC_FLAGS=-I$(JAVA_HOME)/include -I$(JAVA_HOME)/include/linux
      MAIN_TARGET=run
    endif
endif

LIB_PREFIX=lib
CC= gcc
WARN= -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings
NOWARN= -Wno-unused-parameter -Wno-nested-externs
INCS= $(JDK_INC_FLAGS) $(LUA_INCLUDES)
CFLAGS= $(WARN) $(NOWARN) $(INCS)

JAR=$(JAVA_HOME)/bin/jar

PKG= luajava-$(LUAJAVA_VERSION)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
JAR_FILE= $(BUILD_DIR)/lib/$(PKG).jar
SO_FILE= $(BUILD_DIR)/lib/$(LIB_PREFIX)$(PKG)$(LIB_EXT)
DIST_DIR= $(PKG)

PKGTREE=org/keplerproject/luajava
PKGHEAD=org_keplerproject_luajava
SRCDIR=src/java/$(PKGTREE)
CLASSDIR=src/java/$(PKGTREE)
EXAMPLES_DIR=examples
METAINF=src/java/META-INF
MANIFEST=$(METAINF)/MANIFEST.MF

CLASSES     = \
	$(CLASSDIR)/LuaLib.class \
	$(CLASSDIR)/CPtr.class \
	$(CLASSDIR)/JavaFunction.class \
	$(CLASSDIR)/LuaException.class \
	$(CLASSDIR)/LuaInvocationHandler.class \
	$(CLASSDIR)/LuaJavaAPI.class \
	$(CLASSDIR)/LuaObject.class \
	$(CLASSDIR)/LuaState.class \
	$(CLASSDIR)/LuaStateFactory.class \
	$(CLASSDIR)/Console.class \
	$(CLASSDIR)/LuaJavaScriptEngine.class \
	$(CLASSDIR)/LuaJavaScriptEngineFactory.class

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

.PHONY: install
install: $(PREFIX) $(JAR_FILE) install-so
	cp -a $(BUILD_DIR)/bin/luajava $(PREFIX)/bin/
	cp -a $(JAR_FILE) $(SO_FILE) $(PREFIX)/lib/

.PHONY: maven-install
maven-install:
	mvn install:install-file -Dfile=$(JAR_FILE) -DgroupId=org.keplerproject -DartifactId=luajava -Dversion=$(LUAJAVA_VERSION) -Dpackaging=jar
	@echo "Don't forget to install $(SO_FILE) with '[sudo] make install-so' if it was not done previously (this is not done automatically because this step may require higher permissions)"

.PHONY: install-so
install-so: $(PREFIX) $(SO_FILE)
	cp -a $(SO_FILE) $(PREFIX)/lib/

run: $(EXAMPLES_DIR)
	@echo ------------------
	@echo   Build Complete
	@echo ------------------
	@echo
	$(MAKE) help

help:
	@echo "For testing: $(BUILD_DIR)/bin/luajava"
	@echo "For installing under $(PREFIX): [sudo] make install"
	@echo "For installing the jar in the local maven repo (requires maven): make maven-install"
	@echo "    (maven-install won't install $(SO_FILE), it must be done separately)"
	@echo "For installing $(SO_FILE) under $(PREFIX)/lib: [sudo] make install-so"

$(EXAMPLES_DIR): build
	cd $(EXAMPLES_DIR) && $(MAKE)

build: checkjdk $(BUILD_DIR) $(JAR_FILE) apidoc $(SO_FILE) $(BUILD_DIR)/bin/luajava

$(BUILD_DIR)/bin/luajava: forceit
	sed "s/__LUAJAVA_VERSION__/$(LUAJAVA_VERSION)/" src/bash/luajava.sh > $(BUILD_DIR)/bin/luajava && chmod +x $(BUILD_DIR)/bin/luajava

$(BUILD_DIR):
	mkdir -p "$(BUILD_DIR)" "$(BUILD_DIR)"/bin "$(BUILD_DIR)"/lib

$(PREFIX):
	mkdir -p "$(PREFIX)" "$(PREFIX)"/bin "$(PREFIX)"/lib


#
# Build .class files.
#
.java.class:
	$(JAVAC) $(JAVAC_FLAGS) -sourcepath ./src/java $*.java

#
# Create the JAR
#
$(JAR_FILE): $(BUILD_DIR) $(MANIFEST) $(CLASSES)
	cd src/java && $(JAR) cvfm $(JAR_FILE) META-INF/MANIFEST.MF $(PKGTREE)/*.class META-INF

# forceit forces the manifest to be regenerated at each call of make
$(MANIFEST): forceit
	sed "s/__ENGINE_VERSION__/$(LUAJAVA_VERSION)/;s/__LANGUAGE_VERSION__/$(LUA_VERSION)/" MANIFEST.TEMPLATE > $@

# phony target for forcing some targets to be rebuilt in all cases
.PHONY: forceit
forceit:

#
# Create the API Documentation
#
apidoc:
	$(JAVA_HOME)/bin/javadoc -public -classpath src/java/ -quiet -d "doc/us/API" $(DOC_CLASSES)

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
checkjdk: $(JAVA_HOME)/bin/java

#
# Cleanliness.
#
cleanh:
	rm -f src/c/luajava.h

# for safety reasons, clean hardcoded build (the default value, if it exists) and not $(BUILD_DIR)
cleanb:
	rm -rf build

clean: cleanh cleanb
	rm -f $(JAR_FILE)
	rm -f $(SO_FILE)
	rm -rf doc/us/API
	rm -f $(CLASSDIR)/*.class src/c/*.o
	rm -f $(TAR_FILE) $(ZIP_FILE)
	cd $(EXAMPLES_DIR) && $(MAKE) clean
	rm -f $(MANIFEST)

dist:	dist_dir
	tar -czf $(TAR_FILE) --exclude \*CVS\* --exclude *.class --exclude *.o --exclude *.h --exclude $(TAR_FILE) --exclude $(ZIP_FILE) $(DIST_DIR)
	zip -qr $(ZIP_FILE) $(DIST_DIR)/* -x ./\*CVS\* *.class *.o *.h ./$(TAR_FILE) ./$(ZIP_FILE)

dist_dir:	apidoc
	mkdir -p $(DIST_DIR)
	cp -R src $(DIST_DIR)
	cp -R doc $(DIST_DIR)
	cp -R test $(DIST_DIR)
	cp config License.txt Makefile config.win Makefile.win $(DIST_DIR)

