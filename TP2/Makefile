toml2json.exe : y.tab.o lex.yy.o storedata.o
	gcc -o toml2json.exe  storedata.o y.tab.o lex.yy.o `pkg-config --cflags --libs glib-2.0` -ll


y.tab.o : y.tab.c storedata.c storedata.h
	gcc -c y.tab.c storedata.c storedata.h `pkg-config --cflags --libs glib-2.0`


storedata.o : storedata.c storedata.h
	gcc -c `pkg-config --cflags --libs glib-2.0` storedata.c storedata.h


lex.yy.o : lex.yy.c
	gcc -c lex.yy.c


y.tab.c y.tab.h : toml2json.y
	yacc -d toml2json.y


lex.yy.c : tomltoken.l y.tab.h
	flex tomltoken.l


clean :
	rm -rf y.tab.c y.tab.h lex.yy.c *.o *.gch *.exe
