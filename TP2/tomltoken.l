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
string_regex \"([^"]|\\\")*\"



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
    return KEY_TOKEN;
}


<LIST,IN_LINE_TABLE>\, {
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return SEPARATE_VALUES; 
}


<IN_LINE_TABLE>\} {
    yy_pop_state();
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return CLOSE_IN_LINE_TABLE;
}


<VALUE,LIST>\{ {
    yy_push_state(IN_LINE_TABLE);
    return OPEN_IN_LINE_TABLE;
}


<LIST>\] {
    yy_pop_state();
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return CLOSE_LIST;
}


<VALUE,LIST>\[ {
    yy_push_state(LIST);
    return OPEN_LIST;
}


\] {
    return CLOSE_TABLE;
}


\[ {
    return OPEN_TABLE;
}


\]\] {
    return CLOSE_ARRAY_OF_TABLES;
}


\[\[ {
    return OPEN_ARRAY_OF_TABLES;
}


\= {
    yy_push_state(VALUE);
    return KEY_EQ_VALUE;
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
    puts("\nKEY :");
    yylval.svalue = strdup(yytext);
    return key; 
}


{comment_regex} ;


<<EOF>> {
   return END;
}


. {
   puts("LOL ERRO TOKENS");
   return 0;
}

%%
