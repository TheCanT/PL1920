toml2json.exe : y.tab.o lex.yy.o
	gcc -o toml2json.exe y.tab.o lex.yy.o -ll

y.tab.o : y.tab.c
	gcc -c y.tab.c

lex.yy.o : lex.yy.c
	gcc -c lex.yy.c

y.tab.c y.tab.h : toml2json.y
	yacc -d toml2json.y

lex.yy.c : tomltoken.l y.tab.h
	flex tomltoken.l

clean :
	rm -rf y.tab.c y.tab.h  *.o lex.yy.c toml2json.exe
