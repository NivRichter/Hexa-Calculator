%macro myPuts 1+
    section .data
        %%str: db %1
        %%len: equ $- %%str
    section .text
            pushad
            mov ecx, %%str
            mov edx, %%len
            mov ebx, 1 
            mov eax, 4
            int 0x80
            popad
%endmacro

%macro myPutc 1
    section .data
        %%char: db %1
    section .text
            pushad
            mov ecx, %%char
            mov edx, 1
            mov ebx, 1 
            mov eax, 4
            int 0x80
            popad
%endmacro

%macro myPutint 1
    section .bss
        %%numX: resd 1
    section .text
            mov dword[%%numX],%1
            pushad
            mov ecx,dword[%%numX]
            push ecx
            push format_string_int
            call printf
            popad
            
%endmacro



section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string
	format_string_noNewLine: db "%s" , 0	; format string
	format_string_int: db "%d",10,0
    format_string_char: db "%c",10, 0
    format_string_char_no_newline: db "%c", 0
    max_size:   db 82
    debug_msg:  db ">debug: ", 0


section .bss			; we define (global) uninitialized variables in .bss section
	debug:  resb 1
    size:   resw 1
    input_str: resb 82
  ;  stack:  resd 255    ;keep all adresses for each oprand on the stack
    stack_index: resd 1 
    acc:    resd 1
    input_read_index: resd 1
    prev_address: resd 1
    stack_pointer:  resb 4
    num_len: resd 1
    new_address: resd 1
    p1: resd 1
    p2: resd 2
    input_size: resd 1
    lat_node: resb 1
     startOfP3: resd 1
    digNumCounter: resb 1
    tempNode:resd 1
    isFirstOfL3: resb 1
    totalOps: resd 1

    espP: resd 1
    ebpP: resd 1
    


section .text
	align 16
    global main
    global twoHexCharsToDec
    global debug_print_number
    extern fprintf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern gets 
    extern getchar 
    extern fgets 
	extern printf
    extern stdin
    extern stderr


_start:
main:

    mov     word [totalOps], 0      ;set operation to zero
    mov     dword [stack_index],0

    mov     eax,0
    mov     ecx,0
    mov     eax,dword [esp+4]    ; argc
    mov     ecx,dword [esp+8]  ;argv[0]  

    ;============= SAVE CURRENT STATE
    push ebp              		; save Base Pointer (bp) original value
    mov ebp, esp         		; use Base Pointer to access stack contents (do_Str(...) activation frame)
    pushad                   	; push all signficant registers onto stack (backup registers values)

   ; myPuts  "argc:"         
        pushad
        push    eax             ;print argc
        push    format_string_int
        ;call    printf
        add     esp, 8
        popad           
    cmp     eax,3
    je      two_args
    cmp     eax, 2          
    je      one_args
    jmp     no_args

one_args:
    ;========== check if got debug mode argument =================
    mov     edi, dword [ecx + 4] ;ecx = argv[0] => edi = argv[1]
    cmp     word [edi] ,'-d'   ;check if argv[1][0] =="-" ->debug mode
    je      in_debug            ;argv[1] = "-d"

    ;;======================= TO DELETE
    mov     edx, 0
    mov     edx, dword [ecx+4]

        pushad
        push    edx
        push    format_string
        ;call printf
        add     esp, 8
        popad
    ;====================   Got stack size argument
    mov ebx,0
    mov eax,0
    mov ebx,[edi]
    mov al, bh

        pushad
        ;myPuts "LowByte:"
        push    eax
        push    format_string_int
       ; call printf
        add     esp, 8
        popad
    mov al,bl
        pushad
     ;   myPuts "HighByte:"
        push    eax
        push    format_string_int
      ;  call printf
        add     esp, 8
        popad

    mov eax,0
    mov ah,bh
    mov al,bl
    pushad
    call twoHexCharsToDec
    popad

    ;=======allocate stack size * 4 byte each node
    mov edi,4
    mul edi
    pushad
    push eax
    call malloc
    mov  dword [stack_pointer],eax
    add esp,4
    popad

    jmp print_stack_size



   

two_args:

      ;========== check if got debug mode argument =================
    mov     edi, dword [ecx + 8] ;ecx = argv[0] => edi = argv[1]
    cmp     word [edi] ,'-d'   ;check if argv[1][0] =="-" ->debug mode
    jne      second_arg            ;argv[1] = "-d"
    mov     byte[debug],1

    ;;======================= TO DELETE
    mov     edx, 0
    mov     edx, dword [ecx+8]

        pushad
        push    edx
        push    format_string
      ;  call printf
        add     esp, 8
        popad
    ;====================   Got stack size argument
