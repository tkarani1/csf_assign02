/*
 * postfix calculator (assembly language version)
 * eval function implementation
 */

.equ TOK_INT, 0
.equ TOK_OP, 1
.equ TOK_UNKNOWN, 2

	.section .rodata

/* TODO: add string constants and other read-only data here */
errorMsgStart: .string "Error: "  // is it a problem that this is also defined in asmPostfixCalcFuncs.S?
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
        pushq %rbp            /* store callee-saved %rbp  */
	movq %rdi, %rdi
	call skipws           /* string pointer should already be in %rdi */
        pushq %r12            /* store callee-saved %r12 and align stack pointer */
        movq %rax, %r12       /* store whitespace-less string pointer in %r12 */
        subq $196, %rsp       /* memory for: stack (20 longs), count, left, right, pval, (longs), and op (int) */
        movq %rsp, %rbp       /* pointer to allocated memory on stack */
        subq $4, %rsp         /* align stack pointer */
        movq $0, 160(%rbp)    /* set count = 0 */
	jmp .LwhilePostfix

.LwhilePostfix:
        cmpq $0, %r12          /* is the string pointer NULL? */
        je .Ldone
	cmpb $0,(%r12)		/*is the string pointing to null terminator */
	je .Ldone
	movq %r12, %rdi		/* string pointer is first argument of tokenType */ 	
	call tokenType
	cmpl $TOK_OP, %eax	/* check if tokenType from result is an operator */
	je .LOp 
	cmpl $TOK_INT, %eax	/*check if tokenType from result is a number */
	je .LInt
	cmpl $TOK_UNKNOWN, %eax	/*check if tokenType is unkown - should this be unconditional? */
	je .LUnknown

.LOp:
	movq %r12, %rdi		/* string pointer is first argument of consumeOp */
	leaq 192(%rbp), %rsi    /* put address of op in second argument register */
        call consumeOp
        movq %rax, %r12          /* update string pointer after op was read */
        movq %rbp, %rdi          /* stack is first parameter for stackPop */
        leaq 160(%rbp), %rsi     /* address of count is second parameter */
        call stackPop
        movq %rax, 176(%rbp)     /* move the popped operand into right */
        movq %rbp, %rdi          /* stack is first parameter for stackPop */
        leaq 160(%rbp), %rsi     /* address of count is second parameter */
        call stackPop
        movq %rax, 168(%rbp)     /* move the popped operand into left */
        movl 192(%rbp), %edi     /* move operator into first argument register */
        movq 168(%rbp), %rsi     /* move left operand into second argument register */
        movq 176(%rbp), %rdx     /* move right operand into third argument register */
        call evalOp              /* result is in %rax */
        movq %rbp, %rdi          /* stack is first argument of stackPush */
        leaq 160(%rbp), %rsi     /* address of count is second argument of stackPush */
        movq %rax, %rdx          /* result of evalOp gets pushed onto stack! */
        call stackPush 
        movq %r12, %rdi          /* move string pointer to first agument for skipws */
	call skipws
        movq %rax, %r12          /* move updated string pointer back to %r12 */
	jmp .LwhilePostfix	

.LInt:         // r12 (string ptr) should aready be in rdi
	movq %r12, %rdi          /* pass address of string to first argument register */
        leaq 184(%rbp), %rsi     /* pass address of pval in second argument register */
        call consumeInt
        movq %rax, %r12          /* update string pointer after int was read */
        movq %rbp, %rdi          /* pointer to stack is first argument */
        leaq 160(%rbp), %rsi     /* address of stack count is second argument */
        movq 184(%rbp), %rdx     /* long value to push onto stack is third argument */
        call stackPush
        movq %r12, %rdi          /* move string pointer to first agument for skipws */
	call skipws
        movq %rax, %r12          /* move updated string pointer back to %r12 */
        jmp .LwhilePostfix
.LUnknown:
        movq $errorMsgInvalidString, %rdi
        call fatalError
        // what happens here?

.Ldone:
        cmpq $1, 160(%rbp)     /* is count == 1? */
        je .Lsuccess          /* if yes, success! */
        movq $errorMsgSingleVal, %rdi
        call fatalError      /* if not, call fatalError */
.Lsuccess:
        movq (%rbp), %rax    /* move last value on stack to return register */
        addq $200, %rsp      /* align stack pointer */
        popq %rbp            /* restore %rbp */
        popq %r12            /* restore %r12 */
	
ret

/* vim:ft=gas:
 */
