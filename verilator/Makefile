#
#
#

V = verilator
#V = /usr/local/bin/verilator
#V = /usr/local/src/verilator-3.876/bin/verilator

TOP = --top-module pong_verilator
RTL = ../src
ROM = ../roms/v3
INC = +incdir+$(RTL) +incdir+$(CPU) +incdir+$(ROM)

DEFINE = +define+debug=1 +define+SIMULATION=1 
LDFLAGS = " -lSDL2 -lpthread "
EXE = ./tmp/Vpong_verilator
OPT = -O2 
CFLAGS = "-O  -I../../emu/famec"

#V_SRC = \
#	centipede_verilator.v \
#	$(RTL)/centipede.v $(RTL)/p6502.v $(RTL)/pokey.v \
#	$(RTL)/ram.v $(RTL)/rom.v \
#	$(RTL)/color_ram.v $(RTL)/pf_ram.v $(RTL)/pf_rom.v \
#	$(RTL)/pf_ram_dp.v \
#	$(RTL)/vprom.v $(RTL)/hs_ram.v

V_SRC = \
	pong_verilator.v \
	$(RTL)/ay38500NTSC.v 

C_SRC = \
	pong_verilator.cpp vga.cpp 

VOUT = tmp/Vpong_verilator.cpp

all: $(EXE)

$(VOUT): $(V_SRC)  Makefile
	$V -cc $(OPT) -LDFLAGS $(LDFLAGS) -exe --Mdir ./tmp $(DEFINE) $(INC) $(TOP) -CFLAGS $(CFLAGS) $(V_SRC) $(C_SRC)

$(EXE): $(VOUT) $(C_SRC)
	(cd tmp; make -f Vpong_verilator.mk)

clean:
	rm -f tmp/*
