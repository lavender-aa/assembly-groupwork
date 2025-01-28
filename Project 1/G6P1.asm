
title Average Program

; Course: CMSC 3100 -- Assembly
; Program 1: Average Program
; Authors: Group 6
;		- Jon Riley        (ril77053@pennwest.edu)
;		- Lavender Wilson  (wil81891@pennwest.edu)
;		- Tanner Lauritzen (lau74968@pennwest.edu)

include Irvine32.inc

.data
; strings (for printing)
prompt byte "Enter a grade: ",0
instr1 byte "Enter integer grades (0-100 inclusive) to average.",0
instr2 byte "When a value <0 or >100 is entered, values will stop being taken and the average will be calculated.",0
error_0_grades byte "Error: cannot take average of 0 grades.",0
sum_name byte "sum: ",0
count_name byte "count: ",0
average_name byte "average: ",0
remainder_name byte "remainder: ",0

; input
inputBuffer byte 11 dup(0)
bufferSize = ($ - inputBuffer)

; accumulating, calculating
sum dword 0
average dword 0 ; = sum(32, will be in a register) / count(8, mem)
remainder dword 0
count word 0

.code
main proc

	; print instructions
	call Crlf
	mov edx, offset instr1
	call WriteString
	call Crlf
	mov edx, offset instr2
	call WriteString
	call Crlf
	call Crlf

_loop:
	; print prompt
	mov edx, offset prompt
	call WriteString

	; read input from user (max 10 chars + null)
	mov edx, offset inputBuffer
	mov ecx, sizeof inputBuffer
	call ReadString
	
	; convert input to integer (stored in eax)
	mov edx, offset inputBuffer
	mov ecx, eax                  ; eax contains number of characters (from above read)
	call ParseInteger32

	; if the parse failed (overflow flag set), skip to next loop iteration
	jo _loop

	; if grade < 0, end _loop
	cmp eax, 0
	jl _out

	; if grade > 100, end _loop
	cmp eax, 100
	jg _out

	; grade is valid; continue
	; add grade to sum
	add sum, eax

	; increase grade count
	inc count

	; go to the next loop
	jmp _loop
	
_out:
	; done entering grades. if more than 0 grades, continue;
	; otherwise, print the error message (and don't perform any calculations).
	cmp count, 0
	je _no_grades

	; calculate average (integer; ignore remainder)
	mov eax, sum     ; put sum in eax for division (lower half of dividend)
	mov edx, 0       ; clear edx for division (upper half of dividend)
	div count   ; edx:eax / count (mem8) -> quotient in eax

	; store quotient and remainder
	mov average, eax
	mov remainder, edx

	; print sum, count, average, remainder
	call Crlf
	mov edx, offset sum_name
	call WriteString
	mov eax, sum
	call WriteInt

	call Crlf
	mov edx, offset count_name
	call WriteString
	movzx eax, count
	call WriteInt

	call Crlf
	mov edx, offset average_name
	call WriteString
	mov eax, average
	call WriteInt

	call Crlf
	mov edx, offset remainder_name
	call WriteString
	mov eax, remainder
	call WriteInt

	; skip error message (only prints for 0 grades)
	jmp _end


_no_grades:
	; branch for if 0 good grades are entered
	mov edx, offset error_0_grades
	call WriteString

_end:
	call Crlf

	exit
main endp
end main
