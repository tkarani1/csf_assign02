/*
 * postfix calculator (assembly language version)
 * main function implementation
 */

.section .rodata

/* TODO: add string constants and other read-only data here */
errorMsgNumArgs: .string "Wrong number of arguments\n"
result: .string "REsult is: %ld\n"


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
	/* TODO: implement */
	pushq %rbp

	cmpl $2, %esp          /* compare argc to 2  ??*/
	je .LwrongNumArgs
	movq 1(%rsi), %rdi     /* move pointer from argv[1] to %rdi */
	call eval
	movq %rax, %rsi       /* move result from eval into second arugment for printf */
	movq $result, %rdi    /* move string format to first argument for printf */
	call printf
	movq $0, %rax
	ret
.LwrongNumArgs:
	movq $errorMsgNumArgs, %rdi
	call printf
	movq $1, %rax
	ret


/* vim:ft=gas:
 */
