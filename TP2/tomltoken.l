%{
#include "y.tab.h"
%}

dig [0-9]

key_regex [A-Za-z0-9_\-]+
string_regex \"[^"]*\"
float_regex {dig}+\.{dig}+
integer_regex {dig}+
boolean_regex (true|false)
date_regex {dig}{4}\-{dig}{2}\-{dig}{2}\ {dig}{2}:{dig}{2}:{dig}{2}

%%
[ \t\n\r] ;

[\=\.\}\{\]\[\,]      { return yytext[0]; }

{boolean_regex}    { yylval.svalue = strdup(yytext); return boolean; }

{integer_regex}    { yylval.ivalue = atoi(yytext); return integer; }

{key_regex}         { yylval.svalue = strdup(yytext); return key; }

{string_regex}     { yylval.svalue = strdup(yytext); return string; }

{float_regex}      { yylval.fvalue = atof(yytext); return yyfloat; }

{date_regex}       { yylval.svalue = strdup(yytext); return date; }

\$                  { return 0; }

.                   { puts("LOL ERRO TOKENS"); return 0; }

%%

//<<EOF>>             { return FIM; }
