%{
#include <stdio.h>
#include <string.h>

#include "storedata.h"

STOREDATA global_table = NULL;
STOREDATA table_in_use = NULL;

int parsing = 0;

extern void asprintf();
extern int yylex();
extern int yylineno;
extern char *yytext;

int yyerror();
int erroSem(char*);
%}

%union{
    char * string_value;
    gpointer pointer;
    STOREDATA store_data;
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


%token <string_value> string key boolean date integer yyfloat

%type  <pointer> Value Listable List InLinable InLineTable Pair

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
        //this is not right
        table_in_use = $3;
    }
;


InLineTable
    : OPEN_IN_LINE_TABLE InLinable CLOSE_IN_LINE_TABLE { asprintf(&$$,"{ %s }",$2); }
;


InLinable
    : Pair                           { $$ = $1; }
    | Pair SEPARATE_VALUES InLinable { asprintf(&$$,"%s, %s",$1,$3); }
;


List
    : OPEN_LIST Listable CLOSE_LIST { asprintf(&$$,"[ %s ]",$2); }
;


Listable
    : Value                          { $$ = store_data_get_key($1); }
    | Value SEPARATE_VALUES Listable { asprintf(&$$,"%s, %s",store_data_get_key($1),$3); }
    | Value SEPARATE_VALUES          { $$ = store_data_get_key($1); }
;


Pair
    : Key KEY_EQ_VALUE Value {
        store_data_set_key($3,store_data_get_key($1));
        store_data_add_value($1,$3);
        asprintf(&$$,"\"%s\" : %s",store_data_get_key($1),store_data_get_data($1)); 
    }
;


Key
    : DotedKey key { $$ = store_data_next_key_value($1,$2); }
;

//arranjar uma forma das in line tables usarem a table atual da Key.
DotedKey
    : DotedKey key KEY_TOKEN { $$ = store_data_next_key($1,$2); }
    |                        { $$ = table_in_use; }
;

//types not right and using keys just to teste some...
Value
    : string        { $$ = store_data_new ('s', $1, $1); }
    | yyfloat       { $$ = store_data_new ('s', $1, $1); }
    | integer       { $$ = store_data_new ('s', $1, $1); }
    | boolean       { $$ = store_data_new ('s', $1, $1); }
    | date          { char * s; asprintf(&s,"\"%s\"",$1); $$ = store_data_new ('s', s, s); }
    | List          { $$ = store_data_new ('s', $1, $1); }
    | InLineTable   { $$ = store_data_new ('s', $1, $1); }
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