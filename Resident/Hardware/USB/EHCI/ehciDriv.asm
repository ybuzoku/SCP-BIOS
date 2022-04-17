;--------------------USB Driver and data area--------------------
;Note, this needs to be updated.
;All SCSI, MSD and HUB related functions are grouped in this file
;SCSI functions need to be moved into their own folder
USB:
;------------------------EHCI functions--------------------------
;eActiveCtrlr must be set with the offset of the controller
; IFF the controller is about to enter a state in which it could
; fire an interrupt. These functions must safeguard against it by
; checking that this byte is -1 first and then setting the byte
; with the selected controller index, ending by resetting this 
; byte to -1 (even on fail). 
;
;Certain functions may be called to act upon the CURRENT ACTIVE
; controller, these functions dont need these safeguards, though
; they may need to ensure that there is a valid controller number 
; in the eActiveCtrlr byte.
;----------------------------------------------------------------
.ehciCriticalErrorWrapper:
;Currently just jumps to the installed address.
;Conditional error calls MUST call this wrapper to allow for
; host operating systems to install their own USB error handlers
; and have the system continue working.
    jmp qword [eHCErrorHandler]
.ehciCriticalErrorHandler:
;Currently just halts the system
    mov ebx, 07h
    call cls
    mov rbp, .ecehmsg
    mov ax, 1304h
    int 30h
    mov al, 0FFh
    out pic1data, al
    out pic2data, al
    cli
    hlt
    jmp $ - 2
.ecehmsg db "EHCI Check 1", 0
.setupEHCIcontroller:
;Resets, initialises variables to default
;Input: al = Controller to setup (0 based)
;Output: CF=CY - Controller failed to reset
;        CF=NC - No problems
; al = Controller that was reset
    push rcx
    push rbx
    push rbp
    call .ehciResetCtrlr    ;Reset the controller
    jc .secexit
    xor bx, bx ;No schedule, no interrupts
    xor ecx, ecx
    mov rbp, ehciAschedule
    call .ehciInitCtrlrRegs    ;Initialise controller registers
    clc
.secexit:
    pop rbp
    pop rbx
    pop rcx
    ret

.ehciResetControllerPort:
;A function that enacts an EHCI reset on a port.
;Works ONLY on the current active controller.
;Input:
; al = Port number [0,N-1] (Checked against ctrlr struc params entry)
;Returns:
; CF set if failed, clear if success
; ax=Error code, 0h=No active controller
;             1h=Invalid port number
;             2h=No device on port
;             3h=Port not enabled (Low speed device)
;             4h=Device not entering reset
;             5h=Device not clearing reset
;             6h=Port not enabled (Full speed device)
; rax destroyed
    push rbx
    push rcx
    push rdx
    push rbp

    xor bp, bp
    movzx edx, al    ;Save port number into dl (edx)
    movzx ebx, byte [eActiveCtrlr]
    cmp bl, -1
    je .ercperr    ;Error, No active controller (ec=0)
    inc bp        ;Inc error counter
    mov ebx, dword [eControllerList + 4 + 8*rbx]    ;get mmiobase into ebx
    mov eax, dword [ebx+ehcistrucparams]    ;Get # of ports in al
    and al, 7Fh    ;al contains port number, clear upper bit
    dec al        ;Zero based port number
    movzx eax, al
    cmp dl, al    ;dl contains called port number
    ja .ercperr    ;Error, invalid port number (ec=1)
    inc bp        ;Inc error counter


    movzx eax, byte [ebx]    ;Byte access for caplength!
    add ebx, eax    ;eax now points to opregs    
    mov cx, 10
.erclp0:    ;Remember ebx=opregs, edx=port number    
    or dword [ebx+4*edx+ehciportsc], 1000h ;Set power bit

    push rcx
    mov ecx, 10
    mov ah, 86h
    int 35h        ;Wait for 10 ms
    pop rcx

.erclp1:
    dec cx
    jz .ercperr ;Error, No device on port (ec=2)
    test dword [ebx+4*edx+ehciportsc], 1h    ;Test device on port
    jz .erclp0
    inc bp        ;Inc error counter

    mov eax, dword [ebx+4*edx+ehciportsc]
    and ax, 0C00h
    sub ax, 400h
    dec ax
    jz .ercperr    ;Error, Low speed device (ec=3)
    inc bp        ;Inc error counter

    mov cx, 10
.erclp2:
    dec cx
    jz .ercperr ;Error, Device not entering reset (ec=4)
    or dword [ebx+4*edx+ehciportsc], 100h    ;Set bit 8, port reset bit
    
    push rcx
    mov ecx, 10
    mov ah, 86h
    int 35h        ;Wait for 10 ms
    pop rcx

    test dword [ebx+4*edx+ehciportsc], 100h    ;Check if entered reset
    jz .erclp2

    inc bp        ;Inc error counter
    mov cx, 10
    and dword [ebx+4*edx+ehciportsc], 0FFFFFEFFh    ;Clear reset bit
.erclp3:
    dec ecx
    jz .ercperr ;Error, Device not leaving reset (ec=5)

    push rcx
    mov ecx, 10
    mov ah, 86h
    int 35h        ;Wait for 10 ms
    pop rcx

    test dword [ebx+4*edx+ehciportsc], 100h
    jnz .erclp3
    inc bp        ;Inc error counter

    test dword [ebx+4*edx+ehciportsc], 4h    ;Bit 2 is the port enabled bit
    jz .ercperr    ;Error, Full speed device (ec=6)
;We get here IFF device on port is high speed
    
;High Speed Device successfully reset. Now print message or whatever
    xor rax, rax
    clc
.ercpexit:
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    ret
.ercperr:
    mov ax, bp    ;Get error code in ax
    stc
    jmp short .ercpexit

.ehciResetCtrlr:
;A function that resets a controller. 
;No other controllers may be running during a ctrlr reset
;Input:
; al = Offset into the ehci controller table
;Returns:
; CF=CY if failed, CF=NC if reset
;All registers preserved
    push rax
    push rcx
    ;cmp byte [eActiveCtrlr], -1
    ;jne .erc2    ;A controller already active, exit fail (ec=0)
    ;mov byte [eActiveCtrlr], al    ;For added security (may be removed later)
    call .ehciGetOpBase
    mov dword [eax + ehciintr], 0h    ;No interrupts
    mov dword [eax + ehcists], 3Fh    ;Clear any outstanding interrupts
    ;Set the reset bit, check to see if run bit has cleared first!
    xor ecx, ecx
.erc0:
    and dword [eax + ehcicmd], 0FFFFFFFEh    ;Force stop the controller
    dec ecx
    jz .erc2    ;Controller not resetting, exit fail  (ec=1)

    test dword [eax + ehcists], 1000h    ;Test if bit 12 has been set
    jz .erc0
    or dword [eax + ehcicmd], 02h ;Set bit 1, reset HC
    ;Spin and wait to give device time to respond and reset.
    xor cx, cx
.erc1:
    dec cx        ;Wait for reset to happen
    jz .erc2    ;Not resetting, exit fail (ec=2)

    push rax
    push rcx
    mov ah, 86h
    mov ecx, 5    ;5ms wait
    int 35h
    pop rcx
    pop rax

    test dword [eax + ehcicmd], 2h    ;Whilst this bit is set, keep looping
    jnz .erc1
    xor eax, eax
    clc
.ercexit:
    mov byte [eActiveCtrlr], -1    ;No controllers active
    pop rcx
    pop rax
    ret
.erc2:
    stc
    jmp short .ercexit

.ehciRunCtrlr:
;A function that runs a controller to process set schedules
;Input:
;   al = Offset into the controller table
;Returns:
; CF = CY if failed, CF = NC if success
    push rax
    push rcx
    call .ehciGetOpBase
    test dword [eax + ehcists], 1000h    ;bit 12 must be set to write 1 in cmd
    jz .esc2
    or dword [eax + ehcicmd], 1h ;Set bit 0 to run
    xor ecx, ecx
.esc0:
    dec cx
    jz .esc2
    test dword [eax + ehcists], 1000h    ;bit 12 must be clear
    jnz .esc0
    xor eax, eax
    clc
.esc1:
    pop rcx
    pop rax
    ret
.esc2:    ;Bad exit
    stc
    jmp short .esc1

.ehciStopCtrlr:
;A function that stops current active controller from running
;Input:
; al=Controller to stop processing
;Returns:
; CF set if failed to stop, clear if success
    push rax
    push rcx
    movzx rax, byte [eActiveCtrlr]
    call .ehciGetOpBase
    and dword [eax + ehcicmd], 0FFFFFFFEh    ;Stop controller
    xor ecx, ecx
.estc0:
    dec cx
    jz .estc1
    test dword [eax + ehcists], 1000h    ;test hchalted until set
    jz .estc0
    clc
.estcexit:
    pop rcx
    pop rax
    ret
.estc1:
    stc
    jmp short .estcexit
.ehciAdjustAsyncSchedCtrlr:
;This function checks the currently online controller and compares it to
; the value provided in al. 
;If they are equal, do nothing.
;If not, turn off controller, update active ctrlr byte and indicate a new bus 
; was activated.
;If no controller active, update active ctrlr byte and indicate which bus 
; has been activated.
;
; Input: al = Controller to activate, preserved.
; Output: CF=CY: Error, turn off all controllers
;         CF=NC: All ok, proceed
    cmp al, byte [eActiveCtrlr]
    je .eacOkExit
    cmp byte [eActiveCtrlr], -1
    je .eacStart
    call .ehciStopAsyncSchedule ;Stop currently transacting controller
    jc .eacBad
.eacStart:
    mov byte [eActiveCtrlr], al ;Set new active controller
    mov byte [eNewBus], 1   ;Set flag that a new bus has been selected
.eacOkExit:
    clc
    ret
.eacBad:
    stc
    ret
.ehciInitCtrlrRegs:
;A function that initialises a given controllers registers as needed.
;Controller is left ready to process data start schedules
;MUST NOT BE CALLED ON A RUNNING CONTROLLER
;Input:
; al = Offset into the ehci controller table
; bl = ehciintr mask
; bh = Schedule mask, bits [7:2] reserved
;        00b = No schedule, 01b=Periodic, 10b=Async, 11b=Both
; ecx = Frame Index
; rbp = Schedule address
;Returns:
; Nothing
    push rax
    push rbx
    push rcx
    push rbx
    call .ehciGetOpBase    ;Get opbase 
    movzx ebx, bx
    mov dword [eax + ehciintr], 0
    mov dword [eax + ehcifrindex], ecx
    mov dword [eax + ehciasyncaddr], ebp
    ror rbp, 20h    ;Get upper dword low
    mov dword [eax + ehcictrlseg], ebp
    pop rbx    ;Get back bh
    xor bl, bl    ;Zero lo byte
    shr bx, 4    ;Shift to hi nybble of lo byte
    and dword [eax + ehcicmd], 0CFh    ;Clear schedule enable bits
    or ebx, dword [eax + ehcicmd]    ;Add ehcicmd to schedule mask
    and ebx, 0FF00FFF3h    ;Clear the Int Threshold and Frame List bits
    or ebx, 000080000h ;Set 8 microframes (1 ms) per interrupt
    mov dword [eax + ehcicmd], ebx    ;Write back
    mov dword [eax + ehciconfigflag], 1h    ;Route all ports to EHCI ctrlr
    pop rcx
    pop rbx
    pop rax
    ret
