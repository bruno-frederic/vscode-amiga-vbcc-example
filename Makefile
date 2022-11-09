# Doc sur GNU Make : https://www.gnu.org/software/make/manual/html_node/index.html
# Sur les variables par défaut :
# https://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html#Automatic-Variables

CC=vc
VASM=vasmm68k_mot
VLINK=vlink
LDFLAGS=-stdlib
CONFIG=+aos68k
ODIR=build-vbcc

# Options nécessaire en plus pour Avalanche :
INCLUDE_PATHS=-I../lib/xad/Include/C -I../lib/xfd/Include/C -I../lib/xvs/Developer/C
EXE=uae/dh0/Avalanche
_OBJ = avalanche.o libs.o locale.o req.o xad.o xfd.o xvs.o
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

# Linking avec le frontend VC aussi.
# C'est équivalent à la commande VLINK de prb28 (j'ai comparé les EXE produit avec winmerge)
$(EXE) : $(OBJ)
	$(CC) $(CONFIG) -g -v $(OBJ) -lamiga -o $(EXE)
#	                                   -o file → Save the target as file (default for exes is a.out)
#	                                      $(EXE) ou $@ → The filename of the target of the rule (variable Make)
#	                           -lamiga → This option specifies a library to be considered for
#	                                     inclusion in the output.
#	                     $(OBJ) ou $^ → les fichiers $(OBJ) en dépendance (variable Make)
#	               +file  → Use file as VC config-file
#			-g → Create debug output. Lors de l'appel au linker, cela évite d'ajouter les options
#	             définies dans la config VC sous -ldnodb, qui retire les symbôles du fichier généré.
#	      -v → légèrement verbeux, pour voir avec quel params VC appelle VLink

# Si on rajoute l'argument -nostdlib à VC, alors dans la configuration VC, c'est avec la commande
# -l2 que VLink sera appelée au lieu de -ld.
# -l2 → pas de code de démarrage startup.o/minstart.o ou autre ni de -lvc (librairice C principale)
# Attention à la confusion avec le parmaètre -nostdlib pour VLink qui est spécifié par toutes les
# configurations VC → Ignore le default library search path, si un a été compilé dans vlink.exe
# pour voir le default library search path : vlink.exe -v

# Avec cette commande, VC appelera VLink comme ceci :
# vlink -bamigahunk -x -Bstatic -Cvbcc -nostdlib -mrel bin/targets/m68k-amigaos/lib/startup.o "build-vbcc\avalanche.o" (...) "build-vbcc\xvs.o"   -lamiga -Lbin/targets/m68k-amigaos/lib -lvc -o uae\dh0\Avalanche
#                                                                                                                                                                                        -lvc → link avec vc.lib qui est la librairie C principale de VBCC
#	                                                                                                                                                                                            Par défaut dans les config de link -ld (mais pas dans -ld2)
#	                                                                                                                                                       -Lpath → Add path to the list of directories to search for libraries specified with the -l option.
#                                                                                                                                                                   When a default search path was compiled in (see vlink.exe -v), then it is searched last, before finally looking into the local directory.
#	                                                                                                                                                                targets/m68k-amigaos/lib → par défaut dans les configs VC aos68k. différent pour les configs kick13
#                                                       startup.o → le code de démarrage pour l'EXE¹
#                                                -mrel → Automatically merge sections, when there
#                                                        are PC-relative references between them.
#                                                        c'était automatiquement fait auparavant par
#                                                        le linker. Désormais il faut le spécifier :
#                                                 https://github.com/Sakura-IT/SonnetAmiga/issues/27
#                                      -nostdlib → Ignore le default library search path, si un path
#                                                  a été compilé dans vlink.exe
#                                                  Par défaut dans toutes les configs VC
#	                                  -C constructor-type → Defines the type of constructor/destructor function names to scan for.
#	                                     vbcc → vbcc style constructors: __INIT[_<pri>]_<name> / __EXIT..
#												Par défaut dans les configs VC aos68k et kick13
#							-Bstatic → This option turns off dynamic linking for all library specifiers until a -Bdynamic is once again given. Any explicitly mentioned shared object encountered on the command line while this option is in effect is flagged as an error.
#	                                   Par défaut dans les configs VC aos68k et kick13
#	                     -x → Discard all local symbols in the input files.
#							  Par défaut dans les configs VC aos68k et kick13
#	         -b targetname → Specifies target file format for the output file.
#	            amigahunk → The AmigaDos hunk format for M68k. Requires AmigaOS 2.04 with -Rshort.
#							Par défaut dans les configs VC aos68k et kick13
#
# Notes :
# ¹ le code de démarrage fait les initialisations puis appelle __main.
#   startup.o par défaut dans les configs VC aos68k et kick13.
#	minstart.o et minres.o dans les configs aos68km et aos68kr et dans ce cas moins d'initialisation
#   sont faites et plus petit exécutable

# prb28 n'utilise pas VC et ses configs, il appelle directement vlink :
# il faut rajouter -lamiga pour linker correctement Avalanche
#	$(VLINK) -bamigahunk -x -Bstatic -Cvbcc -nostdlib $(VBCC)/targets/m68k-amigaos/lib/startup.o $(OBJ) -L$(VBCC)/targets/m68k-amigaos/lib -lvc -o $(EXE)


# Compilation des fichiers C
$(ODIR)/%.o : ../Avalanche/src/%.c
	$(CC) $(CONFIG) -g -c99 $(INCLUDE_PATHS) -c -o $@ $<
#	                                        -c → do not link. Save the compiled files with .o suffix
#	                    -c99 → Set the C standard to be used.
#	                           The default is the 1999 ISO C standard (ISO/IEC9899:1999).
#                   -g → Create debug output.



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
