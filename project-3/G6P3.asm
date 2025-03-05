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
name byte 8 dup(0)
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

; jobs, pointer
jobs byte numjobs * jobsize dup(0)
endjobs dword endjobs ; memory location that stores its own location
jobptr dword jobs

; messages
cr equ 13
lf equ 10
tab equ 9
quitMsg byte "Exiting program.",cr,lf,0
commandPromptMsg byte cr,lf,"Enter a command: ",0
invalidCommandMsg byte "Invalid command: ",0
cancelMsg byte "Cancelling command.",0
promptNameMsg byte "Enter a name for the job: ",0
promptPriorMsg byte "Enter a priority for the job (0-7): ",0
promptRuntMsg byte "Enter a runtime for the job (1-65536): ",0

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

    ; reset input
    call resetInput

    ; get new input
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    call Crlf ; spacing

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




; clears the input buffer and resets index
resetInput proc
    push esi
    mov index, 0
    mov esi, 0
_emptyInput:
    mov inputBuffer[esi], 0
    inc esi
    cmp esi, sizeof inputBuffer
    jl _emptyInput
    pop esi
    ret
resetInput endp




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




; takes: name
; desc: if job exists, move jobptr there; otherwise, do nothing
;       carry flag set: found
;       carry flag unset: not found
findJob proc
    push eax ; save registers
    push esi
    push ebx

    clc ; only set carry flag if job found

    mov eax, offset name ; store name offset in eax
    mov ebx, offset jobptr ; store starting job pointer location
    jmp _loop
_updateJob:
    call nextJob
    cmp jobptr, ebx
    je _ret ; if job pointer becomes where it started, not found
_loop:
    mov esi, jobptr[eax] ; store beginning of job name
    mov edi, offset name ; store beginning of acquired name (will not be empty)
    mov ecx, sizeof name
    repe cmpsb
    jne _updateJob
    stc ; name is equal; match found, jobptr is pointing to it

_ret:
    pop ebx
    pop esi
    pop eax ; restore registers
    ret
findJob endp




; increments the job pointer, wrapping it around to the start
nextJob proc
    push eax ; save registers

    add jobptr, jobsize ; go to next record

    mov eax, offset endjobs
    cmp jobptr, eax
    jge _begin ; if index is too large, wrap to beginning
    jmp _ret

_begin:
    mov eax, offset jobs
    mov jobptr, eax
    
_ret:
    push eax ; restore registers
    ret
nextJob endp




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
; desc: changes job priority
changeCommand proc
    ret
changeCommand endp




; takes: name, priority, runtime
; desc: creates a new job
loadCommand proc
    push eax ; save registers
    push esi
    push edi
    push ecx
    push edx

    ; if there is no space: cancel
    ; else: test input for next data
    call spaceAvailable
    jc _testName
    jmp _cancel

_testName: ; test input buffer; get name if there is more, prompt/get if not
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptName
    ; past: take name from buffer
    call getWord
    jmp _validateName

_promptName: ; prompt for and read name
    mov edx, offset promptNameMsg
    call WriteString

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ReadString
    call Crlf

_validateName: ; if name is empty, cancel; else if invalid, reprompt; else, continue
    cmp wordBuffer, 0
    je _cancel

    mov esi, offset wordBuffer ; copy wordbuffer to name for finding
    mov edi, offset name
    mov ecx, sizeof name
    rep movsb

    ; validate: name is unique
    call findJob
    jc _promptName ; job with same name found; try again

_testPriority:
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptPriority
    ; past: take name from buffer
    call getWord
    jmp _validatePriority

_promptPriority:
    mov edx, offset promptPriorMsg
    call WriteString

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ReadString
    call Crlf

_validatePriority: ; first byte 0-7, second byte null
    mov ah, wordBuffer[1]
    cmp ah, 0
    je _promptPriority
    mov al, wordBuffer
    cmp al, '0'
    jl _promptPriority
    cmp pal, '7'
    jg _promptPriority

    sub al, '0'
    mov priority, al

_testRuntime:
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptRuntime
    ; past: take name from buffer
    call getWord
    jmp _validateRuntime

_promptRuntime:
    mov edx, offset promptRuntMsg
    call WriteString

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ReadString
    call Crlf

_validateRuntime: ; parse integer succeeds, value is not 0, value is less than 65536
    mov edx, wordBuffer
    call ParseInt32
    jc _promptRuntime
    cmp eax, 0
    jle _promptRuntime
    cmp eax, 65536
    jge _promptRuntime
    mov runtime, ax
    jmp _createRecord ; got all data, make record
    

_cancel: ; print message, clear npriority, runtime, name
    mov edx, offset cancelMsg
    call WriteString
    mov priority, 0
    mov runtime, 0
    mov eax, 0
_clearName:
    mov name[eax], 0
    inc eax
    cmp eax, sizeof name
    jl _clearName
    jmp _ret

_createRecord: ; jobptr already pointing at available slot
    ; set variables
    mov eax, system_time
    mov loadtime, eax ; store load time
    mov al, jhold
    mov status, al ; start in hold mode

    ; set name
    mov esi, name
    mov eax, jname
    mov edi, jobptr[eax]
    mov ecx, sizeof name
    rep movsb

    ; set priority
    mov dl, priority
    mov eax, jpriority
    mov jobptr[eax], dl

    ; set status
    mov dl, status
    mov eax, jstatus
    mov jobptr[eax], dl

    ; set runtime
    mov dx, runtime
    mov eax, jruntime
    mov jobptr[eax], dx

    ; set loadtime
    mov dx, system_time
    mov eax, jloadtime
    mov jobptr[eax], dx

_ret:
    pop edx
    pop ecx
    pop edi
    pop esi
    pop eax ; restore registers
    ret
loadCommand endp




; carry flag set: one available space, jobptr points to it
; carry flag unset: no spaces available
spaceAvailable proc
    push eax ; save registers
    push esi
    push ebx

    clc ; set default to false

    mov eax, jobptr ; store original location
    mov esi, jstatus
    jmp _loop
_incJob:
    call nextJob
    cmp jobptr, eax
    je _ret
_loop:
    mov ebx, jobptr + esi
    cmp byte ptr [ebx], 0 ; testing if status is available
    jne _incJob ; if not, move on to next job
    stc ; if so, found available; set carry, return

_ret:
    pop ebx
    pop esi
    pop eax ; restore registers
    ret
spaceAvailable endp


END main