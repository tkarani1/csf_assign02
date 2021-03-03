/*
 * postfix calculator (assembly language version)
 * eval function implementation
 * CSF Assignment 2
 * C. Levitt
 * clevitt1@jh.edu
 * T. Karani
 * tkarani1@jh.edu
 */

.equ TOK_INT, 0
.equ TOK_OP, 1
.equ TOK_UNKNOWN, 2

	.section .rodata

errorMsgSingleVal: .string "stack should end up with a single value!"
errorMsgInvalidString: .string "invalid expression"

	.section .text

/*
 * eval - evaluate a postfix expression
 * Should directly or indirectly call fatalError if the expression is invalid.
 *
 * Params:
 *   s - C string containing a postfix expression
 *
 * Returns:
 *   the result of evaluating the expression
 */
	.globl eval
eval:
/*  local variable memory offsets from %rbp (in bytes)
*   stack: 0    count: 160    left: 168    right: 176    pval: 184    op: 192
*/
        pushq %rbp            /* store callee-saved %rbp and align stack pointer */
	call skipws           /* string pointer should already be in %rdi */
        pushq %r12            /* store callee-saved %r12 */
        movq %rax, %r12       /* string pointer will be stored in %r12 */
        subq $196, %rsp       /* memory for: stack (20 longs), count, left, right, pval (longs), and op (int) */
        movq %rsp, %rbp       /* pointer to allocated memory on stack */
        subq $4, %rsp         /* align stack pointer (2 pushes and 200 sub -> total offset 216, 216 % 16 = 8 */
        movq $0, 160(%rbp)    /* set count to 0 */
	jmp .LwhilePostfix

.LwhilePostfix:
        cmpq $0, %r12          /* is the string pointer NULL? */
        je .Ldone
	cmpb $0,(%r12)		/*is the string pointing to null terminator */
	je .Ldone
	movq %r12, %rdi		/* string pointer is first arg of tokenType */ 	
	call tokenType
	cmpl $TOK_OP, %eax	/* check if tokenType is an operator */
	je .LOp 
	cmpl $TOK_INT, %eax	/* check if tokenType is a number */
	je .LInt
        jmp .LUnknown
.LOp:
	movq %r12, %rdi		/* string pointer is first arg of consumeOp */
	leaq 192(%rbp), %rsi    /* address of op in second arg of consumeOp */
        call consumeOp
        movq %rax, %r12          /* update string pointer after op was read */
        movq %rbp, %rdi          /* stack is first arg for stackPop */
        leaq 160(%rbp), %rsi     /* address of count is second arg for stackPop */
        call stackPop
        movq %rax, 176(%rbp)     /* move the popped operand into right */
        movq %rbp, %rdi          /* stack is first arg for stackPop */
        leaq 160(%rbp), %rsi     /* address of count is second arg for stackPop */
        call stackPop
        movq %rax, 168(%rbp)     /* move the popped operand into left */
        movl 192(%rbp), %edi     /* op is first arg for evalOp */
        movq 168(%rbp), %rsi     /* left operand is second arg for evalOp */
        movq 176(%rbp), %rdx     /* right operand is third arg for evalOp */
        call evalOp              /* result of operation is in %rax */
        movq %rax, 184(%rbp)     /* store result of the operation in pval */
        movq %rbp, %rdi          /* stack is first arg of stackPush */
        leaq 160(%rbp), %rsi     /* address of count is second arg of stackPush */
        movq 184(%rbp), %rdx     /* pval is third argument of stackPush */
        call stackPush 
        movq %r12, %rdi          /* string pointer is first arg for skipws */
	call skipws
        movq %rax, %r12          /* move updated string pointer back to %r12 */
	jmp .LwhilePostfix	

.LInt:        
	movq %r12, %rdi          /* string pointer is first arg for consumeInt */
        leaq 184(%rbp), %rsi     /* address of pval is second arg for consumeInt */
        call consumeInt          /* int to be pushed is stored in pval */
        movq %rax, %r12          /* update string pointer after int was read */
        movq %rbp, %rdi          /* pointer to stack is first arg for stackPush */
        leaq 160(%rbp), %rsi     /* address of stack count is second arg for stackPush */
        movq 184(%rbp), %rdx     /* pval is third arg for stackPush */
        call stackPush           /* push pval onto the stack */
        movq %r12, %rdi          /* string pointer is first arg for skipws */
	call skipws
        movq %rax, %r12          /* move updated string pointer back to %r12 */
        jmp .LwhilePostfix
.LUnknown:
        movq $errorMsgInvalidString, %rdi  /* error string is first arg for fatalError */
        call fatalError

.Ldone:
        cmpq $1, 160(%rbp)     /* is count == 1? */
        je .Lsuccess           /* if yes, success! */
        movq $errorMsgSingleVal, %rdi  /* if no, move error msg to first arg for fatalError */
        call fatalError        
.Lsuccess:
        movq (%rbp), %rax    /* move last value on stack to return register */
        addq $200, %rsp      /* align stack pointer */
        popq %r12            /* restore callee-saved %r12 */
        popq %rbp            /* restore callee-saved %rbp */
	ret

/* vim:ft=gas:
 */
