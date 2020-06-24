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
apostrophe_key \'[^']*\'



integer {dig}((_)?{dig})*
hex 0x[0-9A-Fa-f]+
oct 0o[0-7]+
bin 0b[01]+

integer_regex {signal}?{integer}



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


%x VALUE IN_LINE_TABLE LIST QUOTE_STR_L APOSTROPHE_STR_L QUOTE_STR APOSTROPHE_STR

%%

<QUOTE_STR>\n {
    yylval.string_value = strdup("\\n");
    return quote_char;
}
<QUOTE_STR>\\ {
    yylval.string_value = strdup("\\");
    return quote_char;
}
<QUOTE_STR>\" {
    yylval.string_value = strdup("\\\"");
    return quote_char;
}
<QUOTE_STR>\\[\n\ ]+ {
    yylval.string_value = "";
    return quote_char;
}

<QUOTE_STR>\"\"\" {
    yy_pop_state();
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return QUOTE_TRI_CLOSE;
}
<VALUE>\"\"\"\n? {
    yy_push_state(QUOTE_STR);
    return QUOTE_TRI_OPEN;
}

<QUOTE_STR_L,QUOTE_STR>\\\" {
    yylval.string_value = strdup(yytext);
    return quote_char;
}
<QUOTE_STR_L>\" {
    yy_pop_state();
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return QUOTE_CLOSE;
}
<VALUE,LIST>\" {
    yy_push_state(QUOTE_STR_L);
    return QUOTE_OPEN;
}

<QUOTE_STR,QUOTE_STR_L>. {
    yylval.string_value = strdup(yytext);
    return quote_char;
}




<APOSTROPHE_STR,APOSTROPHE_STR_L>\\ {
    yylval.string_value = strdup("\\\\");
    return apostrophe_char;
}
<APOSTROPHE_STR,APOSTROPHE_STR_L>\" {
    yylval.string_value = strdup("\\\"");
    return apostrophe_char;
}

<APOSTROPHE_STR>\n {
    yylval.string_value = strdup("\\n");
    return apostrophe_char;
}
<APOSTROPHE_STR>\\\' {
    yylval.string_value = strdup(yytext);
    return apostrophe_char;
}
<APOSTROPHE_STR>[^\'\n] {
    yylval.string_value = strdup(yytext);
    return apostrophe_char;
}
<APOSTROPHE_STR>\'\'\' {
    yy_pop_state();
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return APOSTROPHE_TRI_CLOSE;
}
<VALUE>\'\'\'\n? {
    yy_push_state(APOSTROPHE_STR);
    return APOSTROPHE_TRI_OPEN;
}

<APOSTROPHE_STR_L>\' {
    yy_pop_state();
    if(YYSTATE == VALUE) { yy_pop_state(); }
    return APOSTROPHE_CLOSE;
}
<VALUE,LIST>\' {
    yy_push_state(APOSTROPHE_STR_L);
    return APOSTROPHE_OPEN;
}

<APOSTROPHE_STR,APOSTROPHE_STR_L>. {
    yylval.string_value = strdup(yytext);
    return apostrophe_char;
}




<VALUE>\n { yy_pop_state(); }


<*>[ \t\n\r] ;


<*>\. {
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


<*>\= {
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


<VALUE,LIST>{hex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return hex_numeric;
}


<VALUE,LIST>{oct} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return oct_numeric;
}


<VALUE,LIST>{bin} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return bin_numeric;
}


<VALUE,LIST>{float_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return yyfloat;
}


<VALUE,LIST>({inf}|{nan}) {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return undifined_numeric;
}


<VALUE,LIST>{date_regex} {
    if(YYSTATE == VALUE) yy_pop_state();
    yylval.string_value = strdup(yytext);
    return date;
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


<INITIAL,IN_LINE_TABLE>{string_key} {
    yylval.string_value = strdup(yytext);
    return string_key;
}


<INITIAL,IN_LINE_TABLE>{quote_key} {
    yylval.string_value = strdup(yytext);
    return quote_key;
}


<INITIAL,IN_LINE_TABLE>{apostrophe_key} {
    yylval.string_value = strdup(yytext);
    return apostrophe_key;
}


<INITIAL,LIST,VALUE>{comment_regex} ;


<*><<EOF>> {
   return END;
}


<*>. {
   puts("ERROR TOKEN .l");
   return 0;
}

%%
