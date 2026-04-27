%{
#include "prova1.tab.h"
#include <stdlib.h>
#include <string.h>

static char *remove_aspas(const char *txt)
{
    int n = strlen(txt);
    char *s = malloc(n - 1);

    if (!s)
        exit(1);

    strncpy(s, txt + 1, n - 2);
    s[n - 2] = '\0';

    return s;
}
%}

%option noyywrap

%%

[ \t\r]+        { }

"//"[^\n]*      { }

\n              { return EOL; }

"print"         { return PRINT; }
"concat"        { return CONCAT; }
"length"        { return LENGTH; }

[0-9]+          {
                    yylval.ival = atoi(yytext);
                    return NUM;
                }

[a-zA-Z_][a-zA-Z0-9_]* {
                    yylval.sval = strdup(yytext);
                    return IDENT;
                }

\"([^\"\n])*\"  {
                    yylval.sval = remove_aspas(yytext);
                    return STRING;
                }

"="             { return ASSIGN; }

"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return TIMES; }
"/"             { return DIV; }

"("             { return LPAREN; }
")"             { return RPAREN; }
","             { return COMMA; }

.               { return ERROR; }

%%