.ehciCtrlrGetNumberOfPorts:
;Gets the number of ports on a Host Controller.
;Ports are zero addressed so ports numbers are 0 to NUMBER_OF_PORTS - 1
;Input:  al = Offset into the controller table
;Output: rax = Number of ports on controller.
;Warning, input NOT bounds checked.
    movzx eax, al
    mov eax, dword [eControllerList + 4 + 8*rax]
    mov eax, dword [eax + ehcistrucparams]
    and eax, 7Fh    ;Clear upper bits
    ret
.ehciGetNewQHeadAddr:
;Picks which QHead position to put the new Qhead into
;Input: Nothing
;Output: rdi = Position in RAM for QHead
;        r8  = Link to next QHead
;           r8 NEEDS to be or'ed with 2 when used as a QHead pointer
    mov r8, ehciQHead1
    mov rdi, ehciQHead0
    cmp rdi, qword [eCurrAsyncHead]   ;Compare head to start of buffer
    jne .egnqaexit
    xchg rdi, r8
.egnqaexit:
    ret

.ehciToggleTransactingQHead:
;Toggles the transacting Qhead position
;This is called AFTER the old Qhead has been delinked from the AsynchSchedule
    cmp qword [eCurrAsyncHead], ehciQHead0
    jne .ettqh0
    mov qword [eCurrAsyncHead], ehciQHead1
    ret
.ettqh0:
    mov qword [eCurrAsyncHead], ehciQHead0
    ret

.ehciDelinkOldQHead:
;Delinks the old Qhead from the list async list
    push rdi
    push r8
    call .ehciGetNewQHeadAddr
    mov r8, rdi
    or r8, 2
    mov dword [rdi], r8d    ;Point the new qhead to itself
    or dword [rdi + 4], 8000h   ;Toggle H-bit in the current transacting QHead
    pop r8
    pop rdi
    ret

.ehciLinkNewQHead:
;Links the inserted qhead into the async list
    push rdi
    push r8
    call .ehciGetNewQHeadAddr   ;Get bus addresses
    cmp byte [eNewBus], 1
    je .elnqadjusted   ;If equal, exit
    or rdi, 2
    mov dword [r8], edi
.elnqhexit:
    clc
    pop r8
    pop rdi
    ret
;Only here if a new bus was Adjusted
.elnqadjusted:
;The first qhead in a new queue must always point to itself and be
; the head of the reclaim list.
;The same address is provided to the function which writes the qhead
; and in the above function call into rdi, thus allowing us to point
; the new qhead to itself and set the H-bit on, in ALL instances 
    mov r8, rdi
    or r8, 2
    mov dword [rdi], r8d    ;Point the QHead to itself
    or dword [rdi + 4], 8000h   ;Set H bit on
    push rax
    mov al, byte [eActiveCtrlr]
    call .ehciGetOpBase
    mov dword [eax + ehciasyncaddr], edi ;Set the address in the ctrlr register
    pop rax
    call .ehciStartAsyncSchedule    ;Start schedule
    jc .elnqhbad
    dec byte [eNewBus]  ;Reset back to zero if successfully onlined
    jmp short .elnqhexit
.elnqhbad:  ;If Async fails to start, exit
    pop r8
    pop rdi
    stc
    ret

.ehciSetNoData:
;A function that does a set request with no data phase to the device
;at address al.
;Input:
; al = Address number (7 bit value)
; rbx = Setup packet
; cx = Max Packet Length 
;Returns:
; CF = NC if no Host error, CF = CY if Host error
; Caller MUST check the schedule to ensure that the transfer was successful,
; and without transaction errors as these dont constitute Host system errors.
;
; All registers except for CF preserved
    push rdi
    push r8
    push r9
    push r10
    push r11
    push rcx
    push rdx
    cld    ;Set right direction for string ops
    
    ;Write setup packet
    mov qword [ehciDataOut], rbx
    call .ehciGetNewQHeadAddr
    or r8, 2    ;Process qH TDs
    mov r9d, 80006000h  ;Bit 15 not set here!!!!! Important
    movzx ecx, cx
    shl ecx, 8*2
    or r9d, ecx
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    mov r11, ehciTDSpace  ;First TD is the head of the buffer

    call .ehciWriteQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    lea r8, qword [rdi + ehciSizeOfTD]    ;Point to next TD
    mov r9, 1
    mov r10d, 00080E80h ;Active TD, SETUP EP, Error ctr = 3, 8 byte transfer
    mov r11, ehciDataOut ; Data out buffer

    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD     ;Go to next TD space
    mov r8, 1
    mov r9, r8
    mov r10d, 80008D80h        ;Status stage opposite direction of last transfer
    mov r11, msdCSW         ;Nothing should be returned but use this point

    call .ehciWriteQHeadTD
    mov cl, 011b   ;Lock out internal buffer
    jmp .egddproceed

.ehciGetRequest:
;A function which does a standard get request from a device at
;address al.
;Input:
; al = Address number (7 bit value)
; rbx = Setup packet
; ecx = Max Packet Length 
;Returns:
; CF = NC if no Host error, CF = CY if Host error
; Caller MUST check the schedule to ensure that the transfer was successful,
; and without transaction errors as these dont constitute Host system errors.
;
; All registers except for CF preserved
    push rdi
    push r8
    push r9
    push r10
    push r11
    push rcx
    push rdx
    cld    ;Ensure right direction

    ;Write setup packet
    mov qword [ehciDataOut], rbx
    call .ehciGetNewQHeadAddr
    or r8, 2    ;Process qH TDs
    mov r9d, 80006000h  ;Bit 15 not set here!!!!! Important
    movzx ecx, cx
    shl ecx, 8*2
    or r9d, ecx
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    mov r11, ehciTDSpace  ;First TD is the head of the buffer
    
    call .ehciWriteQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    lea r8, qword [rdi + ehciSizeOfTD]    ;Point to next TD
    mov r9, 1
    mov r10d, 00080E80h ;Active TD, SETUP EP, Error ctr = 3, 8 byte transfer
    mov r11, ehciDataOut ; Data out buffer

    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD    ;Go to next TD space
    lea r8, qword [rdi + ehciSizeOfTD]
    mov r9, r8    ;Alt pointer also points to next TD since this is expected!
    mov r10d, 80400D80h ;Active TD, IN EP, Error ctr = 3, max 64 byte transfer
    mov r11, ehciDataIn

    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD     ;Go to next TD space
    mov r8, 1
    mov r9, r8
    mov r10d, 80008C80h
    mov r11, msdCSW

    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer, ignore one interrupt
;Now set controller to process the schedule
.egddproceed:
    call .ehciProcessCommand
;The carry status of the previous function will propagate
.egddexit:
    pop rdx
    pop rcx
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    ret

.ehciStartAsyncSchedule:
    push rax
    push rcx

    mov al, byte [eActiveCtrlr]    ;Deals with current active controller
    call .ehciGetOpBase            ;Return opregs ADDRESS in eax
    or dword [eax + ehcicmd], 20h    ;Process asyncschedule
    xor ecx, ecx
.esas0:
    dec ecx
    jz .esasfail
    test dword [eax + ehcists], 08000h ;Asyncschedule bit should be on
    jz .esas0

    clc
.esasok:
    pop rcx
    pop rax
    ret
.esasfail:
    stc
    jmp short .esasok

.ehciStopAsyncSchedule:
;This function stops the processing of the current active Async Schedule
;Output: CF=CY: Failed to stop Async Schedule CF=NC: Stopped Async Schedule
    push rax
    push rcx
    mov al, byte [eActiveCtrlr]    ;Deals with current active controller
    call .ehciGetOpBase            ;Return opregs ADDRESS in eax
    xor cx, cx
    and dword [eax + ehcicmd], 0FFFFFFDFh ;Stop processing async
.espc0:
    dec cx
    jz .espcfail
    test dword [eax + ehcists], 08000h
    jnz .espc0

    clc
    pop rcx
    pop rax
    ret
.espcfail:
    stc
    pop rcx
    pop rax
    ret

.ehciProcessCommand:
; Allows EHCI async schedule to process commands.
; Preserves all registers except CF
; Returns: CF=CY if error detected 
;          CF=NC if no error detected
;
; If returned with CF=CY, caller must read the msdStatus byte
    push rax
    push rbx
    push rcx
    push rdi

    mov byte [eAsyncMutex], cl  ;Set mutex
    mov al, byte [eActiveCtrlr]    ;Deals with current active controller
    call .ehciGetOpBase            ;Return opregs ADDRESS in eax
    mov rbx, rax
    mov di, 5000
    call .ehciLinkNewQHead
    jc .epcfailedstart
.epc1:
    test dword [ebx + ehcists], 13h
    jnz .epc2     ;If bits we care about are set, call IRQ proceedure
    pause       
    dec di
    jz .epcfailtimeout
    mov ah, 86h
    mov ecx, 1    ;Max 5s in 1ms chunks
    int 35h
    jmp short .epc1
.epc2:
    mov eax, ebx    ;Get opreg base into eax before we proceed into IRQ handler
    call ehci_IRQ.nonIRQep ;Manually call IRQ
    test byte [eActiveInt], 10h ;HC error bit
    jnz .epcHostError   ;HC error detected
    test byte [eAsyncMutex], 0
    jnz .epc1    ;If the mutex isnt cleared, go back to sts check
    call .ehciDelinkOldQHead   ;Perform delink
    call .ehciToggleTransactingQHead    ;Toggle the active Qheads
;Now set doorbell
    or dword [ebx + ehcicmd], 40h   ;Ring Doorbell
    mov di, 5000
.epc3:
    test dword [ebx + ehcists], 20h ;Test for doorbell set high
    jnz .epc4
    pause
    dec di
    jz .epcfaildelinked
    mov ah, 86h
    mov ecx, 1    ;Max 5s in 1ms chunks
    int 35h
    jmp short .epc3
.epc4:
;Clear once more to clear the doorbell bit
    mov ecx, dword [ebx + ehcists]  
    or dword  [ebx + ehcists], ecx    ;WC high bits
;Check if it was a stall
    test byte [eActiveInt], 2h  ;Check USBError bit
    jnz .epcexit
    mov byte [msdStatus], 00h   ;No error... yet
    clc
.epcexit:
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret 
.epcStall:
    mov byte [msdStatus], 21h   ;General Controller Failure - Stall
    stc
    jmp short .epcexit
.epcfail:
    call .ehciDelinkOldQHead   ;Perform delink
    call .ehciToggleTransactingQHead    ;Toggle the active Qheads
.epcfailedstart: ;No need to delink as that data structure is considered garbage
.epcfaildelinked:
    mov ecx, dword [ebx + ehcists]
    or dword  [ebx + ehcists], ecx    ;WC selected bits
