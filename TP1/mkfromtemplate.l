%{
    #include <stdio.h>
    #include <fcntl.h>
    #include <sys/stat.h>
    #include "glib.h"
    #include "gmodule.h"

    extern char * asprintf();

    int line = 1;

    int last_branch = 0;
    int branch = 0;

    char * input_name = NULL;
    char * email = NULL;
    char * author = NULL;

    GPtrArray * this_directory = NULL;
    GPtrArray * final_directories = NULL;



    struct full_dir_st{
        char * name;
        char * dir;
        char type;
    };

    typedef struct full_dir_st * FULL_DIR;

    FULL_DIR init_full_dir(char * n, char * d, char t);
    
    int duplicate_dir(char * n);

    int get_index_of_full_dir(char * n);

    void create_tree(gpointer data,gpointer user_data);



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
    g_ptr_array_foreach(final_directories,create_tree,NULL);
}

<CONTENT>^\=\=\=\  {
    BEGIN CATEGORY;
    if(yyout != stdout){
        fclose(yyout);
        yyout = stdout;
    }
}

^\=\=\=\  {
    BEGIN CATEGORY;
}


<CATEGORY>meta$ {
    if (email != NULL || author != NULL) {
        puts("The \"=== meta\" can only be written once.");
        return 0;
    }
    puts("Parsing meta:");
    BEGIN META;
}

<CATEGORY>tree$ {
    if (this_directory != NULL || final_directories != NULL) {
        puts("The \"=== tree\" can only be written once.");
        return 0;
    }
    this_directory = g_ptr_array_new();
    final_directories = g_ptr_array_new();
    puts("Parsing tree:");
    BEGIN TREE;
}

<CATEGORY>{special_name}$ {
    if (this_directory == NULL || final_directories == NULL) {
        printf("This \"=== %s\" must come after \"=== tree\"",yytext);
        if (email == NULL || author == NULL) printf(" and \"=== metta\"");
        printf(".\n");
        return 0;
    }

    char * name = swap_token_for_name(yytext,"{\%name\%}",input_name);
    int i;
    i = get_index_of_full_dir(yytext);

    if (i < 0) {
        printf("Invalid name file: %s (line %d)\n",yytext,line);
        BEGIN VOID;
        return 1;
    }
    else {
        FULL_DIR fdr = (FULL_DIR) g_ptr_array_index(final_directories,i);

        if (fdr->type != 'f') {
            printf("It's a directory: %s (line %d)\n",yytext,line);
            BEGIN VOID;
        }
        else {
            yyout = fopen(fdr->dir,"a+");
            printf("Valid file loading: %s (line %d)\n",yytext,line);
            BEGIN CONTENT;
        }
    }
}

<CATEGORY>{file_name}+$ {
    if (this_directory == NULL || final_directories == NULL || email == NULL || author == NULL) {
        printf("The \"=== %s\" must come after \"=== tree\"",yytext);
        printf(" and \"=== metta\"");
        printf(".\n");
        return 0;
    }
    
    int i;
    i = get_index_of_full_dir(yytext);

    if (i < 0) {
        printf("Invalid name file: %s (line %d)\n",yytext,line);
        BEGIN VOID;
    }
    else {
        FULL_DIR fdr = (FULL_DIR) g_ptr_array_index(final_directories,i);

        if (fdr->type != 'f') {
            printf("It's a directory: %s (line %d)\n",yytext,line);
            BEGIN VOID;
        }
        else {
            yyout = fopen(fdr->dir,"a+");
            printf("Valid file loading: %s (line %d)\n",yytext,line);
            BEGIN CONTENT;
        }
    }
}

<META>email:\  BEGIN EMAIL;

<META>author:\  BEGIN AUTHOR;

<META>\#.*$ ;

<EMAIL>{email}$ {
    if (email != NULL) {
        puts("You can only assign one email.");
        return 0;
    }

    printf("EMAIL ---> %s\n",yytext);
    email = strdup(yytext);
    BEGIN META;
}

<AUTHOR>({letra}+(\.)?(\ )?)+$ {
    if (author != NULL) {
        puts("You can only assign one author.");
        return 0;
    }

    printf("AUTHOR --> %s\n",yytext);
    author = strdup(yytext);
    BEGIN META;
}


