%{

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "ast.h"
#include "symbolTable.h"
#include "util.h"


/* other external function prototypes */
extern int yylex();
extern int initLex(int ,  char **);
 
    
/* external global variables */

extern int		yydebug;
extern int		yylineno;
extern SymbolTableStackEntryPtr symbolStackTop;
extern int scopeDepth;

/* function prototypes */ 
void	yyerror(const char *);

/* global variables */

AstNodePtr  program;
 

%}

/* YYSTYPE */
%union
{
    AstNodePtr AstNodePtr;
    int        iVal;
    char      *cVal;
    Type      *type;
    ElementPtr  element;
}

    

/* terminals */

%token TOK_IF TOK_RETURN TOK_VOID TOK_INT TOK_WHILE 
%token TOK_PLUS TOK_MINUS TOK_MULT TOK_DIV TOK_LT TOK_LE TOK_GT TOK_GE TOK_EQ TOK_NE TOK_ASSIGN TOK_SEMI TOK_COMMA
%token TOK_LPAREN TOK_LSQ TOK_RSQ TOK_LBRACE TOK_RBRACE TOK_ERROR
%token <cVal> TOK_ID TOK_RPAREN TOK_ELSE
%token <iVal> TOK_NUM
%type <element> Param
%type <AstNodePtr> Declarations Functions Fun_Declaration
%type <type> Type_Specifier 
%type <AstNodePtr> Compound_Stmt Statements Statement
%type <AstNodePtr> Expr_Statement If_Else_Statement Selection_Stmt Iteration_Stmt Return_Stmt  Param_List Params
%type <AstNodePtr> Expression Simple_Expression Additive_Expression Factor Var Call Term
%type <AstNodePtr> Args Args_List
/* associativity and precedence */

%right TOK_ASSIGN
%left TOK_EQ TOK_NE
%nonassoc TOK_LT TOK_GT	TOK_LE TOK_GE
%left TOK_PLUS TOK_SUB
%left TOK_MULT TOK_DIV 
%nonassoc error

%%


Start	: Declarations {

                        }
;



Declarations : Functions { 
   program = $1;
			 }
	     | Var_Declaration Declarations {
	     }
;

Functions    : Fun_Declaration {
			  
	                   $<AstNodePtr>$ = $1;
			   }
	     | Fun_Declaration Functions {
	     		   $<AstNodePtr>$ = $1;
			   $<AstNodePtr>$->sibling = $2;
		   	   }
;

Var_Declaration : Type_Specifier TOK_ID TOK_SEMI {
			        if(symLookup($2) != NULL && scopeDepth == symLookup($2)->scope)
					{
				        printf("Line %d: Symbol in this scope allready exists!\n", yylineno);
					exit(0);
					}
				else
					symInsert($2, $1, yylineno);

			   }
		| Type_Specifier TOK_ID TOK_LSQ TOK_NUM TOK_RSQ TOK_SEMI {
				$1->dimension=$4;
				$1->kind = ARRAY;
				if(symLookup($2) != NULL && scopeDepth == symLookup($2)->scope)
					{
					printf("Line %d: Symbol in this scope allready exists!\n", yylineno);
					exit(0);
					}
				else
					symInsert($2, $1, yylineno);
				
		           }
;

Fun_Declaration : Type_Specifier TOK_ID TOK_LPAREN 

{
		enterScope(); 
		

}

Params TOK_RPAREN Compound_Stmt {
				Type *  method_type;
				leaveScope();
				$<AstNodePtr>$ = new_Node(METHOD);
				$<AstNodePtr>$->children[0] = $5;
				$<AstNodePtr>$->children[1] = $7;
				method_type = new_type(FUNCTION);
				$<AstNodePtr>$->nType = method_type;
				method_type->function = $1;				
				ElementPtr e = symInsert($2, method_type, yylineno);
				$<AstNodePtr>$->nSymbolPtr = e;
                           }
;

Params : Param_List {
		$$ = $1;
			   }
       | TOK_VOID {
       		$$ = NULL;
       			   }
;

Param_List : Param_List TOK_COMMA Param {
			if($3 == NULL)
			printf("NULL");
			AstNodePtr last = $1;
			while(last->sibling != NULL)
				last = last->sibling;
			AstNodePtr n  = new_Node(FORMALVAR);
                        n->nSymbolPtr = $3;
                        n->nType = $3->stype;
                        n->sibling = NULL;
			last->sibling = n;
			$<AstNodePtr>$ = $1;
			   }
	   | Param {
			if($1==NULL)
			printf("NULL");
	   		$<AstNodePtr>$ = new_Node(FORMALVAR);
			$<AstNodePtr>$->nSymbolPtr = $1;
			$<AstNodePtr>$->nType = $1->stype;
			$<AstNodePtr>$->sibling = NULL;		
			}
			
