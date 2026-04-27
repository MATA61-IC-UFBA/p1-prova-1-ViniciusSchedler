%code requires {
typedef struct Valor {
    int tipo;
    int ival;
    char *sval;
} Valor;
}

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
%}

%code {
typedef struct Variavel {
    char *nome;
    Valor valor;
} Variavel;

static Variavel tabela[MAX_VARS];
static int qtd_vars = 0;

static Valor make_int(int x)
{
    Valor v;
    v.tipo = T_INT;
    v.ival = x;
    v.sval = NULL;
    return v;
}

static Valor make_string(const char *s)
{
    Valor v;
    v.tipo = T_STRING;
    v.ival = 0;
    v.sval = strdup(s ? s : "");

    if (!v.sval)
        exit(1);

    return v;
}

static Valor copia_valor(Valor v)
{
    if (v.tipo == T_STRING)
        return make_string(v.sval);

    return make_int(v.ival);
}

static int busca_var(const char *nome)
{
    int i;

    for (i = 0; i < qtd_vars; i++) {
        if (strcmp(tabela[i].nome, nome) == 0)
            return i;
    }

    return -1;
}

static int set_var(const char *nome, Valor v)
{
    int pos = busca_var(nome);

    if (pos == -1) {
        if (qtd_vars >= MAX_VARS)
            return 0;

        pos = qtd_vars;
        tabela[pos].nome = strdup(nome);
        tabela[pos].valor.tipo = 0;
        tabela[pos].valor.sval = NULL;
        qtd_vars++;
    } else {
        if (tabela[pos].valor.tipo == T_STRING && tabela[pos].valor.sval)
            free(tabela[pos].valor.sval);
    }

    tabela[pos].valor = copia_valor(v);
    return 1;
}

static int get_var(const char *nome, Valor *saida)
{
    int pos = busca_var(nome);

    if (pos == -1)
        return 0;

    *saida = copia_valor(tabela[pos].valor);
    return 1;
}

static Valor opera_int(Valor a, Valor b, char op, int *ok)
{
    *ok = 1;

    if (a.tipo != T_INT || b.tipo != T_INT) {
        *ok = 0;
        return make_int(0);
    }

    if (op == '+')
        return make_int(a.ival + b.ival);

    if (op == '-')
        return make_int(a.ival - b.ival);

    if (op == '*')
        return make_int(a.ival * b.ival);

    if (op == '/') {
        if (b.ival == 0) {
            *ok = 0;
            return make_int(0);
        }

        return make_int(a.ival / b.ival);
    }

    *ok = 0;
    return make_int(0);
}

static Valor concatena(Valor a, Valor b, int *ok)
{
    char *tmp;
    Valor r;

    *ok = 1;

    if (a.tipo != T_STRING || b.tipo != T_STRING) {
        *ok = 0;
        return make_string("");
    }

    tmp = malloc(strlen(a.sval) + strlen(b.sval) + 1);

    if (!tmp)
        exit(1);

    strcpy(tmp, a.sval);
    strcat(tmp, b.sval);

    r = make_string(tmp);
    free(tmp);

    return r;
}

static void print_value(Valor v)
{
    if (v.tipo == T_INT)
        fprintf(yyout, "%d\n", v.ival);
    else if (v.tipo == T_STRING)
        fprintf(yyout, "%s\n", v.sval);
}
}

%union {
    int ival;
    char *sval;
    Valor valor;
}

%token ERROR
%token <ival> NUM
%token <sval> IDENT STRING

%token PRINT CONCAT LENGTH
%token ASSIGN

%token PLUS MINUS TIMES DIV
%token LPAREN RPAREN COMMA
%token EOL

%type <valor> expr concat_args

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
    {
        if (!set_var($1, $3))
            YYERROR;

        free($1);
    }
| PRINT expr EOL
    {
        print_value($2);
    }
| expr EOL
| EOL
| ERROR EOL
    {
        YYERROR;
    }
;

expr
: NUM
    {
        $$ = make_int($1);
    }
| STRING
    {
        $$ = make_string($1);
        free($1);
    }
| IDENT
    {
        if (!get_var($1, &$$))
            YYERROR;

        free($1);
    }
| expr PLUS expr
    {
        int ok;
        $$ = opera_int($1, $3, '+', &ok);
        if (!ok) YYERROR;
    }
| expr MINUS expr
    {
        int ok;
        $$ = opera_int($1, $3, '-', &ok);
        if (!ok) YYERROR;
    }
| expr TIMES expr
    {
        int ok;
        $$ = opera_int($1, $3, '*', &ok);
        if (!ok) YYERROR;
    }
| expr DIV expr
    {
        int ok;
        $$ = opera_int($1, $3, '/', &ok);
        if (!ok) YYERROR;
    }
| LPAREN expr RPAREN
    {
        $$ = $2;
    }
| LENGTH LPAREN expr RPAREN
    {
        if ($3.tipo != T_STRING)
            YYERROR;

        $$ = make_int(strlen($3.sval));
    }
| CONCAT LPAREN concat_args RPAREN
    {
        $$ = $3;
    }
;

concat_args
: expr COMMA expr
    {
        int ok;
        $$ = concatena($1, $3, &ok);
        if (!ok) YYERROR;
    }
| concat_args COMMA expr
    {
        int ok;
        $$ = concatena($1, $3, &ok);
        if (!ok) YYERROR;
    }
;

%%