.epcHostError:  ;Host error detected in interrupt register
    mov byte [msdStatus], 20h   ;General Controller Error
    stc
    jmp short .epcexit
.epcfailtimeout:
;Called in the event that the schedule fails to process the QHead.
;Emergency stops the currently transacting schedule
    call .ehciDelinkOldQHead   ;Perform delink
    call .ehciToggleTransactingQHead    ;Toggle the active Qheads
    mov ecx, dword [ebx + ehcists]
    or dword  [ebx + ehcists], ecx    ;WC selected bits
    mov byte [msdStatus], 80h   ;Timeout Error
    stc
    jmp short .epcexit  ;Delink

.ehciEnumerateRootPort:
;This function discovers whether a device is of a valid type
;or not.
;Input: dl=port number - 1 (0 based), dh = bus [0-3]
;       r10b = Host hub address (if the device is on a hub, 0 else)
;Output:     CF=CY if error, CF=NC if bus transaction occured 
;           ZF=ZR if passed enum: ah = bus number, al = Address number
;            ZF=NZ if the device failed enumeration: ax=error code
;                ah = Enum stage, al = Sub function stage
    push rbx
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11

.eebinit:
    xor bp, bp    ;Use as error counter    (Stage 0)
    mov al, dl
    call .ehciResetControllerPort    ;Reset port
    jc .ehciedbadnotimeout
;Power on debounce!
    mov ecx, debounceperiod    ;debounce period
    mov ah, 86h
    int 35h

    inc bp    ;Increment Error Counter    (Stage 1)
.eeb0:
    mov rbx, 00008000001000680h    ;Pass get minimal device descriptor
    mov qword [ehciDataOut], rbx
    mov cx, 40h    ;Pass default endpoint size
    xor al, al
    call .ehciGetRequest
    jc .ehciedexit  ;Fast exit with carry set
.eeb1:
    inc bp    ;Increment Error Counter    (Stage 2)
    xor al, al    ;Increment Error subcounter    (Substage 0)
    mov rbx, ehciDataIn
    cmp byte [rbx + 1], 01h    ;Verify this is a valid dev descriptor
    jne .ehciedbad
    inc al    ;Increment Error subcounter    (Substage 1)
    cmp word [rbx + 2], 0200h    ;Verify this is a USB 2.0 device or above
    jb .ehciedbad
    inc al    ;Increment Error subcounter    (Substage 2)
    cmp byte [rbx + 4], 0    ;Check interfaces
    je .eeb2
    cmp byte [rbx + 4], 08h    ;MSD?
    je .eeb2
    cmp byte [rbx + 4], 09h    ;Hub?
    jne .ehciedbad
.eeb2:
    inc bp    ;Increment Error Counter    (Stage 3)
    movzx r8d, byte [rbx + 7]    ;Byte 7 is MaxPacketSize0, save in r8b
    mov al, dl

    call .ehciResetControllerPort    ;Reset port again
    jc .ehciedbad
    mov r11, 10
.ehciEnumCommonEp:
    inc bp    ;Increment Error Counter    (Stage 4)
    mov al, dh    ;Put bus number into al

    call .ehciGiveValidAddress    ;Get a valid address for device
    cmp al, 80h    
    jae .ehciedbad    ;Invalid address

    inc bp    ;Increment Error Counter    (Stage 5)
    mov r9b, al        ;Save the new device address number in r9b
.eeb3:
    mov ebx, 0500h    ;Set address function
    movzx ecx, r9b    ;move new address into ecx
    shl ecx, 8*2
    or ebx, ecx    ;Add address number to ebx
    mov cx, r8w    ;Move endpoint size into cx
    xor al, al    ;Device still talks on address 0, ax not preserved
    call .ehciSetNoData    ;Set address
    jc .ehciedexit  ;Fast exit with carry set
.eeb4:
    mov ah, 86h
    mov rcx, r11
    int 35h

    inc bp    ;Increment Error Counter    (Stage 6)
.eeb5:
    mov rbx, 00012000001000680h    ;Now get full device descriptor
    mov al, r9b    ;Get address
    mov cx, r8w
    call .ehciGetRequest    ;Get full device descriptor and discard
    jc .ehciedexit  ;Fast exit with carry set
    inc bp    ;Increment Error Counter    (Stage 7/0Bh)
.eeb6:
    mov rbx, 00000000002000680h ;Get config descriptor
    mov ecx, r8d    ;Adjust the packet data with bMaxPacketSize0
    shl rcx, 8*6    ;cx contains bMaxPacketSize0
    or rbx, rcx
    mov al, r9b    ;Get address
    mov cx, r8w    ;Move endpoint size into cx
    call .ehciGetRequest
    jc .ehciedexit  ;Fast exit with carry set
.eeb7:
    inc bp    ;Increment Error Counter    (Stage 8/0Ch)
;Find a valid interface in this config
    call .ehciFindValidInterface
    jc .ehciedbad    ;Dont set config, exit bad
;If success, ah has device type (0=msd, 1=hub), al = Interface to use
;rbx points to interface descriptor
    inc bp    ;Increment Error Counter    (Stage 9/0Dh)
    call .ehciAddDeviceToTables
    jc .ehciedbad    ;Failed to be added to internal tables
    inc byte [usbDevices]   ;Device added successfully, inc byte
;Set configuration 1 (wie OG Windows, consider upgrading soon)
    inc bp    ;Increment Error Counter    (Stage 0Ah/0Ch)
.eeb8:
    mov rbx, 00000000000010900h    ;Set configuration 1 (function 09h)
    mov al, r9b    ;Get address
    mov cx, r8w    ;Move endpoint size into cx
    call .ehciSetNoData
    jc .ehciedexit  ;Fast exit with carry set
.eeb9:
    inc bp    ;Increment Error Counter    (Stage 0Bh/0Dh)
.eeb10:
    mov rbx, 0001000000000880h  ;Get device config (sanity check)
    movzx ecx, r8w              ;bMaxPacketSize0
    mov al, r9b                 ;Get device address
    call .ehciGetRequest
    jc .ehciedexit  ;Fast exit with carry set
.eeb11:
    inc bp    ;Increment Error Counter    (Stage 0Ch/0Eh)
    cmp byte [ehciDataIn], 01
    jne .ehcibadremtables
;Device is now configured and ready to go to set/reset
    mov ah, dh  ;Move bus number
    mov al, r9b ;Move address number
    xor edx, edx  ;This will always set the zero flag
.ehciedexit:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    ret
.ehciedbad:
.ehciedbadnoport:
    push rax
    mov ah, 86h
    mov ecx, 500    ;500 ms wait between failed attempts
    int 35h
    pop rax
.ehciedbadnotimeout:
    mov ah, al    ;Save subproc error code
    xor al, al    ;Zero byte
    or ax, bp    ;Add proc error stage code into al
    xchg ah, al
    xor bp, bp
    inc bp      ;This will always clear the Zero flag
    clc         ;This will force clear the Carry flag
    jmp short .ehciedexit
.ehcibadremtables:
    mov al, r9b ;Get address low
    mov ah, dh  
    call .ehciRemoveDevFromTables
    jmp short .ehciedbadnotimeout

.ehciAddDeviceToTables:
;This function adds a valid device to the internal tables.
;Interrupts are off for this to avoid dead entries
;Input: ah = device type (0=msd, 1=hub)
;       al = Interface Value to use (USB bInterfaceNumber)
;       rbx = Ptr to valid Interface descriptor
;       r8b = MaxPacketSize0
;       r9b = Device Address
;       dh = Bus number
;       dl = Physical Port number - 1
;       r10b = Host hub address
    push r11
    push rbp    ;Error counter
    push rdi
    push rbx
    push rdx
    pushfq
    inc dl      ;Add one to the Physical port number (kludge for root hub enum)
    xor bp, bp  ;Zero error counter (Stage 0)
    mov ecx, usbMaxDevices
    cmp byte [usbDevices], cl   ;Max number of devices, check
    je .eadttbad        ;If max, fail
    inc bp      ;Increment error counter (Stage 1)
    mov rdi, usbDevTbl
    mov cl, usbDevTblE  ;Within the length of the table
;Write Common table first
.eadtt0:
    or byte [rdi], 0   ;Check if there exists a free entry
    jz .eadtt1
    add rdi, usbDevTblEntrySize ;Go to next entry
    dec cl
    jz .eadttbad
    jmp short .eadtt0
.eadtt1:
    inc bp      ;Increment error counter (Stage 2)
    add ah, 08h ;hub is 09h
;Add device here, rdi points to entry
    mov byte [rdi], r9b
    mov byte [rdi + 1], dh
    mov byte [rdi + 2], ah
;Entry written
    inc bp      ;Increment error counter (Stage 3)
;Individual Device table writing
    cmp ah, 08h
    je .eadttmsd
    cmp ah, 09h
    je .eadtthub
    jmp .eadttbad
.eadttmsd:
    mov rdi, msdDevTbl
    mov cl, msdDevTblE  ;Max entries possible
    inc bp      ;Increment error counter (Stage 4)
.eadttmsd0:
    or byte [rdi], 0
    jz .eadttmsd1
    add rdi, msdDevTblEntrySize
    dec cl
    jz .eadttbad
    jmp short .eadttmsd0
.eadttmsd1:
;rdi points to correct offset into table
;rbx points to interface
    mov cl, byte [rbx + 4]   ;Get number of endpoints to check
    mov ch, cl
    inc bp      ;Increment error counter (Stage 5)
    mov r11, rbx    ;Save Interface Pointer in r11
    add rbx, 9  ;Go to first IF
.eadttmsd11:
    push rax
    mov ax, word [rbx + 2]
    shr ax, 4   ;Remove low 4 bits
    cmp ax, 28h     ;Bulk/In bits
    pop rax         ;Doesnt ruin flags
    je .eadttmsd2   ;Not zero only if valid
    add rbx, 7   ;Go to next endpoint
    dec cl
    jz .eadttbad
    jmp short .eadttmsd11
.eadttmsd2:
    mov byte [rdi], r9b      ;Device Address
    mov byte [rdi + 1], dh   ;Root hub/bus
    mov byte [rdi + 2], r10b ;Address of parent device if not root
    mov byte [rdi + 3], dl   ;Port number we are inserted in
    mov byte [rdi + 4], al   ;Save Interface number
    mov al, byte [r11 + 6]   ;bInterfaceSubclass is +6
    mov byte [rdi + 5], al
    mov al, byte [r11 + 7]   ;Protocol
    mov byte [rdi + 6], al
    mov byte [rdi + 7], r8b  ;MaxPacketSize0
;Valid In EP found, write table entries
    mov al, byte [rbx + 2]  ;Get address
    mov byte [rdi + 8], al
    mov ax, word [rbx + 4]  ;Get maxPacketSizeIn
    mov word [rdi + 9], ax

    lea rbx, qword [r11 + 9]   ;Return rbx to first IF
    inc bp      ;Increment error counter (Stage 6)
