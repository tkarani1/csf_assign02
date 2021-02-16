#include <stdio.h>
#include <stdlib.h>
#include "cPostfixCalc.h"

/*
 *   Trisha
 * eval - evaluate a postfix expression
 * Should directly or indirectly call fatalError if the expression is invalid.
 *
 * Params:
 *   s - C string containing a postfix expression
 *
 * Returns:
 *   the result of evaluating the expression
 */
long eval(const char *s) {
  /* TODO: implement */

  /* Note: this function should be implemented by calling functions
   * declared in cPostfixCalc.h and defined in cPostfixCalcFuncs.c
   */

	s = skipws(s); 

	int op; 
	long pval; 
	long stack [MAX_STACK]; 	
	long count; 
	long left; 
	long right; 
	while (s != NULL && *s != '\0') {  
		int token = tokenType(s); 
		if (token == TOK_OP) {
			s = consumeOp(s, &op);
			right = stackPop(stack, &count); 
			left = stackPop(stack, &count); 
		    pval = evalOp(op, left, right); 
			stackPush(stack, &count, pval); 		
		} else if (token == TOK_INT) {
			s = consumeInt(s, &pval); 
			stackPush(stack, &count, pval); 
			continue; 
		} else { //TOK_UNKNOWN case
		       fatalError("Invalid token in string"); 
		}
 		s = skipws(s); 		
	}
	if (count != 1) {
		fatalError("Stack should end up with a single value");
	}
  return 0L;
}
