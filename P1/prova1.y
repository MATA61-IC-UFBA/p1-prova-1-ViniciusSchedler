%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyout;

void yyerror(const char *msg);

#define T_INT 1
#define T_STRING 2
#define MAX_VARS 256

typedef struct {
    char *nome;
    int tipo;
    int ival;
    char *sval;
} Variavel;

static Variavel tabela[MAX_VARS];
static int qtd_vars = 0;

static int busca_var(char *nome)
{
    int i;

    for (i = 0; i < qtd_vars; i++) {
        if (strcmp(tabela[i].nome, nome) == 0)
            return i;
    }

    return -1;
}

static void salva_int(char *nome, int valor)
{
    int pos = busca_var(nome);

    if (pos == -1) {
        pos = qtd_vars++;
        tabela[pos].nome = strdup(nome);
        tabela[pos].sval = NULL;
    }

    if (tabela[pos].tipo == T_STRING && tabela[pos].sval)
        free(tabela[pos].sval);

    tabela[pos].tipo = T_INT;
    tabela[pos].ival = valor;
    tabela[pos].sval = NULL;
}

static void salva_string(char *nome, char *valor)
{
    int pos = busca_var(nome);

    if (pos == -1) {
        pos = qtd_vars++;
        tabela[pos].nome = strdup(nome);
        tabela[pos].sval = NULL;
    }

    if (tabela[pos].tipo == T_STRING && tabela[pos].sval)
        free(tabela[pos].sval);

    tabela[pos].tipo = T_STRING;
    tabela[pos].sval = strdup(valor);
}

static int pega_int(char *nome, int *saida)
{
    int pos = busca_var(nome);

    if (pos == -1 || tabela[pos].tipo != T_INT)
        return 0;

    *saida = tabela[pos].ival;
    return 1;
}

static int pega_string(char *nome, char **saida)
{
    int pos = busca_var(nome);

    if (pos == -1 || tabela[pos].tipo != T_STRING)
        return 0;

    *saida = strdup(tabela[pos].sval);
    return 1;
}

static char *concatena(char *a, char *b)
{
    char *r = malloc(strlen(a) + strlen(b) + 1);

    if (!r)
        exit(1);

    strcpy(r, a);
    strcat(r, b);

    return r;
}
%}

%union {
    int ival;
    char *sval;
}

%token ERROR
%token <ival> NUM
%token <sval> IDENT STRING

%token PRINT CONCAT LENGTH
%token ASSIGN

%token PLUS MINUS TIMES DIV
%token LPAREN RPAREN COMMA
%token EOL

%type <ival> expr_int
%type <sval> expr_str concat_args

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
: IDENT ASSIGN expr_int EOL
    {
        salva_int($1, $3);
        free($1);
    }
| IDENT ASSIGN expr_str EOL
    {
        salva_string($1, $3);
        free($1);
        free($3);
    }
| PRINT LPAREN expr_int RPAREN EOL
    {
        fprintf(yyout, "%d\n", $3);
    }
| PRINT LPAREN expr_str RPAREN EOL
    {
        fprintf(yyout, "%s\n", $3);
        free($3);
    }
| PRINT expr_int EOL
    {
        fprintf(yyout, "%d\n", $2);
    }
| PRINT expr_str EOL
    {
        fprintf(yyout, "%s\n", $2);
        free($2);
    }
| expr_int EOL
| expr_str EOL
    {
        free($1);
    }
| EOL
| ERROR EOL
    {
        YYERROR;
    }
;

expr_int
: NUM
    {
        $$ = $1;
    }
| IDENT
    {
        if (!pega_int($1, &$$))
            YYERROR;

        free($1);
    }
| expr_int PLUS expr_int
    {
        $$ = $1 + $3;
    }
| expr_int MINUS expr_int
    {
        $$ = $1 - $3;
    }
| expr_int TIMES expr_int
    {
        $$ = $1 * $3;
    }
| expr_int DIV expr_int
    {
        if ($3 == 0)
            YYERROR;

        $$ = $1 / $3;
    }
| LPAREN expr_int RPAREN
    {
        $$ = $2;
    }
| LENGTH LPAREN expr_str RPAREN
    {
        $$ = strlen($3);
        free($3);
    }
;

expr_str
: STRING
    {
        $$ = $1;
    }
| IDENT
    {
        if (!pega_string($1, &$$))
            YYERROR;

        free($1);
    }
| CONCAT LPAREN concat_args RPAREN
    {
        $$ = $3;
    }
| LPAREN expr_str RPAREN
    {
        $$ = $2;
    }
;

concat_args
: expr_str COMMA expr_str
    {
        $$ = concatena($1, $3);
        free($1);
        free($3);
    }
| concat_args COMMA expr_str
    {
        $$ = concatena($1, $3);
        free($1);
        free($3);
    }
;

%%
