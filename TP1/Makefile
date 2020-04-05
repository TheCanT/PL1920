
exec: mkfromtemplate.l
	flex mkfromtemplate.l
	gcc lex.yy.c `pkg-config --cflags --libs glib-2.0` -o mkfromtemplate -ll
	
test: exec
	./mkfromtemplate Programa template_flex

clean:
	rm mkfromtemplate lex.yy.c
	rm -rf Programa
	clear

zip: mkfromtemplate.l template_flex Makefile
	zip G15_TP1_EX1.zip mkfromtemplate.l Makefile template_flex