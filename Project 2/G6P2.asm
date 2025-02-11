TITLE RPN calculator

INCLUDE Irvine32.inc

.data

; stack related
stacksize equ 8
index sdword -4
num_stack sdword size dup(0)

; io related
buffer byte 41 dup(0)

test byte "test",0

.code

main proc
loop:
    ; get user input
    mov edx, offset buffer
    mov ecx, sizeof buffer
    call ReadString

    ; get first character
    mov al, buffer[0]

    ; command handler
switch: cmp al, -1
    je end
    jmp out
end:
    mov edx, offset test
    call WriteString
    call Clrf
out:

main endp

read_input proc
	; start with input buffer, define null and tab
	buffersize equ size
	bytecount dword ?
	null equ 0
	tab equ 9
	
	; needs an index to the input buffer
	mov edx, offset buffer ; read command line
	mov ecx, sizeof buffer
	call ReadString
	mov bytecount, eax ; keep number of bytes read
	
	; initialize index reg to 0
	mov edi, 0
skip: 
	; test for empty input, set index to test
	; error if buffer is empty
	cmp edi, bytecount
	jge skip_else
	mov al, buffer[edi]
	
	; error if there is a null character
	; between whitespace and string start
	cmp al, null
	je skip_else
	
	; if space, increment index and check next
	cmp al, ' '
	je next_char
	
	; if tab, increment index and check next
	cmp al, tab
	jne end
	
next_char:
	inc edi
	jmp skip
skip_else:
	mov al, -1 ; nothing in input buffer, set output
end: 
    ret
read_input endp


END main