;

Param : Type_Specifier TOK_ID  {
			$<element>$ = symInsert($2, $1, yylineno); 
		 	}
      | Type_Specifier TOK_ID TOK_LSQ TOK_RSQ  {
			$1->kind = ARRAY;
			$<element>$ = symInsert($2, $1, yylineno);
      			}
;
Type_Specifier : TOK_INT {
			$$=new_type(INT);
			}
	       | TOK_VOID {
	       	$$=new_type(VOID);
	       		}
;

Compound_Stmt : TOK_LBRACE Statements TOK_RBRACE {
		$<AstNodePtr>$ = new_StmtNode(COMPOUND_STMT);
		$<AstNodePtr>$->children[0]=$2;
			}
              | TOK_LBRACE {
			//if($-1 != ")" && $-1 != "else")
			enterScope();
			}
		Local_Declarations Statements TOK_RBRACE {
		$<AstNodePtr>$ = new_StmtNode(COMPOUND_STMT);
		$<AstNodePtr>$->children[0] = $4;	      
	      		}
;

Local_Declarations : Var_Declaration Local_Declarations {

			}
		   | Var_Declaration {
		   
		   	}
;

Statements : Statement Statements {
		$1->sibling = $2;			
		$$ = $1;

			}
	   | {
	   	$$ = NULL;
			}
;

Statement : Expr_Statement  {
		$<AstNodePtr>$ = $1;
			}
	  | Compound_Stmt {
	  	$<AstNodePtr>$ = $1;
			}
	  | Selection_Stmt {
		$<AstNodePtr>$ = $1;
	  		}
	  | Iteration_Stmt {
	  	$<AstNodePtr>$ = $1;
	  		}
	  | Return_Stmt {
	  	$<AstNodePtr>$ = $1;
			}
;

	       	

Selection_Stmt : If_Else_Statement %prec TOK_IF {
			$<AstNodePtr>$ = $1;
			$<AstNodePtr>$->children[2] = NULL;
			}
	       | If_Else_Statement TOK_ELSE Statement {
			$<AstNodePtr>$ = $1;
			$<AstNodePtr>$->children[2] = $3;
}
;

If_Else_Statement : TOK_IF TOK_LPAREN Expression TOK_RPAREN Statement {
			$<AstNodePtr>$ = new_StmtNode(IF_THEN_ELSE_STMT);
			$<AstNodePtr>$->children[0] = $3;
			$<AstNodePtr>$->children[1] = $5;
			}
;

Iteration_Stmt : TOK_WHILE TOK_LPAREN Expression TOK_RPAREN Statement {
			$<AstNodePtr>$ = new_StmtNode(WHILE_STMT);
			$<AstNodePtr>$->children[0] = $3;
			$<AstNodePtr>$->children[1] = $5;
			}
;

Return_Stmt : TOK_RETURN Expression TOK_SEMI {
			$<AstNodePtr>$ = new_StmtNode(RETURN_STMT);
			$<AstNodePtr>$->children[0] = $2;
			}
	    | TOK_RETURN TOK_SEMI {
	    		$<AstNodePtr>$ = new_StmtNode(RETURN_STMT);
			$<AstNodePtr>$->children[0] = NULL;
	    		}
;

Expr_Statement : Expression TOK_SEMI {
		$<AstNodePtr>$ = new_StmtNode(EXPRESSION_STMT);
		$<AstNodePtr>$->children[0]=$1;
}
;

Expression : Var TOK_ASSIGN Expression  {
		$<AstNodePtr>$ = new_ExprNode(ASSI_EXP);
		$<AstNodePtr>$->children[0] = $1;
		$<AstNodePtr>$->children[1] = $3;
			}
            | Simple_Expression {
	    	$<AstNodePtr>$ = $1;
	    		}
;

