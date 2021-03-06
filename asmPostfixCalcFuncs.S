/*
 * postfix calculator (assembly language version)
 * function implementations
 * CSF Assignment 2
 * C. Levitt
 * clevitt1@jh.edu
 * T. Karani
 * tkarani1@jh.edu
 */

/*
 * postfix calculator (assembly language version)
 * function implementation
 */

.equ TOK_INT, 0
.equ TOK_OP, 1
.equ TOK_UNKNOWN, 2

.equ MAX_STACK, 20

	.section .rodata

/* string constants */
eNegativeValue: .string "Negative value"
errorMsgStart: .string "Error: "
errorMsgStackFull: .string "stack full!"
errorMsgStackEmpty: .string "no more operands on stack!"
errorMsgDivByZero: .string "division by zero!"
intInputFormat: .string "%ld"


	.section .text

/*
 * addPositive function (this is just an example function)
 */
	.globl addPositive
addPositive:
	subq $8, %rsp                /* align stack pointer */

	movq $0, %r10                /* let %r10 be 0 */
	cmpq %rdi, %r10              /* compare 1st param to 0 */
	jg .LaddPositiveNegativeOperand /* if less, it's negative */
	cmpq %rsi, %r10              /* compare 2nd param to 0 */
	jg .LaddPositiveNegativeOperand /* if less, it's negative */

	/* both operands are non-negative, do the addition */
	movq %rsi, %rax              /* move second parameter to %rax */
	addq %rdi, %rax              /* add first parameter to second */
	jmp .LaddPositiveDone

.LaddPositiveNegativeOperand:
	movq $eNegativeValue, %rdi
	call fatalError
9:	jmp 9b                       /* should not get here */

.LaddPositiveDone:
	/* the sum is now in %rax */
	addq $8, %rsp                /* restore stack pointer */
	ret


/*
 * Casey
 * fatalError - print an error message an exit with an exit code of 1.
 * Prints a message of the form "Error: <message text>" to standard output.
 * Does not return!
 *
 * Params:
 *   msg - description of the error which occurred
 */
	.globl fatalError
fatalError:
	/* note that this function should not return */
	pushq %r12					/* callee-saved, also aligns stack pointer */           
	movq %rdi, %r12            	/*  store error msg body in r12 */
	movq $errorMsgStart, %rdi   /* move "Error: " pointer to 1st arg for printf */
	call printf
	movq %r12, %rdi             /* move error msg body to 1st arg for printf */
	call printf
	movq $1, %rdi				/* calling exit with code 1 */
	call exit


/* Casey
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
	.globl isSpace
isSpace:
	cmpl $32, %edi         	/* compare c to 32 (space) */
	je .LreturnTrue       	/* if equal, return true */
	cmpl $9, %edi          	/* compare c to 9 (tab) */
	je .LreturnTrue       	/* if equal, return true */
	movl $0, %eax          	/* fall through to return false */
	ret
.LreturnTrue:
	movl $1, %eax          /* returns 1 if c is whitespace */
	ret

/*
 *  Trisha
 * isDigit - tests a character code to determine whether it is one
 * of the digits '0' through '9'
 *
 * Params:
 *   c - an ASCII character code
 *
 * Returns:
 *   1 if c is a digit, 0 otherwise
 */
	.globl isDigit
isDigit:
	cmpl $48, %edi 		/* compare c to 48 ('0') */
	jl .LreturnFalse	/* if c is less than '0', return false */
	cmp $57, %edi 		/* compare c to 57 ('9') */
	jg .LreturnFalse	/* if c is greater than '9', return false */
	movl $1, %eax 		/*if c not < 0 or > 9, it is digit */
	ret
.LreturnFalse:
	movl $0, %eax		/* return 0 for false */
	ret

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
	.globl skipws
skipws:
	pushq %r12     			/* preserve the value of r12, aligns stack pointer */
	movq %rdi, %r12       	/* r12 will be string iterator */
.LwhileTop:					/* loop traversing string */
	movzbl (%r12), %edi  	/* put the character in first arg for isSpace */
	call isSpace       
	cmpl $1, %eax         	/* is this character a space? */
	jne .Ldone             	/* if not whitespace, done */
	incq %r12              	/* advance string pointer */
	jmp .LwhileTop
.Ldone:
	cmpb $0, (%r12)      	/* check if our string iterator is at null terminator */
	je .LreturnNull 		/* if equal, return NULL */
	movq %r12, %rax        	/* put string pointer in return register */
	popq %r12             	/*  restore %r12 */
	ret
.LreturnNull:
	movq $0, %rax          	/* put NULL (0) in return register */
	popq %r12              	/*  restore %r12 */
	ret						/* return rax */


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
	.globl tokenType
tokenType:
	movzbq (%rdi), %r11	/* save first character of string %r11 */
	cmp $42, %r11 		/* check if first char is '*' */
	je .LisOp		/* jump if equal */
        cmp $43, %r11 		/* check if %r11 is '+' */
        je .LisOp		/* jump if equal */
        cmp $45, %r11		/* check if %r11 is '-' */
        je .LisOp		/* jump if equal */
        cmp $47, %r11 		/* check if %r11 is '/' */
        je .LisOp		/* jummp if equal */
	subq $8, %rsp          	/* align stack pointer */
       	movzbl (%rdi), %edi    	/* put first char in rdi - is movzbl right? */
        call isDigit           	/* use isDigit to check if char is a number*/
	addq $8, %rsp          	/* restore stack pointer */
        cmp $1, %eax          	/* did it return true? */
        je .LisInt            	/* if isDigit true, jump to .LisInt to return TOK_INT*/
	jmp .LisUn		/* if not operator or digit, token is undefined */
