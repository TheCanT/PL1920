%{
    int last_branch = 0;
    int branch = 0;
%}

%s categoria meta tree

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
email {email_character}+\@{email_character}+\.{email_character}+
%%

    /* one character match */
[ \t\r\n] ECHO;

. return 0;

    /* flex mkfromtemplate.l && 
       gcc lex.yy.c -o parse_tree -ll && 
       (cat test_tree | ./parse_tree) 
    */

\{%name%\} ;

\{%author%\} ;

\{%email%\} ;

{email} {
    ECHO;
}


\=\=\=\  {
    BEGIN categoria;
    ECHO;
}

<categoria>meta {
    ECHO;
    BEGIN tree;
}

<categoria>tree {
    ECHO;
    BEGIN tree;
}

<meta>email: 

<tree>[\-]+\  {
    for(int i = 0; yytext[i] == '-'; i++) {
        branch++;
        printf("%d",branch);
    }
    printf(" ");
}

<tree>{special_name}$ {
    if(branch > last_branch) return 0;
    ECHO;
    if(branch < last_branch) last_branch = branch;
    branch = 0;
    BEGIN tree;
}

<tree>{file_name}+$ {
    if(branch > last_branch) return 0;
    ECHO;
    if(branch < last_branch) last_branch = branch;
    branch = 0;
    BEGIN tree;
}

<tree>{branch_Sname}$ {
    if(branch > last_branch) return 0;
    ECHO;
    last_branch = branch + 1;
    branch = 0;
    BEGIN tree;
}

<tree>{branch_name}$ {
    if(branch > last_branch) return 0;
    ECHO;
    last_branch = branch + 1;
    branch = 0;
    BEGIN tree;
}


%%