second_arg: 
    mov edi, dword [ecx + 4] ;ecx = argv[0] => edi = argv[1]
    mov ebx,0
    mov eax,0
    mov ebx,[edi]
    mov al, bh

        pushad
      ;  myPuts "LowByte:"
        push    eax
        push    format_string_int
    ;    call printf
        add     esp, 8
        popad
    mov al,bl
        pushad
      ;  myPuts "HighByte:"
        push    eax
        push    format_string_int
      ;  call printf
        add     esp, 8
        popad

    mov eax,0
    mov ah,bh
    mov al,bl
    pushad
    call twoHexCharsToDec
    popad

    ;=======allocate stack size * 5 byte each node
    mov edi,4
    mul edi
    pushad
    push eax
    call malloc
    mov  dword [stack_pointer],eax
    add esp,4
    popad

    jmp print_stack_size



in_debug:
 ;   myPuts "in_debug",10
    mov     byte [debug],1

no_args:
   ; myPuts "setting default size stack",10
  ;allocate memory for stack in defualt size 5 element*4bytes
    pushad
    push dword 20
    call malloc
    mov  dword [stack_pointer],eax
    add esp,4
    popad
    mov word[size],5
    jmp print_stack_size




print_stack_size:
    pushad
   ; myPuts "final stack size:"
    mov eax,0
    mov ax,word[size]
    push eax
    push format_string_int  
    ;call printf
    add esp,8
    popad

   ; mov dword [espP], esp
   ; mov dword [ebpP],ebp
    pushad
    call myCalc

    push eax
    push format_string_int
    call printf
    add esp, 8

    mov eax,1
    int 0x80

myCalc:

prompt_input:
    myPuts "calc: "
    pushad
    ;push    dword [stdin]       ;push FILE* pointer
    ;push    dword 82            ;buffer size
    ;push    dword input_str     ;buffer pointer
    ;call    fgets               ;get oprator input
    ;add     esp,12

    mov     eax,3
    mov     ebx,0
    mov     ecx, input_str
    mov     edx,81
    int     0x80
    mov     dword[input_size],eax

            pushad
            push dword[input_size]
            push format_string_int
           ; call printf     
            add esp,8
            popad
    popad

    ;==========================DEBUGGING    START
                pushad
                mov     bl ,byte [input_str] ;get input to buffer
                push    ebx                     
                push    format_string_char
             ;   call    printf               ;print operator input
                add     esp,8
                popad
                pushad
                mov     ebx,dword input_str
            ; add     ebx,4
                mov     dl, byte[ebx+1]
                push    edx
                push    format_string_char  
              ;  call    printf  
                add esp,8
                popad
    ;==========================DEBUGGING    END


    mov     bl ,byte [input_str]    ;check operator

    cmp     bl, 'q'
    je      quit

    cmp     bl, '+'
    jne     next1
    call    addition
    jmp prompt_input

next1:
    cmp     bl, 'p'
    jne      next2
    call    pop_n_print

    jmp     prompt_input

next2:
    cmp     bl, 'd'
    jne      next3
    call    duplicate
    jmp     prompt_input

next3:
    cmp     bl, '&'
    jne     next4
    call     bwAnd
    jmp prompt_input

next4:
    cmp     bl, '|'
    jne      next5
    call    bwOr
    jmp prompt_input

next5:
    cmp     bl, 'n'
    jne     next6  
    call    numOfHexa
    jmp prompt_input

next6:
    ;not operator, user entered an operand

;============  Clean leadin Zeros 00..A1... => A1....  ==========
clean_leading_zeros:
    mov     eax,0
    mov     ax,word[size]
    mov     cx,word [stack_index]
    cmp     cx,ax
    jge     error_stack_overflow

;================ START PARSING NUMBER======================
    mov     dword[input_read_index],0
loop_clean_zeros:
    mov     edi,dword[input_read_index] ;take ith letter from the buffer
    mov     cl,byte [input_str+edi]     ;read next byte
    cmp     cl,10
    je      got_rand_equal_zero
    cmp     cl,48                       ;current char = '\n\ => stop reading bytes
    jne     add_operand                 ;got the first non zero digit, jump to parsing
    inc     dword[input_read_index]
    jmp loop_clean_zeros

got_rand_equal_zero:
    mov     dword[acc],0
    mov     esi,dword [stack_index] ;esi = index to add the link in the stack
    mov     ecx, dword[stack_pointer]
    mov     dword [ecx+esi*4],0
    jmp     add_link            

add_operand:

    mov     edi,dword[input_size]

    dec     edi
    sub     edi,dword[input_read_index]     ;edi = the exact size of the input in bytes (so we know if its even or not)
    mov     dword[input_size],edi           ;input_size = the exact size of the input in bytes
        pushad
        ;myPuts "input size:"
        push  dword[input_size]
        push format_string_int
        ;call printf
        add esp,8
        popad

    ;============SET FISRT NODE TO NULL
    mov     esi,dword [stack_index] ;esi = index to add the link in the stack   
    mov     edi,dword[stack_pointer]
    mov     dword [edi+esi*4],0
  
  d100:  
    mov edx,0
    mov eax,  dword[input_size]
    mov ecx,2
    div ecx
    cmp edx,0
    je  Conv2CharsToNum              ;input is of even size, act normmaly


    ;=============input is of odd size, add the MSD as one byte only

    mov     ecx,0
    mov     edi,dword[input_read_index]
    mov     cl,byte [input_str+edi]     ;get first character of the 2
    cmp     cl,'9'
    jge     letter_to_num2
    sub     cl,48
    jmp     add_first_byte
