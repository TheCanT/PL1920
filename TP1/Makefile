
exec: mkfromtemplate.l
	flex mkfromtemplate.l
	gcc lex.yy.c `pkg-config --cflags --libs glib-2.0` -o parse_tree -ll
	(cat test_tree | ./parse_tree test_name)

clean:
	rm parse_tree lex.yy.c
	clear