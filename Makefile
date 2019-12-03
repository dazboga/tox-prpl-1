
PIDGIN_TREE_TOP ?= ../pidgin-2.10.11
PIDGIN3_TREE_TOP ?= ../pidgin-main
LIBPURPLE_DIR ?= $(PIDGIN_TREE_TOP)/libpurple
WIN32_DEV_TOP ?= $(PIDGIN_TREE_TOP)/../win32-dev
LIBTOXCORE_DIR ?= ./libtoxcore

WIN32_CC ?= $(WIN32_DEV_TOP)/mingw-4.7.2/bin/gcc
MAKENSIS ?= makensis

PKG_CONFIG ?= pkg-config

CFLAGS	?= -O2 -g -pipe
LDFLAGS ?= 

# Do some nasty OS and purple version detection
ifeq ($(OS),Windows_NT)
  #only defined on 64-bit windows
  PROGFILES32 = ${ProgramFiles(x86)}
  ifndef PROGFILES32
    PROGFILES32 = $(PROGRAMFILES)
  endif
  TOXPRPL_TARGET = libtoxprpl.dll
  TOXPRPL_DEST = "$(PROGFILES32)/Pidgin/plugins"
  TOXPRPL_ICONS_DEST = "$(PROGFILES32)/Pidgin/pixmaps/pidgin/protocols"
  MAKENSIS = "$(PROGFILES32)/NSIS/makensis.exe"
else

  UNAME_S := $(shell uname -s)

  #.. There are special flags we need for OSX
  ifeq ($(UNAME_S), Darwin)
    #
    #.. /opt/local/include and subdirs are included here to ensure this compiles
    #   for folks using Macports.  I believe Homebrew uses /usr/local/include
    #   so things should "just work".  You *must* make sure your packages are
    #   all up to date or you will most likely get compilation errors.
    #
    INCLUDES = -I/$(LIBTOXCORE_DIR)/include  -I/opt/local/include -lz $(OS)

    CC = gcc
  else
    INCLUDES = -I/$(LIBTOXCORE_DIR)/include
    CC ?= gcc
  endif

  ifeq ($(shell $(PKG_CONFIG) --exists purple-3 2>/dev/null && echo "true"),)
    ifeq ($(shell $(PKG_CONFIG) --exists purple 2>/dev/null && echo "true"),)
      TOXPRPL_TARGET = FAILNOPURPLE
      TOXPRPL_DEST =
	  TOXPRPL_ICONS_DEST =
    else
      TOXPRPL_TARGET = libtoxprpl.so
      TOXPRPL_DEST = $(DESTDIR)`$(PKG_CONFIG) --variable=plugindir purple`
	  TOXPRPL_ICONS_DEST = $(DESTDIR)`$(PKG_CONFIG) --variable=datadir purple`/pixmaps/pidgin/protocols
    endif
  else
    TOXPRPL_TARGET = libtoxprpl3.so
    TOXPRPL_DEST = $(DESTDIR)`$(PKG_CONFIG) --variable=plugindir purple-3`
	TOXPRPL_ICONS_DEST = $(DESTDIR)`$(PKG_CONFIG) --variable=datadir purple-3`/pixmaps/pidgin/protocols
  endif
endif

WIN32_CFLAGS = -I$(WIN32_DEV_TOP)/glib-2.28.8/include -I$(WIN32_DEV_TOP)/glib-2.28.8/include/glib-2.0 -I$(WIN32_DEV_TOP)/glib-2.28.8/lib/glib-2.0/include -I$(LIBTOXCORE_DIR)/include -DENABLE_NLS -DPACKAGE_VERSION='"$(PLUGIN_VERSION)"' -Wall -Wextra -Werror -Wno-deprecated-declarations -Wno-unused-parameter -fno-strict-aliasing -Wformat
WIN32_LDFLAGS = -L$(WIN32_DEV_TOP)/glib-2.28.8/lib -L$(LIBTOXCORE_DIR)/lib -lpurple -lintl -lglib-2.0 -lgobject-2.0 -lsodium -lvpx -ltoxcore -lsodium -lws2_32 -pthread -liphlpapi -ladvapi32 -g -ggdb -static-libgcc -lz
WIN32_PIDGIN2_CFLAGS = -I$(PIDGIN_TREE_TOP)/libpurple -I$(PIDGIN_TREE_TOP) $(WIN32_CFLAGS)
WIN32_PIDGIN3_CFLAGS = -I$(PIDGIN3_TREE_TOP)/libpurple -I$(PIDGIN3_TREE_TOP) -I$(WIN32_DEV_TOP)/gplugin-dev/gplugin $(WIN32_CFLAGS)
WIN32_PIDGIN2_LDFLAGS = -L$(PIDGIN_TREE_TOP)/libpurple $(WIN32_LDFLAGS)
WIN32_PIDGIN3_LDFLAGS = -L$(PIDGIN3_TREE_TOP)/libpurple -L$(WIN32_DEV_TOP)/gplugin-dev/gplugin $(WIN32_LDFLAGS) -lgplugin

