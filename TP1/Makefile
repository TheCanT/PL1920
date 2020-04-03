
exec: mkfromtemplate.l
	flex mkfromtemplate.l
	gcc lex.yy.c `pkg-config --cflags --libs glib-2.0` -o mkfromtemplate -ll
	
test:
	./mkfromtemplate Programa template_flex

clean:
	rm mkfromtemplate lex.yy.c
	rm -rf Programa
	clear

retry:
	make clean
	make exec
	make test