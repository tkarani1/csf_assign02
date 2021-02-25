/*
 * postfix calculator (assembly language version)
 * eval function implementation
 */

.equ TOK_INT, 0
.equ TOK_OP, 1
.equ TOK_UNKNOWN, 2

	.section .rodata

/* TODO: add string constants and other read-only data here */
errorMsgStart: .string "Error: "
errorMsgSingleVal: .string "stack should end up with a single value!"

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
        pushq %r12            /* store callee-saved %r12 and align stack pointer */
        call skipws           /* string pointer should already be in %rdi */
        movq %rax, %r12       /* store whitespace-less string pointer in %r12 */
        pushq %rbp            /* store callee-saved %rbp  */
        subq $196, %rsp       /* memory for: stack (20 longs), count, left, right, pval, (longs), and op (int) */
        movq %rsp, %rbp       /* pointer to allocated memory on stack */
        subq $4, %rsp         /* align stack pointer */
        movq $0, 160(%rbp)    /* set count = 0 */
        cmp $0, %r12          /* is the string pointer NULL? */
        je .Ldone

.Ldone:
        cmp $1, 160(%rbp)     /* is count == 1? */
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
