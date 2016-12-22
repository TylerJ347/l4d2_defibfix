# (C)2004-2009 SourceMod Development Team
# Makefile written by David "BAILOPAN" Anderson

SMSDK ?= ../sourcemod
SRCDS_BASE ?= ../../../../../_SDK_PLATFORM/srcds
HL2SDK ?= ../hl2sdk
MMSOURCE ?= ../mmsource

ENGINE=left4dead2
#####################################
### EDIT BELOW FOR OTHER PROJECTS ###
#####################################

PROJECT = defibfix

#Uncomment for Metamod: Source enabled extension
USEMETA = true

OBJECTS = smsdk_ext.cpp CDetour/detours.cpp asm/asm.c extension.cpp

##############################################
### CONFIGURE ANY OTHER FLAGS/OPTIONS HERE ###
##############################################

C_OPT_FLAGS = -DNDEBUG -O2 -funroll-loops -pipe -fno-strict-aliasing
C_DEBUG_FLAGS = -D_DEBUG -DDEBUG -g -ggdb3
C_GCC4_FLAGS = -fvisibility=hidden
CPP_GCC4_FLAGS = -fvisibility-inlines-hidden
CPP = gcc

override ENGSET = false

HL2PUB = $(HL2SDK)/public
HL2LIB = $(HL2SDK)/lib/linux
METAMOD = $(MMSOURCE)/core
CFLAGS += -DSOURCE_ENGINE=9
INCLUDE += -I$(HL2SDK)/public/game/server -I$(HL2SDK)/common -I$(HL2SDK)/game/shared
SRCDS = $(SRCDS_BASE)/$(ENGINE)


# Check for valid list of engines
ifneq (,$(filter left4dead2,$(ENGINE)))
	override ENGSET = true
endif


ifeq "$(USEMETA)" "true"
	LINK += $(HL2LIB)/tier1_i486.a $(HL2LIB)/mathlib_i486.a libvstdlib_srv.so libtier0_srv.so

	INCLUDE += -I. -I.. -Isdk -I$(HL2PUB) -I$(HL2PUB)/engine -I$(HL2PUB)/mathlib -I$(HL2PUB)/tier0 \
			-I$(HL2PUB)/tier1 -I$(METAMOD) -I$(METAMOD)/sourcehook -I$(SMSDK)/public -I$(SMSDK)/public/extensions \
			-I$(SMSDK)/sourcepawn/include

	CFLAGS += -DSE_EPISODEONE=1 -DSE_DARKMESSIAH=2 -DSE_ORANGEBOX=3 -DSE_ORANGEBOXVALVE=4 \
		-DSE_LEFT4DEAD=5 -DSE_LEFT4DEAD2=6
else
	INCLUDE += -I. -I.. -Isdk -I$(SMSDK)/public -I$(SMSDK)/sourcepawn/include
endif


LINK += -m32 -lm -ldl

CFLAGS += -D_LINUX -Dstricmp=strcasecmp -D_stricmp=strcasecmp -D_strnicmp=strncasecmp -Dstrnicmp=strncasecmp \
	-D_snprintf=snprintf -D_vsnprintf=vsnprintf -D_alloca=alloca -Dstrcmpi=strcasecmp -Wall -Werror -Wno-switch \
	-Wno-unused -mfpmath=sse -msse -DSOURCEMOD_BUILD -DHAVE_STDINT_H -m32
CPPFLAGS += -Wno-non-virtual-dtor -fno-exceptions -fno-rtti -std=c++11

################################################
### DO NOT EDIT BELOW HERE FOR MOST PROJECTS ###
################################################

ifeq "$(DEBUG)" "true"
	BIN_DIR = Debug
	CFLAGS += $(C_DEBUG_FLAGS)
else
	BIN_DIR = Release
	CFLAGS += $(C_OPT_FLAGS)
endif

ifeq "$(USEMETA)" "true"
	BIN_DIR := $(BIN_DIR).$(ENGINE)
endif

OS := $(shell uname -s)
ifeq "$(OS)" "Darwin"
	LINK += -dynamiclib
	BINARY = $(PROJECT).ext.dylib
else
	LINK += -static-libgcc -shared
	BINARY = $(PROJECT).ext.so
endif

GCC_VERSION := $(shell $(CPP) -dumpversion >&1 | cut -b1)
ifeq "$(GCC_VERSION)" "4"
	CFLAGS += $(C_GCC4_FLAGS)
	CPPFLAGS += $(CPP_GCC4_FLAGS)
endif

OBJ_LINUX := $(OBJECTS:%.cpp=$(BIN_DIR)/%.o)

$(BIN_DIR)/%.o: %.cpp
	$(CPP) $(INCLUDE) $(CFLAGS) $(CPPFLAGS) -o $@ -c $<

all: check
	mkdir -p $(BIN_DIR)
	ln -sf $(SMSDK)/public/smsdk_ext.cpp
	mkdir -p $(BIN_DIR)/CDetour
	ln -sf $(HL2SDK)/lib/linux/libvstdlib_srv.so libvstdlib_srv.so;
	ln -sf $(HL2SDK)/lib/linux/libtier0_srv.so libtier0_srv.so;
	$(MAKE) -f Makefile extension

check:
	if [ "$(USEMETA)" = "true" ] && [ "$(ENGSET)" = "false" ]; then \
		echo "You must supply one of the following values for ENGINE:"; \
		echo "left4dead2, left4dead, orangeboxvalve, orangebox, or original"; \
		exit 1; \
	fi

extension: check $(OBJ_LINUX)
	$(CPP) $(INCLUDE) $(OBJ_LINUX) $(LINK) -o $(BIN_DIR)/$(BINARY)

debug:
	$(MAKE) -f Makefile all DEBUG=true

default: all

clean: check
	rm -rf Debug.*/ Release.*/