<TREE>[\-]+\  {
    for(int i = 0; yytext[i] == '-'; i++)
        branch++;
}

<TREE>{special_name}$ {
    if(branch > last_branch) {
        printf("Error in branch for \"%s\" (line %d)\n",yytext,line);
        return 0;
    }

    if (branch < last_branch) last_branch = branch;

    char * updated_name = swap_token_for_name(yytext,"{\%name\%}",input_name);
    if (!duplicate_dir(yytext)) {
        printf("Duplicated directory \"%s\" (line %d)\n",yytext,line);
        return 0;
    }
    
    char * dir = full_path(updated_name);
    g_ptr_array_add(final_directories,init_full_dir(yytext,dir,'f'));

    branch = 0;
}

<TREE>{file_name}+$ {
    if(branch > last_branch) {
        printf("Error in branch for \"%s\" (line %d)\n",yytext,line);
        return 0;
    }

    if(branch < last_branch) last_branch = branch;
    
    if (!duplicate_dir(yytext)) {
        printf("Duplicated directory \"%s\" (line %d)\n",yytext,line);
        return 0;
    }

    char* dir = full_path(yytext);

    g_ptr_array_add(final_directories,init_full_dir(yytext,dir,'f'));

    branch = 0;
}

<TREE>{branch_Sname}$ {
    if(branch > last_branch) {
        printf("Error in branch for \"%s\" (line %d)\n",yytext,line);
        return 0;
    }

    last_branch = branch + 1;
    
    char * name = strndup(yytext,yyleng-1);
    char * updated_Sbranch = swap_token_for_name(yytext,"{\%name\%}",input_name);
    if (!duplicate_dir(name)) {
        printf("Duplicated directory \"%s\" (line %d)\n",yytext,line);
        return 0;
    }

    char * dir = full_path(updated_Sbranch);
    g_ptr_array_add(final_directories,init_full_dir(name,dir,'d'));

    branch = 0;
}

<TREE>{branch_name}$ {
    if(branch > last_branch) {
        printf("Error in branch for \"%s\" (line %d)\n",yytext,line);
        return 0;
    }

    last_branch = branch + 1;

    char * name = strndup(yytext,yyleng-1);
    if (!duplicate_dir(name)) {
        printf("Duplicated directory \"%s\" (line %d)\n",yytext,line);
        return 0;
    }
    
    char* dir = full_path(yytext);
    g_ptr_array_add(final_directories,init_full_dir(name,dir,'d'));

    branch = 0;
}



<CONTENT>\{%name%\} fprintf(yyout,"%s",input_name);
<CONTENT>\{%author%\} fprintf(yyout,"%s",author);
<CONTENT>\{%email%\} fprintf(yyout,"%s",email);
<CONTENT>{letra}+ ECHO;
<CONTENT>. ECHO;
<CONTENT>\n {line++; ECHO;}

<VOID>.|[ \t\r] ;
<VOID>\n line++;

    /* one character match */
[ \t\r] ;
\n line++;

. {printf("Syntatic error. (\"%s\" line %d)",yytext,line); return 0;}

<<EOF>> {puts("EOF"); return 0;}

%%



int main(int argc, char ** argv){
    if(argc>2){
        input_name = strdup(argv[1]);
        yyin = fopen(argv[2],"r");
    }
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
    
    gboolean equal_name_dir(gconstpointer a, gconstpointer b){
        FULL_DIR fdir = (FULL_DIR) a;
        char* name = (char*) b;
        if(!strcmp(fdir->name,name)){
            return TRUE;
        }
        return FALSE;
    }
    
    int duplicate_dir(char * n){
        int i = -1;
        g_ptr_array_find_with_equal_func(final_directories,n,equal_name_dir,&i);
        if (i != -1) return 0;
        else return 1;
    }

    int get_index_of_full_dir(char * n){
        int i = -1;
        g_ptr_array_find_with_equal_func(final_directories,n,equal_name_dir,&i);
        return i;
    }

    void create_tree(gpointer data,gpointer user_data){
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