.LisInt: 
	movl $TOK_INT, %eax 	/* move TOK_INT to be returned */
	ret
.LisOp:
	movl $TOK_OP, %eax	/* move TOK_OP to be returned */
	ret
.LisUn: 
	movl $TOK_UNKNOWN, %eax	/* move TOK_UNKNOWN to be returned */
	ret

/*
 * Trisha
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
	.globl consumeInt
consumeInt:
        pushq %r12          	/* preserve the value of r12, aligns stack pointer */
        movq %rdi, %r12       	/* store string pointer in r12 */
	pushq %r13
	movq %rsi, %r13		/* save pval pointer into %r13 */
	movq $intInputFormat, %rsi	/* save sscanf input format into %rsi */
	movq %r13, %rdx		/* save pval pointer into third argument %rdx */
	subq $8, %rsp		/* align stack pointer */
	call sscanf 		/* save int into pval (in %r13) */
.LwhileInt:
        movzbl (%r12), %edi    	/* put first char in rdi */
        call isDigit          	/* is this char a space? */
        cmpl $0, %eax          	/* did it return false? */
        je .LdoneFinding     	/* if not digit, jump to done */
        incq %r12             	/* advance string pointer */
        jmp .LwhileInt
.LdoneFinding:
	addq $8, %rsp 		/* align stack pointer */
        movq %r12, %rax        	/* put string pointer in return register */
	popq %r13		/* restore %r13 */
        popq %r12              	/*  restore %r12 */
        ret
/*
 *  Casey
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
	.globl consumeOp
consumeOp:
	movzbl (%rdi), %r10d    /* get operator from memory, store temporarily */
	movl %r10d, (%rsi)		/* store operator in op */
	addq $1, %rdi			/* advance string pointer */
	movq %rdi, %rax         /* return advanced string pointer */
	ret

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
	.globl stackPush
stackPush:
	subq $8, %rsp					/* align stack pointer */
	movq (%rsi), %r10       		/* store current stack count in r10 */
	cmpq $MAX_STACK, %r10          	/* compare current size (r10) to max stack size */
	jl .Lpush                       /* if curSize < max, jump to push - otherwise, fall through to fatalError */
	movq $errorMsgStackFull, %rdi   /* move address of error message for fatalError */
	call fatalError                 /* should not return */
.Lpush:
	movq %rdx, (%rdi, %r10, 8)		/* push given value to the top of the stack */
	incq (%rsi)						/* increment stack count */
	addq $8, %rsp					/* align stack pointer */
	ret

/*
 *  Trisha
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
	.globl stackPop
stackPop:
	pushq %r12       	/* using a callee saved register and aligning stack pointer */
	movq %rdi, %r12     	/* put address of stack in %r12 */
	movq (%rsi), %r11	/* put stack size in %r11 */
	cmp $0, %r11  		/* check if stack is empty */
	jg .Lpop		/* if count > 0, pop */
	movq $errorMsgStackEmpty, %rdi	/* if count <= 0, put error message in first argument register */
	call fatalError		/* if count <=0, call fatalError */
.Lpop:
	subq $1, %r11 	/* decrement count */
	movq %r11, (%rsi) /*move r11 value to count */
	movq (%r12, %r11, 8),%rax 
	popq %r12
	ret

/*
 *  Trisha
 * evalOp - evaluate a computation by applying an operator to two operands.
 *
 * Params:
 *   op - the operator ('+', '-', '*', or '/')  (int)
 *   left - the left operand   (long)
 *   right - the right operand   (long)
 *
 * Returns:
 *   the result of applying the operator to the operands
 */
	.globl evalOp
evalOp:    
  	movl %edi, %r11d     	/* save op into %r11d */
	movq %rsi, %r10		/* save left into %r10 */
	movq %rdx, %r9		/* save right into %r9 */
    	cmp $42, %r11d		/* check if op is '*' */
	je .LMult		/* if op is '*' then multiply */
    	cmp $43, %r11d 		/* check if op is '+' */
    	je .LAdd		/* if op is '+' then add */
    	cmp $45, %r11d 		/* check if op is '-' */
    	je .LSub		/* if equal, subtract */
    	cmp $47, %r11d		/* check if op is '/'*/
    	je .LDiv		/* if equal, divide */
.LAdd:			
	addq %r10, %r9		/* add left and right */
	movq %r9, %rax		/* result stored in r9 */
	ret
.LMult: 
	imulq %r10, %r9		/* signed multiplication of left and right */
	movq %r9, %rax		/* move result from r9 to rax  */
	ret			/* return rax */
.LSub:
	subq %r9, %r10		/* subtraction of left and right */
	movq %r10, %rax		/* move result from r10 to rax */
        ret			
.LDiv: 
	cmp $0, %r9		/* check if right is 0 - avoid divide by 0 */
	je .LDivByZero		/* if equal, jump and send error */
	movq %r10, %rax		/* store left in r10 */
	cqto 			/* sign extend rax to rdx:rax */
	idivq %r9		/* signed integer division - left / right */
    	ret			/* return result stored in r9 */
.LDivByZero:
	movq $errorMsgDivByZero, %rdi	/*send error message as first argument to fatalError */
	subq $8, %rsp			/* align stack pointer */
	call fatalError

/* vim:ft=gas:
 */
