%{
    #include "glib.h"

    int last_branch = 0;
    int branch = 0;

    char * input_name;

    GPtrArray * directory_vector;
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
        printf("%d",branch);
    }
    printf(" ");
}

<tree>{special_name}\n {
    if(branch > last_branch) return 0;
    ECHO;
    if(branch < last_branch) last_branch = branch;
    branch = 0;
}

<tree>{file_name}+\n {
    if(branch > last_branch) return 0;
    ECHO;
    if(branch < last_branch) last_branch = branch;
    branch = 0;
}

<tree>{branch_Sname}\n {
    if(branch > last_branch) return 0;
    ECHO;
    last_branch = branch + 1;
    branch = 0;
}

<tree>{branch_name}\n {
    if(branch > last_branch) return 0;
    ECHO;
    last_branch = branch + 1;
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
    yylex();
    return 1;
}