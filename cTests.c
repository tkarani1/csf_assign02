/*
 * Unit tests for C version of postfix calculator
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tctest.h"
#include "cPostfixCalc.h"

typedef struct {
	/* TODO: add fields for test fixture */

	/* representation of operand stack */
	long values[MAX_STACK];
	long count;
} TestObjs;

TestObjs *setup(void) {
	TestObjs *objs = malloc(sizeof(TestObjs));

	/* TODO: initialize test fixture */

	/* stack is initially empty */
	objs->count = 0;

	return objs;
}

void cleanup(TestObjs *objs) {
	/* TODO: do any cleanup needed for test fixture */

	free(objs);
}

/*
 * Prototypes for test functions
 */
void testAddPositive(TestObjs *obj);         /* example test function */
void testAddPositiveInvalid(TestObjs *obj);  /* example test function */
void testIsSpace(TestObjs *objs);
void testIsDigit(TestObjs *objs);
void testSkipws(TestObjs *objs);
void testTokenType(TestObjs *objs);
void testConsumeInt(TestObjs *objs);
void testConsumeOp(TestObjs *objs);
void testPush(TestObjs *objs);
void testPushFull(TestObjs *objs);
void testPop(TestObjs *objs);
void testEvalOp(TestObjs *objs);
void testEval(TestObjs *objs);
void testEvalInvalid(TestObjs *objs);

/* set to nonzero if a call to exit is expected */
int expectedExit;
/* jump buffer that our version of exit can use to jump back to test function */
sigjmp_buf exitBuf;

/*
 * Custom version of exit: useful for testing functions where
 * the expected behavior is a call to exit (e.g., because
 * an argument value is invalid.)  If the expectedExit
 * variable is set to a nonzero value, uses siglongjmp (via
 * exitBuf) to return control to the test function.
 * If expectedExit is not set, immediately fails the
 * current test.
 */
void exit(int exitCode) {
	if (expectedExit) {
		/* jump back to test function */
		siglongjmp(exitBuf, 1);
	} else {
		/* exit called unexpectedly, fail the test */
		FAIL("Unexpected exit");
	}
}

void on_complete(int numPassed, int numExecuted) {
	printf("%d/%d tests passed\n", numPassed, numExecuted);
}

/*
 * Main function.
 * If no command line arguments are passed,
 * executes all tests.  If a single command line
 * argument is passed, only the test with that
 * name is executed.
 */
int main(int argc, char **argv) {
	if (argc > 2) {
		printf("Usage: %s [<test name>]\n", argv[0]);
		return 1;
	}

	if (argc == 2) {
		tctest_testname_to_execute = argv[1];
	}

	tctest_on_complete = on_complete;

	TEST_INIT();

	TEST(testAddPositive);
	TEST(testAddPositiveInvalid);
	TEST(testIsSpace);
	TEST(testIsDigit);
	TEST(testSkipws);
	TEST(testTokenType);
	TEST(testConsumeInt);
	TEST(testConsumeOp);
	TEST(testPush);
	TEST(testPushFull);
	TEST(testPop);
	TEST(testEvalOp);
       	TEST(testEval);
       	TEST(testEvalInvalid);

	TEST_FINI();
}

/*
 * Example test function.
 */
void testAddPositive(TestObjs *obj) {
	ASSERT(2L == addPositive(1L, 1L));
	ASSERT(23L == addPositive(15L, 8L));
}

/*
 * Example of a test function that verifies that an invalid
 * input results in a call to the exit function.
 */
void testAddPositiveInvalid(TestObjs *obj) {
	/*
	 * addPositive should call exit if either of its arguments is negative
	 */

	expectedExit = 1;

	if (sigsetjmp(exitBuf, 1) == 0) {
		addPositive(-1L, 1L);
		FAIL("addPositive with invalid first argument did not exit");
	} else {
		printf("addPositive exited, good...");
	}

	if (sigsetjmp(exitBuf, 1) == 0) {
		addPositive(1L, -1L);
		FAIL("addPositive with invalid second argument did not exit");
	} else {
		printf("addPositive exited, good...");
	}
}

void testIsSpace(TestObjs *objs) {
	ASSERT(isSpace(' '));
	ASSERT(isSpace('\t'));
	ASSERT(!isSpace('0'));
	ASSERT(!isSpace('3'));
	ASSERT(!isSpace('+'));
	ASSERT(!isSpace('a'));
}