letter_to_num2:   
    sub     cl,55
    add_first_byte:
    mov     dword[acc],ecx
    ;inc     dword[input_read_index]
    jmp     add_link


add_link:
        pushad
        ;myPuts "adding list in index:",0
        push    dword[stack_index]
        push format_string_int
        ;call printf
        add esp,8
        popad

    mov     esi,dword [stack_index] ;esi = index to add the link in the stack   
    mov     edi,dword[stack_pointer]
    mov     edi,dword [edi+esi*4]
    mov     dword[prev_address],  edi       ;prev_adrees = stack

      ; myPuts "current first link before adding new one: "
        pushad
        mov edx, dword[prev_address]
        cmp edx,0
        je firstIsNull
        mov cl, byte [edx]
        push ecx
        push format_string_int
        ;call printf
        add esp,8
        jmp do_pop
        firstIsNull:
         ;   myPuts"fisrt is null",10,0
        do_pop:
            popad
    pushad  

    push    dword 5
    call    malloc                  ;;allocate place for new link
    add     esp,4   

    mov     esi,dword [stack_index] ;esi = index to add the link in the stack      
    mov     ecx,  dword[stack_pointer]
    mov     dword [ecx+esi*4],eax    ;stack[i] = pointer to the new allocated link

        mov     edx, dword[acc]         ;edi = data to set in the link
        pushad
      ;  myPuts "check acc:",0
        push edx
        push format_string_int
       ; call printf
        add esp,8
        popad

    mov     dl,byte[acc]
    mov     esi,dword [stack_index] ;esi = index to add the link in the stack      
    mov     ecx,  dword[stack_pointer]
    mov     eax, dword [ecx+esi*4]   ;stack[i] = pointer to the new allocated link
    mov     byte[eax],dl 
    mov     edx,dword[prev_address]
    mov     dword[eax+1],edx
d5:    
        ;myPuts  "new link was added in the beggining:",10,0
        pushad
        mov ecx,0
        mov ebx,0
        mov ebx,dword[stack_pointer ]
        mov ebx,dword [ebx + esi*4]
        mov cl,byte[ebx]
        push ecx
        push format_string_int
     ;   call printf
        add esp,8
        popad
d6:
        pushad  
        mov     edx,0
        mov     esi,dword [stack_index]
        mov     ecx,dword[stack_pointer]
        mov     ecx,dword [ecx+esi*4]
        mov     edi,dword [ecx+1]         ;edi -> link.next
        cmp     edi,0
        je      newWasNull ;next is null, dont print
   ;     myPuts "updated next link:",0
d7:
        mov     ecx,0
        mov     cl,byte [edi];get the value of the next link
        push    ecx
        push    format_string_int
      ;  call printf
        add esp,8
     newWasNull:   
        popad
    popad  

    ;check if there are more bytes to read from input
    mov     ecx,0
    mov     eax,0
    mov     esi,dword [stack_index]
    mov     edi,dword[input_read_index]
    mov     cl,byte [input_str+edi]     ;read next byte
 d8:

    mov     edx, dword[stack_pointer]
    mov     edx,[edx +esi*4]
    mov     al, byte[edx]

    cmp     cl,10
    je      end_reading_operand
    inc     dword [input_read_index]
    jmp     Conv2CharsToNum             ;continue reading bytes
    


Conv2CharsToNum:
    mov     edi,dword[input_read_index] ;take ith letter from the buffer
    mov     cl,byte [input_str+edi]     ;read next byte
    cmp     cl,10                       ;current char = '\n\ => stop reading bytes
    je      end_reading_operand

    mov     ecx,0
    mov     edi,dword[input_read_index]
    mov     cl,byte [input_str+edi]     ;get first character of the 2
    cmp     cl,'9'
    jge     letter_to_num
    sub     cl,48
    jmp     second_char
letter_to_num:   
    sub     cl,55
second_char:
    inc     dword[input_read_index]
    mov     edi,dword[input_read_index]
    mov     dword [acc],0
    add     dword [acc],ecx
    mov     eax,dword[acc]
    mov     cl,byte [input_str+edi]
    cmp     cl,10
    je      endOfConv
    mov     eax,0
    mov     eax,dword [acc]

    mov     ebx,0
    mov     bl,16
    mul     bl

    mov     dword [acc],eax
    cmp     cl,'9'
    jge     scndLetter_to_num
    sub     cl,48
    add     dword [acc],ecx
    jmp     endOfConv

scndLetter_to_num:    
    sub     cl,55
    add     dword [acc],ecx
    jmp     endOfConv

endOfConv:
    pushad
 ;   myPuts "value of current 2 chars:",10
    mov     ecx,dword[acc]
    push ecx
    push format_string_int
   ; call printf
    add esp,8
    popad
    jmp add_link


end_reading_operand: 
    inc dword[stack_index]
        pushad
   ;     myPuts "new stack index:"
        push dword[stack_index]
        push format_string_int
        ;call printf
        add esp,8
        popad

    ;=========DEBUG PRINT:==========
    pushad
    call debug_print_number
    popad

    jmp prompt_input
    

   

    

