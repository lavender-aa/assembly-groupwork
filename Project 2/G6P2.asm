TITLE RPN calculator

INCLUDE Irvine32.inc

.data

; stack related
stacksize equ 8
index sdword -4
num_stack sdword stacksize dup(0)

; io related
cr equ 13
lf equ 10
tab equ 9
invalidInputMsg byte "Error: Invalid input.",cr,lf,0
generalCommandErrorMsg byte "Error: Cannot perform command.",cr,lf,0
stackTooSmallErrorMsg byte "Error: Stack has too few elements to perform operation.",cr,lf,0
stackTooBigErrorMsg byte "Error: Stack is full, cannot perform operation.",cr,lf,0
parseIntErrorMsg byte "Error: Unable to parse input into an integer.",cr,lf,0

buffer byte 41 dup(0)
bytecount dword 0
menu byte "Options:",cr,lf
	 byte "--------",cr,lf
	 byte tab,"[integer]: push number onto stack",cr,lf
	 byte tab,"+: add top two stack elements",cr,lf
	 byte tab,"-: subtract top two stack elements",cr,lf
	 byte tab,"*: multiply top two stack elements",cr,lf
	 byte tab,"/: divide top two stack elements",cr,lf
	 byte tab,"x: exchange top two stack elements",cr,lf
	 byte tab,"n: negate top stack element",cr,lf
	 byte tab,"u: roll stack up",cr,lf
	 byte tab,"d: roll stack down",cr,lf
	 byte tab,"v: view stack",cr,lf
	 byte tab,"c: clear stack",cr,lf
	 byte tab,"q: quit",cr,lf,cr,lf,0
prompt byte "Enter choice: ",0


.code

main proc
	; print options
	mov edx, offset menu
	call WriteString

_loop:
    ; prompt, get user input
	mov edx, offset prompt
	call WriteString
    call read_input

	; command handler
_switch:
	cmp al, -1
    je _end

_c1: ; first character is digit
	cmp al, '0'
	jl _c2
	cmp al, '9'
	jg _c2
	; convert input string to integer, push to stack
	mov edx, offset buffer
	mov ecx, sizeof buffer
	call ParseInteger32 ; on success: integer in eax
	jo _c1err
	; cast was a success; continue processing
	call push_num
	jno _end
	mov edx, offset stackTooBigErrorMsg ; push fails when stack is full
	call WriteString
	jmp _end
_c1err: ; cast was a failure; print message
	mov edx, offset parseIntErrorMsg
	call WriteString
	jmp _end

_c2: ; first character is a minus sign -- negative number OR subtract
	cmp al, '-'
	jne _c3
	mov al, buffer[1] ; check next character
	cmp al, '0'
	jl _c2err
	cmp al, '9'
	jg _c2err
	; input is a number; same as case 1
	mov edx, offset buffer
	mov ecx, sizeof buffer
	call ParseInteger32
	jo _c2err
	; parse success; push number
	call push_num
	jno _end
	mov edx, offset stackTooBigErrorMsg
	call WriteString
	jmp _end
_c2err: ; parse fail; not a number, subtract operation
	call sub_nums
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c3: ; addition
	cmp al, '+'
	jne _c4
	call add_nums
	jnc _end
	mov edx, offset stackTooSmallErrorMsg ; cannot add if stack is too small
	call WriteString
	jmp _end

_c4: ; multiplication
	cmp al, '*'
	jne _c5
	call mul_nums
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c5: ; division
	cmp al, '/'
	jne _c6
	call div_nums
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c6: ; exchange top two elements of stack
	cmp al, 'x'
	jne _c7
	call exchange_top_two
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c7: ; negate top element
	cmp al, 'n'
	jne _c8
	call negate_top
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c8: ; roll stack up
	cmp al, 'u'
	jne _c9
	call roll_stack_up
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c9: ; roll stack down
	cmp al, 'd'
	jne _c10
	call roll_stack_down
	jnc _end
	mov edx, offset stackTooSmallErrorMsg
	call WriteString
	jmp _end

_c10: ; print stack ("view")
	cmp al, 'v'
	jne _c11
	call print_stack
	jmp _end

_c11: ; clear stack
	cmp al, 'c'
	jne _c12
	call clear_stack
	jmp _end

_c12: ; quit
	cmp al, 'q'
	jne _default
	jmp _out

_default: ; print error
	mov edx, offset invalidInputMsg
	call WriteString
	; fall through to _end
    
_end: ; continue to next loop
	jmp _loop
	
_out: ;exit program
	exit
main endp


negate_top proc
	; store registers used
	push eax
	push ebx
	push esi

	clc ; clear carry flag, used for error
	cmp index, 0
	jl _error
	mov esi, index
	mov eax, num_stack[esi]
	mov ebx, -1
	imul ebx
	mov num_stack[esi], eax
	jmp _ret
_error: ; stack empty; set carry flag
	stc
_ret:
	; restore registers
	pop esi
	pop ebx
	pop eax
	ret
negate_top endp


sub_nums proc
	ret
sub_nums endp


add_nums proc
	ret
add_nums endp


mul_nums proc
	ret
mul_nums endp


div_nums proc
	ret
div_nums endp


push_num proc
	ret
push_num endp


pop_num proc
	ret
pop_num endp

read_input proc
	; save registers used
	push ebx
	push ecx
	push edx
	push edi

	; start with input buffer, define null and tab
	null equ 0
	tab equ 9
	
	; needs an index to the input buffer
	mov edx, offset buffer ; read command line
	mov ecx, sizeof buffer
	call ReadString
	mov bytecount, eax ; keep number of bytes read

	; initialize index reg to 0
	mov edi, 0