PURPLE_COMPAT_FILES := 
PURPLE_C_FILES := src/toxprpl.c



.PHONY:	all install FAILNOPURPLE clean

all: $(TOXPRPL_TARGET)

libtoxprpl.so: $(PURPLE_C_FILES) $(PURPLE_COMPAT_FILES)
	$(CC) -fPIC $(CFLAGS) -DVERSION="$(VERSION)" -DPACKAGE_URL="$(PACKAGE_URL)" -shared -o $@ $^ $(LDFLAGS) `$(PKG_CONFIG) purple glib-2.0 zlib toxcore --libs --cflags` -ldl $(INCLUDES) -Ipurple2compat -g -ggdb

libtoxprpl3.so: $(PURPLE_C_FILES)
	$(CC) -fPIC $(CFLAGS) -DVERSION="$(VERSION)" -DPACKAGE_URL="$(PACKAGE_URL)" -shared -o $@ $^ $(LDFLAGS) `$(PKG_CONFIG) purple-3 glib-2.0 zlib toxcore --libs --cflags` -ldl $(INCLUDES) -g -ggdb

toxcore_compat.o: src/toxcore_compat.c
	$(WIN32_CC) -c $^ -static -o $@

libtoxcore_compat.a: src/toxcore_compat.o
	ar -rc $@ $^

libtoxprpl.dll: toxcore_compat.o $(PURPLE_C_FILES) $(PURPLE_COMPAT_FILES)
	$(WIN32_CC) -DVERSION="$(VERSION)" -DPACKAGE_URL="$(PACKAGE_URL)" -shared -o $@ -L. -ltoxcore_compat $^ $(WIN32_PIDGIN2_CFLAGS) $(WIN32_PIDGIN2_LDFLAGS) -Ipurple2compat

libtoxprpl3.dll: $(PURPLE_C_FILES)
	$(WIN32_CC) -DVERSION="$(VERSION)" -DPACKAGE_URL="$(PACKAGE_URL)" -shared -o $@ $^ $(WIN32_PIDGIN3_CFLAGS) $(WIN32_PIDGIN3_LDFLAGS)

install: $(TOXPRPL_TARGET) install-icons
	mkdir -p $(TOXPRPL_DEST)
	install -p $(TOXPRPL_TARGET) $(TOXPRPL_DEST)

install-icons: pixmaps/protocols/16/tox.png pixmaps/protocols/22/tox.png pixmaps/protocols/48/tox.png
	mkdir -p $(TOXPRPL_ICONS_DEST)/16
	mkdir -p $(TOXPRPL_ICONS_DEST)/22
	mkdir -p $(TOXPRPL_ICONS_DEST)/48
	install pixmaps/protocols/16/tox.png $(TOXPRPL_ICONS_DEST)/16/tox.png
	install pixmaps/protocols/22/tox.png $(TOXPRPL_ICONS_DEST)/22/tox.png
	install pixmaps/protocols/48/tox.png $(TOXPRPL_ICONS_DEST)/48/tox.png

FAILNOPURPLE:
	echo "You need libpurple development headers installed to be able to compile this plugin"

clean:
	rm -f $(TOXPRPL_TARGET)


installer: nsis/tox-prpl.nsi
	$(MAKENSIS) nsis/tox-prpl.nsi