void testIsDigit(TestObjs *objs) {
	ASSERT(isDigit('0'));
	ASSERT(isDigit('1'));
	ASSERT(isDigit('2'));
	ASSERT(isDigit('3'));
	ASSERT(isDigit('4'));
	ASSERT(isDigit('5'));
	ASSERT(isDigit('6'));
	ASSERT(isDigit('7'));
	ASSERT(isDigit('8'));
	ASSERT(isDigit('9'));
	ASSERT(!isDigit(' '));
	ASSERT(!isDigit('\t'));
	ASSERT(!isDigit('a'));
	ASSERT(!isDigit('/'));
	ASSERT(!isDigit(':'));
}

void testSkipws(TestObjs *objs) {
	ASSERT(0 == strcmp("abc", skipws("abc")));
	ASSERT(0 == strcmp("abc", skipws(" abc")));
	ASSERT(0 == strcmp("abc", skipws("\tabc")));
	ASSERT(0 == strcmp("abc", skipws("     abc")));
	ASSERT(0 == strcmp("abc", skipws("\t\t\t\tabc")));
	ASSERT(0 == strcmp("abc", skipws(" \tabc")));
	ASSERT(NULL == skipws(""));
}

void testTokenType(TestObjs *objs) {
	
	ASSERT(TOK_OP == tokenType("+")); 
	ASSERT(TOK_OP == tokenType("/")); 
	ASSERT(TOK_OP == tokenType("*")); 
	ASSERT(TOK_OP == tokenType("-")); 
	ASSERT(TOK_UNKNOWN == tokenType("$")); 
	ASSERT(TOK_INT == tokenType("0")); 
	ASSERT(TOK_INT == tokenType("9"));
    ASSERT(TOK_INT == tokenType("4"));
	ASSERT(TOK_OP == tokenType("-5"));        
	ASSERT(TOK_INT == tokenType("2 3 +"));
	ASSERT(TOK_INT == tokenType("123 4 +"));
	ASSERT(TOK_OP == tokenType("+ 2 3"));
	ASSERT(TOK_OP == tokenType("- 2 3"));
	ASSERT(TOK_OP == tokenType("* 2 3"));
	ASSERT(TOK_OP == tokenType("/ 2 3"));

	ASSERT(TOK_UNKNOWN == tokenType("abc"));
	ASSERT(TOK_UNKNOWN == tokenType("?"));
	
}

void testConsumeInt(TestObjs *objs) {
	long val;
	ASSERT(0 == strcmp(" 3 +", consumeInt("2 3 +", &val)));
	ASSERT(2L == val);
	ASSERT(0 == strcmp(" 456 -", consumeInt("123 456 -", &val)));
	ASSERT(123L == val);
}

void testConsumeOp(TestObjs *objs) {
	int op;

	ASSERT(0 == strcmp(" 3", consumeOp("+ 3", &op)));
	ASSERT('+' == op);
	ASSERT(0 == strcmp(" 3", consumeOp("- 3", &op)));
	ASSERT('-' == op);
	ASSERT(0 == strcmp(" 3", consumeOp("* 3", &op)));
	ASSERT('*' == op);
	ASSERT(0 == strcmp(" 3", consumeOp("/ 3", &op)));
	ASSERT('/' == op);
}

void testPush(TestObjs *objs) {
	ASSERT(0 == objs->count);
	stackPush(objs->values, &objs->count, 123L);
	ASSERT(1 == objs->count);
	ASSERT(123L == objs->values[0]);
	stackPush(objs->values, &objs->count, 456L);
	ASSERT(2 == objs->count);
	ASSERT(456L == objs->values[1]);
	stackPush(objs->values, &objs->count, 789L);
	ASSERT(3 == objs->count);
	ASSERT(789L == objs->values[2]);
}

void testPushFull(TestObjs *objs) {
	/* push maximum number of values onto stack */
	for (long i = 1L; i <= MAX_STACK; i++) {
		stackPush(objs->values, &objs->count, i);
	}
	ASSERT(MAX_STACK == objs->count);

	/* pushing another item should cause a fatal error */
	expectedExit = 1;
	if (sigsetjmp(exitBuf, 1) == 0) {
		stackPush(objs->values, &objs->count, 999L);
		FAIL("pushing onto full stack didn't fail");
	} else {
		/* good, push failed */
		printf("push onto full stack failed, good...");
	}
}

