#include "symbolTable.h"
#include "ast.h"
#include "util.h"

extern SymbolTableStackEntryPtr symbolStackTop;

extern int scopeDepth;
int  ind=0;
AstNodePtr new_Node(NodeKind kind)
{
AstNodePtr n  = (AstNodePtr)malloc(sizeof(AstNode));
n->nKind = kind;
return n;
}
//creates a new expression node
AstNodePtr  new_ExprNode(ExpKind kind) 
{
AstNodePtr n = new_Node(EXPRESSION);
n->eKind = kind;
return n;
}

//creates a new statement node
AstNodePtr new_StmtNode(StmtKind kind)
{
AstNodePtr n = new_Node(STMT);
n->sKind = kind;
return n;
}

//creates a new type node for entry into symbol table
Type* new_type(TypeKind kind)
{

	Type* ty = (Type*)malloc(sizeof(Type));
	ty->kind=kind;
	return ty;
}







/* Original Code: Silvano Bonacia, Fall 2006 */
/* Modifications and changes, Prof. Venkat, Spring 08 */



extern AstNode *program;
extern SymbolTableStackEntryPtr symbolStackTop;

extern void printSymbolTable(); 

#define PAD_STR "   "





/*
 * Print the parameters of the method (parameters being in the
 * current scope)
 */
void outputMethodParams (SymbolTableStackEntryPtr scope) {
	int i;
	SymbolTableStackEntryPtr SymbolStackEntry = scope;
	for(i=0; i<MAXHASHSIZE;i++) {	
	   ElementPtr symelement = SymbolStackEntry->symbolTablePtr->hashTable[i];
		while(symelement) {
		   switch(symelement->stype->kind) {
		   case INT :
		      printf("int %s", symelement->id);
		   break;
		   case ARRAY :
		      printf("int %s[]", symelement->id);
		   break;
		   case VOID :
		      printf("Void");
		   break;
		   case FUNCTION :
		   break;
		   }
			symelement = symelement->next; 
			if(symelement)
			   printf(", ");
		}		
	}
} 

/*
 * Print the variable declarations of the scope.
 * Return the number of variables
 */
int outputVarDeclarations (SymbolTablePtr scope)
{

	int noVar = 0;
    int i;
	
	for(i=0; i<MAXHASHSIZE;i++) {	
	   ElementPtr symelement = scope->hashTable[i];
		while(symelement) {
		   
           switch(symelement->stype->kind) {
		   case INT :
		      printf("int %s;\n", symelement->id);
		      noVar++;
		   break;
		   case ARRAY :
		      printf("int %s[%d];\n", symelement->id, symelement->stype->dimension);
		      noVar++;
		   break;
		   case VOID:
		   break;
		   case FUNCTION :
		   break;
		   }
			symelement = symelement->next; 
		}		
	}	
	return noVar;
}

//traverses through the entire program and symbol table  and prints it
//the output must match the program with the exception of white spaces
//do a diff -w to ignre white spaces 
void outputType(TypePtr type, int dummy){

	switch(type->kind) {
	   case INT :
		   printf("INT");
		break;
		case ARRAY :
		   printf("INT");
		break;
		case VOID:
		   printf("VOID");
		break;
		case FUNCTION :
		   outputType(type->function, 0);
		break;	
	}

}

