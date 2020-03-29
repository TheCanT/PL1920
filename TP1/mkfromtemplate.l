%{
    #include "glib.h"
    #include "gmodule.h"

    int last_branch = 0;
    int branch = 0;

    char * input_name = NULL;
    char * email = NULL;
    char * author = NULL;

    GPtrArray * directory_vector;
    GPtrArray * this_directory;
    GPtrArray * final_directories;


    struct full_dir_st{
        char * name;
        char * dir;
        long ini;
        long end;
    };

    typedef struct full_dir_st * FULL_DIR;

    FULL_DIR init_full_dir(char * n, char * d){
        FULL_DIR fdir = malloc(sizeof(struct full_dir_st)); 
        fdir->name = strdup(n);
        fdir->dir = strdup(d);
        fdir->ini = 0;
        fdir->end = 0;
        return fdir;
    }


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

    char * full_path(char * name){
        DIRECTORY ptr = init_directory(branch,name);
        g_ptr_array_add(directory_vector,(gpointer)ptr);
        g_ptr_array_foreach(directory_vector,set_directory,NULL);
    
        GString * s = g_string_new(NULL);
        g_ptr_array_foreach(this_directory,get_directory,s);
        return strdup(g_string_free(s,FALSE));
    }


    char * swap_token_for_name(char * s, char * tok, char * name){
        char * t = strstr(s,tok);
        char * r = malloc(strlen(s)-strlen(tok)+strlen(name));
        sprintf(r,"%s%s%s",strndup(s,t-s),name,strndup(t+strlen(tok),t-s+strlen(tok)));
        return r;
    }

%}

%s CATEGORY META EMAIL AUTHOR TREE CONTENT

upper [A-Z]
lower [a-z]
digit [0-9]

acentos \xc3[\x80-\xbf]       
letra [a-zA-Z]|{acentos}

file_name ([\x21-\x2E\x30-\x5B\x5D-\x7E]|{letra})
special_name {file_name}*\{%name%\}{file_name}*

branch_name {file_name}+\/
branch_Sname {special_name}\/

email [A-Za-z0-9\_\]+((\.|\+|\-)[A-Za-z0-9\_\]+)*\@[A-Za-z\_\"]+((\.|\+|\-)[A-Za-z\_\"]+)+
%%

\{%name%\} printf("%s",input_name);

\{%author%\} printf("%s",author);

\{%email%\} printf("%s",email);


^\=\=\=\  {
    BEGIN CATEGORY;
    ECHO;
}


<CATEGORY>meta$ {
    ECHO;
    BEGIN META;
}

<CATEGORY>tree$ {
    ECHO;
    BEGIN TREE;
}

<CATEGORY>{special_name}$ {
    printf("%s",swap_token_for_name(yytext,"{\%name\%}",input_name));
    BEGIN CONTENT;
}

<CATEGORY>{file_name}+$ {
    ECHO;
    BEGIN CONTENT;
}

<META>email:\  BEGIN EMAIL;

<EMAIL>{email}$ {
    ECHO;
    email = strdup(yytext);
    BEGIN META;
}

<META>author:\  BEGIN AUTHOR;

<AUTHOR>({letra}+(\.)?(\ )?)+$ {
    ECHO;
    author = strdup(yytext);
    BEGIN META;
}

<META>\#.*$ ECHO;

<TREE>[\-]+\  {
    for(int i = 0; yytext[i] == '-'; i++) {
        branch++;
    }
}

<TREE>{special_name}$ {
    if(branch > last_branch) return 0;
    if(branch < last_branch) last_branch = branch;
    
    char * updated_name = swap_token_for_name(yytext,"{\%name\%}",input_name);
  
    printf("%s",full_path(updated_name));

    branch = 0;
}

<TREE>{file_name}+$ {
    if(branch > last_branch) return 0;
    if(branch < last_branch) last_branch = branch;
    
    printf("%s",full_path(yytext));

    branch = 0;
}

<TREE>{branch_Sname}$ {
    if(branch > last_branch) return 0;
    last_branch = branch + 1;
    
    char * updated_Sbranch = swap_token_for_name(yytext,"{\%name\%}",input_name);

    printf("%s",full_path(updated_Sbranch));

    branch = 0;
}

<TREE>{branch_name}$ {
    if(branch > last_branch) return 0;
    last_branch = branch + 1;
    
    printf("%s",full_path(yytext));

    branch = 0;
}



<CONTENT>{letra}+ ECHO;
<CONTENT>. ECHO;


    /* one character match */
[ \t\r\n] ECHO;

. return 0;

<<EOF>> {puts("EOF"); return 0;}

%%

int main(int argc, char ** argv){
    if(argc>2){
        input_name = strdup(argv[1]);
        yyin = fopen(argv[2],"r");
    }
    directory_vector = g_ptr_array_new();
    this_directory = g_ptr_array_new();
    yylex();
    return 1;
}