.eadttmsd21:
    mov ax, word [rbx + 2]  ;Bulk/Out bits
    shr ax, 4
    cmp ax, 20h
    je .eadttmsd3   ;Not zero only if valid
    add rbx, 7   ;Go to next endpoint
    dec ch
    jz .eadttbad
    jmp short .eadttmsd21
.eadttmsd3:
    mov al, byte [rbx + 2]  ;Get address
    mov byte [rdi + 11], al
    mov ax, word [rbx + 4]  ;Get maxPacketSizeIn
    mov word [rdi + 12], ax
    xor ax, ax  ;Zero ax
    mov word [rdi + 14], ax ;Make dt bits for I/O EPs zero
;Table entry written for MSD device
    jmp .eadttpass
.eadtthub:
    mov rdi, hubDevTbl
    mov cl,  hubDevTblE ;Max entries possible
    mov bp, 7      ;Increment error counter (Stage 7)
.eadtthub0:
    or byte [rdi], 0
    jz .eadtthub1
    add rdi, hubDevTblEntrySize
    dec cl
    jz .eadttbad
    jmp short .eadtthub0
.eadtthub1:
;Valid table space found
    mov byte [rdi], r9b      ;Device Address
    mov byte [rdi + 1], dh   ;Root hub/bus
    mov byte [rdi + 2], r10b ;Address of parent device if not root
    mov byte [rdi + 3], dl   ;Port number we are inserted in
    mov byte [rdi + 4], r8b  ;MaxPacketSize0
    mov ax, 0FF00h  ;Res byte is 0FFh, Num ports (byte 6) is 0
    mov word [rdi + 5], ax   ;Number of ports and PowerOn2PowerGood
    mov byte [rdi + 7], 0FFh    ;EP address, currently reserved
.eadttpass:
    popfq   ;If IF was clear, it will be set clear by popf
    xor ax, ax  ;Clear ax and clc
.eadttexit:
    pop rdx
    pop rbx
    pop rdi
    pop rbp
    pop r11
    ret
.eadttbad:
    popfq   ;If IF was clear, it will be set clear by popf
    stc
    mov ax, bp
    jmp short .eadttexit
.ehciRemoveDevFromTables:
;This function removes a function from internal tables
;Input: al = Address number, ah = Bus number
;Output: Internal tables zeroed out, ax destroyed, Carry clear
;    If invalid argument, Carry set
    push rdi
    push rcx
    push rbx
    mov rdi, usbDevTbl
    mov cl, usbDevTblE    ;10 entries possible
.erdft0:
    scasw
    je .erdft1    ;Device signature found
    inc rdi
    dec cl
    jz .erdftbad
    jmp short .erdft0
.erdft1:
    sub rdi, 2  ;scasw pointers to the next word past the comparison
    mov ah, byte [rdi + 2]    ;Save class code in ah
    cmp ah, 08h ;USB MSD Class device
    jne .erdft11    ;Skip the dec if it is a hub class device
    dec byte [numMSD]   ;Device is being removed from tables, decrement count
.erdft11:
;Clear usbDevTbl entry for usb device
    push rax
    mov ecx, usbDevTblEntrySize    ;Table entry size
    xor al, al
    rep stosb    ;Store zeros for entry
    pop rax

    mov rbx, hubDevTbl
    mov rcx, msdDevTbl
    cmp ah, 09h
    cmove rcx, rbx ;If 09h (Hub), change table pointed to by rcx
    mov rdi, rcx    ;Point rdi to appropriate table
    mov ebx, hubDevTblEntrySize    ;Size of hub table entry
    mov ecx, msdDevTblEntrySize    ;Size of msd table entry
    cmp ah, 09h
    cmove ecx, ebx    ;If hub, move size into cx
;cx has entry size, rdi points to appropriate table
    mov rbx, rdi
    xor edi, edi
    sub edi, ecx
    mov ah, 11h
.erdft2:
    dec ah
    jz .erdftbad    ;Somehow, address not found
    add edi, ecx
    cmp al, byte [rbx + rdi]
    jne .erdft2
    add rdi, rbx    ;point rdi to table entry
    xor al, al
    rep stosb    ;ecx contains table entry size in bytes
    dec byte [usbDevices]   ;Decrement total usb devices
    clc
.erdftexit:
    pop rbx
    pop rcx
    pop rdi
    ret
.erdftbad:
    stc
    jmp short .erdftexit 
.ehciGiveValidAddress:
;This function will return a valid value to use as an address
;for a new device.
;Input: al = Controller number [0-3]
;Output: al = Address, or 80h => No valid available address
    push rdi
    push rcx
    mov ah, al    ;Move bus number high
    mov al, 0 ;Address 0, start at addr 1
.egva0:
    inc al
    cmp al, 80h
    jae .egvaexit
    mov rdi, usbDevTbl
    mov cl, usbDevTblE    ;10 entries possible
.egva1:
    scasw
    je .egva0
    inc rdi    ;Pass third byte in table entry
    dec cl
    jnz .egva1    ;Check every entry for any addresses being used
.egvaexit:
    pop rcx
    pop rdi
    ret 
.ehciFindValidInterface:
;A proc to check a valid interface descriptor is present. 
;Input: Nothing [Assumes Get Config was called in standard buffer]
;Output: Carry set if invalid. Carry clear if valid.
;    On success: ah = device type (0 is msd, 1 is hub)
;                al = interface number to set
;               rbx = Pointer to Interface Descriptor
;   On fail: al contains error code, registers rbx, cx, dx destroyed
    push rsi
    push rdi
    push rcx
    push rdx

    mov rsi, ehciDataIn    ;Shift to buffer
    xor dl, dl    ;Error code counter
    cmp byte [rsi + 1], 02h    ;Check if valid config descriptor
    jne .ecvifail
    inc dl
;cl counts ep's per interface, ch counts possible interfaces
    mov ch, byte [rsi + 5]        ;Get number of interfaces
.ecvi0:
    test ch, ch
    jz .ecvifail    ;Zero interfaces is invalid for us
    inc dl

    mov rbx, rsi    ;Save this descriptor in rbx
    movzx rsi, byte [rbx]    ;get the size of the config to skip
    add rsi, rbx    ;point rsi to head of first interface descriptor
    cmp byte [rsi + 1], 04h    ;Check if valid interface descriptor
    jne .ecvifail
    inc dl
    mov cl, byte [rsi + 4]
;Cmp IF has valid class/prototcol
    xor rax, rax    ;Device signature, 0 is msd, 1 is hub
    call .ehciCheckMsdIf
    jnc    .ecviif    ;Not clear => valid interface
    inc ah    ;Device signature, 0 is msd, 1 is hub
    call .ehciCheckHubIf
    jc    .ecvibadif    ;Clear => bad interface
.ecviif:    ;Valid interface found
    mov al, byte [rsi + 2]    ;Get interface number into al
    mov rbx, rsi    ;Save pointer in rbx for return
    clc ;Clear carry
.ecviexit:
    pop rdx
    pop rcx
    pop rdi
    pop rsi
    ret
.ecvifail:
    xor ebx, ebx    ;Zero rbx for bad returns
    stc
    mov al, dl    ;Move error code
    jmp short .ecviexit
.ecvibadif:    ;Bad interface, goto next interface
    test cl, cl
    jz .ecvibadif1
    dec cl
    add rsi, 7
    jmp short .ecvibadif
.ecvibadif1:
    add rsi, 9
    dec ch
    mov dl, 1
    jmp short .ecvi0
.ehciCheckHubIf:
;Input: rsi points to interface descriptor
;Output: All registers preserved, carry set if NOT valid hub
    push rsi
    cmp byte [rsi + 5], 09h
    jne .ecdhfail
    cmp byte [rsi + 6], 0
    jne .ecdhfail
    cmp byte [rsi + 7], 2
    ja .ecdhfail
    cmp byte [rsi + 4], 1    ;One endpoint to rule them all
    jne .ecdhfail
    clc 
.ecdhexit:
    pop rsi
    ret
.ecdhfail:
    stc
    jmp short .ecdhexit
.ehciCheckMsdIf:
;Input: rsi points to interface descriptor
;Output: Carry set if fail, ax destroyed
;    rsi points to good descriptor if all ok
;Note we only accept 09/00/50 and 09/06/50
    push rsi
    push rbx
    push rcx
    cmp byte [rsi + 5], 08h    ;MSD class
    jne .ecdmfail
;Subclass check
    cmp byte [rsi + 6], 06h    ;SCSI actual
    je .ecdmprot
    cmp byte [rsi + 6], 00h    ;SCSI defacto
    jne .ecdmfail
.ecdmprot:
    cmp byte [rsi + 7], 50h    ;BBB
    jne .ecdmfail
.ecdmprotUAF:   ;Dummy label to find where to add this later
.ecdmpass:
    clc
.ecdmexit:
    pop rcx
    pop rbx
    pop rsi
    ret
.ecdmfail:
    stc
    jmp short .ecdmexit
.ehciGetDevicePtr:
;Gets address/bus pair and returns in rax a pointer to the data
;structure of the device, in the data table.
;Input: ah = bus number, al = Address number
;Output: ax = Preserved, rsi = Pointer to table structure, bl = USB Class Code
    push rcx
    push rdx
    push rbp
    mov ecx, usbMaxDevices
    mov rsi, usbDevTbl
.egdp0:
    cmp ax, word [rsi]
    je .egdp1   ;Device found
    add rsi, usbDevTblEntrySize
    dec cx
    jz .egdpfail    ;Got to the end with no dev found, exit
    jmp short .egdp0
.egdp1:
    mov rbp, hubDevTbl
    mov ecx, hubDevTblEntrySize
    movzx ebx, byte [rsi + 2]  ;Return bl for device type
    cmp bl, 09h ;Are we hub?
    mov rsi, msdDevTbl  ;Set to msd
    mov edx, msdDevTblEntrySize
    cmove rsi, rbp  ;If hub, reload rsi pointer to hub table
    cmove edx, ecx    ;If hub, reload dx with hub table size
    mov ecx, usbMaxDevices
.egdp2:
    cmp ax, word [rsi]
    je .egdp3
    add rsi, rdx    ;rdx contains size of entry for either table
    dec cx
    jz .egdpfail
    jmp short .egdp2
.egdp3:
    clc
.egdpexit:
    pop rbp
    pop rdx
    pop rcx
    ret
.egdpfail:
    xor bx, bx
    stc
    jmp short .egdpexit

.ehciProbeQhead:
;A proc that returns a Queue Heads' status byte in bl.
;Input:
;   rbx = Address of QHead to probe
;Output: 
;   bl = Status byte, if 0, successful transfer!
    mov bl, byte [rbx + 18h]  ;08h is offset in qTD
    ret