pop_n_print:
    inc dword[totalOps]
    mov dword[num_len],0
    cmp byte[stack_index],1
    jge ok_do_pop
    jmp error_not_enogh_rands
    inc dword[stack_index]
    ret

    ok_do_pop: 
    dec dword[stack_index]
     pushad
      ;  myPuts "poping stack index:"
        push dword[stack_index]
        push format_string_int
       ; call printf
        add esp,8
        popad
d2:
    mov edi,dword [stack_index]
    mov ecx,dword [stack_pointer]
    mov ecx,[ecx + 4*edi]

    loop_pop:
        inc dword[num_len]
        mov eax,0
        mov al,byte [ecx]
        push eax
            pushad
            push eax
            push format_string_int
          ;  call printf
            add esp,8
            popad

    d1:
    mov edx, ecx
    mov ecx,dword[edx+1]
    mov edx,0
    ;============= FREE THE NODE
        pushad
        push edx
        call free
        add esp,4
        mov edx,0
        popad
    ;============= END FREE THE NODE


    cmp ecx,0
    je printInHexa_start        ;je prompt_input
    ret
   ; jmp loop_pop


printInHexa_start :         ;first node, dont print leading zero
    pop eax
        ; myPuts "curr num",10
            pushad
            push eax
            push format_string_int
           ; call printf
            add esp,8
            popad   
    cmp eax,16
    jge calc_hex_val
    ;myPuts "HEERRRRRR",10
    mov edx,eax
    jmp calc_quetinet       ; jump to print only the quetinet




printInHexa:
    cmp dword[num_len],0
    jg .not_last_node
    ret

.not_last_node:    
    mov eax,0
    pop eax
          ;  myPuts "curr num",10
            pushad
            push eax
            push format_string_int
            ;call printf
            add esp,8
            popad
    ;cmp eax,0           ;current node data is zero - add 48 and print
    ;jne calc_hex_val
    ;pushad
    ;push 48
    ;push format_string_char_no_newline
    ;call printf
    ;add esp,8
    ;popad
    ;jmp endOfPrintingLink
calc_hex_val:

    mov ecx,16
    mov edx,0
    div ecx
     
convNumForPrint:
 ;   cmp dword[num_len],1        ;last node, dont print leading zero
  ;  jne .continue_print_2_chars
   ; cmp eax,0                   ;if High Byte was zero, dont print
    ;je calc_quetinet     
.continue_print_2_chars:
    cmp eax,10
    jge to_letter
    add eax,48
    jmp calcFirstChar
to_letter:
    add eax,55
calcFirstChar:
    pushad
    push eax
    push format_string_char_no_newline
    call printf
    add esp,8
    popad
calc_quetinet:
    cmp edx, 10
    jge quetinent_to_letter
    add edx,48
    jmp print_second_char
quetinent_to_letter:
    add edx,55
print_second_char:
    pushad  
    push edx
    push format_string_char_no_newline
    call printf
    add esp,8
    popad



endOfPrintingLink:
    dec dword[num_len]
    cmp dword[num_len],0
    jne printInHexa
    pushad
    push 10 ;new line inteded
    push format_string_char_no_newline
    call printf
    add esp,8
    popad
    ret
















addition:
    cmp dword[stack_index],1
    jle error_not_enogh_rands

    ;=====receive 2 pointers to both last inserted lists
    cmp dword [stack_index],2;check if there at least 2 numbers
    jnge error_not_enogh_rands
    inc dword[totalOps]
    dec dword [stack_index]
    mov esi,dword [stack_index]
    mov edi,dword [stack_pointer]
    mov eax,dword [edi+4*esi];take last inserted
    dec dword [stack_index]
    mov esi,dword [stack_index]
    mov ebx,dword [edi+4*esi]; take second last inserted
    ;=====================================================
    mov byte [isFirstOfL3],0
    jmp additionLoop

    ;===================================
    CheckifSecondIsNull:
    cmp ebx,0
    jne notBothAreNull
    jmp checkForCarry
    



additionLoop:
    
 ;=====check if both are null======
CheckifFirstIsNull:
    mov dword [p1],eax 
    mov dword [p2],ebx
    cmp eax,0
    je CheckifSecondIsNull

notBothAreNull:
    ;=====allocate first node in the new list========
    pushad
    push 5
    call malloc
    mov dword [tempNode],eax
    add esp,4
    popad
    ;================================
    inc byte [isFirstOfL3]
    cmp byte [isFirstOfL3],1 ;check if this is the first node of l3
    jne dontSetAsFirst
    mov edx,dword [tempNode]
    mov dword [startOfP3],edx
    mov ecx ,dword [startOfP3];first node of l3
    jmp nodeBackUp
dontSetAsFirst:
    ;========connect node to l3 and progress iter==============
    mov edx,dword [tempNode]
    mov dword [ecx+1], edx
    mov ecx,dword [ecx+1]
    ;==========================================================
