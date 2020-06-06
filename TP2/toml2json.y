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

//%token ERRO HALT PRINT READ SHOW IF ELSE 
//%token NOT EQUAL LT LE GT GE
//%token <ivalue> num 
//%token <cvalue> id
//%token <svalue> comentario string
//%type <ivalue> Fator Termo Exp

//%token FIM

// uninon values
%token <svalue> string key boolean date
%token <svalue> integer
%token <svalue> yyfloat

%%

S : SequencePairs '$';


SequencePairs
    : Pair SequencePairs
    |
;

//    | Table SequencePairs
//    | ArrayOfTables SequencePairs

//Table
//    : 
//;


//ArrayOfTables
//    :
//;


InLineTable
    : {printf("{");} '{' InLinable '}' {printf("}\n");}
;


InLinable
    : Pair
    | Pair ',' InLinable
;


List
    :  {printf("[");} '[' Listable ']' {printf("]\n");}
;


Listable
    : Value
    | Value ',' Listable
    | Value ',' {printf("vazio\n");}
;


Pair
    : Key '=' {printf(" = ");} Value
;


Key
    : DotedKey key {printf("%s",$2);}
//    | DotedKey string {printf("%s",$2);}
;


DotedKey
    : Key '.' {printf(".");}
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