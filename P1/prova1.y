%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
void yyerror(const char *msg);
%}

%token ERROR
%token NUM
%token IDENT
%token STRING
%token PRINT
%token CONCAT
%token LENGTH
%token ASSIGN
%token PLUS
%token MINUS
%token TIMES
%token DIV
%token LPAREN
%token RPAREN
%token COMMA
%token EOL

%left PLUS MINUS
%left TIMES DIV

%start program

%%

program
: stmt_list
;

stmt_list
: 
| stmt_list stmt
;

stmt
: IDENT ASSIGN expr EOL
| PRINT LPAREN expr RPAREN EOL
| PRINT expr EOL
| expr EOL
| EOL
| ERROR EOL { YYERROR; }
;

expr
: NUM
| IDENT
| STRING
| expr PLUS expr
| expr MINUS expr
| expr TIMES expr
| expr DIV expr
| LPAREN expr RPAREN
| LENGTH LPAREN expr RPAREN
| CONCAT LPAREN exprlist RPAREN
;

exprlist
: expr COMMA expr
| exprlist COMMA expr
;

%%