nodeBackUp:
    ;=======backup of both node pointers
    mov dword [p1],eax 
    mov dword [p2],ebx
    ;===========set node value to AX and BX============
    cmp eax,0
    jne setNextValA
    mov al,0
afterSetA:
    cmp ebx,0
    jne setNextValB
    mov bl,0
afterSetB:
    ;===============calc addition with carry===========
    adc al,bl ;add with carry
    mov byte [ecx],al;set value to ecx node

;========================================
    mov eax,dword [p1]
    cmp eax,0
    je afterProgress1
    mov eax,dword [p1]
    mov eax,dword [eax+1];progress l1 iter
afterProgress1:
    mov ebx,dword [p2]
    cmp ebx,0
    je afterProgress2
    mov ebx,dword [p2]
    mov ebx,dword [ebx+1];progress l2 iter
afterProgress2:    
    jmp freeSection_last;free node if needed
    ;jmp additionLoop


checkForCarry:
    jc lastNode
    jmp freeSection_last;if the last value is 0 including CF
    ;erase the nodes of iter1 and iter2 
    ;and connect l3 to stack

lastNode:
    adc al,bl;
    cmp al,0
    je connectToList

    ;=======allocate last node=======
        pushad
        push 5
        call malloc
        mov dword[tempNode],eax
        add esp,4
        popad
    ;=========connect node and progress iter========
    mov edx,dword [tempNode]
    mov dword [ecx+1],edx
    mov dword ecx,[ecx+1]
    ;=============================================
    mov byte [ecx],al ;insert value into last node

freeSection_last:
    cmp dword [p1],0
    jne freeFirst
afterFree1_last:
    cmp dword [p2],0
    jne freeSecond
afterFree2_last:
    mov dword [acc],eax
    add dword [acc],ebx
    cmp dword [acc],0
    jne additionLoop
    jmp connectToList

connectToList:
    
    mov esi,dword[stack_pointer]
    mov edi,dword[stack_index]
    mov edx,dword[startOfP3]
    mov dword [esi+4*edi],edx
    inc dword [stack_index]
    call debug_print_number
    ret
    

setNextValA:
    ;====set value if node isn't null
    mov al,byte [eax]
    jmp afterSetA
    ;================================
setNextValB:
    ;====set value if node isn't null
    mov bl,byte [ebx]
    jmp afterSetB
    ;=================================

freeFirst:
    pushad 
    mov eax,dword [p1]
    push eax
    call free
    add esp,4
    popa
    jmp afterFree1_last

freeSecond:
    pushad 
    mov eax,dword [p2]
    push eax
    call free
    add esp,4
    popad
    jmp afterFree2_last










duplicate:
    inc dword[totalOps]
    cmp dword[stack_index],0 ;check if there is at least one number in the list
    je error_not_enogh_rands
    dec dword [stack_index]
    mov esi,[stack_index]
    mov edi,[stack_pointer]
    mov eax , dword[edi+4*esi]; eax=first node in the list
    inc dword [stack_index]

    mov ecx,0;reset ecx
    pushad
    push 5
    call malloc
    mov dword [p1],eax
    add esp,4
    popad
    ;==========connect dup to list==========
    mov ebx,[p1]
    mov esi,dword [stack_index]
    mov dword [edi +4*esi],ebx
    inc dword [stack_index]
    ;=======================================
 dupLoop:
    mov cl,byte [eax];take eax value to 
    mov byte [ebx],cl
    mov dword [ebx+1],0 ;set null


    mov eax,dword [eax+1];go to  next node
    cmp eax,0
    jne .cont   ;Not Finshed yet

    call debug_print_number
    ret
    .cont: 
    ;======create new node=======
    mov ecx,0;reset ecx
    pushad
    push 5
    call malloc
    mov dword [p1],eax
    add esp,4
    popad
    ;==========go to next link===========

    mov edx,dword[p1];temp node that holds the node.next
    mov dword [ebx+1],edx
    mov ebx,dword [ebx+1]
    jmp dupLoop

bwOr:
    inc dword[totalOps]
    cmp dword[stack_index],0
    je error_not_enogh_rands
    dec     dword [stack_index] ;go the last inserted number
    cmp     dword [stack_index],1       ;1 or more means at least 2 oprands on the stack - its ok
    jl      error_not_enogh_rands 
    mov     esi,dword [stack_index] ;esi = index to add the link in the stack
    mov     edi, dword[stack_pointer]         ;;top most list in the stack
    mov     eax, dword[edi + esi*4]     ;get the last inserted number ;esi=index
    mov     dword [p1],eax              ;p1=iter pointer to last inserted
   ; mov     ecx, dword[stack_pointer]   
    dec     esi                         ; index of second last number
    mov     ecx, dword[edi+esi*4]     ;the second top most list in the stack - will be updated to new values
    mov     dword [p2],ecx                ;p2=iter pointer to second last  
  ;  mov     dword[acc],0
