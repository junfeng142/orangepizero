# Define compilation type
#OSTYPE	= msys
#OSTYPE	= oda320
#OSTYPE	= odgcw
OSTYPE	?= miyoo

ifeq ($(OSTYPE), oda320)
PRGNAME     = race-od
else
PRGNAME     = race
endif

# define regarding OS, which compiler to use
ifeq ($(OSTYPE), msys)
EXESUFFIX	= .exe
TOOLCHAIN	= /c/MinGW32
CC			= gcc
CCP			= g++
LD			= g++
else ifeq ($(OSTYPE), oda320)
EXESUFFIX = .dge
TOOLCHAIN = /opt/gcw0-toolchain/usr
CC  = $(TOOLCHAIN)/bin/mipsel-gcw0-linux-uclibc-gcc
CCP = $(TOOLCHAIN)/bin/mipsel-gcw0-linux-uclibc-g++
LD  = $(TOOLCHAIN)/bin/mipsel-gcw0-linux-uclibc-g++
else
ifeq ($(OSTYPE), miyoo)
CHAINPREFIX		?=/opt/FunKey-sdk-2.3.0
CROSS_COMPILE	?= $(CHAINPREFIX)/usr/bin/arm-funkey-linux-gnueabihf-
endif
CC				= $(CROSS_COMPILE)gcc
CXX				= $(CROSS_COMPILE)g++
STRIP			= $(CROSS_COMPILE)strip
endif

# add SDL dependencies
SDL_LIB     = $(SYSROOT)/usr/lib
SDL_INCLUDE = $(SYSROOT)/usr/include

# use pkg-config if supported
SYSROOT		?= $(shell $(CC) --print-sysroot)
PKGS		 = sdl SDL_image zlib
PKGS_CFLAGS  = $(shell $(SYSROOT)/../../usr/bin/pkg-config --cflags $(PKGS))
PKGS_LIBS	 = $(shell $(SYSROOT)/../../usr/bin/pkg-config --libs $(PKGS))

# change compilation / linking flag options
ifeq ($(OSTYPE), msys)
F_OPTS = -fpermissive -fno-exceptions -fno-rtti
CC_OPTS = -O2 -g $(F_OPTS)
CFLAGS = -I$(SDL_INCLUDE) -DZ80 -DTARGET_OD -D_MAX_PATH=2048 -DHOST_FPS=60 -DNOUNCRYPT $(CC_OPTS)
CXXFLAGS=$(CFLAGS) 
LDFLAGS     = -L$(SDL_LIB) -lmingw32 -lSDLmain -lSDL -lz -mwindows
else
F_OPTS = -falign-functions -falign-loops -falign-labels -falign-jumps \
	-ffast-math -fsingle-precision-constant -funsafe-math-optimizations \
	-fomit-frame-pointer -fno-builtin -fno-common \
	-fstrict-aliasing  -fexpensive-optimizations \
	-finline -finline-functions -fpeel-loops -fno-exceptions -fno-rtti -fpermissive \
	-fdata-sections -ffunction-sections -fno-PIC
endif
ifeq ($(OSTYPE), oda320)
CC_OPTS		= -Ofast -march=armv5te -mtune=arm926ej-s -msoft-float -DNOUNCRYPT $(F_OPTS)
else ifeq ($(OSTYPE), miyoo)
CC_OPTS		= -Os -march=armv7-a+neon-vfpv4 -mtune=cortex-a7 -mfpu=neon-vfpv4 -mfpu=neon -marm -DNOUNCRYPT $(F_OPTS)
else ifeq ($(OSTYPE), odgcw)
CC_OPTS		= -O2 -mips32 -mhard-float -G0 -DNOUNCRYPT $(F_OPTS)
else
CC_OPTS		= -O2 $(F_OPTS)
endif
ifeq ($(OSTYPE), miyoo)
CFLAGS		= $(PKGS_CFLAGS) -D_OPENDINGUX_ -DZ80 -DTARGET_OD -D_MAX_PATH=2048 -DHOST_FPS=60 $(CC_OPTS)
CXXFLAGS	= $(CFLAGS)
LDFLAGS		= $(PKGS_LIBS)
else
CFLAGS		= -I$(SDL_INCLUDE) -D_OPENDINGUX_ -DZ80 -DTARGET_OD -D_MAX_PATH=2048 -DHOST_FPS=60 $(CC_OPTS)
CXXFLAGS	= $(CFLAGS)
LDFLAGS		= -L$(SDL_LIB) -lstdc++ -lSDL -lSDL_image -lz
endif

# Files to be compiled
SRCDIR	= ./emu ./opendingux .
VPATH	= $(SRCDIR)
SRC_C	= $(foreach dir, $(SRCDIR), $(wildcard $(dir)/*.c))
SRC_CP	= $(foreach dir, $(SRCDIR), $(wildcard $(dir)/*.cpp))
OBJ_C	= $(notdir $(patsubst %.c, %.o, $(SRC_C)))
OBJ_CP	= $(notdir $(patsubst %.cpp, %.o, $(SRC_CP)))
OBJS	= $(OBJ_C) $(OBJ_CP)

# Rules to make executable
$(PRGNAME)$(EXESUFFIX): $(OBJS)
ifeq ($(OSTYPE), msys)
	$(LD) $(CFLAGS) -o $(PRGNAME)$(EXESUFFIX) $^ $(LDFLAGS)
else
	$(CC) $^ -o $(PRGNAME)$(EXESUFFIX) $(LDFLAGS)
endif

%.o: %.c %.cpp
	$(CC) $(CFLAGS) -c -o $@ $<

release: $(PRGNAME)$(EXESUFFIX)
	$(STRIP) $(PRGNAME)$(EXESUFFIX)

ipk: release
	gm2xpkg -i -c -f pkg.cfg

clean:
	rm -f $(PRGNAME)$(EXESUFFIX) *.o
