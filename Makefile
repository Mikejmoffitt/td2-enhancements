AS=asl
P2BIN=p2bin
SRC=patch.s
BSPLIT=bsplit
MAME=mame
ROMDIR=/home/moffitt/.mame/roms/

ASFLAGS=-i . -n -U -g

.PHONY: game_prg

all: game_prg

prg.orig:
	cp 6.rom prg.orig

game_prg:
	$(BSPLIT) x prg.orig prg.sw
	$(AS) $(SRC) $(ASFLAGS) -o prg.o
	$(P2BIN) prg.o 6.sw -r \$$-0x7FFFF
	rm prg.sw
	$(BSPLIT) x 6.sw 6.rom

test: game_prg
	$(MAME) -debug tdragon2

clean:
	@-cp prg.orig 6.rom
	@-rm prg.bin
	@-rm prg.o
