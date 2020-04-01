
exec: mkfromtemplate.l
	flex mkfromtemplate.l
	gcc lex.yy.c `pkg-config --cflags --libs glib-2.0` -o parse_tree -ll
	
test:
	./parse_tree Programa template_flex

clean:
	rm parse_tree lex.yy.c
	rm -rf Programa
	clear

retry:
	make clean
	make exec
	make test