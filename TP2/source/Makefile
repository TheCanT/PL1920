toml2json.exe : y.tab.o lex.yy.o storedata.o
	gcc -o toml2json y.tab.o lex.yy.o storedata.o `pkg-config --cflags --libs glib-2.0` -ll


y.tab.o : y.tab.c storedata.c storedata.h
	gcc -c y.tab.c storedata.c storedata.h `pkg-config --cflags --libs glib-2.0`


storedata.o : storedata.c storedata.h
	gcc -c `pkg-config --cflags --libs glib-2.0` storedata.c storedata.h


lex.yy.o : lex.yy.c storedata.h
	gcc -c lex.yy.c storedata.h `pkg-config --cflags --libs glib-2.0`


y.tab.c y.tab.h : toml2json.y
	yacc -d toml2json.y


lex.yy.c : tomltoken.l y.tab.h
	flex tomltoken.l


clean :
	rm -rf y.tab.c y.tab.h lex.yy.c *.o *.gch *.exe


zipcode : toml2json.y tomltoken.l storedata.c storedata.h
	zip -o codezip toml2json.y tomltoken.l storedata.c storedata.h


zip_tp2 : ../source ../toml_examples
	zip -o G15_TP2_EX4.zip -r ../source ../toml_examples ../relatorio.pdf