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
wordBuffer byte 8 dup(0)
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
priorBuffer byte 8 dup(0)
runtimeBuffer byte 8 dup(0)
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
cancelMsg byte "Cancelling command.",cr,lf,0
promptnameMsg byte "Enter a name for the job: ",0
promptPriorMsg byte "Enter a priority for the job (0-7): ",0
promptRuntMsg byte "Enter a runtime for the job (1-65536): ",0
promptBadDataMsg byte "Invalid data entered.",cr,lf,0
stackFullMsg byte "There is no room available for a new job.",cr,lf,0
runCommandMsg byte "Enter job to change to RUN mode: ",0
runCommandNotFound byte "Job not found.",cr,lf,0
runCommandSuccess byte "Job successfully changed to RUN mode.",cr,lf,0
runCommandAlrRun byte "Job is already in the RUN mode.",cr,lf,0
holdCommandMsg byte "Enter job to change to HOLD mode: ",0
holdCommandSuccess byte "Job successfully changed to HOLD mode.",cr,lf,0
holdCommandAlrHold byte "Job is already in the HOLD mode.",cr,lf,0
killCommandMsg byte "Enter job to kill: ",0
killCommandSuccess byte "Job killed successfully.",cr,lf,0
killCommandNotHold byte "Cannot kill job that is in RUN mode.",cr,lf,0
changeCommandMsg byte "Enter job to change priority of: ",0
changeCommandSuccess byte "Job priority successfully changed.",cr,lf,0
changeCommandAlr byte "Job already has this priority.",cr,lf,0
changeCommandBadPrior byte "Invalid priority.",cr,lf,0
changeCommandPriorMsg byte "Enter a new priority (0-7): ",0

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




; takes: name from nameBuffer
; desc: if job exists, move jobptr there; otherwise, do nothing
;       carry flag set: found
;       carry flag unset: not found
findJob proc
    push ebx
    push ecx
    push edi

    clc ; clear carry

    mov ebx, jobptr ; keep original job to check
    jmp _while
_incJob:
    call nextJob
    cmp jobptr, ebx
    je _ret ; if the current job is the original, job not found
_while:
    ; move offsets of current job name and job name to check
    ; to compare
    mov esi, jobptr
    add esi, jnameBuffer
    mov edi, offset nameBuffer

    ; if status is available, skip
    movzx ecx, byte ptr jstatus[esi]
    cmp ecx, 0
    je _incJob

    mov ecx, sizeof nameBuffer ; max number of characters to read
    cld
    repe cmpsb ; compare input with current job name
    jne _incJob ; if they are different, move on to next loop

    ; BUG: even when wordBuffer and nameBuffer have same contents, cmpsb fails

    stc ; if the names do match, job was found

_ret:
    pop edi
    pop ecx
    pop ebx
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
    movzx ecx, byte ptr jstatus[eax] ; get status of current job

    cmp ecx, 0 ; test if status is available
    je _incJob ; if so, go to next job

    call Crlf ; space for next job

    ; write name: move current name to nameBuffer, write
    mov esi, eax
    add esi, jnameBuffer
    mov edi, offset nameBuffer
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
    add edx, jstatus
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

    jmp _incJob ; go to next job
    
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
    push eax
    push ecx
    push edx
    push esi
    push edi

    ; get command to run
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jl _getName

_promptName:
    ; name was not provided; prompt
    mov edx, offset runCommandMsg
    call WriteString
    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString
    call skipSpace

_getName:
    call getWord
    cmp wordBuffer, 0
    je _cancel
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

_findJob:
    call findJob
    jnc _notFound
    mov eax, jobptr
    mov esi, jrun
    movzx ecx, byte ptr jstatus[eax]
    cmp ecx, esi
    jne _setRun
    mov edx, offset runCommandAlrRun
    call WriteString
    jmp _ret

_setRun:
    mov jstatus[eax], esi ; change status byte of record to run
    mov edx, offset runCommandSuccess
    call WriteString
    jmp _ret

_notFound:
    mov edx, offset runCommandNotFound
    call WriteString
    jmp _ret

_cancel:
    mov edx, offset cancelMsg
    call WriteString

_ret:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
runCommand endp




; takes: nameBuffer
; desc: changes a job from run to hold
holdCommand proc
    push eax
    push ecx
    push edx
    push esi
    push edi

    ; get command to run
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jl _getName