void output_Expression(AstNodePtr expr, int endWithSemi) {
   if(expr == NULL) {
      return;
   }

   switch(expr->eKind) {
   case VAR_EXP :  
      printf("Subtype: VAR_EXP\nIdentifier: %s\n", expr->nSymbolPtr->id);
   break;
   case ARRAY_EXP :
      printf("Subtype: ARRAY_EXP\nIdentifier: %s\n", expr->nSymbolPtr->id);
      output_Expression(expr->children[0], 0);
   break;
   case ASSI_EXP :
      printf("Subtype: ASSI_EXP\n");
      output_Expression(expr->children[0], 0); 
      output_Expression(expr->children[1], 0);
   break;
   case ADD_EXP :
      printf("Subtype: ADD_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case SUB_EXP :
      printf("Subtype: SUB_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case MULT_EXP :
      printf("Subtype: MULT_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case DIV_EXP :
      printf("Subtype: DIV_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case GT_EXP :
      printf("Subtype: GT_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case LT_EXP :
      printf("Subtype: LT_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case GE_EXP :
      printf("Subtype: GE_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break; 
   case LE_EXP :
      printf("Subtype: LE_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case EQ_EXP :
      printf("Subtype: EQ_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case NE_EXP :
      printf("Subtype: NE_EXP\n");
      output_Expression(expr->children[0], 0);
      output_Expression(expr->children[1], 0);
   break;
   case CALL_EXP :
      printf("Subtype: CALL_EXP\n");
      if(expr->children[0] != NULL) {
         output_Expression(expr->children[0], 0);
         AstNodePtr ptr = expr->children[0]->sibling;
         while(ptr != NULL) {
            output_Expression(ptr, 0);
            ptr = ptr->sibling;
         }
      }
   break;
   case CONST_EXP :
      printf("Subtype: CONST_EXP\nValue: %d\n", expr->nValue);
   break;
   }


}

void output_Statement(AstNodePtr stmt) {
   if(stmt == NULL)
      return;
   
      
   switch(stmt->sKind) {
   case IF_THEN_ELSE_STMT :
      printf("Subtype: IF_THEN_ELSE_STMT\n");
      output_Expression(stmt->children[0], 0);
      if(stmt->children[1] != NULL) {
         if(stmt->children[1]->sKind != COMPOUND_STMT) {
            ind++;
            output_Statement(stmt->children[1]);
            ind--;
         } else output_Statement(stmt->children[1]);  
      } 
      if(stmt->children[2] != NULL) {
                           
         if(stmt->children[2]->sKind != COMPOUND_STMT) {
            ind++;
            output_Statement(stmt->children[2]);
            ind--;
         } else output_Statement(stmt->children[2]); 
      } 
   break;
   case WHILE_STMT :
      printf("Subtype: WHILE_STMT\n");
      output_Expression(stmt->children[0], 0);
      if(stmt->children[1] != NULL) {
         if(stmt->children[1]->sKind != COMPOUND_STMT) {
            ind++;
            output_Statement(stmt->children[1]);
            ind--;
         } else output_Statement(stmt->children[1]);
      } 
   break;
   case RETURN_STMT :
      printf("Subtype: RETURN_STMT\n");
      if(stmt->children[0] != NULL)
	      output_Expression(stmt->children[0], 1);
   break;
   case COMPOUND_STMT :
      printf("Subtype: COMPOUND_STMT\n");
      ind++;
      if(stmt->nSymbolTabPtr != NULL) {
         if(outputVarDeclarations(stmt->nSymbolTabPtr) > 0)
            printf("\n");
      }  
      if(stmt->children[0] != NULL)          
         output_Statement(stmt->children[0]); // Print the first statement

      ind--;
   break;
   case EXPRESSION_STMT : 
      output_Expression(stmt->children[0], 1);
   break;
   }  
//printf("sibling : %d\n", stmt->sibling);   
   output_Statement(stmt->sibling); // Print the next statement
}

void output_Ast_Recursion(AstNodePtr root) { 
//printf("output_Ast_Recursion: root = %d\n", root);
   /*
    * End the recursion
    */
   if(root == NULL)
      return;
     
   switch(root->nKind) {
   case METHOD :
	//if(root->nKind)
      printf("Identifier: %s\n", root->nSymbolPtr->id);
      printf("Return type is: ");
      outputType(root->nType, 0);
      printf("\n");

      if(root->children[0] != NULL)
         output_Ast_Recursion(root->children[0]); // print the parameters of the method
     
      output_Ast_Recursion(root->children[1]); // print the body of the method
      output_Ast_Recursion(root->sibling); // print the next method
   break;
   case FORMALVAR :
//printf("root->nKind = FORMALVAR\n");   
      printf("Identifier: %s\n", root->nSymbolPtr->id); // print the name of the variable
       /*
       * Print the next parameter if there's one
       */
      if(root->sibling != NULL) {
         output_Ast_Recursion(root->sibling);
      }
   break;
   case STMT :
//printf("root->nKind = STMT\n");   
      output_Statement(root);
   break;
   case EXPRESSION :
//printf("root->nKind = EXPRESSION\n");   
      output_Expression(root, 1); // I don't think it ever gets here
   break;
   }
}

void print() {
   /*
    * First print the entire symbol table
    */
   //printSymbolTable();

   /*
    * Then print the program
    */
   ind = 0;


   output_Ast_Recursion(program);
}

 