.ehciStandardErrorHandler:
;Attempts to verify if something went wrong in previous transaction.
;May only be called if eActiveInt has bit USBSTS bit set
;Input:  al = Device Address
;        cx = Default Endpoint Size
;Output: CF=CY: Host error, Reset host system
;        CF=NC: Proceed with below
;        al = 0 => Benign error, Make request again/Verify data.
;        al = 1 => Stall, Transaction error or Handshake error, corrected.
;        al = 80h => Fatal error, EPClear errored out, but no clear reason why
;        al > 80h => Bits 6-0 give the status byte for the error on EP Clear.
;                  Bit 7 is the fatal error bit. 
;                  If set, recommend device is port reset.
;All other registers preserved
    push rbx
    push r8
    push r9

    mov r8, rax
    mov r9, rcx
    xor al, al                  ;Set error counter and clear CF
    test byte [eActiveInt], 2   ;Error Interrupt
    jz .esehexit                ;No error found, should not have been called
    mov rbx, qword [eCurrAsyncHead] ;Get the current transacting QHead address
    call .ehciProbeQhead    ;Ret in bl status byte
    and bl, 01111000b       ;Check if it is something we should clear EP for
    jz .esehexit            ;If it is not, benign error. al = 0

    mov rbx, qword [eCurrAsyncHead] ;Get current AsyncHead again
    mov al, r8b        ;Device Address
    mov cx, r9w        ;EP size
    mov bl, byte [rbx + 05h]  ;Get Endpoint to reset
    and bl, 0Fh ;Lo nybble only
    call .ehciClearEpStallHalt
    jc .esehexit        ;HC error!
    mov al, 1           ;Stall cleared
    test byte [eActiveInt], 2   ;Check if interrupt returned an error
    jz .esehexit                ;No error found, return al=1, stall cleared
    mov al, 80h                 ;Fatal error indication
    mov rbx, qword [eCurrAsyncHead] ;Get the current transacting QHead address
    call .ehciProbeQhead   
    or al, bl          ;Add error bits to al for Fatal error indication.
.esehexit:
    mov rcx, r9
    pop r9
    pop r8
    pop rbx
    ret

.ehciClearEpStallHalt:
;Clears a halt or stall on an endpoint.
;Input: bl=Endpoint (0 for control)
;       al=Device Address
;       cx=Ctrl Endpoint Size
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check interrupt error bit for confirmation
    push rbx
    movzx rbx, bl
    shl rbx, 2*10h  ;Shift wIndex by two words
    or rbx, 0102h   ;01=bRequest(CLEAR_FEATURE) 02h=bmRequestType (Endpoint)
    call .ehciSetNoData
    pop rbx ;Get original bx
    ret

.ehciWriteQHead:
;Writes a Queue head at rdi, and clears the space for the transfer descriptor
;rdi points at the head of the qhead on return
;All non argument registers preserved
;r8d=Horizontal Ptr + Typ + T
;r9d=Endpoint Characteristics
;r10d=Endpoint Capabilities
;r11d=Next qTD Pointer
    push rax
    push rcx
    push rdi
    xor eax, eax
    mov eax, r8d
    stosd
    mov eax, r9d
    stosd
    mov eax, r10d
    stosd
    xor eax, eax
    stosd            ;Enter 0 for the current qTD pointer entry
    mov eax, r11d
    stosd
    mov ecx, 10
    xor eax, eax
    rep stosd
    pop rdi
    pop rcx
    pop rax
    ret
.ehciWriteQHeadTD:
;Writes a transfer descriptor at the location pointed at by rdi
;rdi points at the head of the qheadTD on return
;All registers except passed arguments, preserved
;rdi=location for current linked list element
;r8d=Next qTD ptr
;r9d=Alternate Next qTD ptr
;r10d=Transfer Descriptor Token
;r11=Buffer Ptr 0 + Current Offset
    push rax
    push rdi
    mov eax, r8d
    stosd
    mov eax, r9d
    stosd
    mov eax, r10d
    stosd
    mov eax, r11d
    stosd
    and eax, 0FFFFF000h
    add eax, 1000h
    stosd
    add eax, 1000h
    stosd
    add eax, 1000h
    stosd
    add eax, 1000h
    stosd

    mov rax, r11
    ror rax, 20h
    stosd
    ror rax, 20h
    and rax, 0FFFFFFFFFFFFF000h
    add rax, 1000h
    ror rax, 20h
    stosd
    ror rax, 20h
    add rax, 1000h
    ror rax, 20h
    stosd  
    ror rax, 20h
    add rax, 1000h
    ror rax, 20h
    stosd
    ror rax, 20h
    add rax, 1000h
    ror rax, 20h
    stosd
    pop rdi
    pop rax
    ret


.ehciDevSetupHub:
;Device specific setup. Takes rsi as a ptr to the 
; specific device parameter block.
    push rbx
    push rcx
    push rsi
    push rbp
    xor bp, bp    ;Error Stage 0
.edshub:
    call .ehciHubClassDescriptor
    jc .edsfail
    inc bp  ;Error Stage 1
    mov cl, byte [rsi + 5] ;Get number of ports here
    mov dl, 1   ;Start port number to begin enum on (hub ports start at 1)
.edshub1:
    mov r12, 3
.edshub11:
    call .ehciEnumerateHubPort    ;dl for port to scan/enumerate
    jz .edshub13    ;If ZF=ZR, valid device found!
    cmp byte [msdStatus], 20h  ;General Controller Failure
    je USB.ehciCriticalErrorWrapper
    dec r12
    jnz .edshub11   ;Still not zero but failed, try again.
.edshub13:
    inc dl  ;Start with port 1
    cmp cl, dl
    jae .edshub1
.edshub2:
;Need to write bHostHub for any detected devices here
    clc    ;Common success exit
    pop rbp
    pop rsi
    pop rcx
    pop rbx
    ret

.ehciDeviceSetupMsd:
; Input:  rsi = MSD Device Parameter Block
; Output: CF=CY if catastrophic host error.
;         CF=NC then ax = Return code
;         ax = 0 if successful setup
;         ax = 1 if device did not reset the first time
;         ax = 2 if device did not return a valid LUN
;         ax = 3 if device did not reset the second time
;         Device must me removed from tables and port reset if ax != 0
    push rcx
    push rbp
    push r8
    xor bp, bp    ;Error Stage 0
.edsmsd:
    mov r8, 10h ;Loop counter setup
.edsm1:
    call .ehciMsdDeviceReset
    jc .edsexit
;Check eActiveInterrupt for confirmation if we need to handle error
    test byte [eActiveInt], 2   ;If this is set, handle error
    jz .edsms2
    mov cx, word [rsi + 7]    ;Pass endpoint size
    mov al, byte [rsi]  ;Device address
    call .ehciStandardErrorHandler
    test al, 80h 
    jnz .edsfail   ;If bit 7 is set, something is seriously wrong, fail dev!
    dec r8                ;Dec loop counter
    jz .edsfail           ;Fatal error if after 16 goes nothing was resolved
    jmp short .edsm1
.edsms2:
    inc bp  ;Error Stage 1
.edsms3:
    call .ehciMsdGetMaxLun  ;If stall, clear endpoint and proceed. No loop
    jc .edsexit
    test byte [eActiveInt], 2   ;If this is set, handle error
    jz .edsms4

    mov cx, word [rsi + 7]    ;Pass endpoint size
    mov al, byte [rsi]  ;Device address
    call .ehciStandardErrorHandler
    test al, 80h 
    jnz .edsfail   ;If bit 7 is set, something is seriously wrong, fail dev!
.edsms4:
    inc bp  ;Error Stage 2
    mov r8, 10h ;Loop counter setup
.edsms5:
    call .ehciMsdDeviceReset  ;Reset once again to clear issues
    jc .edsexit
    test byte [eActiveInt], 2   ;If this is set, handle error
    jz .edsms6

    mov cx, word [rsi + 7]    ;Pass endpoint size
    mov al, byte [rsi]  ;Device address
    call .ehciStandardErrorHandler
    test al, 80h 
    jnz .edsfail   ;If bit 7 is set, something is seriously wrong, fail dev!
    dec r8                 ;Dec loop counter
    jz .edsfail           ;Fatal error if after 16 goes nothing was resolved
    jmp short .edsms5
.edsms6:
    inc byte [numMSD] 
    xor ax, ax  ;Note that xor also clears CF
.edsexit:
    pop r8
    pop rbp
    pop rcx
    ret
.edsfail:
;If a fail occurs, then the entry needs to be removed from the data tables
    mov ax, bp
    jmp .edsexit

.ehciEnumerateHubPort:
;Enumerates devices on an external Hub.
;Use rsi to get device properties
;Input: rsi = ptr to hub device block
;       dl = Port number to reset
;Output: None, CF

    push rbx
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11

    movzx edx, dl
    shl rdx, 4*8    ;Shift port number to right bits
.eehdeinit:
    xor bp, bp  ;Error counter
    movzx r9, word [rsi]        ;Save hub bus/addr in r9w
    movzx r8, byte [rsi + 4]    ;Get MaxPacketSize0

.eehde0:
    mov rbx, 0000000000080323h  ;Set port power feature
    or rbx, rdx ;Add port number into descriptor
    mov cx, r8w
    mov al, r9b
    call .ehciSetNoData   ;Turn on power to port on device in addr al
    jc .eehdecritical  ;Fast exit with carry set
.eehde1:
;Power on debounce!
    mov ah, 86h
    movzx ecx, byte [rsi + 6]   ;poweron2powergood
    shl ecx, 1
    int 35h

    inc bp      ;Increment Error Counter    (Stage 1)
.eehde2:
    mov rbx, 0000000000100123h  ;Clear port set connection bit
    or rbx, rdx ;Add port number into descriptor
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
    jc .eehdecritical  ;Fast exit with carry set
.eehde3:

    inc bp      ;Increment Error Counter    (Stage 2)
.eehde31:
    mov rbx, 00040000000000A3h ;Get port status
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciGetRequest
    jc .eehdecritical  ;Fast exit with carry set
.eehde4:
    inc bp      ;Increment Error Counter    (Stage 3)

    mov cl, byte [ehciDataIn]   ;Get the first byte in into cx
    test cl, 1  ;Check device in port
    jz .eehdebadnotimeout

.eehde41:   ;EP for first port reset state
    inc bp      ;Increment Error Counter    (Stage 4)
    call .eehdereset    ;First port reset
    jc .eehdecritical  ;Fast exit with carry set

    inc bp      ;Increment Error Counter    (Stage 5)

    mov r11, 10h
.eehde5:
    mov rbx, 00040000000000A3h ;Get port status again
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciGetRequest
    jc .eehdecritical  ;Fast exit with carry set
.eehde6:
    inc bp      ;Increment Error Counter    (Stage 6)
;Now check for high speed

    mov cx, word [ehciDataIn]
    and cx, 7FFh    ;Zero upper bits
    shr cx, 9   ;Bring bits [10:9] low
    cmp cx, 2   ;2 is High Speed device
    jne .eehdebadnotimeout
    mov qword [ehciDataIn], 0

    inc bp      ;Increment Error Counter    (Stage 7)

    push rdi
    mov rdi, ehciDataIn
    mov ecx, 8
    xor eax, eax
    rep stosq
    pop rdi
.eehde7:
    mov rbx, 0000000000120123h  ;Clear port suspend
    or rbx, rdx ;Add port number into descriptor
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
    jc .eehdecritical  ;Fast exit with carry set

