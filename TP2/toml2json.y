%{
#include <stdio.h>
#include <string.h>

#include "storedata.h"

STOREDATA global_table = NULL;
STOREDATA table_in_use = NULL;
STOREDATA in_line_table = NULL;

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
    : Sequence Pair
    | Sequence Table
    | Sequence ArrayOfTables
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
    : OPEN_IN_LINE_TABLE InLinable CLOSE_IN_LINE_TABLE { $$ = $2; parsing--; }
;


InLinable
    : {
        parsing++;
        in_line_table = store_data_new_table("inlinable");
    } 
    Pair 
    { 
        STOREDATA s = in_line_table; 
        $$ = s; 
    }
    | InLinable SEPARATE_VALUES Pair { $$ = $1; }
;


List
    : OPEN_LIST Listable CLOSE_LIST { $$ = $2; }
;


Listable
    : Value { 
        STOREDATA s = store_data_new_array("listable"); 
        store_data_add_value(s,$1);
        $$ = s;
    }
    | Listable SEPARATE_VALUES Value { store_data_add_value($1,$3); $$ = $1; }
    | Listable SEPARATE_VALUES       { $$ = $1; }
;


Pair
    : Key KEY_EQ_VALUE Value {
        store_data_set_key($3,store_data_get_key($1));
        store_data_add_value($1,$3);
        $$ = $1;
    }
;


Key
    : DotedKey key { $$ = store_data_next_key_value($1,$2); }
;


DotedKey
    : DotedKey key KEY_TOKEN { $$ = store_data_next_key($1,$2); }
    | { if (parsing > 0) $$ = in_line_table;
        else             $$ = table_in_use; }
;


Value
    : string        { $$ = store_data_new ('s', "", $1); }
    | yyfloat       { $$ = store_data_new ('s', "", $1); }
    | integer       { $$ = store_data_new ('s', "", $1); }
    | boolean       { $$ = store_data_new ('s', "", $1); }
    | date          { char * s; asprintf(&s,"\"%s\"",$1); $$ = store_data_new ('s', "", s); }
    | List          { $$ = $1; }
    | InLineTable   { $$ = $1; }
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