void testPop(TestObjs *objs) {
	stackPush(objs->values, &objs->count, 6L);
	stackPush(objs->values, &objs->count, 7L);
	stackPush(objs->values, &objs->count, 8L);
	stackPush(objs->values, &objs->count, 9L);
	stackPush(objs->values, &objs->count, 10L);

	ASSERT(10L == stackPop(objs->values, &objs->count));
	ASSERT(9L == stackPop(objs->values, &objs->count));
	ASSERT(8L == stackPop(objs->values, &objs->count));
	ASSERT(7L == stackPop(objs->values, &objs->count));
	ASSERT(6L == stackPop(objs->values, &objs->count));
	ASSERT(0 == objs->count);
	/* popping another item should cause a fatal error */
        expectedExit = 1;
        if (sigsetjmp(exitBuf, 1) == 0) {
                stackPop(objs->values, &objs->count);
                FAIL("pop onto empty stack didn't fail");
        } else {
                /* good, push failed */
                printf("pop onto empty stack failed, good...");
        }

}

void testEvalOp(TestObjs *objs) {
	ASSERT(3L == evalOp('+', 1L, 2L));
	ASSERT(-10L == evalOp('-', 3L, 13L));
	ASSERT(77L == evalOp('*', 11L, 7L));
	ASSERT(3 == evalOp('/', 17L, 5L));
	
	expectedExit = 1; 
	if (sigsetjmp(exitBuf, 1) == 0) {
                evalOp('/', 12L, 0L);
                FAIL("Divide by 0 not handled");
        } else {
                // good, expected failure 
                printf("good, divide by 0 handled...");
        } 


}

void testEval(TestObjs *objs) {
	ASSERT(1L == eval("1"));
	ASSERT(2L == eval("1 1 +"));
	ASSERT(3L == eval("4 1 -"));
	ASSERT(33L == eval("11 3 *"));
	ASSERT(5L == eval("17 3 /"));
	ASSERT(27L == eval("3 4 5 + *"));
	ASSERT(42L == eval("6 6 6 6 6 6 6 + + + + + +"));
	ASSERT(20L == eval("1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 +++++++++++++++++++"));
	ASSERT(1142L == eval("0 1 2 3 4 5 6 7 8 9 10 11 12 + - * 1 2 3 4 5 6 7 8 9 10 + + + + - - - - * - - * + - + - + - -"));
	ASSERT(190L == eval("0 1 2 3 4 5 6 7 8 9 10 11 12 + - * 1 2 3 4 5 6 7 8 9 10 + + + + - - - - * - - * + - + - + - - 2 / 3 /"));
	/* make sure eval can handle arbitrary whitespace */
	ASSERT(6L == eval("  1  \t 5\t\t + \t"));
	ASSERT(-201L == eval("9 13 + 2 5 + 2 19 - + * 13 + 6 8 19 8 12 + + / + +")); 
	ASSERT(-15L == eval("2 11 + 15 14 * - 14 17 * 7 7 * * / 15 -"));
	
	ASSERT(-362L == eval("9 13 + 2 5 + 2 19 - + * 13 + 6 8 19 8 12 + + / + + 19 5 - 11 13 * - 9 14 + 15 9 - + * 10 * 15 5 / 6 4 - 2 3 * - + 14 18 + 8 - 13 4 * 17 4 / * + + / +")); 

	}

void testEvalInvalid(TestObjs *objs) {
	expectedExit = 1;

	/* multiple items left on stack */
	if (sigsetjmp(exitBuf, 1) == 0) {
		eval("2 2");
		FAIL("multiple items on stack not handled");
	} else {
		/* good, expected failure */
		printf("good, multiple items on stack handled...");
	}

	/* operator with insufficient operands */
	if (sigsetjmp(exitBuf, 1) == 0) {
		eval("1 +");
		FAIL("stack underflow not handled");
	} else {
		/* good, expected failure */
		printf("good, stack underflow handled...");
	}

	/* operator with insufficient operands */
        if (sigsetjmp(exitBuf, 1) == 0) {
                eval("-17 + 4 - 6");
                FAIL("stack underflow not handled");
        } else {
                /* good, expected failure */
                printf("good, stack underflow handled...");
        }

	/* stack overflow */
        if (sigsetjmp(exitBuf, 1) == 0) {
                eval("1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1");
                FAIL("stack overflow not handled");
        } else {
                /* good, expected failure */
                printf("good, stack overflow handled...");
        }

	/* empty string */
        if (sigsetjmp(exitBuf, 1) == 0) {
                eval("");
                FAIL("empty string not handled");
        } else {
                /* good, expected failure */
                printf("good, empty string handled...");
        }

	/* division by 0 */
        if (sigsetjmp(exitBuf, 1) == 0) {
                eval("5 0 /");
                FAIL("division by 0 not handled");
        } else {
                /* good, expected failure */
                printf("good, division by 0 handled...");
        }
}
