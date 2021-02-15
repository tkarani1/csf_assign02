#include <stdio.h>
#include <stdlib.h>
#include "cPostfixCalc.h"
#include <string.h>

/*
 * Example function (see tests in cTests.c)
 */
long addPositive(long a, long b) {
  if (a < 0L || b < 0L) {
    printf("Error: values must be positive\n");
    exit(1);
  }
  return a + b;
}

/*
 *  Casey
 * fatalError - print an error message an exit with an exit code of 1.
 * Prints a message of the form "Error: <message text>" to standard output.
 * Does not return!
 *
 * Params:
 *   msg - description of the error which occurred
 */
void fatalError(const char *msg) {
  printf("Error: ");
  printf(msg);
  exit(1);
}

/*
 * Casey
 * isSpace - tests a character code to determine whether or not it
 * is a space character.
 *
 * Params:
 *   c - an ASCII character code
 *
 * Returns:
 *   1 if c is a space or tab character, 0 otherwise
 *   (the function is allowed to also return 1 if c is a newline
 *   or carriage return, but it's only required to handle
 *   spaces and tabs)
 */
int isSpace(int c)  { //typecast c???
  return c == 32 || c == 9;
}

/*
 *  Casey
 * isDigit - tests a character code to determine whether it is one
 * of the digits '0' through '9'
 *
 * Params:
 *   c - an ASCII character code
 *
 * Returns:
 *   1 if c is a digit, 0 otherwise
 */
int isDigit(int c) {
  return c >= '0' && c <= '9';
}

/*
 *  Casey
 * skipws - skips any whitespace characters (as determined by isSpace)
 * at the beginning of a C character string.
 *
 * Params:
 *   s - pointer to a C character string
 *
 * Returns:
 *   pointer to the first non-space character in the string, or NULL
 *   if there are no non-space characters before the end of the string
 *   is reached
 */
const char *skipws(const char *s) {
  while (isSpace(*s)) {
    s++;
  }
  if (*s == '\n') {
    return NULL;
  }
  return s;
}

/*
 *  Trisha  
 * tokenType - return the token type (TOK_INT, TOK_OP, or TOK_UNKNOWN)
 * of the token at the beginning of given C character string.
 *
 * Params:
 *   s - nonempty C character string (which should not have any leading
 *       space characters)
 *
 * Returns:
 *   the token type
 */
int tokenType(const char *s) {
	char c = *s; 
	switch (c) {
		case '+':
		case '-': 
		case '*':
		case '/': 
			return TOK_OP; 
			break; 
		default: 
			if (isDigit(c)) {
				return TOK_INT; 
			} 
			break;
	}

	return TOK_UNKNOWN; 
}


/*
 *  Trisha
 * consumeInt - consume one or more digit characters at the beginning
 * of given C character string, convert them to an integer value, and
 * store the integer value in the long (64 bit signed integer)
 * variable that pval points to.
 *
 * Params:
 *   s    - pointer to a nonempty C character string which should start
 *          with a digit character
 *   pval - points to a long variable where the converted integer value
 *          should be stored
 *
 * Returns:
 *   pointer to the first character in the string that is not a digit
 */
const char *consumeInt(const char *s, long *pval) {
	//question: does consume mean that we remove the digits ???
	//unknown token type? no non-ints?
	//take the int as is or add values?
	int start = 0; 
	for (; start<strlen(s); start++) {
		if (isDigit(*(s+start))) {
			continue; 
		} else {
			break;
		}
	} 
	//use powers of ten instead?
/*	
	char * numString = (char *)calloc(start+2, sizeof(char));
	memcpy(numString, s, start+1); 
	numString[start+1] = '\0'; 
	*pval = atoi(numString); 
	free(numString); 
*/
	if (start == strlen(s)) {
		return -1; 
	} 

	return *(s+start); //make a new string? 
}

/*
 *  Trisha
 * consumeOp - consume an operator character from the beginning of the
 * given C character string.
 *
 * Params:
 *   s - pointer to a nonempty C character string
 *   op - pointer to an int (32 bit signed integer) variable where the
 *        ASCII code of the first character of s should be stored
 *
 * Returns:
 *   a pointer to the second character of s
 */
const char *consumeOp(const char *s, int *op) {
	char firstOp = *s; 
	*op = atoi(firstOp); 
	return *(s+1);
}

/*
 *  Casey
 * stackPush - push a long (64 bit signed integer) value onto the stack.
 * Calls the fatalError function if the stack is full.
 * A full stack contains MAX_STACK (20) values.
 * If a value is successfully pushed on the stack, the count should
 * be incremented by 1.
 *
 * Params:
 *   stack - pointer to the beginning of the stack storage array
 *   count - pointer to a long variable storing the number of items
 *           currently on the stack
 *   val   - the value to push onto the stack
 *
 * Returns:
 *   nothing
 */
void stackPush(long stack[], long *count, long val) {
  if (*count >= MAX_STACK) {
    fatalError("stack full!");
  } else {
	stack[*count] = val;
  	(*count)++;
  }
  return;
}

/*
 *   Trisha
 * stackPop - pops a long (64 bit signed integer) value from the stack.
 * Calls the fatalError function if the stack is empty.
 * If a value is successfully popped off the stack, the count should
 * be decremented by 1.
 *
 * Params:
 *   stack - pointer to the beginning of the stack storage array
 *   count - pointer to a long variable storing the number of items
 *           currently on the stack
 *
 * Returns:
 *   the value popped from the stack
 */
long stackPop(long stack[], long *count) {
  /* TODO: implement */
}

/*
 *  Casey
 * evalOp - evaluate a computation by applying an operator to two operands.
 *
 * Params:
 *   op - the operator ('+', '-', '*', or '/')
 *   left - the left operand
 *   right - the right operand
 *
 * Returns:
 *   the result of applying the operator to the operands
 */
long evalOp(int op, long left, long right) {
  switch(op) {
    	case '+' :
		return left + right;
    	case '-' :
		return left - right;
	case '*' :
		return left * right;
	case '/' :
		if (right == 0) {
			fatalError("Division by Zero"); 
		}
		return left / right;
	default :
		return 0L;
  }
  return 0L;
}
