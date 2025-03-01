TITLE Operating System Simulator

; Program 3: Operating System Simulator
; Course: CMSC 3100 -- Assembly
; Authors: Group 6
;		- Jon Riley        (ril77053@pennwest.edu)
;		- Lavender Wilson  (wil81891@pennwest.edu)
;		- Tanner Lauritzen (lau74968@pennwest.edu)

INCLUDE Irvine32.inc

.data

; command line input processing
inputBuffer byte 51 dup(0)
wordBuffer byte 11 dup(0)
index dword 0

; command targets
quitTarget   byte 'quit',0
helpTarget   byte 'help',0
showTarget   byte 'show',0
runTarget    byte 'run',0
holdTarget   byte 'hold',0
killTarget   byte 'kill',0
stepTarget   byte 'step',0
changeTarget byte 'change',0
loadTarget   byte 'load',0

; record data
name byte 9 dup(0)
priority byte 0
status byte 0
runtime word 0
system_time word 0

; record field offsets
jname equ 0
jpriority equ 8
jstatus equ 9
jruntime equ 10
jloadtime equ 12

; status value constants
javailable equ 0
jrun equ 1
jhold equ 2

; lowest priority, job size, max number of jobs
jlowestpriority equ 7
jobsize equ 14
numjobs equ 10

; jobs
jobs byte numjobs * jobsize dup(0)
endjobs dword endjobs ; memory location that stores its own location

; messages
cr equ 13
lf equ 10
tab equ 9
quitMsg byte "Exiting program.",cr,lf,0
commandPromptMsg byte "Enter a command: ",0
invalidCommandMsg byte "Invalid command: ",0

; debug
debug byte 'debug',0

.code

main PROC
_loop:  ; carry set: continue loop
    call commandHandler
    jc _loop
_out:
    mov edx, offset quitMsg
    call WriteString
    exit
main ENDP




commandHandler proc
    ; prompt for command
    mov edx, offset commandPromptMsg
    call WriteString

    ; empty previous input
    mov esi, 0
_emptyInput:
    mov inputBuffer[esi], 0
    inc esi
    cmp esi, sizeof inputBuffer
    jl _emptyInput

    ; get new input
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    mov index, 0 ; reset index for new line
    call skipSpace ; move input to first word
    call getWord ; get word into buffer

    ; test word
    cld
_quit:
    mov esi, offset wordBuffer
    mov edi, offset quitTarget
    mov ecx, sizeof quitTarget
    repe cmpsb
    jne _help
    clc ; stop main loop
    jmp _ret
_help:
    mov esi, offset wordBuffer
    mov edi, offset helpTarget
    mov ecx, sizeof helpTarget
    repe cmpsb
    jne _show
    mov edx, offset helpTarget
    call WriteString
    jmp _continue
_show:
    mov esi, offset wordBuffer
    mov edi, offset showTarget
    mov ecx, sizeof showTarget
    repe cmpsb
    jne _run
    mov edx, offset showTarget
    call WriteString
    jmp _continue
_run:
    mov esi, offset wordBuffer
    mov edi, offset runTarget
    mov ecx, sizeof runTarget
    repe cmpsb
    jne _hold
    mov edx, offset runTarget
    call WriteString
    jmp _continue
_hold:
    mov esi, offset wordBuffer
    mov edi, offset holdTarget
    mov ecx, sizeof holdTarget
    repe cmpsb
    jne _kill
    mov edx, offset holdTarget
    call WriteString
    jmp _continue
_kill:
    mov esi, offset wordBuffer
    mov edi, offset killTarget
    mov ecx, sizeof killTarget
    repe cmpsb
    jne _step
    mov edx, offset killTarget
    call WriteString
    jmp _continue
_step:
    mov esi, offset wordBuffer
    mov edi, offset stepTarget
    mov ecx, sizeof stepTarget
    repe cmpsb
    jne _change
    mov edx, offset stepTarget
    call WriteString
    jmp _continue
_change:
    mov esi, offset wordBuffer
    mov edi, offset changeTarget
    mov ecx, sizeof changeTarget
    repe cmpsb
    jne _load
    mov edx, offset changeTarget
    call WriteString
    jmp _continue
_load:
    mov esi, offset wordBuffer
    mov edi, offset loadTarget
    mov ecx, sizeof loadTarget
    repe cmpsb
    jne _default
    mov edx, offset loadTarget
    call WriteString
    jmp _continue
_default:
    ; print error message
    mov edx, offset invalidCommandMsg
    call WriteString
    mov edx, offset wordBuffer
    call WriteString
    call Crlf

_continue:
    stc
_ret:
    ret
commandHandler endp




skipSpace proc
    push eax ; save registers
    push esi

    ; loop through input buffer, start at index
    ; and end when nonwhitespace is found
    mov esi, index
    jmp _loop
_inc:
    inc esi
_loop:
    cmp esi, sizeof inputBuffer
    jge _ret
    mov al, inputBuffer[esi]
    call isSpace
    jc _inc
_ret:
    mov index, esi ; update index
    pop esi
    pop eax ; restore registers
    ret
skipSpace endp




; carry flag set: true (al is whitespace)
; carry flag unset: false (al is not whitespace
isSpace proc
    clc
    cmp al, ' '
    je _true
    cmp al, tab
    je _true
    jmp _false
_true:
    stc
_false:
    ret
isSpace endp




getWord proc
    push esi ; save registers
    push edi

    ; empty word buffer
    mov esi, 0
_emptyWord:
    mov wordBuffer[esi], 0
    inc esi
    cmp esi, sizeof wordBuffer
    jl _emptyWord

    ; copy values until end of word buffer or found whitespace
    mov esi, index
    mov edi, 0
_loop:
    cmp esi, sizeof inputBuffer
    jge _ret
    cmp edi, sizeof wordBuffer
    jge _ret
    mov al, inputBuffer[esi]
    call isSpace
    jc _updateIndex
    call toLower
    mov wordBuffer[edi], al
    inc esi
    inc edi
    jmp _loop

_updateIndex:
    mov index, esi
_ret:
    pop edi
    pop esi ; restore registers
    ret
getWord endp




; turns a capital letter stored in al to lowercase
toLower proc
    cmp al, 'A'
    jl _ret
    cmp al, 'Z'
    jg _ret
    or al, 20h
_ret:
    ret
toLower endp












END main