firstNode:    
    ;myPuts "gotHere",10
    ;============check if both pointers not null==============
    mov     dword[acc],eax
    add     dword[acc],ecx
    cmp     dword[acc],0
    je      endOfORLoop
    ;============end of check=============================
    
    ;=============allocate first node in new list===========
    pushad
    push 5
    call malloc
    add esp,4
    mov     dword[prev_address],eax ;new list of p3
    mov     dword[new_address],eax  
    mov    dword [startOfP3], eax
    popad
    ;===============end of allocate============================

    
    cmp     eax, 0                    ;check if first operand node is null
    je    setFirstRandZero
    cmp     ecx,0                    ;check if second operand node is null
    je    setSecondRandZero
    
    ;=========both nodes aren't null============
    mov     dl,byte[eax]        ;get data of first node
    mov     bl,byte[ecx]        ;get data of second node
    OR      bl,dl
                            ;============check============
                             ;   myPuts "gotHere2",10
                                pushad
                                push ebx
                                push format_string_int
                              ;  call printf
                                add esp,8
                                popad
                            ;==========end of check========
    ;============set new link==========
    mov     esi,dword[prev_address] ;move link adress to esi
    mov     byte [esi],bl           ;insert OR's result
    ;==============end of set==========

    mov     edi,dword[eax+1]        ;edi = node.next
    mov     dword [p1],edi     ;move iter to next node
    mov     esi,dword[ecx+1] ;next link address to esi      
    mov     dword [p2], esi  ;move iter to next node

    ;delete node in l1
    pushad              ;free first operand cuurent node
    push    eax         ;node of topmost  list
    call    free            ;free the nodeq
    add     esp,4
    popad

    ;delete node in l2
    pushad              ;free first operand cuurent node
    push    ecx         ;node of topmost  list
    call    free            ;free the nodeq
    add     esp,4
    popad
    
    jmp     second_node
    


second_node:
    ;============check if both pointers not null==============
    mov eax,dword[p1];move reg to next node
    mov ecx,dword[p2];move reg to next node
    mov     dword[acc],eax
    add     dword[acc],ecx
    cmp     dword[acc],0
    je      endOfORLoop
    ;============end of check=============================
    pushad
    push 5;allocate new node in the link
    call malloc
    add esp,4
    mov     dword[new_address],eax
    mov     esi,dword[prev_address]
    mov     dword [esi+1],eax       ;set the new node.next to the prev node
    mov     dword[prev_address],eax ;remember the current node be the next later
    popad

    ;mov     eax,dword [p1]            ;eax.nxt
    ;mov     ecx,dword [p2]         ;ecx.nxt

d22:
    ;mov     ebx,0
    cmp     dword [p1], 0                    ;check if first operand node is null
    je    setFirstRandZero
    cmp     dword[p2],0                    ;check if second operand node is null
    je    setSecondRandZero
    jmp     setDataToCalcOr

setFirstRandZero:
    mov dl,0
    mov     bl,byte[ecx]        ;get data of second node
    jmp calcOr
setSecondRandZero:
    mov bl,0
    mov     dl,byte[eax]        ;get data of first node
    jmp calcOr

d23:
setDataToCalcOr:
    mov     dl,byte[eax]        ;get data of first node
    mov     bl,byte[ecx]        ;get data of second node
calcOr:
    OR     bl,dl
        ;test======print l1 number ======
        pushad
        push eax
        push format_string_int
      ;  call printf
        add esp,8
        popad
        
d24:

    mov     esi,dword[new_address]
    mov     byte [esi],bl;insert the number to l3

    cmp     dword[p1],0
    je      dont_update_first
    mov     eax,dword [p1]
    mov     edi,eax             ;to be free 1
    mov     eax,dword[eax+1]
    mov     dword[p1],eax
    ;========free curr link on l1=========
    pushad
    push edi
    call free
    add esp,4
    popad
    ;===============end====================

dont_update_first:

    cmp    dword[p2],0
    je      dont_update_second
    mov     ecx,dword[p2]
    mov     esi,ecx
    mov     ecx,dword[ecx+1]
    mov     dword[p2],ecx
    ;========free curr link on l2=========
    pushad
    push esi
    call free             ;to be free 2
    add esp,4
    popad

    ;==============end=====================
dont_update_second:

    jmp     second_node

d13:
endOfORLoop:
  ;  myPuts "end of OR operation",10
    dec     dword[stack_index]
    mov     esi,dword[stack_index]
    mov     edi,dword[stack_pointer]
    mov     eax,dword[startOfP3] 
    mov     ebx,dword [new_address] 
    mov     dword [ebx+1],0
    mov     dword[edi +4*esi],eax
   
        ;myPuts "inserting result in index:"
        pushad
        push esi
        push format_string_int
       ; call printf
        add esp,8
        popad
    inc dword[stack_index]
    call debug_print_number
    ret






bwAnd:
    inc     dword[totalOps]
    dec     dword [stack_index]
    cmp     dword [stack_index],1       ;1 or more means at least 2 oprands on the stack - its ok
    jl      error_not_enogh_rands 
    mov     esi,dword [stack_index] ;esi = index to add the link in the stack
    mov     edi, dword[stack_pointer]         ;;top most list in the stack
    mov     eax, dword[edi + esi*4]
    mov     ecx, dword[stack_pointer]
    dec     esi
    mov     ecx, dword[edi+esi*4]     ;;the second top most list in the stack - will be updated to new values