_skip: 
	; test for empty input, set index to test
	; error if buffer is empty
	cmp edi, bytecount
	jge _skip_else
	mov al, buffer[edi]
	
	; error if there is a null character
	; between whitespace and string start
	cmp al, null
	je _skip_else
	
	; if space, increment index and check next
	cmp al, ' '
	je _next_char
	
	; if tab, increment index and check next
	cmp al, tab
	jne _end
	
_next_char:
	inc edi
	jmp _skip

_skip_else:
	mov al, -1 ; nothing in input buffer, set output
	jmp _ret

_end: 
	; make sure letter is uppercase before returning
	cmp al, 'A'
	jl _ret
	cmp al, 'Z'
	jg _ret
	or al, 20h ; set 'case' bit

_ret:

	; move buffer over to first nonspace character
	mov ebx, 0
_movbuff: ; move buffer contents over by edi characters
	cmp ebx, 40
	jge _endbuff
	mov cl, buffer[ebx + edi] ; get the next character starting at nonwhitespace
	mov buffer[ebx], cl ; move the character over to the beginning
	inc ebx
	jmp _movbuff
_endbuff:

	; restore registers used
	pop edi
	pop edx
	pop ecx
	pop ebx

    ret
read_input endp




clear_stack PROC
	; set index back to -4 and return
	mov index,-4
	ret
clear_stack ENDP



exchange_top_two PROC
	; save the registers
	push eax
	push ebx

	; check if the stack has less than 2 elements
	cmp index,4
	jl error_exchange_top_two

	; pop the numbers and store them
	call pop_num	; pop the first number
	push eax		; push onto system stack
	call pop_num	; pop the second number
	mov ebx,eax	; store in temp register

	; push the numbers in reverse order
	pop eax		; pop the first number from system stack
	call push_num	; push onto the stack
	mov eax,ebx	; get the second number from temp register
	call push_num	; push onto the stack

	; indicate success
	clc

	; jump to end of procedure
	jmp end_exchange_top_two

error_exchange_top_two:
	; indicate insufficient operands
	stc

end_exchange_top_two:
	; restore the registers
	pop ebx
	pop eax

	;return
	ret
exchange_top_two ENDP



roll_stack_up PROC
	; save the registers
	push esi
	push eax
	push ebx

	; check if stack is empty
	cmp index,0
	jl error_roll_stack_up

	; get the stack index
	mov esi,index

	; store the number at ebx
	mov ebx,num_stack[esi]
	sub esi,4		; subtract 4 from index register

roll_stack_up_firstLoop:
	; check if beginning of stack
	cmp esi,0
	jl end_roll_stack_up_firstLoop

	; store the number at index register onto system stack
	mov eax,num_stack[esi]
	push eax		; store on system stack
	sub esi,4		; subtract 4 from index register

	; keep looping
	jmp roll_stack_up_firstLoop

end_roll_stack_up_firstLoop:
	; put the number at ebx at the beginning
	add esi,4
	mov num_stack[esi],ebx

roll_stack_up_secondLoop:
	; increment esi register
	add esi,4

	; check if index register is at index
	cmp esi,index
	jg end_roll_stack_up_secondLoop

	; get the number in system stack and put it at index register
	pop eax
	mov num_stack[esi],eax

	; keep looping
	jmp roll_stack_up_secondLoop

end_roll_stack_up_secondLoop:
	; indicate success
	clc

	; jump to end of procedure
	jmp end_roll_stack_up

error_roll_stack_up:
	; indicate stack is empty
	stc

end_roll_stack_up:
	; restore the registers
	pop ebx
	pop eax
	pop esi

	;return
	ret
roll_stack_up ENDP



roll_stack_down PROC
	; save the registers
	push esi
	push eax
	push ebx

	; check if stack is empty
	cmp index,0
	jl error_roll_stack_down

	; get the stack index
	mov esi,index

roll_stack_down_firstLoop:
	; check if beginning of stack
	cmp esi,0
	jl end_roll_stack_down_firstLoop

	; store the number at index register onto system stack
	mov eax,num_stack[esi]
	push eax		; store on system stack
	sub esi,4		; subtract 4 from index register

	; keep looping
	jmp roll_stack_down_firstLoop

end_roll_stack_down_firstLoop:
	; get the new top and store it in ebx
	pop ebx

roll_stack_down_secondLoop:
	; increment the index register
	add esi,4

	; check if index register is at index
	cmp esi,index
	jge end_roll_stack_down_secondLoop

	; get the number in system stack and put it at index register
	pop eax
	mov num_stack[esi],eax

	; keep looping
	jmp roll_stack_down_secondLoop

end_roll_stack_down_secondLoop:
	; put new top stored in ebx onto stack at index
	mov num_stack[esi],ebx

	; indicate success
	clc

	; jump to end of procedure
	jmp end_roll_stack_down

error_roll_stack_down:
	; indicate empty stack
	stc

end_roll_stack_down:
	; restore the registers
	pop ebx
	pop eax
	pop esi

	; return
	ret
roll_stack_down ENDP



print_stack PROC
	; save the registers
	push esi
	push eax

	; get the index
	mov esi,index

print_stack_loop:
	; check if index register is less than 0
	cmp esi,0
	jl end_print_stack

	; get the number from the stack
	mov eax,num_stack[esi]

	; print the number
	call WriteInt
	call Crlf

	; subtract from index register
	sub esi,4

	; keep looping
	jmp print_stack_loop

end_print_stack:
	; restore the registers
	pop eax
	pop esi

	;return
	ret
print_stack ENDP
END main