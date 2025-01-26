TITLE Average Program

INCLUDE Irvine32.inc

.data
;strings
prompt	BYTE	"Enter a grade (0 to 100): ",0
instr1	BYTE	"This program will average the grades entered.",0
instr2	BYTE "Any value outside of (0 - 100) will end the program.",0
noGradesStr	BYTE	"No grades have been entered.",0
countName		BYTE	"Count: ",0
sumName		BYTE	"Sum: ",0
averageName	BYTE	"Average: ",0
remainderName	BYTE "Remainder: ",0

;for input
buffer	BYTE		7 DUP(0)

;variables
sum		DWORD	0
count	DWORD	0
average	DWORD	0
remainder	DWORD	0

.code
main PROC
	;display the instructions
	mov edx,OFFSET instr1	;set up instr string
	call WriteString		;display instr
	call Crlf
	mov edx,OFFSET instr2	;set up instr2 string
	call WriteString		;display instr2
	call Crlf

mainLoop:
	;prompt the user to enter a grade
	mov edx,OFFSET prompt	;set up prompt
	call WriteString		;write prompt

	;take user input
	mov edx,OFFSET buffer	;point to the buffer
	mov ecx,SIZEOF buffer	;specify max characters
	call ReadString		;input the string

	;convert user input to integer
	mov ecx,eax			;move string count to ecx
	call ParseInteger32		;convert to integer
	
	;check if entered number is < 0
	cmp eax,0
	jl exitLoop

	;check if entered number is > 100
	cmp eax,100
	jg exitLoop

	;add number to sum
	add sum,eax

	;increment the counter
	inc count

	;repeat the loop
	jmp mainLoop

exitLoop:
	;check if no grades were entered
	cmp count,0
	je noGrades

	;calculate average
	mov edx,0		;clear edx for div, dividend high
	mov eax,sum	;move sum to eax, dividend low
	div count		;divide by count

	;store results
	mov average,eax	;store quotient to average
	mov remainder,edx	;store remainder to remainder

	;display the count, sum, average
	call Crlf
	mov edx,OFFSET countName		;set up count name string
	call WriteString			;display the count name string
	mov eax,count				;get the count
	call WriteInt				;display the count
	call Crlf
	mov edx,OFFSET sumName		;set up sum name string
	call WriteString			;display the sum name string
	mov eax,sum				;get the sum
	call WriteInt				;display the sum
	call Crlf
	mov edx,OFFSET averageName	;set up the average name string
	call WriteString			;display the average name string
	mov eax,average			;get the average
	call WriteInt				;display the average
	call Crlf
	mov edx,OFFSET remainderName	;set up the remainder name string
	call WriteString			;display the remainder name string
	mov eax,remainder			;get the remainder
	call WriteInt				;display the remainder

	;jump to ending
	jmp ending

noGrades:
	;no grades were entered
	call Crlf
	mov edx,OFFSET noGradesStr	;set up no grades entered error msg
	call WriteString			;display the error msg

ending:
	call Crlf

	exit
main ENDP
END main