.bwAnd_loop:    

    mov     ebx,0
    cmp     eax, 0                    ;check if first operand node is null
    je    .endCalcAnd
    cmp     ecx,0                    ;check if second operand node is null
    je    .endCalcAnd
    mov     dl,byte[eax]        ;get data of first node
    mov     bl,byte[ecx]        ;get data of second node
    AND     bl,dl
        ;myPuts "gotHere2",10
        pushad
        push ebx
        push format_string_int
       ; call printf
        add esp,8
        popad
    mov     byte[ecx],bl
    mov     edi,dword[eax+1]        ;edi = node.next

    pushad              ;free first operand cuurent node
    push    eax         ;node of topmost  list
    call    free            ;free the nodeq
    add     esp,4
    popad

    mov     eax,edi            ;eax.nxt
    mov     ecx,dword[ecx+1]            ;ecx.nxt
    jmp     .bwAnd_loop


    .endCalcAnd:
    pushad
    call free_list
    popad

    
    cmp  ecx,0
    jz .update_index
    mov  eax,dword[ecx+1]   ;free the rest of the second list if nesceery
    pushad
    call free_list
    popad
    .update_index:
d10:

    mov     esi,dword [stack_index] ;esi = index to add the link in the stack
    mov     edi, dword[stack_pointer]
    mov     dword [edi+esi*4],0         ;set the list that was top most to null
        pushad
        ;myPuts "new stack index:",10
        push dword  [stack_index]
        push format_string_int
       ; call printf
        add esp,8
        popad
 ;   myPuts "end of AND Calculation",10

    call debug_print_number
    ret


;========= FREE The list from node pointer at eax    
free_list:
    cmp eax,0
    je  endOfFree_List
    mov ecx,dword[eax+1]        ;save the next node pointer
    
    pushad
    push eax
    call free               ;free current node
    add esp,4
    popad
    mov  eax,0              ;set current node to null
    mov  eax,ecx
    jmp free_list



endOfFree_List:
    ret


numOfHexa:
        inc dword[totalOps]
        cmp dword[stack_index],0
        jle error_not_enogh_rands
        mov dword [digNumCounter],0  ;reset the counter
        ;======Get last inserted num=====
        dec dword [stack_index]
        mov esi , [stack_index]
        mov edi , [stack_pointer]
        mov eax ,[edi +4*esi]
        ;=================================
        mov dword [p1] ,eax ;save pointer to index in stack
startOfLoop:
        mov ebx, eax
        cmp dword [ebx+1],0 ;check if next is null
        jne nextNodeAvailable
        cmp byte [eax], 15
        jbe oneDigit 
        add byte [digNumCounter],1
oneDigit:
        add byte [digNumCounter],1
        jmp endOfNumHexa

nextNodeAvailable:
        add byte [digNumCounter],2 ;because there is a next node we can add 2 digits
        mov eax, dword[ebx+1];
        ;======free the link=========
        pushad 
        push ebx;
        call free
        add esp,4
        popad
        ;=========================
        jmp startOfLoop
endOfNumHexa:


     ;======create new link containing the 
        pushad
        push 5
        call malloc
        mov ecx,0;
        mov cl , byte [digNumCounter]
        mov byte [eax],cl;
        mov dword [eax+1],0  ;next is null

        mov     esi,dword[stack_index]
        mov     edi,dword[stack_pointer]
        mov     dword[edi +4*esi],eax
        add esp ,4
        popad
        inc dword [stack_index]
;========================================
        


        mov ecx,0
        mov cl,byte [digNumCounter]
      ;  myPuts "counter is:",10
        
                     pushad 
                    push ecx;
                    push format_string_int
                   ; call printf
                    add esp,8
                    popad

        pushad 
        push ebx;
        call free
        add esp,4
        popad
        ;myPuts "final link is free",10
        call debug_print_number
        ret
        ;jmp prompt_input




error_not_enogh_rands:
    myPuts "Error: Insufficient Number of Arguments on Stack",10
    ret 




;2 chars are in eax
;ah = low byte
;al = high byte
;returns in eax the dec value of the 2 chars
twoHexCharsToDec:
        mov dword[acc],0
        mov ecx,eax     ;backup eax
        cmp ah,0
        jne .two_chars 
     cmp al, 65      ;65 == 'A'
        jge .one_char_to_letter
        sub al,48
        jmp .add_onechar
    .one_char_to_letter:
        sub al,55
    .add_onechar:
        mov ebx,0
        mov bl,al
        mov dword[acc],ebx  
        jmp .end_of_func

    .two_chars: 
        cmp ah, 65      ;65 == 'A'
        jge .to_letter
        sub ah,48
        jmp .add_first_letter
    .to_letter:
        sub ah,55
    .add_first_letter:  
        mov ebx,0
        mov bl,ah
        add dword[acc],ebx
    .calc_second_letter:
        cmp al, 65      ;65 == 'A'
        jge .secnd_to_letter
        sub al,48
        jmp .add_second_letter
    .secnd_to_letter:
        sub al,55
    .add_second_letter:   
        mov dl,16
        mul dl
        mov ebx,0
        mov bl,al
        add dword[acc],ebx
    .end_of_func:    
        mov eax,dword[acc]

            pushad
           ; myPuts "new stack size:"
            push eax
            push format_string_int
         ;   call printf
            add esp,8
            popad

        mov eax,dword[acc]
        mov word[size],ax

        ret

    
