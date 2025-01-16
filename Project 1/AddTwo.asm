TITLE test
; author: lavender

INCLUDE Irvine32.inc

.data
message byte "testing copying project folders",0

.code
main PROC

	mov edx, OFFSET message
	call WriteString
	call Crlf
	exit

main ENDP
END main