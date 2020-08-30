# Hexa-Calculator
A Hexadecimal calculator written in Assembly x86

The calcualtor is running in the linux terminal. Input is requested by promp 'calc:' in RPN(Polish Reverse Notation) as followed:
calc: 7A
calc: 09
calc: +

Operations are performed as is standard for an RPN calculator: any input number is pushed onto an operand stack. Each operation is performed on operands which are popped from the operand stack. The result, if any, is pushed onto the operand stack. The output should contain no leading zeroes, but the input may have some leading zeroes.
