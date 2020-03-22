%{
    int last_branch = 0;
    int branch = 0;
%}

%s tree

upper [A-Z]+
lower [a-z]+
digit [0-9]+

file_name [\x21-\x2E\x30-\x5B\x5D-\x7E]*
special_name {file_name}\{%name%\}{file_name}

branch_name {file_name}\/
branch_Sname {special_name}\/

%%

    /* flex mkfromtemplate.l && 
       gcc lex.yy.c -o parse_tree -ll && 
       (cat test_tree | ./parse_tree) 
    */

\=\=\=\ tree {
    ECHO;
    BEGIN tree;
}

<tree>\=\=\= {
    printf("ACABOU A TREE\n");
    return 0;
}


<tree>[\-]+\  {
    for(int i = 0; yytext[i] == '-'; i++) {
        branch++;
        printf("%d",branch);
    }
    printf(" ");
}


<tree>{special_name} { 
    printf(" -- %d > %d -- ",branch,last_branch);
    if(branch > last_branch) return 0;
    ECHO;
    if(branch < last_branch) last_branch = branch;
    branch = 0;
    BEGIN tree;
}

<tree>{file_name} {
    printf(" -- %d > %d -- ",branch,last_branch);
    if(branch > last_branch) return 0;
    ECHO;
    if(branch < last_branch) last_branch = branch;
    branch = 0;
    BEGIN tree;
}

<tree>{branch_Sname} {
    printf(" -- %d > %d -- ",branch,last_branch);
    if(branch > last_branch) return 0;
    ECHO;
    last_branch = branch + 1;
    branch = 0;
    BEGIN tree;
}

<tree>{branch_name} {
    printf(" -- %d > %d -- ",branch,last_branch);
    if(branch > last_branch) return 0;
    ECHO;
    last_branch = branch + 1;
    branch = 0;
    BEGIN tree;
}



    /* one character match */
[ \t\r\n] ECHO;

. return 0;

%%
