%option 8bit noyywrap yylineno stack

%{
#include "storedata.h"
#include "y.tab.h"
%}

dig [0-9]
signal [\+\-]



comment_regex #.*



boolean_regex (true|false)



string_key [A-Za-z0-9_\-]+
quote_key \"([^"]|\\\")*\"
apostrophe_key \'([^']|\\\')*\'

/* key_regex ({key}|{key_quotes}) */


quote_string \"([^"]|\\\")*\"
apostrophe_string \'([^']|\\\')*\'
quote_tri_string \'\'\'
apostrophe_tri_string \"\"\"

/* string_regex ({apostrophe_string}|{quote_string}) */



integer {dig}((_)?{dig})*
hex 0x[0-9A-Fa-f]+
oct 0o[0-7]+
bin 0b[01]+

integer_regex ({signal}?{integer}|{hex}|{oct}|{bin})



fractional \.{integer}
exponent [Ee]{signal}?{integer}
inf {signal}?inf
nan {signal}?nan

float_regex ({signal}?{integer}{fractional}?{exponent}?)



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


\= {
    yy_push_state(VALUE);
    return KEY_EQ_VALUE;
}


<VALUE,LIST>{boolean_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return boolean;
}


<VALUE,LIST>{integer_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return integer;
}


<VALUE,LIST>{float_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return yyfloat;
}


<VALUE,LIST>({inf}|{nan}) {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return special_numeric;
}


<VALUE,LIST>{date_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return date;
}


<VALUE,LIST>{apostrophe_string} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return apostrophe_string;
}


<VALUE,LIST>{quote_string} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return quote_string;
}


<VALUE,LIST>{apostrophe_tri_string} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return apostrophe_tri_string;
}


<VALUE,LIST>{quote_tri_string} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return quote_tri_string;
}


<INITIAL>\] {
    return CLOSE_TABLE;
}


<INITIAL>\[ {
    return OPEN_TABLE;
}


<INITIAL>\]\] {
    return CLOSE_ARRAY_OF_TABLES;
}


<INITIAL>\[\[ {
    return OPEN_ARRAY_OF_TABLES;
}


{string_key} {
    yylval.string_value = strdup(yytext);
    return string_key;
}

{quote_key} {
    yylval.string_value = strdup(yytext);
    return quote_key;
}

{apostrophe_key} {
    yylval.string_value = strdup(yytext);
    return apostrophe_key;
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