.eehde10:
    mov rbx, 00008000001000680h    ;Pass get minimal device descriptor
    mov cx, 40h    ;Pass default endpoint size
    xor al, al
    call .ehciGetRequest
    jc .eehdecritical  ;Fast exit with carry set
.eehde101:
    inc bp      ;Increment Error Counter    (Stage 8)

    cmp byte [ehciDataIn + 1], 01h    ;Verify this is a valid dev descriptor
    jne .eehdebad       ;ehciDataIn contains error signature

;Sanity check the returned descriptor here
.eehde11:
    cmp word [ehciDataIn + 2], 0200h    ;Verify this is a USB 2.0+ device or
    jb .eehdebad
    cmp byte [ehciDataIn + 4], 0    ;Check interfaces
    je .eehde12
    cmp byte [ehciDataIn + 4], 08h    ;MSD?
    je .eehde12
    cmp byte [ehciDataIn + 4], 09h    ;Hub?
    jne .eehdebad

.eehde12:    ;Valid device detected
    movzx r8d, byte [ehciDataIn + 7]   ;Save attached device max ep size
.eehde13: 
    call .eehdereset    ;Do second reset
    jc .eehdecritical  ;Fast exit with carry set
;Clear the data in buffer
    push rdi
    mov rdi, ehciDataIn
    mov ecx, 8
    xor eax, eax
    rep stosq
    pop rdi

;Device on port now ready to have an address set to it, and be enumerated
    shr rdx, 4*8    ;Shift port number back down to dl
    mov ax, word [rsi]  ;Get hub bus/addr pair
    mov dh, ah          ;Move the bus number into dh
    movzx r10d, al      ;Move hub address into r10b
;Ensure dl=port number - 1, dh=Root hub (Bus) number, r10b=Host hub number
;       r8b=Max Control EP endpoint size
    mov r11, 100    ;Address settle time
    dec dl
    jmp .ehciEnumCommonEp

.eehdebad:
.eehdebadnoport:    ;EP if done without disabling port
    jmp .ehciedbadnoport
.eehdebadnotimeout:
    jmp .ehciedbadnotimeout
.eehdebadremtables:
    jmp .ehcibadremtables
.eehdecritical:
    jmp .ehciedexit  ;Fast exit with carry set
.eehdereset:
;rsi must point to valid Hub device block
    mov rbx, 0000000000040323h  ;Reset port 
    or rbx, rdx ;Add device address
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
    jc .eehcritexit

    mov r11, 5000 ;Just keep trying
.eehder1:
    mov ah, 86h
    mov ecx, 20     ;20 ms is max according to USB 2.0 standard
    int 35h

    mov rbx, 00040000000000A3h ;Get port status
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciGetRequest
    mov cl, byte [ehciDataIn]   ;Get low byte of in data
    test cl, 10h    ;If bit not set, reset over, proceed
    jz .eehder2
    dec r11
    jnz .eehder1
.eehder2:
    mov rbx, 0000000000140123h ;Clear port reset bit
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
.eehcritexit:
    ret

.ehciHubClassDescriptor:
;Gets the Hub class descriptor
;Get Hub descriptor for device pointed to by rsi
;If invalid data, returns error
;Input: rsi = Ptr to hub data block
;Output:
;   Carry Clear if success
;   Carry Set if fail, al contains error code
    push rbx
    push rcx
    push rbp
    mov bp, 3

    mov rbx, 00070000290006A0h  ;Get Hub descriptor (only first 7 bytes)
    movzx ecx, byte [rsi + 4]  ;bMaxPacketSize0
    mov al, byte [rsi]      ;Get device address
    call .ehciGetRequest
    jc .ehcdfail    ;Errors 0-2 live here

    inc bp
    cmp byte [ehciDataIn + 1], 29h  ;Is this a valid hub descriptor
    jne .ehcdfail

    mov cl, byte [ehciDataIn + 2]   ;Get number of downstream ports
    mov byte [rsi + 5], cl  ;Store in variable, marking device as configured

    mov cl, byte [ehciDataIn + 5]   ;Get PowerOn2PowerGood
    mov byte [rsi + 6], cl  ;Store in variable
    clc
.ehcdexit:
    pop rbp
    pop rcx
    pop rbx
    ret
.ehcdfail:
    mov al, bpl
    stc
    jmp short .ehcdexit
;                        ---------MSD functions---------
.ehciMsdInitialise:
;Initialises an MSD device.
;Input: rsi = Valid MSD device block
;Output: CF=CY: Init did not complete
;        al = 0 => Device initialised
;        al = 1 => Host/Schedule error
;        al = 2 => Device failed to initialise
;        CF=NC: Init complete, rsi points to complete USB MSD device block
    push rcx
    mov al, byte [rsi + 1]  ;Get the bus number into al
    call .ehciAdjustAsyncSchedCtrlr
    mov al, 1
    jc .ehciMsdInitFail
    call .ehciDeviceSetupMsd
    mov al, 2
    jc .ehciMsdInitFail
    call .ehciMsdBOTInquiry
    jc .ehciMsdInitFail
    mov ecx, 5
.emi0:
    call .ehciMsdBOTReadFormatCapacities
    cmp byte [msdStatus], 20h   ;Host error
    je .ehciMsdInitialisePfail  ;Protocol fail
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emipf0
    call .ehciMsdBOTModeSense6
    cmp byte [msdStatus], 20h   ;Host error
    je .ehciMsdInitialisePfail  ;Protocol fail
    call .ehciMsdBOTCheckTransaction
    test ax, ax     ;Also clears CF if zero
    jnz .emipf0
.ehciMsdInitExit:
    pop rcx
    ret
.ehciMsdInitFail:
    mov ax, word [rsi]
    call .ehciRemoveDevFromTables
    dec byte [numMSD]   ;Device was removed from tables, decrement
    stc
    mov al, 2
    jmp short .ehciMsdInitExit
.ehciMsdInitialisePfail:
    call .ehciMsdBOTResetRecovery
    dec ecx
    jz .ehciMsdInitFail
.emipf0:
    call .ehciMsdBOTRequestSense
    cmp byte [msdStatus], 20h
    je .ehciMsdInitialisePfail
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jz .emi0
    jmp short .ehciMsdInitialisePfail

.ehciMsdDeviceReset:
;Reset an MSD device on current active EHCI bus
;Input: rsi = Pointer to table data structure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check reset occurred successfully 
;          (If eActiveIntr AND 2 != 0, then error in transfer)
    push rcx
    push rdx
    push rbx
    push rax

    movzx ecx, byte [rsi + 7]  ;Get bMaxPacketSize0
    movzx rdx, byte [rsi + 4]  ;Get Interface Number
    shl rdx, 5*8 ;Send to 5th byte
    mov rbx, 0FF21h            ;MSD Reset
    or rbx, rdx                ;And those bytes
    mov al, byte [rsi]
    call .ehciSetNoData

    pop rax
    pop rbx
    pop rdx
    pop rcx
    ret

.ehciMsdGetMaxLun:
;Get max LUN of an MSD device on current active EHCI bus
;Input: rsi = Pointer to table data structure
;       al = Address
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
;   Max Lun saved at DataIn Buffer (first byte)
;   Check this was transferred, by checking total data transferred value
    push rcx
    push rdx
    push rbx
    push rax

    movzx ecx, byte [rsi + 7]  ;Get bMaxPacketSize0
    movzx rdx, byte [rsi + 4]  ;Get Interface Number
    shl rdx, 5*8 ;Send to 5th byte
    mov rbx, 000100000000FEA1h            ;MSD Get Max LUN
    or rbx, rdx                ;And those bytes
    mov al, byte [rsi]
    call .ehciGetRequest

    pop rax
    pop rbx
    pop rdx
    pop rcx
    ret

.ehciMsdBOTResetRecovery:
;----------------------------------------------------------------
;Calls the reset recovery procedure on a device ptd to by rsi   :
;Input:  rsi = Pointer to MSD device parameter block            :
;Output: CF=CY if something went wrong. Else CF=NC              :
;----------------------------------------------------------------
;Calls an MSDBBB reset then calls StandardErrorHandler AFTER    : 
; writing the Qhead for each Bulk EP.                           :
;----------------------------------------------------------------
    push rax
    push rbx
    push rcx
    mov word [rsi + 14], 00h    ;Reset clear both endpoint dt bits 

    call .ehciMsdDeviceReset    ;Call the device reset
    jc .embrrexit
;Now clear stall on IN EP
    mov al, byte [rsi]          ;Get the address
    mov bl, byte [rsi + 8]      ;Get the 4 byte EP address
    movzx ecx, byte [rsi + 7]   ;Get the Max packet size for the ctrl EP
    call .ehciClearEpStallHalt
    jc .embrrexit
;Now clear stall on OUT EP
    mov al, byte [rsi]          ;Get the address
    mov bl, byte [rsi + 11]     ;Get the 4 byte EP address
    movzx ecx, byte [rsi + 7]   ;Get the Max packet size for the ctrl EP
    call .ehciClearEpStallHalt
.embrrexit:
    pop rcx
    pop rbx
    pop rax
    ret
.ehciMsdBOTCheckValidCSW:
; This function checks that the recieved CSW was valid.
; If this function returns a non-zero value in al, 
; a reset recovery of the device is required
; Output: al = 0 : valid CSW
;         If CSW not valid, al contains a bitfield describing what failed
;         al = 1h   : CSW is not 13 bytes in length
;         al = 2h   : dCSWSignature is not equal to 053425355h
;         al = 4h   : dCSWTag does not match the dCBWTag
;         al = 0F8h : Reserved
;   rax destroyed
    push rbx
    push rcx
    xor eax, eax
    mov cx, 1
    mov bx, word [ehciTDSpace + 2*ehciSizeOfTD + 0Ah]   
;Get total bytes to transfer from third QHeadTD to see if 13h bytes were 
; transferred
    and bx, 7FFFh   ;Clear upper bit
    cmovnz ax, cx   ;If the result for the and is not zero, <>13 bytes were sent

    shl cx, 1     
    or cx, ax
    cmp dword [msdCSW], CSWSig
    cmovne ax, cx

    mov cx, 4h
    or cx, ax
    movzx ebx, byte [cbwTag]
    dec bl
    cmp bl, byte [msdCSW + 4h]
    cmovne ax, cx

    pop rcx
    pop rbx
    ret

