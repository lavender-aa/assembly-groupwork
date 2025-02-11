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
	
_out: ; quit the program
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
    ret
read_input endp


END main