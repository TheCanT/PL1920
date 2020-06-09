%{
#include <stdio.h>
#include <string.h>

#include "storedata.h"

STOREDATA global_table = NULL;
STOREDATA table_in_use = NULL;

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
    struct storedata_st * store_data;
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


%token <svalue> string key boolean date integer yyfloat

%type <store_data> DotedKey Key

%%

S :
    { 
        global_table = store_data_new_table("global"); 
        table_in_use = global_table; 
    } 
      Sequence END 
    { 
        print_2_JSON(global_table); 
        return 0; 
    }
;


Sequence
    : Pair Sequence
    | Table Sequence
    | ArrayOfTables Sequence
    |
;


Table
    : { table_in_use = global_table; } OPEN_TABLE Key CLOSE_TABLE {
        store_data_set_data($3,g_hash_table_new(g_str_hash,g_str_equal));
        store_data_set_type($3,'h');
        table_in_use = $3;
    }
;


ArrayOfTables
    : { table_in_use = global_table; } OPEN_ARRAY_OF_TABLES Key CLOSE_ARRAY_OF_TABLES {
        store_data_set_data($3,g_hash_table_new(g_str_hash,g_str_equal));
        store_data_set_type($3,'h');
        table_in_use = $3;
        //this is not right
    }
;


InLineTable
    : OPEN_IN_LINE_TABLE InLinable CLOSE_IN_LINE_TABLE
;


InLinable
    : Pair
    | Pair SEPARATE_VALUES InLinable
;


List
    : OPEN_LIST Listable CLOSE_LIST
;


Listable
    : Value
    | Value SEPARATE_VALUES Listable
    | Value SEPARATE_VALUES
;


Pair
    : Key KEY_EQ_VALUE Value {  }
;


Key
    : DotedKey key { $$ = store_data_next_key_value($1,$2); }
;


DotedKey
    : DotedKey key KEY_TOKEN { $$ = store_data_next_key($1,$2); }
    |                        { $$ = table_in_use; }
;


Value
    : string
    | yyfloat
    | integer
    | boolean
    | date
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