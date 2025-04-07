TITLE name

; Program x: name
; Course: CMSC 3100 -- Assembly
; Authors: Group 6
;		- Jon Riley        (ril77053@pennwest.edu)
;		- Lavender Wilson  (wil81891@pennwest.edu)
;		- Tanner Lauritzen (lau74968@pennwest.edu)

INCLUDE Irvine32.inc

.data
message byte "working",0

.code
main PROC

	mov edx, OFFSET message
	call WriteString
	call Crlf
	exit

main ENDP
END main