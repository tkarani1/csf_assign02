/*
 * postfix calculator (assembly language version)
 * main function implementation
 * CSF Assignment 2
 * C. Levitt
 * clevitt1@jh.edu
 * T. Karani
 * tkarani1@jh.edu
 */

.section .rodata


errorMsgNumArgs: .string "Wrong number of arguments\n"
result: .string "Result is: %ld\n"


.section .text

/*
 * main function: program entry point
 *
 * Params:
 *   argc - number of command line arguments (including program name)
 *   argv - array of pointers to command line arguments
 *
 * Returns:
 *   exit code
 */
	.globl main
main:
	subq $8, %rsp          /* align stack pointer */
	cmpl $2, %edi          /* compare argc to 2  */
	jne .LwrongNumArgs     /* jump if number of arguments not equal to 2 */
	movq 8(%rsi), %rdi     /* string pointer from argv[1] is first arg for eval */
	call eval
	movq %rax, %rsi       /* move result from eval into second arg for printf */
	movq $result, %rdi    /* move string format to first arg for printf */
	call printf
	addq $8, %rsp        /* restore stack pointer */
	movq $0, %rax        /* return zero */
	ret
.LwrongNumArgs:
	movq $errorMsgNumArgs, %rdi   /* move error string into first arg for printf */
	call printf
	addq $8, %rsp        /* restore stack pointer */
	movq $1, %rax        /* return 1 */
	ret


/* vim:ft=gas:
 */
