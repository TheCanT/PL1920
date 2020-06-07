%{
#include <stdio.h>
#include <string.h>

extern int yylex();
extern int yylineno;
extern char *yytext;

int yyerror();
int erroSem(char*);
%}

%union{
    float  fvalue;
    int    ivalue;
    char   cvalue;
    char * svalue;
}


%token OPEN_LIST    // '['
%token CLOSE_LIST   // ']'


%token OPEN_IN_LINE_TABLE   // '{'
%token CLOSE_IN_LINE_TABLE  // '}'


%token OPEN_TABLE   // '['
%token CLOSE_TABLE  // ']'


%token OPEN_ARRAY_OF_TABLES     // '[['
%token CLOSE_ARRAY_OF_TABLES    // ']]'


%token KEY_EQ_VALUE     // '='
%token KEY_TOKEN        // '.'
%token SEPARATE_VALUES  // ','


%token END // <<EOF>>


%token <svalue> string key boolean date
%token <svalue> integer
%token <svalue> yyfloat

%%

S
    : SequencePairs END { return 0; }
;


SequencePairs
    : Pair SequencePairs
    | Table SequencePairs
    | ArrayOfTables SequencePairs
    |
;


Table
    : OPEN_TABLE Key CLOSE_TABLE
;


ArrayOfTables
    : OPEN_ARRAY_OF_TABLES Key CLOSE_ARRAY_OF_TABLES
;


InLineTable
    : {printf("{");} OPEN_IN_LINE_TABLE InLinable CLOSE_IN_LINE_TABLE {printf("}\n");}
;


InLinable
    : Pair
    | Pair SEPARATE_VALUES InLinable
;


List
    :  {printf("[");} OPEN_LIST Listable CLOSE_LIST {printf("]\n");}
;


Listable
    : Value
    | Value SEPARATE_VALUES Listable
    | Value SEPARATE_VALUES {printf("vazio\n");}
;


Pair
    : Key KEY_EQ_VALUE {printf(" = ");} Value
;


Key
    : DotedKey key {printf("%s",$2);}
;


DotedKey
    : Key KEY_TOKEN {printf(".");}
    | //passa uma hashtable
;


Value
    : string    {printf("%s\n",$1);}
    | yyfloat   {printf("%s\n",$1);}
    | integer   {printf("%s\n",$1);}
    | boolean   {printf("%s\n",$1);}
    | date      {printf("%s\n",$1);}
    | List
    | InLineTable
;

%%

int main(){
    yyparse();
    return 0;
}

int erroSem(char *s){
    printf("Erro Semântico na linha: %d, %s...\n", yylineno, s);
    return 0;
}

int yyerror(){
    printf("Erro Sintático ou Léxico na linha: %d, com o texto: %s\n", yylineno, yytext);
    return 0;
}