.ehciMsdBOTCheckMeaningfulCSW:
; This function checks if the CSW was meaningful.
; If this function returns a non-zero value in al, it is up to the
; caller to decide what action to take. The possible set of actions that
; can be taken is outlined in Section 6.7 of the USB MSC BOT Revision 1.0 
; specification.
; Output :  al = 0h  : Invalid
;           al = 1h  : bCSWStatus = 0
;           al = 2h  : bCSWStatus = 1
;           al = 4h  : bCSWStatus = 2
;           al = 8h  : bCSWStatus > 2
;           al = 10h : dCSWDataResidue = 0
;           al = 20h : dCSWDataResidue < dCBWDataTransferLength
;           al = 40h : dCSWDataResidue > dCBWDataTransferLength
;           al = 80h : Reserved
;   rax destroyed
    push rbx
    push rcx

    xor eax, eax  ;In the event that things go completely wrong
    mov bx, 8h
    mov cl, byte [msdCSW + 0Ch]

    cmp cl, 2
    cmova ax, bx
    ja .embcmcResidueCheck

    shr bx, 1       ;Shift it down to 4
    cmove ax, bx    ;If bCSWStatus = 2, move it in
    je .embcmcResidueCheck

    shr bx, 1       ;Shift down to 2
    cmp cl, 1
    cmove ax, bx    ;If bCSWStatus = 1, move bx into ax
    je .embcmcResidueCheck

    inc ax          ;Otherwise bCSWStatus = 0
.embcmcResidueCheck:
    mov ecx, dword [msdCSW + 8] ;Get dCSWDataResidue

    mov bx, 10h
    or bx, ax   
    test ecx, ecx
    cmovz ax, bx    ;If its zero, move bx with added bit from ax into ax
    jz .embcmcExit

    mov bx, 20h
    or bx, ax 
    cmp ecx, dword [ehciDataOut + 8];ehciDataOut + 8 = dCBWDataTransferLength
    cmovb ax, bx
    jb .embcmcExit

    or ax, 40h  ;Else, it must be above, fail
.embcmcExit:
    pop rcx
    pop rbx
    ret

.ehciMsdBOTCheckTransaction:
;Check successful return data here
;Output: ax = 0                                 : CSW Valid and Meaningful
;        ah = 1, al = CSW Validity bitfield     : CSW NOT valid
;        ah = 2, al = CSW Meaningful bitfield   : CSW NOT meaningful
;   rax destroyed
    xor ah, ah
    call .ehciMsdBOTCheckValidCSW
    test al, al
    jz .embhiehcswmeaningful
    mov ah, 1       ; CSW Not Valid signature
    jmp .embhiehexit
.embhiehcswmeaningful:
    call .ehciMsdBOTCheckMeaningfulCSW
    and al, 4Ch     ;Check bad bits first and bCSWStatus=02 40h|08h|04h
    jz .embhiehexit
    mov ah, 2       ; CSW Not Meaningful signature
.embhiehexit:
    ret
.ehciMsdBOTOO64I:   ;For devices with 64 byte max packet size
.ehciMsdBOTOI64I:   ;For devices with 64 byte max packet size
    mov byte [msdStatus], 0BBh   ;Undefined error
    ret
.ehciMsdBOTOOI:     ;Out Out In transfer
;Input - rsi = MSD device parameter block
;        rbx = Input buffer for Data In
;        ecx = Number of milliseconds to wait between Out and In packets
;        r8  = Number of bytes to be transferred (for the DATA phase)
;        r10 = LUN Value
;        r11 = Length of CBW command block
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push rcx
    cld

    mov r12, r8     ;Save number of bytes to transfer to MSD device
    push rcx
;Write QHead for CBW
    mov r11, ehciTDSpace ;First TD is the head of the Out buffer
    call .ehciMsdWriteOutQHead
;Write TD for CBW send
    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    movzx r10d, byte [rsi + 15]   ;Get Out EP dt bit
    xor byte [rsi + 15], 1  ;Toggle bit
    ror r10d, 1 ;Roll dt bit to upper bit of dword
    or r10d, 001F8C80h 
; Active TD, OUT EP, Error ctr = 3, 01Fh = 31 byte transfer
    mov r11, ehciDataOut ; Data out buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    pop rcx    ;Wait ecx ms for "motors to spin up"
    jc .emboexit    ;If catastrophic Host system error, exit!

    push rax
    mov ah, 86h
    int 35h
    pop rax
;Write Qhead to Send data
    mov r11, ehciSizeOfTD + ehciSizeOfTD
    call .ehciMsdWriteOutQHead
;Write TD for data send
    mov rdi, r11
    mov r8, 1
    mov r9, r8
    mov r10, r12     ;Get back number of bytes to transfer
    shl r10, 8*2    ;Shift into 3rd byte
    or r10d, 00008C80h ;Add control bits: Active TD, OUT EP, Error ctr = 3
    movzx ecx, byte [rsi + 15]  ;Get Out EP dt bit in r9d
    xor byte [rsi + 15], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, rbx    ;Get the address of Data buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    jc .emboexit    ;If catastrophic Host system error, exit!
;Write Qhead for CSW
    mov r11, ehciTDSpace + 2*ehciSizeOfTD ;Third TD
    call .ehciMsdWriteInQHead
    mov rdi, r11
    jmp .emboiicommonep
.ehciMsdBOTOII: ;Out In In transfer
;Input - rsi = MSD device parameter block
;        rbx = Input buffer for Data In
;        ecx = Number of milliseconds to wait between Out and In packets
;        r8  = Number of bytes to be transferred (for the DATA phase)
;        r10 = LUN Value
;        r11 = Length of CBW command block

    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push rcx
    cld

    mov r12, r8 ;Save the number of bytes to be transferred
    push rcx

;Write the OUT Queue Head
    mov r11, ehciTDSpace ;First TD is the head of the Out buffer
    call .ehciMsdWriteOutQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    movzx r10d, byte [rsi + 15]   ;Get Out EP dt bit
    xor byte [rsi + 15], 1  ;Toggle bit
    ror r10d, 1 ;Roll dt bit to upper bit of dword
    or r10d, 001F8C80h 
; Active TD, OUT EP, Error ctr = 3, 01Fh = 31 byte transfer
    mov r11, ehciDataOut ; Data out buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    pop rcx    ;Wait ecx ms for "motors to spin up"
    jc .emboexit    ;If catastrophic Host system error, exit!
         
    push rax
    mov ah, 86h
    int 35h
    pop rax
;Write the IN Queue Head
    mov r11, ehciTDSpace + ehciSizeOfTD ;Move to position 2 to preserve OUT TD
    call .ehciMsdWriteInQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    lea r8, qword [rdi + ehciSizeOfTD]  ;Point to next TD
    mov r9, r8
    mov r10, r12     ;Get back number of bytes to transfer from the stack
    shl r10, 8*2    ;Shift into 3rd byte
    or r10d, 00000D80h ;Add control bits: Active TD, IN EP, Error ctr = 3
    movzx ecx, byte [rsi + 14]  ;Get IN EP dt bit in r9d
    xor byte [rsi + 14], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, rbx ; Data out buffer, default ehciDataIn
    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD     ;Go to next TD space
.emboiicommonep:
    mov r8, 1
    mov r9, r8
    mov r10d, 000D8D80h     ;Active TD, IN EP, Error ctr = 3, 0Dh = 13 byte CSW
    movzx ecx, byte [rsi + 14]  ;Get IN EP dt bit in r9d
    xor byte [rsi + 14], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, msdCSW

    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
.emboexit:
    pop rcx
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    ret
.ehciMsdBOTOI: ;Out In transfer
;Input - rsi = MSD device parameter block
;        rbx = Input buffer for Data In
;        ecx = Number of milliseconds to wait between Out and In packets
;        r8  = Number of bytes to be transferred (for the DATA phase)
;        r10 = LUN Value
;        r11 = Length of CBW command block

    push rdi
    push r8
    push r9
    push r10
    push r11
    push rcx
    cld


;Write the OUT Queue Head
    mov r11, ehciTDSpace ;First TD is the head of the Out buffer
    call .ehciMsdWriteOutQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    movzx r10d, byte [rsi + 15]   ;Get Out EP dt bit
    xor byte [rsi + 15], 1  ;Toggle bit
    ror r10d, 1 ;Roll dt bit to upper bit of dword
    or r10d, 001F8C80h 
; Active TD, OUT EP, Error ctr = 3, 01Fh = 31 byte transfer
    mov r11, ehciDataOut ; Data out buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    jc .emboiexit    ;If catastrophic Host system error, exit!
         
;Write the IN Queue Head
    mov r11, ehciTDSpace + ehciSizeOfTD ;Move to position 2 to preserve OUT TD
    call .ehciMsdWriteInQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    mov r10d, 000D8D80h     ;Active TD, IN EP, Error ctr = 3, 0Dh = 13 byte CSW
    movzx ecx, byte [rsi + 14]  ;Get IN EP dt bit in r9d
    xor byte [rsi + 14], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, msdCSW

    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
.emboiexit:
    pop rcx
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    ret
.ehciMsdWriteOutQHead:
;Input: rsi = Valid MSD device
;       r11 = Ptr to First QHTD
    call .ehciGetNewQHeadAddr
    or r8d, 2    ;Process QHs
    mov r9d, 00006000h  ;Default mask, no nak counter
    movzx ecx, word [rsi + 12]  ;wMaxPacketSizeOut
    shl ecx, 8*2
    or r9d, ecx
    movzx ecx, byte [rsi + 11]  ;EP address
    and ecx, 0Fh
    shl ecx, 8  ;Shift to second byte 
    or r9d, ecx ;Add bits
    mov al, byte [rsi]  ;Get device address
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    call .ehciWriteQHead
    ret
.ehciMsdWriteInQHead:
;Input: rsi = Valid MSD device
;       r11 = Ptr to First QHTD
    call .ehciGetNewQHeadAddr
    or r8, 2
    mov r9d, 00006000h  ;Default mask
    movzx ecx, word [rsi + 9]  ;wMaxPacketSizeIn
    shl ecx, 8*2
    or r9d, ecx
    movzx ecx, byte [rsi + 8]  ;EP address
    and ecx, 0Fh
    shl ecx, 8  ;Shift to second byte 
    or r9d, ecx ;Add bits
    mov al, byte [rsi]  ;Get device address
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    call .ehciWriteQHead
    ret
.ehciMsdBOTRequest:
;Input: ecx = Number of miliseconds to wait between Out and In requests
;       rbx = Data in Buffer
;       r8  = Number of bytes to be returned by command
;       r11 = Length of SCSI command block
;       r14 = Pointer to EHCI(USB) transaction function
;       r15 = Pointer to SCSI command function
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rax
    push rcx
    push rdi
    push r9
    push r10
;Clear the previous CSW
    mov rdi, msdCSW
    xor al, al
    mov ecx, 13
    rep stosb
;Write the CBW
    mov rdi, ehciDataOut    ;Write the CBW at the data out point

    mov r9b, 80h            ;Recieve an IN packet
    xor r10, r10            ;LUN 0
    call .msdWriteCBW       ;Write the 15 byte CBW
;Append the Command Block to the CBW
    xor al, al              ;LUN 0 device
    call r15                ;Write the valid CBW Command block
;Enact transaction
    call r14

    pop r10
    pop r9
    pop rdi
    pop rcx
    pop rax
    ret

.ehciMsdBOTInquiry:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Inqure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8d, 024h           ;36 bytes to be returned
    mov r11, 0Ch            ;The command block is 12 bytes (As per Bootability)
    mov r15, .scsiInquiry
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

.ehciMsdBOTReadFormatCapacities:
;Input: 
; rsi = Pointer to MSD table data structure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 0FCh            ;Return 252 bytes
    mov r11, 0Ah            ;The command block is 10 bytes
    mov r15, .scsiReadFormatCapacities
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

