%{
#include "y.tab.h"
//%x VALUE PAIR
%}


dig [0-9]
signal [\+\-]


comment_regex #.*$


boolean_regex (true|false)

key [A-Za-z0-9_\-]+
key_quotes \"[^"]*\"

key_regex ({key}|{key_quotes})


/* STRINGS POR ACABAR */
string_regex \"[^"]*\"


integer {dig}((_)?{dig})*
hex 0x[0-9A-Fa-f]+
oct 0o[0-7]+
bin 0b[01]+

integer_regex ({signal}?{integer}|{hex}|{oct}|{bin})


fractional \.{integer}
exponent [Ee]{signal}?{integer}
inf {signal}?inf
nan {signal}?nan

float_regex ({signal}?{integer}{fractional}?{exponent}?|{inf}|{nan})


offset {dig}{2}:{dig}{2}
local_date {dig}{4}\-{dig}{2}\-{dig}{2}
local_time {dig}{2}:{dig}{2}:{dig}{2}(\.{dig}{6})?
local_date_time {local_date}T{local_time}
offset_date_time {local_date_time}(Z|\-{offset})

date_regex ({local_date}|{local_time}|{local_date_time}|{offset_date_time})

/* NAO ERA MÁ IDEIA USAR TOKENS PARA O pair = key value .... */

/* ESTOU A TER UM ERRO QUE TEM HAVER COM key_regex PODE SOBRE PÔR POR float_regex 
   TAMBEM COM date_regex  PROVAVELMENTE TAMBEM IRÀ DAR COM string_regex */
%%
[ \t\n\r] ;

[\.\,]    { return yytext[0]; }

\} { return yytext[0]; }

\{ { return yytext[0]; }
   
\] { return yytext[0]; }

\[ { return yytext[0]; }

\= { return yytext[0]; }

{boolean_regex}     { puts("\nBOOL :"); yylval.svalue = strdup(yytext); return boolean; }

{integer_regex}     { puts("\nINT :"); yylval.svalue = strdup(yytext); return integer; }

{float_regex}       { puts("\nFLOAT :"); yylval.svalue = strdup(yytext); return yyfloat; }

{date_regex}        { puts("\nDATE :"); yylval.svalue = strdup(yytext); return date; }

{key_regex}         { puts("\nKEY :"); yylval.svalue = strdup(yytext); return key; }

{string_regex}      { puts("\nSTR :"); yylval.svalue = strdup(yytext); return string; }

{comment_regex} ;

\$                  { return yytext[0]; }

<<EOF>>             { puts("EOF"); return '$'; }

.                   { puts("LOL ERRO TOKENS"); return 0; }

%%

//<<EOF>>             { return FIM; }
