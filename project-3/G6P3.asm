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
commandPromptMsg byte cr,lf,"Enter a command: ",0
invalidCommandMsg byte "Invalid command: ",0

; help message
helpMsg byte "This program is a simple simulation of an operating system.",cr,lf
        byte "Jobs can be run by the system, and have 5 elmeents:",cr,lf
        byte tab,"name: a unique 8-character name for the job.",cr,lf
        byte tab,"prority: a number 0-7 (highest-lowest) for which jobs should be run first.",cr,lf
        byte tab,"status: either 'available' (0), 'holding' (1), or 'running' (2).",cr,lf
        byte tab,"runtime: the number of clock cycles the job takes to complete.",cr,lf
        byte tab,"loadtime: the system time at which the job was first loaded.",cr,lf,cr,lf
        byte "When a clock cycle is processed, the job with the next highest priority will have its runtime decremented.",cr,lf
        byte "When a job's runtime reaches 0, the job is removed from the list.",cr,lf
        byte "There can only be up to 10 jobs at once.",cr,lf,cr,lf
        byte "Commands are not case sensitive, and neither are names (both are converted to lowercase).",cr,lf
        byte "Below is a list of commands. The items in [brackets] are optional but will be prompted for,",cr,lf
        byte "and the items in (parenthesis) are optional and have default values.",cr,lf
        byte "If any prompted-for field is left empty, the command will be cancelled.",cr,lf,cr,lf
        byte "Command descriptions have this form:",cr,lf
        byte "Command Name:",cr,lf,tab,"'Syntax, options'",cr,lf,tab,"Description",cr,lf,cr,lf
        byte "Commands:",cr,lf,"---------",cr,lf,cr,lf
        byte "Quit:",cr,lf,tab,"'quit'",cr,lf,tab,"Quits the program.",cr,lf,cr,lf
        byte "Help:",cr,lf,tab,"'help'",cr,lf,tab,"Displays this message.",cr,lf,cr,lf
        byte "Show:",cr,lf,tab,"'show'",cr,lf,tab,"Displays all jobs.",cr,lf,cr,lf
        byte "Run:",cr,lf,tab,"'run [name]'",cr,lf,tab,"Changes the status of a job from 'hold' to 'run'.",cr,lf,cr,lf
        byte "Hold:",cr,lf,tab,"'hold [name]'",cr,lf,tab,"Changes the status of a job from 'run' to 'hold'.",cr,lf,cr,lf
        byte "Kill:",cr,lf,tab,"'kill [name]'",cr,lf,tab,"Removes a job whose status is 'hold'.",cr,lf,cr,lf
        byte "Step:",cr,lf,tab,"'step (num_steps)'",cr,lf,tab,"Processes a positive integer number of clock cycles.",cr,lf,cr,lf
        byte "Change:",cr,lf,tab,"'change [name [new_priority]]'",cr,lf,tab,"Changes a job's priority.'",cr,lf,cr,lf
        byte "Load:",cr,lf,tab,"'load [name [priority [runtime]]]'",cr,lf,tab,"Creates a new job if there is space.",cr,lf,0

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

    call Crlf ; spacing

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
    mov edx, offset helpMsg
    call WriteString
    jmp _continue
_show:
    mov esi, offset wordBuffer
    mov edi, offset showTarget
    mov ecx, sizeof showTarget
    repe cmpsb
    jne _run
    call showCommand
    jmp _continue
_run:
    mov esi, offset wordBuffer
    mov edi, offset runTarget
    mov ecx, sizeof runTarget
    repe cmpsb
    jne _hold
    call runCommand
    jmp _continue
_hold:
    mov esi, offset wordBuffer
    mov edi, offset holdTarget
    mov ecx, sizeof holdTarget
    repe cmpsb
    jne _kill
    call holdCommand
    jmp _continue
_kill:
    mov esi, offset wordBuffer
    mov edi, offset killTarget
    mov ecx, sizeof killTarget
    repe cmpsb
    jne _step
    call killCommand
    jmp _continue
_step:
    mov esi, offset wordBuffer
    mov edi, offset stepTarget
    mov ecx, sizeof stepTarget
    repe cmpsb
    jne _change
    call stepCommand
    jmp _continue
_change:
    mov esi, offset wordBuffer
    mov edi, offset changeTarget
    mov ecx, sizeof changeTarget
    repe cmpsb
    jne _load
    call changeCommand
    jmp _continue
_load:
    mov esi, offset wordBuffer
    mov edi, offset loadTarget
    mov ecx, sizeof loadTarget
    repe cmpsb
    jne _default
    call loadCommand
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




; takes: nothing
; desc: shows all non-available records
showCommand proc
    ret
showCommand endp




; takes: name
; desc: changes a job from hold to run
runCommand proc
    ret
runCommand endp




; takes: name
; desc: changes a job from run to hold
holdCommand proc
    ret
holdCommand endp




; takes: name
; desc: removes a job if it is in hold mode
killCommand proc
    ret
killCommand endp




; takes: number or nothing
; desc: processes n steps
stepCommand proc
    ret
stepCommand endp




; takes: name, new_priority
; desc: changes job's priority
changeCommand proc
    ret
changeCommand endp




; takes: name, priority, runtime
; desc: creates a new job
loadCommand proc
    ret
loadCommand endp


END main