.ehciMsdBOTReadCapacity10:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Read Capcities
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 8
    mov r11, 0Ah
    mov r15, .scsiReadCap10
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret
.ehciMsdBOTFormatUnit:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Format
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rax
    push r8
    push r11
    push r14
    push r15
    xor r8, r8  ;Request no data
    mov r11, 06h  ;Command length is 6 bytes
    mov r14, .ehciMsdBOTOI
    mov r15, .scsiFormatUnit
    call .ehciMsdBOTRequest
    jc .embfuerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .embfuerror
.embfu0:
    call .ehciMsdBOTTestReady
    jc .embfuerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jz .embfuexit
    call .ehciMsdBOTRequestSense
    jc .embfuerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .embfu0
.embfuexit:
    pop r15
    pop r14
    pop r11
    pop r8
    pop rax
    ret
.embfuerror:
    stc
    jmp short .embfuexit
.ehciMsdBOTVerify:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Verify Sectors
; edx = Starting LBA to verify
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rax
    push r8
    push r11
    push r12
    push r14
    push r15
    xor r8, r8  ;Request no data
    mov r11, 0Ah  ;Command length is 10 bytes
    mov r12d, edx
    mov r14, .ehciMsdBOTOI
    mov r15, .scsiVerify
    call .ehciMsdBOTRequest
    jc .embvbad
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .embvbad
.embvexit:
    pop r15
    pop r14
    pop r12
    pop r11
    pop r8
    pop rcx
    ret
.embvbad:
    stc
    jmp short .embvexit
.ehciMsdBOTRequestSense:
;Input: 
; rsi = Pointer to device MSD table data structure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 12h         ;Request 18 bytes
    mov r11, 6          ;Command length is 6
    mov r15, .scsiRequestSense
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

.ehciMsdBOTTestReady:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Test Ready
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push r8
    push r11
    push r14
    push r15
    xor r8, r8  ;Request no data
    mov r11, 6  ;Command length is 6
    mov r14, .ehciMsdBOTOI
    mov r15, .scsiTestUnitReady
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    ret
.ehciMsdBOTModeSense6:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Test Ready
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 0C0h        ;Request 192 bytes
    mov r11, 6          ;Command length is 6
    mov r15, .scsiModeSense6
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

;.ehciMsdBOTOutSector64:
.ehciMsdBOTOutSector512:
;Input: 
; rsi = Pointer to MSD table data structure that we want to read
; rbx = Address of the buffer to read the segment from
; edx = Starting LBA to read to
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push r9
    push r14
    push r15
    push rax
    xor r9, r9 ;Send an OUT packet
    mov r14, .ehciMsdBOTOOI
    mov r15, .scsiWrite10
    call .ehciMsdBOTSector512
    jc .emboseerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emboseerror
    call .ehciMsdBOTTestReady   ;Seems to flush data onto disk
    jc .emboseerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emboseerror
.embosexit:
    pop rax
    pop r15
    pop r14
    pop r9
    ret
.emboseerror:
    stc
    jmp short .embosexit
;.ehciMsdBOTInSector64:
.ehciMsdBOTInSector512:
;Input: 
; rsi = Pointer to MSD table data structure that we want to read
; rbx = Address of the buffer to read the segment into
; edx = Starting LBA to read from
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push r9
    push r14
    push r15
    push rax
    mov r9, 80h ;Recieve an IN packet
    mov r14, .ehciMsdBOTOII
    mov r15, .scsiRead10
    call .ehciMsdBOTSector512
    jc .emboseerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emboseerror
    jmp short .embosexit
.ehciMsdBOTSector512:
;Input: 
; rsi = Pointer to MSD table data structure that we want to read
; rbx = Address of the buffer to read the segment into
; edx = Starting LBA to read to/from
; r9  = CBW flag (IN or OUT transaction)
; r15 = SCSI function
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rdi
    push r8
    push r10
    push r11

    mov rdi, ehciDataOut    ;Write the CBW at the data out point
    mov r8d, 200h           ;512 bytes to be transferred
    xor r10, r10            ;LUN 0
    mov r11, 0Ch            ;The command block is 10 bytes long
    call .msdWriteCBW     ;Write the CBW

    push rax                ;Temp push ax
    push r8                 ;Temp save # of bytes for transfer
    xor al, al              ;LUN 0 device
    mov r8d, edx            ;Starting LBA to read from
    mov r9, 1               ;Number of LBAs to read
    call r15                ;Write the valid CBW Command block
    pop r8
    pop rax

    mov ecx, 10              ;Wait for data preparation, 10ms
    call r14

    pop r11
    pop r10
    pop r8
    pop rdi
    ret
.msdWriteCBW:
;Writes a Command Block Wrapper at the location pointed to by rdi
; without a functional command block. Must be appended by user.
; Input:  rdi=Pointer to CBW buffer
;         r8d=Command Block Wrapper Data Transfer Length
;         r9b=Command Block Wrapper Flags
;         r10b=Command Block Wrapper LUN nybble
;         r11b=Command Block Wrapper Command Block Length
; Output: rdi = Pointer to CBW's (SCSI) Command Descriptor Block buffer
    push rax
    mov eax, CBWSig
    stosd
    movzx eax, byte [cbwTag]
    inc byte [cbwTag]
    stosd
    mov eax, r8d
    stosd
    mov al, r9b
    stosb
    mov al, r10b
    stosb
    mov al, r11b
    stosb
    xor eax, eax
    push rdi
    stosq   ;16 bytes in csw command block
    stosq   ;Clear memory
    pop rdi
    pop rax
    ret

;                        --------SCSI functions---------

.scsiInquiry:
;Writes an inquiry scsi command block to the location pointed to by rdi
;al contains the LUN of the device we are accessing. (lower 3 bits considered)
;al not preserved
    mov ah, 12h        ;Move inquiry command value high
    shl al, 5        ;Shift left by five to align LUN properly
    xchg ah, al        ;swap ah and al
    stosw            ;Store command and shifted LUN together
    xor rax, rax
    stosw            ;Store two zeros (reserved fields)
    mov rax, 24h    ;Allocation length (36 bytes)
    stosq
    ret
;NOTE! Using read/write 10 means can't read beyond the first 4 Gb of Medium.
.scsiWrite10:
;Writes a scsi write 10 transfer command to the location pointed at by rdi
;al contains the LUN of the device we are accessing
;r8d contains the LBA start address
;r9w contains the Verification Length
    mov ah, 2Ah        ;Operation code for command
    jmp short .scsirw
.scsiRead10:
;Writes a scsi Read 10 command to the location pointed to by rdi
;al contains the LUN of the device we are accessing.
;r8d contains the LBA to read from
;r9w contains the number of contiguous blocks to read (should be 1 for us)
    mov ah, 28h        ;Move read(10) command value high
.scsirw:
    shl al, 5        ;Shift left by five to align LUN properly
    xchg ah, al        ;swap ah and al
    stosw            ;Store command and shifted LUN together
    bswap r8d        ;swap endianness of r8d
    mov eax, r8d
    stosd
    xor rax, rax    ;Clear for a Reserved byte
    stosb
    mov ax, r9w        ;move into ax to use xchg on upper and lower bytes
    xchg al, ah        ;MSB first, yuck yuck yuck
    stosw
    shr eax, 16        ;Bring zeros down onto lower word
    stosw            ;Store one reserved byte and two padding bytes
    stosb            
    ret
.scsiRequestSense:
;Writes a scsi Request Sense command to the location pointer to by rdi
;al contains the LUN of the device we are accessing.
    mov ah, 03h        ;Move reqsense command value high
    shl al, 5        ;Shift left by five to align LUN properly
    xchg ah, al        ;swap ah and al
    stosw            ;Store command and shifted LUN together
    xor rax, rax    
    stosw            ;Reserved word
    mov al, 12h    ;Move alloc length byte into al
    stosq
    ret
.scsiTestUnitReady:
;Writes a scsi test unit ready command to the location pointed to by rdi
;al contains the LUN of the device we are accessing.
    xor ah, ah        ;Operation code zero
    shl al, 5
    xchg ah, al
    stosw            ;Store shifted LUN and command code
    ret
.scsiReadFormatCapacities:
;al contains the LUN of the device
    mov ah, al
    mov al, 23h        ;Operation code for command
    stosw            ;Store shifted LUN and command code
    xor rax, rax
    stosd          ;Reserved dword    
    stosw           ;Reserved word
    mov al, 0FCh    ;Move alloc length byte into al
    stosb
    ret
.scsiReadCap10:
;Writes a scsi read capacity command to the location pointed to by rdi
;al contains the LUN of the device we are accessing
    mov ah, 25h        ;Operation code for command
    shl al, 5
    xchg ah, al
    stosw            ;Store shifted LUN and command code
    ret
.scsiFormatUnit:
;Writes a scsi format unit command to the location pointed to by rdi
;al contains the LUN of the device we are accessing
    mov ah, 04h        ;Operation code for format command
    shl al, 5
    or al, 17h      ;Set bits [3:0] and 5, keep bit 4 clear
    xchg ah, al
    stosw
    xor al, al
    stosw            ;Vender specific, set to 0!!
    xor rax, rax
    stosq            ;Store LSB byte and all the 0 padding
    ret
.scsiVerify:
;Writes a scsi verify transfer command to the location pointed at by rdi
;al contains the LUN of the device we are accessing
;r12d contains the LBA for the sector address
;Verifies one sector
    mov ah, 2Fh        ;Operation code for command
    shl al, 5        ;Hardcode bytecheck (byte [1]) to 0
    xchg ah, al
    stosw            ;Store shifted LUN and command code
    bswap r12d        ;swap endianness of r12d
    mov eax, r12d
    stosd
    xor rax, rax    ;Clear for a Reserved byte
    stosb
    mov ax, 0100h    ;Write the number 1 in Big endian
    stosw
    shr eax, 16        ;Bring zeros down onto lower word
    stosw            ;Store one reserved byte and two padding bytes
    stosb        
    ret
.scsiModeSense6:
;al contains the LUN of the device we are accessing
    mov ah, 1Ah     ;Operation code for Mode Sense 6
    shl al, 5       ;Move LUN
    xchg ah, al
    stosw
    mov eax, 0C0003Fh    
    ;Request all pages, reserve byte, 192 bytes and 0 end byte
    stosd
    ret
;                    -------------------------------
.ehciGetOpBase:
;Gets opbase from mmio base (aka adds caplength) into eax
;Input:
; al = offset into ehci table
;Return:
; eax = opbase (low 4Gb)
    push rbx
    xor rbx, rbx
    movzx rax, al
    mov eax, dword [eControllerList + 4 + 8*rax]    ;get mmiobase into eax
    test eax, eax             ;addrress of 0 means no controller
    jz .egob1
    movzx ebx, byte [eax]    ;get the offset to opbase into ebx
    add eax, ebx            ;add this offset to mmiobase to get opbase
.egob1:
    pop rbx
    ret
