#! /usr/bin/env bash

# System tests for postfix calculator (can test both C and asm versions)

# Check usage
if [ $# -ne 1 ]; then
	echo "Usage: ./sysTests.sh <exe name>"
	echo "  <exeName> should be './cPostfixCalc' or './asmPostfixCalc'"
	exit 1
fi

# Get the executable to test
exe="$1"

# Variables to keep track of test passed/attempted
numPassed=0
numAttempted=0

# Function testing that a postfix expression yields the expected result
expect() {
	local expected="$1"
	local expr="$2"

	if ./runTest.rb "$exe" "$expected" "$expr"; then
		numPassed=$(expr $numPassed + 1)
	fi
	numAttempted=$(expr $numAttempted + 1)
}

# Function testing that an invalid postfix expression yields an error
expect_error() {
	local expr="$1"

	if ./runTest.rb "$exe" "ERROR" "$expr"; then
		numPassed=$(expr $numPassed + 1)
	fi
	numAttempted=$(expr $numAttempted + 1)
}

#######################################################################
# Tests go here
#######################################################################

expect 5 '2 3 +'
expect 42 '6 7 *'
expect 42 '6 6 6 6 6 6 6 + + + + + +'
expect_error '2 2'      # elements left on stack
expect_error '1 *'      # stack underflow
expect_error '*/'       # empty stack
expect_error '1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1'            # stack overflow!
expect -12 '2 5 - 4 *'  # negative numbers on stack
expect 4 '8 9-5+'       # "negative numbers" in expression
expect_error '	   '    # expression is only whitespace
expect_error ''         # expression is an empty string
expect_error '6 0 /'    # division by 0
expect 20 '1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 +++++++++++++++++++'  # fill stack, then expty it
expect_error '-5 + -5 +1' #operator when stack empty
expect_error '5 % 5' # % not defined
expect -362 '9 13 + 2 5 + 2 19 - + * 13 + 6 8 19 8 12 + + / + + 19 5 - 11 13 * - 9 14 + 15 9 - + * 10 * 15 5 / 6 4 - 2 3 * - + 14 18 + 8 - 13 4 * 17 4 / * + + / +' # really long expression
#######################################################################
# End of tests
#######################################################################

# Summarize results
echo "$numPassed/$numAttempted tests passed"
if [ $numPassed -eq $numAttempted ]; then
	exit 0
else
	exit 1
fi
