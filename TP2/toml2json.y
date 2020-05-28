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

S : Pair '$';


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
    ;


Pair 
    : Key '=' Value
    ;


Key 
    : key {printf("%s",$1);} DotedKey {printf(" = ");}
    ;

// maybe try to fix this
DotedKey 
    : '.' key DotedKey {printf(".%s",$2);}
    | 
    ;


Value 
    : string    {printf("%s\n",$1);}
    | yyfloat   {printf("%s\n",$1);}
    | integer   {printf("%s\n",$1);}
    | boolean   {printf("%s\n",$1);}
    | date      {printf("%s\n",$1);}
    | List
    | InLineTable
    | {printf("vazio\n");}
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