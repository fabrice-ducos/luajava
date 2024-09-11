#
# Makefile for LuaJava Distribution
#

include version.cfg

ifeq (, $(wildcard build.cfg))
$(error build.cfg was not found. It is probably a fresh installation. Please copy build.cfg.dist to build.cfg, check up the file and edit it if necessary, then retry)
endif

include $(shell pwd)/build.cfg

ifeq (, $(wildcard $(JAVA_HOME)/bin/javac))
$(error JAVA_HOME=$(JAVA_HOME) doesn't appear to be set a valid JDK path. Please configure JAVA_HOME in your environment or build.cfg, then retry (if your JAVA_HOME is set and you still get this message with 'sudo', consider trying 'sudo -E' to preserve your environment))
endif

#############################################################
JAVAC=$(JAVA_HOME)/bin/javac
JAVAH=$(JAVA_HOME)/bin/javah
JAR=$(JAVA_HOME)/bin/jar
JAVADOC=$(JAVA_HOME)/bin/javadoc

NATIVE_DIR=native

# ref. https://stackoverflow.com/questions/714100/os-detecting-makefile
MAIN_TARGET=failed
ifeq ($(OS),Windows_NT)
    # all the commented lines that follow were intended for native Windows (CMD or Powershell)
    # but won't work well with MSYS2. For the time being, only MSYS2 is supported on Windows,
    # GNU make being difficult to use in a portable way on native Windows.
    #
    # the substitution trick converts \ into \\, because \ are not properly
    # managed by some environments (notably MSYS and MSYS2 that remove single slashes);
    # there are possibly other solutions, but this one was simple enough
    JAVA_HOME_SAFE:=$(subst \,\\,$(JAVA_HOME))
    JAVAC=$(JAVA_HOME_SAFE)\\bin\\javac
    JAVAH=$(JAVA_HOME_SAFE)\\bin\\javah
    JAVADOC=$(JAVA_HOME_SAFE)\\bin\\javadoc
    JAR=$(JAVA_HOME_SAFE)\\bin\\jar
    # no lib prefix is expected on Windows for native libraries (dll)
    # https://jornvernee.github.io/java/panama-ffi/panama/jni/native/2021/09/13/debugging-unsatisfiedlinkerrors.html
    LIB_PREFIX=
    LIB_EXT=dll
    NATIVE_SUBDIR=$(NATIVE_DIR)/windows
    LIB_OPTION=-shared
    JDK_INC_FLAGS=-I$(JAVA_HOME_SAFE)\\include -I$(JAVA_HOME_SAFE)\\include\\win32
    MAIN_TARGET=run
    # on MSYS2, HOMEPATH (e.g. C:\Users\Username) != HOME (/home/Username)
    HOMEPATH_SAFE:=$(subst \,/,$(HOMEPATH))
    M2_ROOT=$(HOMEDRIVE)$(HOMEPATH_SAFE)/.m2
    MAKE_ALIAS=cp
else
    UNAME_S := $(shell uname -s)
    UNAME_P := $(shell uname -p)
    OS=$(UNAME_S)
    ifeq ($(UNAME_S),Darwin)
      JAVA_HOME_SAFE=$(JAVA_HOME)
      LIB_PREFIX=lib
      LIB_EXT=dylib
      NATIVE_SUBDIR=$(NATIVE_DIR)/macos
      LIB_OPTION=-shared
      JDK_INC_FLAGS=-I$(JAVA_HOME_SAFE)/include -I$(JAVA_HOME_SAFE)/include/darwin
      MAIN_TARGET=run
      M2_ROOT=$(HOME)/.m2
      MAKE_ALIAS=ln -sf
    endif
    ifeq ($(UNAME_S),Linux)
      JAVA_HOME_SAFE=$(JAVA_HOME)
      LIB_PREFIX=lib
      LIB_EXT=so
      NATIVE_SUBDIR=$(NATIVE_DIR)/linux
      LIB_OPTION=-shared
      JDK_INC_FLAGS=-I$(JAVA_HOME_SAFE)/include -I$(JAVA_HOME_SAFE)/include/linux
      MAIN_TARGET=run
      M2_ROOT=$(HOME)/.m2
      # GNU ln can create relative links with the -r option
      MAKE_ALIAS=ln -sfr
    endif
endif

CC= gcc
WARN= -O2 -Wall -fPIC -W -Waggregate-return -Wcast-align -Wmissing-prototypes -Wnested-externs -Wshadow -Wwrite-strings
NOWARN= -Wno-unused-parameter -Wno-nested-externs
INCS= $(JDK_INC_FLAGS) $(LUA_INCLUDES)
CFLAGS= $(WARN) $(NOWARN) $(INCS)

# For MacOSX only (for native libraries)
JAVA_EXTENSIONS_DIR=$(HOME)/Library/Java/Extensions

PKG=luajava-$(LUAJAVA_VERSION)
TAR_FILE=$(PKG).tar.gz
ZIP_FILE=$(PKG).zip
JAR_FILE=$(BUILD_DIR)/lib/$(PKG).jar
SO_BASE=$(LIB_PREFIX)$(PKG).$(LIB_EXT)
SO_FILE=$(BUILD_DIR)/lib/$(SO_BASE)
SO_FILE_IN_NATIVE=$(NATIVE_SUBDIR)/$(SO_BASE)
DIST_DIR=$(PKG)
M2_TARGET_DIR=$(M2_ROOT)/repository/org/keplerproject/luajava/$(LUAJAVA_VERSION)

TOP_DIR=$(shell pwd)
PKGTREE=org/keplerproject/luajava
PKGHEAD=org_keplerproject_luajava
SRCDIR=$(TOP_DIR)/src/main/java/$(PKGTREE)
CLASSDIR=$(TOP_DIR)/src/main/java/$(PKGTREE)
EXAMPLES_DIR=$(TOP_DIR)/examples
RESOURCES_DIR=$(TOP_DIR)/src/main/resources
METAINF=$(RESOURCES_DIR)/META-INF
MANIFEST=$(METAINF)/MANIFEST.MF

CLASSES     = \
	$(CLASSDIR)/ManifestUtil.class \
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

OBJS        = src/main/c/luajava.o
.SUFFIXES: .java .class

.PHONY: run examples build cleanh cleanb clean checkjdk dist dist_dir

#
# Targets
#

start: $(MAIN_TARGET)

failed:
	@echo "System $(OS) not recognized or not supported for the time being"

.PHONY: install
install: $(PREFIX) $(JAR_FILE) install-lib install-exe

.PHONY: install-exe
install-exe:
	cp -a $(BUILD_DIR)/bin/luajava $(PREFIX)/bin/

.PHONY: install-lib
install-lib:
	cp -a $(JAR_FILE) $(PREFIX)/lib/

.PHONY: install-dylib
install-dylib: $(JAVA_EXTENSIONS_DIR)
	cp -a $(SO_FILE) $<

$(JAVA_EXTENSIONS_DIR):
	mkdir -p "$(HOME)/Library/Java/Extensions"

.PHONY: uninstall
uninstall:
	-rm -i "$(PREFIX)/bin/luajava"
	-rm -i "$(PREFIX)/lib"/*luajava*

.PHONY: maven-install
maven-install: maven-install-jar

# the extra level (libluajava for the artifactId, instead of simply stopping at luajava), allows to store
# the .jar and the native library (.dll, .so or .dylib) in the same directory;
# without this level, the native library would be renamed by Maven 'luajava-x.y.so' (based on the artifactId), 
# instead of 'libluajava-x.y.so', leading to linkage errors.
maven-install-jar:
	mvn install:install-file -Dfile=$(JAR_FILE) -DgroupId=org.keplerproject -DartifactId=luajava -Dversion=$(LUAJAVA_VERSION) -Dpackaging=jar	

.PHONY: maven-uninstall
maven-uninstall:
	-rm -rfv $(M2_ROOT)/repository/org/keplerproject/luajava

.PHONY: run
run: $(EXAMPLES_DIR)
	@echo ------------------
	@echo   Build Complete
	@echo ------------------
	@echo
	$(MAKE) help

.PHONY: help
help:
	@echo "For testing: $(BUILD_DIR)/bin/luajava"
	@echo "For installing under $(PREFIX): [sudo -E] make install (will install the executable and the libraries)"
	@echo "For installing the executable only: [sudo -E] make install-exe (handy if the libraries have been installed with maven)"
	@echo "For installing the libraries only: [sudo -E] make install-lib"
	@echo "For installing luajava in the local maven repo (requires maven): make maven-install"
	@echo
	@echo "For uninstalling under $(PREFIX): [sudo -E] make uninstall"
	@echo "For uninstalling from the local maven repo: make maven-uninstall"
	@echo
	@echo "Detected configuration:"
	@echo "OS: $(OS)"
	@echo "JAVA_HOME: $(JAVA_HOME_SAFE)"
	@echo "PREFIX: $(PREFIX)"
	@echo "M2_ROOT: $(M2_ROOT)"
	@echo ""
	@echo "NOTE: the -E in [sudo -E] is needed if you want to preserve your user's environment with superuser's permissions"

$(EXAMPLES_DIR): build
	cd $(EXAMPLES_DIR) && $(MAKE)

.PHONY: build
build: checkjdk $(BUILD_DIR) $(JAR_FILE) apidoc $(SO_FILE_IN_NATIVE) $(BUILD_DIR)/bin/luajava

# one uses pipes (|) in the second sed substitution command because M2_ROOT is a path that
# contains / or \.
#
$(BUILD_DIR)/bin/luajava: forceit
	sed "s/__LUAJAVA_VERSION__/$(LUAJAVA_VERSION)/;s|__M2_ROOT__|$(M2_ROOT)|" src/main/bash/luajava.sh > $(BUILD_DIR)/bin/luajava && chmod +x $(BUILD_DIR)/bin/luajava

$(BUILD_DIR):
	mkdir -p "$(BUILD_DIR)" "$(BUILD_DIR)"/bin "$(BUILD_DIR)"/lib

$(PREFIX): forceit
	mkdir -p "$(PREFIX)" "$(PREFIX)"/bin "$(PREFIX)"/lib


#
# Build .class files.
#
.java.class:
	$(JAVAC) $(JAVAC_FLAGS) -sourcepath ./src/main/java $*.java

#
# Create the JAR
#
$(JAR_FILE): $(BUILD_DIR) $(MANIFEST) $(CLASSES)
	cd src/main/java && $(JAR) cvfm $(JAR_FILE) $(MANIFEST) $(PKGTREE)/*.class -C $(RESOURCES_DIR) META-INF && cd - && $(JAR) -uf $(JAR_FILE) $(NATIVE_DIR)

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
	$(JAVADOC) -public -classpath src/main/java/ -quiet -d "doc/us/API" $(DOC_CLASSES)

$(SO_FILE_IN_NATIVE): $(SO_FILE)
	cp $< $@ && cd $(NATIVE_SUBDIR)

#
# Build .c files.
#
#$(SO_FILE): $(OBJS)
#	export MACOSX_DEPLOYMENT_TARGET=10.3; $(CC) $(LIB_OPTION) -o $@ $? $(LIB_LUA)

$(SO_FILE): $(OBJS)
	$(CC) $(LIB_OPTION) -o $@ $? $(LIB_LUA)

src/main/c/luajava.c: src/main/c/luajava.h

src/main/c/luajava.h:
	test -x $(JAVAH) && $(JAVAH) -o src/main/c/luajava.h -classpath "$(JAR_FILE)" org.keplerproject.luajava.LuaState || \
	( $(JAVAC) -cp "$(JAR_FILE)" -h src/main/c $(SRCDIR)/LuaState.java && mv src/main/c/$(PKGHEAD)_LuaState.h src/main/c/luajava.h )

## regras implicitas para compilacao

$(OBJDIR)/%.o:  %.c
	$(CC) -c $(CFLAGS) -o $@ $<

#
# Check that the user has a valid JDK install.  This will cause a
# premature death if JDK is not defined.
#
checkjdk: $(JAVA_HOME_SAFE)/bin/java

#
# Cleanliness.
#
cleanh:
	rm -f src/main/c/luajava.h

# for safety reasons, clean hardcoded build (the default value, if it exists) and not $(BUILD_DIR)
cleanb:
	rm -rf build

clean: cleanh cleanb
	rm -f $(JAR_FILE)
	rm -f $(SO_FILE)
	rm -rf doc/us/API
	rm -f $(CLASSDIR)/*.class src/main/c/*.o
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