_promptName:
    ; name was not provided; prompt
    mov edx, offset holdCommandMsg
    call WriteString
    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString
    call skipSpace

_getName:
    call getWord
    cmp wordBuffer, 0
    je _cancel
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

_findJob:
    call findJob
    jnc _notFound
    mov eax, jobptr
    mov esi, jhold
    movzx ecx, byte ptr jstatus[eax]
    cmp ecx, esi
    jne _setHold
    mov edx, offset holdCommandAlrHold
    call WriteString
    jmp _ret

_setHold:
    mov jstatus[eax], esi ; change status byte of record to run
    mov edx, offset holdCommandSuccess
    call WriteString 
    jmp _ret

_notFound:
    mov edx, offset runCommandNotFound
    call WriteString
    jmp _ret

_cancel:
    mov edx, offset cancelMsg
    call WriteString

_ret:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
holdCommand endp




; takes: nameBuffer
; desc: removes a job if it is in hold mode
killCommand proc
    push eax
    push ecx
    push edx
    push esi
    push edi

    ; get job to kill
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jl _getName

_promptName:
    ; name was not provided; prompt
    mov edx, offset killCommandMsg
    call WriteString
    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString
    call skipSpace

_getName:
    call getWord
    cmp wordBuffer, 0
    je _cancel
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

_findName:
    call findJob
    jnc _notFound
    mov eax, jobptr
    mov esi, jhold
    mov cl, byte ptr jstatus[eax]
    cmp cl, jhold
    jne _notHold

    ; empty all data (0-13 byte offset)
    mov esi, 0
_clearRecord:
    cmp esi, 14
    jge _done
    mov byte ptr [eax], 0
    inc eax
    inc esi
    jmp _clearRecord
_done:
    ; print success
    mov edx, offset killCommandSuccess
    call WriteString
    jmp _ret

_notFound:
    mov edx, offset runCommandNotFound
    call WriteString
    jmp _ret

_notHold:
    mov edx, offset killCommandNotHold
    call WriteString
    jmp _ret

_cancel:
    mov edx, offset cancelMsg
    call WriteString

_ret:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
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
    push eax
    push ecx
    push edx
    push esi
    push edi

    mov ebx, 0 ; keep track of how many inputs given

    ; test name
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptName
    inc ebx
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

    ; test priority
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptName
    inc ebx
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset priorBuffer
    mov ecx, sizeof priorBuffer
    rep movsb
    jmp _promptName

_invalidName:
    mov edx, offset runCommandNotFound
    call WriteString
    jmp _getName
_promptName:
    cmp ebx, 1
    jge _validateName
_getName:
    mov edx, offset changeCommandMsg
    call WriteString

    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    call skipSpace
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

_validateName: ; must exist
    cmp nameBuffer, 0
    je _cancel
    call findJob
    jc _promptPriority
    jmp _invalidName

_invalidPriority:
    mov edx, offset changeCommandBadPrior
    call WriteString
    jmp _getPriority
_promptPriority:
    cmp ebx, 2
    jge _validatePriority
_getPriority:
    mov edx, offset changeCommandPriorMsg
    call WriteString

    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    call skipSpace
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset priorBuffer
    mov ecx, sizeof priorBuffer
    rep movsb

_validatePriority:
    cmp priorBuffer, 0
    je _cancel
    mov edx, offset priorBuffer
    mov ecx, sizeof priorBuffer
    call ParseInteger32
    jc _getPriority
    cmp eax, 0
    jl _getPriority
    cmp eax, 7
    jg _getPriority

_change:
    mov ecx, eax ; priority to write (cl for one byte)
    mov eax, jobptr ; job to write to

    cmp cl, byte ptr jpriority[eax]
    je _alrPrior

    mov byte ptr jpriority[eax], cl
    mov edx, offset changeCommandSuccess
    call WriteString
    jmp _ret

_alrPrior:
    mov edx, offset changeCommandAlr
    call WriteString
    jmp _ret

_cancel:
    mov edx, offset cancelMsg
    call WriteString

_ret:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
changeCommand endp




; takes: name, priority, runtime
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
    jc _foundSpace
    mov edx, offset stackFullMsg
    call WriteString
    jmp _cancel

