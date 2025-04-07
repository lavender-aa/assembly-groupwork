TITLE Network Simulator

; Program 4: Network Simulator
; Course: CMSC 3100 -- Assembly
; Authors: Group 6
;		- Jon Riley        (ril77053@pennwest.edu)
;		- Lavender Wilson  (wil81891@pennwest.edu)
;		- Tanner Lauritzen (lau74968@pennwest.edu)

INCLUDE Irvine32.inc

.data

; packet fields
dest equ 0
sender equ 1
origin equ 2
ttl equ 3
received equ 4
pSize equ 6



; transmit queue buffers

; node a buffers
aXb label byte
bRa byte pSize dup(0)
aXe label byte
eRa byte psize dup(0)

; node b buffers
bXa label byte 
aRb byte pSize dup(0)
bXc label byte 
cRb byte pSize dup(0)
bXf label byte
fRb byte pSize dup(0)

; node c buffers
cXb label byte
bRc byte pSize dup(0)
cXe label byte
eRc byte pSize dup(0)
cXd label byte
dRc byte pSize dup(0)

; node d buffers
dXc label byte
cRd byte pSize dup(0)
dXf label byte
fRd byte pSize dup(0)

; node e buffers
eXa label byte
aRe byte pSize dup(0)
eXc label byte
cRe byte pSize dup(0)
eXf label byte
fRe byte pSize dup(0)

; node f buffers
fXe label byte
eRf byte pSize dup(0)
fXb label byte
bRf byte pSize dup(0)
fXd label byte
dRf byte pSize dup(0)



; transmission queues
qSize equ 10
qA byte qSize*pSize dup(0)
qB byte qSize*pSize dup(0)
qC byte qSize*pSize dup(0)
qD byte qSize*pSize dup(0)
qE byte qSize*pSize dup(0)
qF byte qSize*pSize dup(0)



; node structures (dwords all pointers)

; node a
nodeA   byte 'A' ; name
		byte 2   ; num connections
		dword qA ; transmit queue address
		dword qA ; in pointer of qA (init to start)
		dword qA ; out pointer (initialized to start)

		; A <-> B
		dword nodeB
		dword aXb ; a -> b
		dword aRb ; a <- b

		; A <-> E
		dword nodeE
		dword axE
		dword aRe

; node b
nodeB   byte 'B'
		byte 3
		dword qB
		dword qB
		dword qB

		; B <-> A
		dword nodeA
		dword bXa
		dword bRa

		; B <-> C
		dword nodeC
		dword bXc
		dword bRc

		; B <-> F
		dword nodeF
		dword bXf
		dword bRf

; node c
nodeC	byte 'C'
		byte 3
		dword qC
		dword qC
		dword qC

		; C <-> B
		dword nodeB
		dword cXb
		dword cRb

		; C <-> D
		dword nodeD
		dword cXd
		dword cRd

		; C <-> E
		dword nodeE
		dword cXe
		dword cRe

; node d
nodeD	byte 'D'
		byte 2
		dword qD
		dword qD
		dword qD

		; D <-> C
		dword nodeC
		dword dXc
		dword dRc

		; D <-> F
		dword nodeF
		dword dXf
		dword dRf

; node e
nodeE	byte 'E'
		byte 3
		dword qE
		dword qE
		dword qE

		; E <-> A
		dword nodeA
		dword eXa
		dword eRa

		; E <-> C
		dword nodeC
		dword eXc
		dword eRc

		; E <-> F
		dword nodeF
		dword eXf
		dword eRf

; node f
nodeF	byte 'F'
		byte 3
		dword qF
		dword qF
		dword qF

		; F <-> B
		dword nodeB
		dword fXb
		dword fRb

		; F <-> D
		dword nodeD
		dword fXd
		dword fRd

		; F <-> E
		dword nodeE
		dword fXe
		dword fRe

.code
main PROC

	

	exit
main ENDP
END main