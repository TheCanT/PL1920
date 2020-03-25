%{
    #include "glib.h"
    #include "gmodule.h"

    int last_branch = 0;
    int branch = 0;

    char * input_name;

    GPtrArray * directory_vector;
    GPtrArray * this_directory;

    struct directory_st{
        int depth;
        char * dir_name;
    };

    typedef struct directory_st * DIRECTORY;

    DIRECTORY init_directory(int b, char * d){
        DIRECTORY dir = malloc(sizeof(struct directory_st)); 
        dir->depth = b;
        dir->dir_name = strdup(d);
        return dir;
    }

    void set_directory(gpointer data, gpointer user_data){
        DIRECTORY dir = (DIRECTORY) data;
        g_ptr_array_insert(this_directory,dir->depth,dir);
    }

    void get_directory(gpointer data, gpointer user_data){
        DIRECTORY dir = (DIRECTORY) data;
        GString * s = (GString*) user_data;
        if(branch >= 0){
            g_string_append(s,dir->dir_name);
            branch--;
        }
    }

    char * swap_token_for_name(char* s, char* tok, char* name){
        char* t = strstr(s,tok);
        char* r = malloc(strlen(s)-strlen(tok)+strlen(name));

    /*    char* token1 = strtok(s,tok);
        char* token2 = strtok(NULL,tok);
        if(t == s) puts(" ## 1"),sprintf(r,"%s%s",name,token1);
        else puts(" ## 2"),sprintf(r,"%s%s%s",token1,name,token2);
    */
        sprintf(r,"%s%s%s",strndup(s,t-s),name,strndup(t+strlen(tok),t-s+strlen(tok)));
        return r;
    }

%}

%s categoria meta email author tree content

upper [A-Z]
lower [a-z]
digit [0-9]

acentos \xc3[\x80-\xbf]       
letra [a-zA-Z]|{acentos}

file_name ([\x21-\x2E\x30-\x5B\x5D-\x7E]|{letra})
special_name {file_name}*\{%name%\}{file_name}*

branch_name {file_name}+\/
branch_Sname {special_name}\/

email_character ({upper}|{lower}|{digit}|[\_\-\.])
email [A-Za-z0-9\_\"]+((\.|\+|\-)[A-Za-z0-9\_\"]+)*\@[A-Za-z\_\"]+((\.|\+|\-)[A-Za-z\_\"]+)+
    //{email_character}+\@{email_character}+\.{email_character}+
    // [A-Za-z0-9\_\"]+((\.|\+|\-)[A-Za-z0-9\_\"]+)*\@[A-Za-z\_\"]+((\.|\+|\-)[A-Za-z\_\"]+)+\n
%%
    /* flex mkfromtemplate.l && 
       gcc lex.yy.c -o parse_tree -ll && 
       (cat test_tree | ./parse_tree) 
    */

 //\{%name%\} ;

 //\{%author%\} ;

 //\{%email%\} ;


^\=\=\=\  {
    BEGIN categoria;
    ECHO;
}


<categoria>meta$ {
    ECHO;
    BEGIN meta;
}

<categoria>tree$ {
    ECHO;
    BEGIN tree;
}

<categoria>{special_name}$ {
    ECHO;
    BEGIN content;
}

<categoria>{file_name}+$ {
    ECHO;
    BEGIN content;
}

<meta>email:\  BEGIN email;

<email>{email}$ {
    ECHO;
    BEGIN meta;
}

<meta>author:\  BEGIN author;

<author>({letra}+(\.)?(\ )?)+$ {
    ECHO;
    BEGIN meta;
}

<tree>[\-]+\  {
    for(int i = 0; yytext[i] == '-'; i++) {
        branch++;
    }
}

<tree>{special_name}$ {
    if(branch > last_branch) return 0;
    if(branch < last_branch) last_branch = branch;
    
    char * updated_name = swap_token_for_name(yytext,"{\%name\%}",input_name);

    DIRECTORY ptr = init_directory(branch,updated_name);
    g_ptr_array_add(directory_vector,(gpointer)ptr);
    g_ptr_array_foreach(directory_vector,set_directory,NULL);
    
    GString * s = g_string_new(NULL);
    g_ptr_array_foreach(this_directory,get_directory,s);    
    printf("%s",g_string_free(s,FALSE));

    branch = 0;
}

<tree>{file_name}+$ {
    if(branch > last_branch) return 0;
    if(branch < last_branch) last_branch = branch;
    
    DIRECTORY ptr = init_directory(branch,yytext);
    g_ptr_array_add(directory_vector,(gpointer)ptr);
    g_ptr_array_foreach(directory_vector,set_directory,NULL);
    
    GString * s = g_string_new(NULL);
    g_ptr_array_foreach(this_directory,get_directory,s);    
    printf("%s",g_string_free(s,FALSE));

    branch = 0;
}

<tree>{branch_Sname}$ {
    if(branch > last_branch) return 0;
    last_branch = branch + 1;
    
    char * updated_Sbranch = swap_token_for_name(yytext,"{\%name\%}",input_name);

    DIRECTORY ptr = init_directory(branch,updated_Sbranch);
    g_ptr_array_add(directory_vector,(gpointer)ptr);
    g_ptr_array_foreach(directory_vector,set_directory,NULL);
    
    GString * s = g_string_new(NULL);
    g_ptr_array_foreach(this_directory,get_directory,s);    
    printf("%s",g_string_free(s,FALSE));

    branch = 0;
}

<tree>{branch_name}$ {
    if(branch > last_branch) return 0;
    last_branch = branch + 1;
    
    DIRECTORY ptr = init_directory(branch,yytext);
    g_ptr_array_add(directory_vector,(gpointer)ptr);
    g_ptr_array_foreach(directory_vector,set_directory,NULL);
    
    GString * s = g_string_new(NULL);
    g_ptr_array_foreach(this_directory,get_directory,s);    
    printf("%s",g_string_free(s,FALSE));

    branch = 0;
}


    /* one character match */
[ \t\r\n] ECHO;

. return 0;

<<EOF>> {puts("EOF"); return 0;}

%%

int main(int argc, char ** argv){
    if(argc>1) input_name = strdup(argv[1]);
    directory_vector = g_ptr_array_new();
    this_directory = g_ptr_array_new();
    yylex();
    return 1;
}