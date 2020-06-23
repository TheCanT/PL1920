%{
#include <stdio.h>
#include <string.h>

#include "storedata.h"

STOREDATA global_table    = NULL;
STOREDATA table_in_use    = NULL;
STOREDATA in_line_table   = NULL;
STOREDATA array_of_tables = NULL;

int parsing_InLineTable   = 0;
int parsing_ArrayOfTables = 0;
int parsing_Table         = 0;

extern void asprintf();
extern int yylex();
extern int yylineno;
extern char *yytext;


char * take_of_under_score (char * s);
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


%token <string_value> boolean date

%token <string_value> integer yyfloat special_numeric

%token <string_value> quote_string apostrophe_string
%token <string_value> quote_tri_string apostrophe_tri_string

%token <string_value> string_key quote_key apostrophe_key


%type  <pointer> Value Listable List InLinable InLineTable Pair

%type <store_data> DotedKey Key

%type <string_value> String KeyString Numeric


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
    : { 
        table_in_use = global_table;
        parsing_Table = 1;
        parsing_ArrayOfTables=0;
    }
    OPEN_TABLE Key CLOSE_TABLE 
    {
        if (parsing_ArrayOfTables > 0) {
            array_of_tables = $3;
        }
        else {
            table_in_use = $3;
            store_data_set_data($3,g_hash_table_new(g_str_hash,g_str_equal));
            store_data_set_type($3,'h');
        }

        parsing_Table = 0;
    }
;


ArrayOfTables
    : { 
        table_in_use = global_table;
        parsing_ArrayOfTables = 0;
        parsing_Table = 1;
    } 
    OPEN_ARRAY_OF_TABLES Key CLOSE_ARRAY_OF_TABLES
    {
        if (store_data_get_type($3) != 'a') {
            store_data_set_data($3,g_ptr_array_new());
            store_data_set_type($3,'a');
        }
        
        STOREDATA s = store_data_new_table("table");
        store_data_add_value($3,s);

        table_in_use = s;
        array_of_tables = s;
        parsing_Table = 0;
    }
;


InLineTable
    : OPEN_IN_LINE_TABLE InLinable CLOSE_IN_LINE_TABLE { $$ = $2; parsing_InLineTable--; }
;


InLinable
    : {
        parsing_InLineTable++;
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
    : DotedKey KeyString { $$ = store_data_next_key_value($1,$2); }
;


DotedKey
    : DotedKey KeyString KEY_TOKEN { $$ = store_data_next_key($1,$2); }
    | { 
        $$ = table_in_use;
        if (parsing_ArrayOfTables > 0 && !parsing_Table) $$ = array_of_tables;
        if (parsing_InLineTable   > 0 && !parsing_Table) $$ = in_line_table;
    }
;


KeyString
    : string_key        { asprintf(&$$,"%s",$1); }
    | quote_key         { char * s = $1+1; s[strlen(s)-1] = '\0'; asprintf(&$$,"%s",s); }
    | apostrophe_key    { char * s = $1+1; s[strlen(s)-1] = '\0'; asprintf(&$$,"%s",s); }
;


Value
    : String        { $$ = store_data_new ('s', "", $1); }
    | Numeric       { $$ = store_data_new ('s', "", $1); }
    | boolean       { $$ = store_data_new ('s', "", $1); }
    | date          { char * s; asprintf(&s,"\"%s\"",$1); $$ = store_data_new ('s', "", s); }
    | List          { $$ = $1; }
    | InLineTable   { $$ = $1; }
;


String
    : quote_string          { asprintf(&$$,"%s",$1); }
    | apostrophe_string     { char * s = $1+1; s[strlen(s)-1] = '\0'; asprintf(&$$,"\"%s\"",s); }
    | quote_tri_string      { asprintf(&$$,"%s",$1); }
    | apostrophe_tri_string { asprintf(&$$,"%s",$1); }
;


Numeric
    : yyfloat           { $$ = take_of_under_score (*$1 == '+'  ? $1 + 1 : $1); }
    | integer           { $$ = take_of_under_score (*$1 == '+'  ? $1 + 1 : $1); }
    | special_numeric   { asprintf(&$$,"\"%s\"",$1); }
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

char * take_of_under_score (char * s) {
    char * r = malloc(strlen(s));
    int i = 0, j = 0;
    
    while (s[i]) {
        if (s[i] != '_') r[j++] = s[i]; 
        i++;
    }
    r[j] = '\0';
    
    return r; 
}