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
nameBuffer byte 8 dup(0)
priority byte 0
status byte 0
runtime word 0
loadtime word 0

; system time
system_time word 0

; record field offsets
jnameBuffer equ 0
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
endjobs dword offset endjobs ; memory location that stores its own location
jobptr dword offset jobs

; messages
cr equ 13
lf equ 10
tab equ 9
quitMsg byte "Exiting program.",cr,lf,0
commandPromptMsg byte cr,lf,"Enter a command: ",0
invalidCommandMsg byte "Invalid command: ",0
cancelMsg byte "Cancelling command.",0
promptnameMsg byte "Enter a name for the job: ",0
promptPriorMsg byte "Enter a priority for the job (0-7): ",0
promptRuntMsg byte "Enter a runtime for the job (1-65536): ",0
promptBadDataMsg byte "Invalid data entered.",cr,lf,0
stackFullMsg byte "There is no room available for a new job.",cr,lf,0

; record printing strings
rpNameMsg byte "Record name: ",0
rpPrior byte "Priority: ",0
rpStatus byte "Status: ",0
rpStatRun byte "running",0
rpStatHold byte "holding",0
rpRun byte "Runtime: ",0
rpLoad byte "Load time: ",0

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
        byte "Command name:",cr,lf,tab,"'Syntax, options'",cr,lf,tab,"Description",cr,lf,cr,lf
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
    push eax
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
    pop eax
    ret
skipSpace endp




