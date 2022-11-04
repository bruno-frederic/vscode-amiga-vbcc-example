CC=vc
VASM=vasmm68k_mot
VLINK=vlink
LDFLAGS=-stdlib
CONFIG=+aos68k
ODIR=build-vbcc

EXE=uae/dh0/hello
_OBJ = hello.o mul_by_ten.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))
UAE_CACHE_FILE=bin/configuration.cache bin/winuaebootlog.txt bin/default.uss bin/winuae_*.dmp
MAKEFILE_UPTODATE=$(ODIR)/Makefile.uptodate

# Prepare variables for target 'clean'
ifeq ($(OS),Windows_NT)
	RM:=del
	TOUCH:=COPY /Y NUL
	PATHSEP:=\\
	CONFIG:=${CONFIG}_win
else
	RM:=rm -f
	TOUCH:=touch
	PATHSEP:=/
endif

all: $(MAKEFILE_UPTODATE) $(EXE)

$(EXE) : $(OBJ)
	$(CC) $(CONFIG) -g -v $(OBJ) -o $(EXE)

$(ODIR)/%.o : %.c
	$(CC) $(CONFIG) -g -c -o $@ $<

$(ODIR)/%.o : %.s
	$(VASM) -quiet -m68000 -Fhunk -linedebug -o $@ $<


clean:
	-$(RM) $(ODIR)$(PATHSEP)*.o
	-$(RM) $(subst /,$(PATHSEP),$(EXE))
	-$(RM) $(subst /,$(PATHSEP),$(UAE_CACHE_FILE))
	-$(RM) $(subst /,$(PATHSEP),$(MAKEFILE_UPTODATE))

# Force clean when Makefile is updated :
$(MAKEFILE_UPTODATE): Makefile
	make clean
	$(TOUCH) $(subst /,$(PATHSEP),$@)