_foundSpace:
    mov eax, jobptr
    push eax ; store available slot (jobptr messed up by name validation)

    ; for each input: see if it was provided, then start validation

_testName:
    mov ebx, 0 ; keep track of number of provided inputs
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptName
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb
    inc ebx
    jmp _testPriority

_testPriority:
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptName
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset priorBuffer
    mov ecx, sizeof priorBuffer
    rep movsb
    inc ebx
    jmp _testRuntime

_testRuntime:
    call skipSpace
    mov eax, index
    cmp eax, sizeof inputBuffer
    jge _promptName
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset runtimeBuffer
    mov ecx, sizeof runtimeBuffer
    rep movsb
    inc ebx
    jmp _validateName

_invalidName:
    mov edx, offset promptBadDataMsg
    call WriteString
    jmp _getName
_promptName: ; prompt for and read name
    cmp ebx, 1
    jge _validateName
_getName:
    call Crlf
    mov edx, offset promptNameMsg
    call WriteString

    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    call skipSpace
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset nameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

_validateName: ; if Name is empty, cancel; else if invalid, reprompt; else, continue
    cmp nameBuffer, 0
    je _cancel

    ; validate: Name is unique
    call findJob
    jc _invalidName ; job with same Name found; try again
    jmp _promptPriority

_invalidPriority:
    mov edx, offset promptBadDataMsg
    call WriteString
    jmp _getPriority
_promptPriority:
    cmp ebx, 2
    jge _validatePriority
_getPriority:
    mov edx, offset promptPriorMsg
    call WriteString

    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    call skipSpace
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset priorBuffer
    mov ecx, sizeof priorBuffer
    rep movsb

_validatePriority: ; first byte 0-7, second byte null
    cmp priorBuffer, 0
    je _cancel

    mov ah, priorBuffer[1]
    cmp ah, 0
    jne _invalidPriority
    mov al, priorBuffer
    cmp al, '0'
    jl _invalidPriority
    cmp al, '7'
    jg _invalidPriority

    sub al, '0'
    mov priority, al
    jmp _promptRuntime

_invalidRuntime:
    mov edx, offset promptBadDataMsg
    call WriteString
    jmp _getRuntime
_promptRuntime:
    cmp ebx, 3
    jge _validateRuntime
_getRuntime:
    mov edx, offset promptRuntMsg
    call WriteString

    call resetInput
    mov edx, offset inputBuffer
    mov ecx, sizeof inputBuffer
    call ReadString

    call skipSpace
    call getWord
    mov esi, offset wordBuffer
    mov edi, offset runtimeBuffer
    mov ecx, sizeof runtimeBuffer
    rep movsb

_validateRuntime: ; parse integer succeeds, value is not 0, value is less than 65536
    cmp runtimeBuffer, 0
    je _cancel

    mov edx, offset runtimeBuffer
    mov ecx, sizeof runtimeBuffer
    call ParseInteger32
    jc _promptRuntime
    cmp eax, 0
    jle _invalidRuntime
    cmp eax, 65536
    jge _invalidRuntime
    mov runtime, ax
    jmp _createRecord ; got all data, make record
    

_cancel: ; print message, clear npriority, runtime, Name
    mov edx, offset cancelMsg
    call WriteString
    mov priority, 0
    mov runtime, 0
    mov eax, 0
    jmp _ret

_createRecord: ; jobptr already pointing at available slot

    ; retrieve available record location
    ; (was stored via push at beginning of proc)
    pop eax

    ; set name
    mov esi, offset nameBuffer
    mov edi, eax
    add edi, jnameBuffer
    mov ecx, sizeof nameBuffer
    rep movsb

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




; carry flag set: at least one available space, jobptr points to it
; carry flag unset: no spaces available
spaceAvailable proc
    push eax
    push esi
    push ebx

    clc ; set default to false

    mov ebx, jobptr ; store original location
    jmp _loop
_incJob:
    call nextJob
    cmp jobptr, ebx
    je _ret
_loop:
    mov eax, jobptr
    cmp byte ptr jstatus[eax], 0 ; testing if status is available
    jne _incJob ; if not, move on to next job
    stc ; if so, found available; set carry, return

_ret:
    pop ebx
    pop esi
    pop eax
    ret
spaceAvailable endp


END main