error_stack_overflow:
    myPuts "Error: Operand Stack Overflow",10
    jmp prompt_input
    





quit:
    mov eax,dword[totalOps]
            pushad
            push eax
            push format_string_int
           ; call printf
            add esp,8
            popad

    call free_all_stack
   
    mov eax, dword [totalOps]  
    ret





;=========== DEBUG PRINT ================
debug_print_number:
    
    cmp byte[debug],1
    je .debugModeIsActivated
    ret
.debugModeIsActivated:
    pushad
    ;inc dword[totalOps]
    mov dword[num_len],0
    cmp byte[stack_index],1
    jge .ok_do_pop
    jmp error_not_enogh_rands

    .ok_do_pop: 
    pushad  
    push debug_msg
    push format_string_noNewLine
    push dword[stderr]
    call fprintf
    add esp,12
    popad

    ;dec dword[stack_index]             ;NO NEED TO DEC INDEX CAUSE NOT POPING NUMBER
     pushad
      ;  myPuts "poping stack index:"
        push dword[stack_index]
        push format_string_int
       ; call printf
        add esp,8
        popad
    mov edi,dword [stack_index]
    dec edi         ;The Last number is in index-1
    mov ecx,dword [stack_pointer]
    mov ecx,[ecx + 4*edi]

    .loop_pop:
        inc dword[num_len]
        mov eax,0
        mov al,byte [ecx]
        push eax
            pushad
            push eax
            push format_string_int
          ;  call printf
            add esp,8
            popad

    mov edx, ecx
    mov ecx,dword[edx+1]
    mov edx,0
    ;============= FREE THE NODE
        ;pushad
        ;push edx
       ; call free
        ;add esp,4
       ; mov edx,0
        ;popad
    ;============= END FREE THE NODE


    cmp ecx,0
    je .printInHexa_start        ;je prompt_input
    jmp .loop_pop


.printInHexa_start :         ;first node, dont print leading zero
    pop eax
        ; myPuts "curr num",10
            pushad
            push eax
            push format_string_int
           ; call printf
            add esp,8
            popad   
    cmp eax,16
    jge .calc_hex_val
    ;myPuts "HEERRRRRR",10
    mov edx,eax
    jmp .calc_quetinet       ; jump to print only the quetinet




.printInHexa:
    cmp dword[num_len],0
    jle endOfDebugPrint

.not_last_node:    
    mov eax,0
    pop eax
          ;  myPuts "curr num",10
            pushad
            push eax
            push format_string_int
            ;call printf
            add esp,8
            popad
    ;cmp eax,0           ;current node data is zero - add 48 and print
    ;jne calc_hex_val
    ;pushad
    ;push 48
    ;push format_string_char_no_newline
    ;call printf
    ;add esp,8
    ;popad
    ;jmp endOfPrintingLink
.calc_hex_val:

    mov ecx,16
    mov edx,0
    div ecx
     
.convNumForPrint:
 ;   cmp dword[num_len],1        ;last node, dont print leading zero
  ;  jne .continue_print_2_chars
   ; cmp eax,0                   ;if High Byte was zero, dont print
    ;je calc_quetinet     
.continue_print_2_chars:
    cmp eax,10
    jge .to_letter
    add eax,48
    jmp .calcFirstChar
.to_letter:
    add eax,55
.calcFirstChar:
    pushad
    push eax
    push format_string_char_no_newline
    push dword [stderr]
    call fprintf
    ;push format_string_char_no_newline
    ;call printf
    add esp,12
    popad
.calc_quetinet:
    cmp edx, 10
    jge .quetinent_to_letter
    add edx,48
    jmp .print_second_char
.quetinent_to_letter:
    add edx,55
.print_second_char:
    pushad  
    push edx
    push format_string_char_no_newline
    push dword[stderr]
    call fprintf
    add esp,12
    popad



.endOfPrintingLink:
    dec dword[num_len]
    cmp dword[num_len],0
    jne .printInHexa
endOfDebugPrint:
    pushad
    push 10 ;new line inteded
    push format_string_char_no_newline
    push dword[stderr]
    call fprintf
    add esp,12
    popad
d777:
    popad
    ret



free_all_stack:
        cmp dword [stack_index],0
        jl free_stack_pointer
        mov esi , dword [stack_index]
        mov edi , dword [stack_pointer]
        mov eax ,[edi +4*esi]
        pushad
        call free_list
        popad
        dec dword [stack_index]
        jmp free_all_stack

free_stack_pointer:
        mov eax, dword [stack_pointer]
        pushad
        push    eax
        call free
        add esp,4
        popad

        ret
