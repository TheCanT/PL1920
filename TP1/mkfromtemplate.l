%{
    #define _GNU_SOURCE
    #include <stdio.h>
    #include <fcntl.h>
    #include <sys/stat.h>
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
        char type;
    };

    typedef struct full_dir_st * FULL_DIR;

    FULL_DIR this_fdir = NULL;

    FULL_DIR init_full_dir(char * n, char * d, char t);

    gboolean equal_full_dir1(gconstpointer a, gconstpointer b);
    
    gboolean equal_full_dir(gconstpointer a, gconstpointer b);
    
    int duplicate_dir(char * n);

    int get_index_of_full_dir(char * n);

    void printit(gpointer data,gpointer user_data);



    struct directory_st{
        int depth;
        char * dir_name;
    };

    typedef struct directory_st * DIRECTORY;

    DIRECTORY init_directory(int b, char * d);

    void set_directory(gpointer data, gpointer user_data);

    void get_directory(gpointer data, gpointer user_data);

    char * full_path(char * name);



    char * swap_token_for_name(char * s, char * tok, char * name);

%}

%s CATEGORY META EMAIL AUTHOR TREE CONTENT VOID

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

<TREE>^\=\=\=\  {
    puts("The tree is correct.");
    BEGIN CATEGORY;
    g_ptr_array_foreach(final_directories,printit,NULL);
}
 

^\=\=\=\  {
    BEGIN CATEGORY;
    if(yyout != stdout) fclose(yyout);
    yyout = stdout;
}


<CATEGORY>meta$ {
    puts("Parsing meta:");
    BEGIN META;
}

<CATEGORY>tree$ {
    puts("Parsing tree:");
    BEGIN TREE;
}

<CATEGORY>{special_name}$ {
    char * name = swap_token_for_name(yytext,"{\%name\%}",input_name);
    BEGIN CONTENT;

    int i;
    if((i = get_index_of_full_dir(name)) > -1){
        FULL_DIR fdr = (FULL_DIR) g_ptr_array_index(final_directories,i);
        yyout = fopen(fdr->dir,"a+");
        printf("Valid file loading: %s\n",name);
    }
    else {
        printf("Invalid file: %s\n",name);
        BEGIN VOID;
    }
}

<CATEGORY>{file_name}+$ {
    BEGIN CONTENT;
    
    int i;
    if((i = get_index_of_full_dir(yytext)) > -1){
        FULL_DIR fdr = (FULL_DIR) g_ptr_array_index(final_directories,i);
        yyout = fopen(fdr->dir,"a+");
        printf("Valid file loading: %s\n",yytext);
    }
    else {
        printf("Invalid file: %s\n",yytext);
        BEGIN VOID;
    }
}

<META>email:\  BEGIN EMAIL;

<EMAIL>{email}$ {
    printf("EMAIL ---> %s\n",yytext);
    email = strdup(yytext);
    BEGIN META;
}

<META>author:\  BEGIN AUTHOR;

<AUTHOR>({letra}+(\.)?(\ )?)+$ {
    printf("AUTHOR --> %s\n",yytext);
    author = strdup(yytext);
    BEGIN META;
}

<META>\#.*$ ;

<TREE>[\-]+\  {
    for(int i = 0; yytext[i] == '-'; i++)
        branch++;
}

<TREE>{special_name}$ {
    if(branch > last_branch) return 0;
    if(branch < last_branch) last_branch = branch;
    
    char * updated_name = swap_token_for_name(yytext,"{\%name\%}",input_name);
    if (!duplicate_dir(updated_name)) return 0;
    
    char * dir = full_path(updated_name);
    g_ptr_array_add(final_directories,init_full_dir(updated_name,dir,'f'));

    branch = 0;
}

<TREE>{file_name}+$ {
    if(branch > last_branch) return 0;
    if(branch < last_branch) last_branch = branch;
    
    if (!duplicate_dir(yytext)) return 0;

    char* dir = full_path(yytext);

    g_ptr_array_add(final_directories,init_full_dir(yytext,dir,'f'));

    branch = 0;
}

<TREE>{branch_Sname}$ {
    if(branch > last_branch) return 0;
    last_branch = branch + 1;
    
    char * updated_Sbranch = swap_token_for_name(yytext,"{\%name\%}",input_name);
    if (!duplicate_dir(updated_Sbranch)) return 0;
    
    char * dir = full_path(updated_Sbranch);
    g_ptr_array_add(final_directories,init_full_dir(updated_Sbranch,dir,'d'));

    branch = 0;
}

<TREE>{branch_name}$ {
    if(branch > last_branch) return 0;
    last_branch = branch + 1;

    if (!duplicate_dir(yytext)) return 0;
    
    char* dir = full_path(yytext);
    g_ptr_array_add(final_directories,init_full_dir(yytext,dir,'d'));

    branch = 0;
}



<CONTENT>\{%name%\} fprintf(yyout,"%s",input_name);
<CONTENT>\{%author%\} fprintf(yyout,"%s",author);
<CONTENT>\{%email%\} fprintf(yyout,"%s",email);
<CONTENT>{letra}+ ECHO;
<CONTENT>.|\n ECHO;

<VOID>.|[ \t\r\n] ;

    /* one character match */
[ \t\r\n] ;

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
    final_directories = g_ptr_array_new();
    yylex();
    return 1;
}


  // FULL DIRECTORY SECTION

    FULL_DIR init_full_dir(char * n, char * d, char t){
        FULL_DIR fdir = malloc(sizeof(struct full_dir_st)); 
        fdir->name = strdup(n);
        fdir->dir = strdup(d);
        fdir->type = t;
        return fdir;
    }

    gboolean equal_full_dir1(gconstpointer a, gconstpointer b){
        FULL_DIR fdir = (FULL_DIR) a;
        char* name = (char*) b;
        if(!strcmp(fdir->name,name) && fdir->type == 'f'){
            yyout = fopen(fdir->dir,"a+");
            return TRUE;
        }
        else return FALSE;
    }
    
    gboolean equal_full_dir(gconstpointer a, gconstpointer b){
        FULL_DIR fdir = (FULL_DIR) a;
        char* name = (char*) b;
        if(!strcmp(fdir->name,name)){
            return TRUE;
        }
        return FALSE;
    }
    
    int duplicate_dir(char * n){
        int i = -1;
        g_ptr_array_find_with_equal_func(final_directories,n,equal_full_dir,&i);
        if(i!=-1) {
            puts("dir already exists");
            return 0;
        }
        return 1;
    }

    int get_index_of_full_dir(char * n){
        int i = -1;
        g_ptr_array_find_with_equal_func(final_directories,n,equal_full_dir,&i);
        return i;
    }

    void printit(gpointer data,gpointer user_data){
        FULL_DIR f = (FULL_DIR) data;
        char * cmd;

        switch(f->type) {
            case 'f':
                asprintf(&cmd,"touch %s",f->dir);
                system(cmd);
                break;
            
            case 'd':
                mkdir(f->dir,0755);
                break;

            default:
                break;
        }
    }

  // DIRECTORY SECTION

    DIRECTORY init_directory(int b, char * d){
        DIRECTORY dir = malloc(sizeof(struct directory_st)); 
        dir->depth = b;
        dir->dir_name = strdup(d);
        return dir;
    }

    // acho que não é mais necessário
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
        g_ptr_array_insert(this_directory,ptr->depth,ptr);
    
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