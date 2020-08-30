all: exec

libs: asm-lib

asm-lib: Hexa_Calculator.s
	nasm -f elf Hexa_Calculator.s -o calc.o
	

exec: libs
	gcc -m32 -Wall -g calc.o -o main
	rm calc.o

.PHONY: clean
clean:
	rm -rf ./*.o main
