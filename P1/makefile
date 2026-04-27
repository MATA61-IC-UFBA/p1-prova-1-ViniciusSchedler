bison:
	bison -d prova1.y

flex:
	flex prova1.l

compile:
	gcc -o prova1 prova1.tab.c lex.yy.c main.c

all:
	make bison
	make flex
	make compile

clean:
	rm -f lex.yy.c
	rm -f prova1.tab.*
	rm -f prova1
