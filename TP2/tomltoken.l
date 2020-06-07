%option 8bit noyywrap yylineno stack

%{
#include "y.tab.h"
%}

dig [0-9]
signal [\+\-]


comment_regex #.*


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


%s VALUE IN_LINE_TABLE LIST

%%

<VALUE>\n { yy_pop_state(); }


[ \t\n\r] ;


\. {
    return yytext[0];
}


<VALUE,LIST,IN_LINE_TABLE>\, {
    if(YYSTATE == VALUE) yy_pop_state();
    return yytext[0]; 
}


<VALUE,IN_LINE_TABLE>\} {
    yy_pop_state();
    if(YYSTATE == VALUE) yy_pop_state();
    return yytext[0];
}


<VALUE,LIST>\{ {
    yy_push_state(IN_LINE_TABLE);
    return yytext[0];
}


<LIST>\] {
    yy_pop_state();
    if(YYSTATE == VALUE) yy_pop_state();
    return yytext[0];
}


<VALUE>\[ {
    yy_push_state(LIST);
    return yytext[0];
}


\= {
    yy_push_state(VALUE);
    return yytext[0];
}


<VALUE,LIST>{boolean_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    puts("\nBOOL :");
    yylval.svalue = strdup(yytext);
    return boolean;
}


<VALUE,LIST>{integer_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    puts("\nINT :");
    yylval.svalue = strdup(yytext);
    return integer;
}


<VALUE,LIST>{float_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    puts("\nFLOAT :");
    yylval.svalue = strdup(yytext);
    return yyfloat;
}


<VALUE,LIST>{date_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    puts("\nDATE :");
    yylval.svalue = strdup(yytext);
    return date;
}


<VALUE,LIST>{string_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    puts("\nSTR :");
    yylval.svalue = strdup(yytext);
    return string;
}


{key_regex} {
/* <INITIAL,IN_LINE_TABLE>{key_regex} */
    puts("\nKEY :");
    yylval.svalue = strdup(yytext);
    return key; 
}


{comment_regex} ;


\$ {
   return yytext[0];
}


<<EOF>> {
   puts("EOF");
   return '$';
}


. {
   puts("LOL ERRO TOKENS");
   return 0;
}

%%
