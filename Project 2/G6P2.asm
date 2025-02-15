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
errormsg byte "Error: invalid input.",cr,lf,0
buffer byte 41 dup(0)
bytecount dword ?

string byte "your input: a",cr,lf,0


.code

main proc
_loop:
    ; get user input
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
	; case 1 body
	jmp _end

_c2: ; first character is a minus sign -- negative number OR subtract
	cmp al, '-'
	jne _c3
	; case 2 body
	jmp _end

_c3: ; addition
	cmp al, '+'
	jne _c4
	; case 3 body
	jmp _end

_c4: ; multiplication
	cmp al, '*'
	jne _c5
	; case 4 body
	jmp _end

_c5: ; division
	cmp al, '/'
	jne _c6
	; case 5 body
	jmp _end

_c6: ; exchange top two elements of stack
	cmp al, 'x'
	jne _c7
	; case 6 body
	jmp _end

_c7: ; roll stack up
	cmp al, 'u'
	jne _c8
	; case 7 body
	jmp _end

_c8: ; roll stack down
	cmp al, 'd'
	jne _c9
	; case 8 body
	jmp _end

_c9: ; print stack ("view")
	cmp al, 'v'
	jne _c10
	; case 9 body
	jmp _end

_c10: ; clear stack
	cmp al, 'c'
	jne _c11
	; case 10 body
	jmp _end

_c11: ; quit
	cmp al, 'q'
	jne _default
	jmp _out

_default: ; print error
	mov edx, offset errormsg
	call WriteString
	; fall through to _end
    
_end: ; continue to next loop
	jmp _loop
	
_out: ;exit program
	exit
main endp



read_input proc
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

_end: 
	; make sure letter is uppercase before returning
	cmp al, 'A'
	jl _ret
	cmp al, 'Z'
	jg _ret
	or al, 20h ; set 'case' bit

_ret:
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