Var : TOK_ID {
		ElementPtr e = symLookup($1);
		if (e != NULL)
		{
			$<AstNodePtr>$ = new_Node(EXPRESSION);
			$<AstNodePtr>$->eKind = VAR_EXP;
			$<AstNodePtr>$->nSymbolPtr = e;
			$<AstNodePtr>$->nType = e->stype;
			$<AstNodePtr>$->nLinenumber = yylineno;		
		}
		else{
			printf("Unidentified variable %s in line:%d",$1,yylineno);
			exit(0);
		}
			}
    | TOK_ID TOK_LSQ Simple_Expression TOK_RSQ {
    		ElementPtr e = symLookup($1);
		if(e != NULL)
		{
		$<AstNodePtr>$ = new_Node(EXPRESSION);
		$<AstNodePtr>$->children[0] = $3;
		$<AstNodePtr>$->eKind = ARRAY_EXP;
		$<AstNodePtr>$->nSymbolPtr = e;
		$<AstNodePtr>$->nType = e->stype;
		$<AstNodePtr>$->nLinenumber = yylineno;
		}
		else{
			printf("Unidentified variable %s in line:%d", $1, yylineno);
			exit(0);
		}
    			}
;

Simple_Expression : Additive_Expression TOK_GT Additive_Expression {
		$<AstNodePtr>$ = new_ExprNode(GT_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
			}
                  | Additive_Expression TOK_LT Additive_Expression {
		$<AstNodePtr>$ = new_ExprNode(LT_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
		  	}
                  | Additive_Expression TOK_GE Additive_Expression {
		$<AstNodePtr>$ = new_ExprNode(GE_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
		  	}
                  | Additive_Expression TOK_LE Additive_Expression {
		$<AstNodePtr>$ = new_ExprNode(LE_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
			}
                  | Additive_Expression TOK_EQ Additive_Expression {
		$<AstNodePtr>$ = new_ExprNode(EQ_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
		  	}
                  | Additive_Expression TOK_NE Additive_Expression {
		$<AstNodePtr>$ = new_ExprNode(NE_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
		  	}
		  | Additive_Expression {
		$<AstNodePtr>$ = $1;
		  	}
;

Additive_Expression : Additive_Expression TOK_PLUS Term {
		$<AstNodePtr>$ = new_ExprNode(ADD_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
			}
                    | Additive_Expression TOK_MINUS Term {
		$<AstNodePtr>$ = new_ExprNode(SUB_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
		    	}
		    | Term {
		$<AstNodePtr>$ = $1;    
		    	}
;

Term : Term TOK_MULT Factor  {
		$<AstNodePtr>$ = new_ExprNode(MULT_EXP);
                $<AstNodePtr>$->children[0] = $1;
                $<AstNodePtr>$->children[1] = $3;
			}
     |  Term TOK_DIV Factor {
     		$<AstNodePtr>$ = new_ExprNode(DIV_EXP);
		$<AstNodePtr>$->children[0] = $1;
		$<AstNodePtr>$->children[1] = $3;
     			}
     | Factor {
		$<AstNodePtr>$ = $1;     			
			}
;

Factor : TOK_LPAREN Expression TOK_RPAREN {
		$<AstNodePtr>$ = $2;
			}
       | Var {
       		$<AstNodePtr>$ = $1;
			}
       | Call {
       		$<AstNodePtr>$ = $1; 
       			}
       | TOK_NUM {
       		$<AstNodePtr>$ = new_ExprNode(CONST_EXP);
		$<AstNodePtr>$->nValue = $1;
       			}
;

Call : TOK_ID TOK_LPAREN Args TOK_RPAREN {
		$<AstNodePtr>$ = new_ExprNode(CALL_EXP);
		$<AstNodePtr>$->fname = $1;
		$<AstNodePtr>$->children[0]=$3;
			}
;

Args : Args_List {
		$<AstNodePtr>$ = $1;			
			}
     | {
		$<AstNodePtr>$ = NULL;     
     			}
;

Args_List : Args_List TOK_COMMA Expression {
		AstNodePtr current_node = $1;
		while(current_node->sibling != NULL)
			current_node = current_node->sibling;
		current_node->sibling = $3;
		$<AstNodePtr>$ = $1;
			}
	  | Expression {
	  	$<AstNodePtr>$ = $1;
		$<AstNodePtr>$->sibling = NULL;
	  		}
;

%%
void yyerror (char const *s) {
       fprintf (stderr, "Line %d: %s\n", yylineno, s);
}

int main(int argc, char **argv){
	initSymbolTable();
	initLex(argc,argv);

#ifdef YYLLEXER
   while (gettok() !=0) ; //gettok returns 0 on EOF
    return;
#else
    yyparse();
    print();
//    printSymbolTable();

    
#endif
    
} 


