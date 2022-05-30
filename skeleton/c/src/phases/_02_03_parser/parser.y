%{

/*
 * parser.y -- SPL parser specification
 */

#include <stdlib.h>
#include <util/errors.h>
#include <table/identifier.h>
#include <types/types.h>
#include <absyn/absyn.h>
#include <phases/_01_scanner/scanner.h>
#include <phases/_02_03_parser/parser.h>

void yyerror(Program**, char *);

%}

// This section is placed into the header to make functions available to other modules
%code requires{
	/**
	  @return The name of the token class signalled by the given id.
	 */
	char const * tokenName(int token_class_id);
}

%token-table
%expect 0 //TODO Change?
%parse-param {Program** program}

%union {
  NoVal noVal;
  IntVal intVal;
  IdentVal identVal;

  Expression *expression;
  Variable *variable;
  Statement *statement;
  TypeExpression *typeExpression;
  GlobalDeclaration *globalDeclaration;
  VariableDeclaration *variableDeclaration;
  ParameterDeclaration *parameterDeclaration;

  StatementList *statementList;
  ExpressionList *expressionList;
  VariableDeclarationList *variableList;
  ParameterDeclarationList *parameterList;
  GlobalDeclarationList *globalDeclarationList;
}

%token	<noVal>		ARRAY ELSE IF OF PROC
%token	<noVal>		REF TYPE VAR WHILE DO
%token	<noVal>		LPAREN RPAREN LBRACK
%token	<noVal>		RBRACK LCURL RCURL
%token	<noVal>		EQ NE LT LE GT GE
%token	<noVal>		ASGN COLON COMMA SEMIC
%token	<noVal>		PLUS MINUS STAR SLASH
%token	<identVal>	IDENT
%token	<intVal>	INTLIT

%type   <expression>            exp rel_exp add_exp mul_exp unary_exp primary_exp
%type   <variable>              variable
%type   <statement>             stm empty_stm assign_stm compound_stm if_stm while_stm call_proc
%type   <typeExpression>        type
%type   <globalDeclaration>     global_dec proc_dec global_var
%type   <variableDeclaration>   local_var_dec
%type   <parameterDeclaration>  par_dec

%type   <statementList>         stm_list
%type   <expressionList>        arg_list
%type   <variableList>          local_var_list
%type   <parameterList>         par_list
%type   <globalDeclarationList> program global_list

%precedence "then"
%precedence ELSE

%start			program

%%

program             : global_list
                    ;

global_list         :
                    | global_dec global_list
                    ;

type                : IDENT
                    | ARRAY LBRACK INTLIT RBRACK OF type
                    ;
global_dec          : global_var
                    | proc_dec
                    ;
global_var          : TYPE type EQ type SEMIC
                    ;
proc_dec            : PROC IDENT LPAREN par_list RPAREN LCURL local_var_list stm_list RCURL

par_list            :
                    | non_empty_par
                    ;
non_empty_par       : par_dec
                    | par_dec COMMA non_empty_par
                    ;
par_dec             : REF IDENT COLON type
                    | IDENT COLON type
                    ;

local_var_list      :
                    | local_var_dec local_var_list
                    ;
local_var_dec       : VAR variable COLON type SEMIC
                    ;

stm_list            :
                    | stm stm_list
                    ;

stm                 : empty_stm
                    | assign_stm
                    | compound_stm
                    | if_stm
                    | while_stm
                    | call_proc
                    ;

empty_stm           : SEMIC
                    ;
compound_stm        : LCURL stm_list RCURL
                    ;
if_stm              : IF LPAREN exp RPAREN stm  %prec "then"
                    | IF LPAREN exp RPAREN stm ELSE stm
                    ;
while_stm           : WHILE LPAREN exp RPAREN stm
                    | DO stm WHILE LPAREN exp RPAREN stm
                    ;
assign_stm          : variable ASGN exp SEMIC
                    ;
call_proc           : IDENT LPAREN RPAREN SEMIC
                    | IDENT LPAREN arg_list RPAREN SEMIC
                    ;

arg_list            : exp
                    | exp COMMA arg_list
                    ;

exp                 : rel_exp
                    ;
rel_exp             : add_exp
                    | add_exp EQ add_exp
                    | add_exp NE add_exp
                    | add_exp LT add_exp
                    | add_exp LE add_exp
                    | add_exp GT add_exp
                    | add_exp GE add_exp
                    ;
add_exp             : mul_exp
                    | add_exp PLUS mul_exp
                    | add_exp MINUS mul_exp
                    ;
mul_exp             : unary_exp
                    | mul_exp STAR unary_exp
                    | mul_exp SLASH unary_exp
                    ;
unary_exp           : primary_exp
                    | MINUS unary_exp
                    ;
primary_exp         : INTLIT
                    | variable
                    | LPAREN rel_exp RPAREN
                    ;

array_index         : LBRACK add_exp RBRACK
                    | LBRACK add_exp RBRACK array_index
                    ;

variable            : IDENT
                    | IDENT array_index
                    ;
%%

void yyerror(Program** program, char *msg) {
    // The first parameter is needed because of '%parse-param {Program** program}'.
    // Both parameters are unused and gcc would normally emits a warning for them.
    // The following lines "use" the parameters, but do nothing. They are used to silence the warning.
    (void)program;
    (void)msg;
    syntaxError(yylval.noVal.position, yytext);
}

// This function needs to be defined here because yytname and YYTRANSLATE are only available in the parser's implementation file.
char const *tokenName(int token_class_id) {
  // 0 is a special case because token_name(token) return "$end" instead of EOF.
  return token_class_id == 0 ? "EOF" : yytname[YYTRANSLATE(token_class_id)];
}
