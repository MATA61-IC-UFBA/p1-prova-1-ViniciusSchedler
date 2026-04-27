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
	rm lex.yy.c
	rm prova1.tab.*
	rm prova1