; carry flag set: true (al is whitespace)
; carry flag unset: false (al is not whitespace
isSpace proc
    clc
    cmp al, 0
    je _true
    cmp al, ' '
    je _true
    cmp al, tab
    je _true
    cmp al, 10 ; '\n'
    je _true
    jmp _false
_true:
    stc
_false:
    ret
isSpace endp




getWord proc
    push esi
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
    pop esi
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




; takes: name offset in esi
; desc: if job exists, move jobptr there; otherwise, do nothing
;       carry flag set: found
;       carry flag unset: not found
findJob proc
    push eax
    push ebx
    push ecx
    push edi

    clc ; clear carry

    mov ebx, jobptr ; keep original job to check
    mov eax, jobptr ; initialize current job pointer
    jmp _while
_incJob:
    call nextJob
    mov eax, jobptr ; store current job
    cmp eax, ebx
    je _ret ; if the current job is the original, job not found
_while:
    mov edi, eax
    add edi, jnameBuffer ; store offset of current job name

    mov ecx, 8 ; max number of characters to read
    repe cmpsb ; compare input with current job name
    jne _incJob ; if they are different, move on to next loop

    stc ; if the names do match, job was found

_ret:
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret
findJob endp




; increments the job pointer, wrapping it around to the start
nextJob proc
    push eax
    push ebx

    mov ebx, jobsize
    add jobptr, ebx ; go to next record

    mov eax, offset endjobs
    cmp jobptr, eax
    jge _begin ; if index is too large, wrap to beginning
    jmp _ret

_begin:
    mov eax, offset jobs
    mov jobptr, eax
    
_ret:
    pop ebx
    pop eax
    ret
nextJob endp




; takes: nothing
; desc: shows all non-available records
showCommand proc
    push eax
    push ebx
    push ecx
    push edi
    push esi

    mov ebx, jobptr ; origin
    jmp _while

_incJob:
    call nextJob
    cmp jobptr, ebx
    je _ret
_while:
    mov eax, jobptr ; current job
    mov edx, eax
    add edx, jstatus ; get pointer to status in edx
    movzx ecx, byte ptr [edx]

    cmp ecx, 0 ; test if status is available
    je _incJob ; if so, go to next job

    ; write name
    mov edi, eax
    add edi, jnameBuffer
    mov esi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb ; copy 8 bytes from record into name buffer
    
    mov edx, offset rpNameMsg
    call WriteString
    mov edx, offset nameBuffer
    call WriteString
    call Crlf

    ; write priority
    mov edx, offset rpPrior
    call WriteString
    mov edx, eax
    add edx, jPriority
    push eax
    movzx eax, byte ptr [edx]
    call WriteInt
    call Crlf
    pop eax

    ; write status
    mov edx, offset rpStatus
    call WriteString
    mov edx, eax
    add edx, jPriority
    mov cl, byte ptr [edx]
    cmp cl, jrun
    jne _hold
    mov edx, offset rpStatRun
    jmp _printStat
_hold:
    mov edx, offset rpStatHold
_printStat:
    call WriteString
    call Crlf

    ; write runtime
    mov edx, offset rpRun
    call WriteString
    mov edx, eax
    add edx, jruntime
    push eax
    movzx eax, word ptr [edx]
    call WriteInt
    call Crlf
    pop eax

    ; write loadtime
    mov edx, offset rpLoad
    call WriteString
    mov edx, eax
    add edx, jloadtime
    push eax
    movzx eax, word ptr [edx]
    call WriteInt
    call Crlf
    pop eax
    
_ret:
    pop esi
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret
showCommand endp




; takes: nameBuffer
; desc: changes a job from hold to run
runCommand proc
    ret
runCommand endp




; takes: nameBuffer
; desc: changes a job from run to hold
holdCommand proc
    ret
holdCommand endp




; takes: nameBuffer
; desc: removes a job if it is in hold mode
killCommand proc
    ret
killCommand endp




; takes: number or nothing
; desc: processes n steps
stepCommand proc
    ret
stepCommand endp




; takes: nameBuffer, new_priority
; desc: changes job priority
changeCommand proc
    ret
changeCommand endp




; takes: nameBuffer, priority, runtime
; desc: creates a new job
loadCommand proc
    push eax
    push esi
    push edi
    push ecx
    push edx

    ; if there is no space: cancel
    ; else: test input for next data
    call spaceAvailable
    jc _testnameBuffer
    mov edx, offset stackFullMsg
    call WriteString
    jmp _cancel

_testnameBuffer: ; test input buffer; get nameBuffer if there is more, prompt/get if not
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptnameBuffer
    call getWord
    jmp _validatenameBuffer

_invalidName:
    mov edx, offset promptBadDataMsg
    call WriteString
_promptnameBuffer: ; prompt for and read name
    mov edx, offset promptNameMsg
    call WriteString

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ReadString
    call Crlf

_validatenameBuffer: ; if nameBuffer is empty, cancel; else if invalid, reprompt; else, continue
    cmp wordBuffer, 0
    je _cancel

    mov esi, offset wordBuffer ; copy wordbuffer to nameBuffer for finding
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

    ; validate: nameBuffer is unique
    call findJob
    jc _invalidName ; job with same nameBuffer found; try again

_testPriority:
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptPriority
    ; past: take nameBuffer from buffer
    call getWord
    jmp _validatePriority

_invalidPriority:
    mov edx, offset promptBadDataMsg
    call WriteString
_promptPriority:
    mov edx, offset promptPriorMsg
    call WriteString

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ReadString
    call Crlf

_validatePriority: ; first byte 0-7, second byte null
    cmp wordBuffer, 0
    je _cancel

    mov ah, wordBuffer[1]
    cmp ah, 0
    jne _invalidPriority
    mov al, wordBuffer
    cmp al, '0'
    jl _invalidPriority
    cmp al, '7'
    jg _invalidPriority

    sub al, '0'
    mov priority, al

_testRuntime:
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptRuntime
    ; past: take nameBuffer from buffer
    call getWord
    jmp _validateRuntime

_invalidRuntime:
    mov edx, offset promptBadDataMsg
    call WriteString
_promptRuntime:
    mov edx, offset promptRuntMsg
    call WriteString

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ReadString
    call Crlf

_validateRuntime: ; parse integer succeeds, value is not 0, value is less than 65536
    cmp wordBuffer, 0
    je _cancel

    mov edx, offset wordBuffer
    mov ecx, sizeof wordBuffer
    call ParseInteger32
    jc _promptRuntime
    cmp eax, 1
    jle _invalidRuntime
    cmp eax, 65536
    jge _invalidRuntime
    mov runtime, ax
    jmp _createRecord ; got all data, make record
    

_cancel: ; print message, clear npriority, runtime, nameBuffer
    mov edx, offset cancelMsg
    call WriteString
    mov priority, 0
    mov runtime, 0
    mov eax, 0
_clearnameBuffer:
    mov nameBuffer[eax], 0
    inc eax
    cmp eax, sizeof nameBuffer
    jl _clearnameBuffer
    jmp _ret

_createRecord: ; jobptr already pointing at available slot

    ; store job offset in eax
    mov eax, jobptr

    ; set nameBuffer
    mov esi, offset nameBuffer
    mov edi, eax
    add edi, jnameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb ; error

    ; set priority
    mov dl, priority
    mov byte ptr jpriority[eax], dl

    ; set status
    mov dl, jhold
    mov byte ptr jstatus[eax], dl

    ; set runtime
    mov dx, runtime
    mov word ptr jruntime[eax], dx

    ; set loadtime
    mov dx, system_time
    mov word ptr jloadtime[eax], dx

_ret:
    pop edx
    pop ecx
    pop edi
    pop esi
    pop eax
    ret
loadCommand endp




; carry flag set: one available space, jobptr points to it
; carry flag unset: no spaces available
spaceAvailable proc
    push eax
    push esi
    push ebx

    clc ; set default to false

    mov eax, jobptr ; store original location
    mov esi, jstatus
    jmp _loop
_incJob:
    call nextJob
    cmp ebx, eax
    je _ret
_loop:
    mov ebx, jobptr
    add ebx, esi
    cmp byte ptr [ebx], 0 ; testing if status is available
    jne _incJob ; if not, move on to next job
    stc ; if so, found available; set carry, return

_ret:
    pop ebx
    pop esi
    pop eax
    ret
spaceAvailable endp


END main