TITLE Network Simulator

; Program 4: Network Simulator
; Course: CMSC 3100 -- Assembly
; Authors: Group 6
;		- Jon Riley        (ril77053@pennwest.edu)
;		- Lavender Wilson  (wil81891@pennwest.edu)
;		- Tanner Lauritzen (lau74968@pennwest.edu)

INCLUDE Irvine32.inc

; constants
tab equ 9
messagesInQ equ 30 ; maximum number of elements in each queue
pSize equ 6
qSize equ (messagesInQ+1) * pSize
nodeSize equ 14 ; base, without connections
connectionSize equ 12
nameOffset equ 0
numConn equ 1



; packet fields
dest equ 0		; byte
sender equ 1	; byte
origin equ 2	; byte
ttl equ 3		; word
received equ 5	; byte




.data
; string/printing related
currentNode byte "Node: ",0
connectionNode byte tab,"connection: ",0
nodePosition equ sizeof currentNode - 2 ; (?)
connectionPosition equ sizeof connectionNode - 2 



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

endNodes dword offset endNodes

.code
main PROC

_mainLoop:
	; edi points to beginning of current node
	; esi points to connected note struct
	; ecx, edx used for messages
	; build source node message
	; ebx used for connection counter
	; eax temp for data, calculations

	mov edi, offset nodeA ; start of network

	; init time
	call PrintCrlf
	mov edx, offset timemess
	mov ecx, sizeof timemess
	movzx eax, time
	stc
	call PrintMessageNumber

	; init pointer, packets
	mov nodepointer, offest nodeA
	mov generatedpackets, 0

	; transmit loop
xmtloop:
	; print "processing node (name)" message
	mov esi, nodepointer
	call PrintCrlf
	mov edx, offset processingout
	mov eax, sizeof processingout
	add edx, eax
	sub edx, 2
	mov al, nodeoffset[esi]
	mov [edx], al
	mov edx, offset processingout
	mov ecx, sizeof processingout
	stc
	call PrintMessage
	
	; get message from transmit queue
	mov messagepointer, offset temppacket
	call Get
	jc nextXMT
	mov ebx, 0
	mov bl, numconnoffset[esi]
	mov edi, offset temppacket
	
	; print "at time (time)"
	mov edx, offset attime
	mov ecx, sizeof attime
	mov eax, word ptr rcvtimeoffset[edi]
	clc
	call PrintMessageNumber
	
	; print "received from (node)"
	mov edx, offset messagereceived
	mov eax, sizeof messagereceived
	add edx, eax
	sub edx, 2
	mov al, sendoffset[edi]
	mov [edx], al
	mov nodefrom, al
	mov al, nodename
	mov sendoffset[edi], al
	mov edx, offset messagereceived
	mov ecx, offset messagereceived
	stc
	call PrintMessage
	
	; initialize packet counters
	mov newpackets, -1
	dec generatedpackets
	dec totalpackets
	dec activepackets
	
	; process each connection
	add esi, basenodesize
xmtnodeloop:
	; print "message generated for (node)" message
	mov edx, offset messagegenerated
	mov eax, sizeof messagegenerated
	add edx, eax
	sub edx, 2
	mov edi, connectionoffset[esi]
	mov al, nodeoffset[edi]
	mov [edx], al
	mov edx, offest messagegenerated
	mov ecx, sizeof messagegenerated
	stc
	call PrintMessage
	
	; echo or no echo
	cmp echof, true
	je sendit
	cmp nodefrom, al
	je dontsend
sendit:
	inc activepackets
	inc newpackets
	inc generatedpackets
	inc totalpackets
	; copy temppacket to transmit buffer for this connection
	call SendPacket
	mov edx, offset messagesent
	mov ecx, sizeof messagesent
	stc
	call PrintMessage
	jmp nextXMT
dontsend:
	mov edx, offset messagenotsent
	mov ecx, sizeof messagenotsent
	stc
	call PrintMessage

nextXMT:
	; move to the next connection in the current node
	add esi, connectionsize
	dec ebx ; count processed node connection
	jg xmtnodeloop ; process next connection if there is one
	
	; go to the next node
	movzx eax, byte ptr numconnoffset[esi]
	movzx ebx, connectionsize
	mul bl
	add eax, basenodesize ; node + connections
	add esi, eax
	mov nodepointer, esi
	cmp esi, endofnodes
	jl xmtloop

	; transmit loop complete
	
	; print number of active and generated messages
	call PrintCrlf
	mov edx, offset thereare2
	mov ecx, offset thereare2
	movzx eax, activepackets
	clc
	call PrintMessageNumber
	mov edx, offset messagesactiveand
	mov ecx, sizeof messagesactiveand
	movzx eax, generatedpackets
	clc
	call PrintMessageNumber
	mov edx, offset messageshavebeen
	mov ecx, sizeof messageshavebeen
	movzx eax, totalpackets
	clc
	call PrintMessageNumber
	mov edx, offset totalmessageshavebeen
	mov ecx, offset totalmessageshavebeen
	stc
	call PrintMessage
	
	; update time
	inc time


	exit
main ENDP
END main