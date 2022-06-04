include ../version.cfg

BUILD_DIR=../build
LIB_DIR=$(BUILD_DIR)/lib
LUAJAVA=$(LIB_DIR)/luajava-$(VERSION).jar
CLASSPATH+=$(LUAJAVA):.
LD_LIBRARY_PATH+=$(LIB_DIR)
DYLD_LIBRARY_PATH=$(LD_LIBRARY_PATH)

JAVAC=javac
JAVAC_FLAGS=-g -cp $(CLASSPATH)
JAVA=java
JAVA_FLAGS=-cp $(CLASSPATH) -Djava.library.path=$(LIB_DIR)

all: hello

hello: Hello.class
	$(JAVA) $(JAVA_FLAGS) Hello

Hello.class: Hello.java
	$(JAVAC) $(JAVAC_FLAGS) $<

clean:
	-rm -f *.class *~

