main:	game.s game.cfg
	ca65 game.s
	ld65 game.o -C game.cfg -o game.nes

run:	game.nes
	fceux game.nes

clean:
	rm -fr *.o
	rm -fr *.nes

