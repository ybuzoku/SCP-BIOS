;-------------------Misc IO Interrupts Int 35h-------------------
;Misc features int that can be used for a variety of things.
;This will break compatibility with BIOS, since hopefully more 
; advanced features will be present.
;
; ah = 0 - 82h System Reserved
; ah = 83h -> Reserved, Event wait
; ah = 86h -> Delay rcx = # of milliseconds to wait
; ah = 88h -> Basic High Mem Map 1 (First 16MB only)
; ah = 89h to C4h - System Reserved
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ah = C5h - FFh BIOS device class dispatcher extensions
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ah = C5h -> Misc sys function dispatcher      (3 funct)
; ah = E8h -> Adv mem management sys dispatcher (4 funct)
; ah = F0h -> Sys data table dispatcher         (15 funct)
; ah = F1h -> EHCI system dispatcher            (4 funct)
;----------------------------------------------------------------
misc_io:
    cmp ah, 86h
    jb .badFunction
    jz .delay
    cmp ah, 88h
    jz .memory16MB

    cmp ah, 0C5h    ;Miscellaneous function dispatcher
    jz .miscDispatcher 
    cmp ah, 0E8h    ;Advanced memory management system dispatcher
    jz .advSysMemDispatcher
    cmp ah, 0F0h    ;System table dispatcher
    jz .sysDataTableDispatcher
    cmp ah, 0F1h    ;EHCI function dispatcher
    jz .ehciFunctionDispatcher
.badFunction:
    mov ah, 80h    ;Invalid Function
.badout:
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq

.delay:
;Input: rcx = milliseconds to wait (rcx < 7FFFFFFFFFFFFFFFh)
;Init IRQ 8, wait for loop to end, deactivate
    cli    ;NO INTERRUPTS
    test rcx, rcx
    jz .return  ;Can avoid sti since we return caller flags
    push rax
;Ensure PIC is saved
    in al, pic1data
    push rax    ;Save unaltered pic1 value
    and al, 0FBh ;Ensure Cascading pic1 line unmasked
    out pic1data, al

    in al, pic2data
    push rax    ;Save unaltered pic2 value
    and al, 0FEh ;Ensure line 0 of pic2 unmasked 
    out pic2data, al

    mov qword [rtc_ticks], rcx
    mov ax, 8B8Bh       
    out cmos_base, al   ;NMI disabled
    out waitp, al
    jmp short $+2
    in al, cmos_data
    and al, 7Fh    ;Clear upper bit
    or al, 40h    ;Set periodic interrupt bit
    xchg ah, al
    out cmos_base, al
    out waitp, al
    jmp short $+2
    xchg al, ah
    out cmos_data, al
    mov al, 0Dh     ;Read Register D and reenable NMI
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data  
    sti        ;Reenable interrupts
.loopdelay:
    pause ;allow an interrupt to occur
    cmp qword [rtc_ticks], 0        ;See if we at 0 yet
    jg .loopdelay    ;If not, keep looping
;Return CMOS to default state
    cli
    mov ax, 8B8Bh   ;NMI disabled
    out cmos_base, al
    out waitp, al
    jmp short $+2
    in al, cmos_data
    and al, 0Fh    ;Clear all upper 4 bits
    xchg ah, al
    out cmos_base, al
    out waitp, al
    jmp short $+2
    xchg ah, al
    out cmos_data, al
    mov al, 0Dh     ;Read Register D and reenable NMI
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data  

    pop rax ;Return pic2 value
    out pic2data, al
    pop rax    ;Return pic1 value
    out pic1data, al

    pop rax    ;Return rax value
    sti
.return:
    iretq
.memory16MB:    ;ah=88 function
    mov ax, word [srData1]
    iretq

.miscDispatcher:
; ax = C500h -> Beep PC speaker
; ax = C501h -> Connect Debugger 
; ax = C502h -> Disconnect Debugger
    test al, al     ;Play a tone using PC speaker
    jz .mdBeeper
    cmp al, 01h     ;Connect Debugger
    jz .mdConnectDebugger
    cmp al, 02h     ;Disconnect Debugger
    jz .mdDisconnectDebugger
    jmp .badFunction
.mdConnectDebugger:
    push rax
    push rbx
    push rdx
    push rsi
    mov edx, 8F00h
    mov ebx, codedescriptor
    mov rax, MCP_int.singleStepsEP  ;Pointer
    mov rsi, 01 ;Interrupt number, Single Step
    call idtWriteEntry
    mov rax, MCP_int.debugEp  ;Pointer
    mov rsi, 03 ;Interrupt number, Software Breakpoint
    call idtWriteEntry
    mov rax, MCP_int.debugEpHardware  ;Pointer
    mov rsi, 3Bh ;Interrupt number, Invoke debugger through hardware CTRL+BREAK
    call idtWriteEntry
    jmp short .mdDebugExit
.mdDisconnectDebugger:
    push rax
    push rbx
    push rdx
    push rsi
    mov edx, 8F00h
    mov ebx, codedescriptor
    mov rax, i1  ;Pointer
    mov rsi, 01 ;Interrupt number, Single Step
    call idtWriteEntry
    mov rax, i3  ;Pointer
    mov rsi, 03 ;Interrupt number, Software Breakpoint
    call idtWriteEntry
    mov rax, ctrlbreak_io  ;Pointer
    mov rsi, 3Bh ;Interrupt number, CTRL+Break
    call idtWriteEntry
.mdDebugExit:
    pop rsi
    pop rdx
    pop rbx
    pop rax
    iretq

.mdBeeper:
;Input: 
;   bx = Frequency divisor to use for tone
;   rcx = # of ms to beep for
; All registers including ax preserved
    call beep
    iretq

.advSysMemDispatcher:
; ax = E800h -> Return userBase pointer
; ax = E801h -> Give RAM count, minus the size of SCPBIOS, in ax, bx, cx, dx.
; ax = E802h -> Total RAM count (without SCP/BIOS)
; ax = E820h -> Full Memory Map, including entry for SCPBIOS
    test al, al
    jz .retUserBase
    cmp al, 01h
    je .memory64MB
    cmp al, 02h
    je .memoryBIOSseg
    cmp al, 20h
    je .fullMemoryMap
    jmp .badFunction

.retUserBase:
    mov rax, qword [userBase]
    iretq
.memory64MB:
    mov ax, word [srData]
    mov bx, word [srData + 2]
    mov cx, word [srData + 4]
    mov dx, word [srData + 6]
    iretq    
.memoryBIOSseg:
;This gives information about the SCP/BIOS segment
    mov rax, BIOSStartAddr  ;Start address of BIOS
    xor ebx, ebx
    mov ebx, dword [scpSize]    ;Total sum of segment sizes
    mov rdx, qword [sysMem]     ;Get total usable memory count
    sub rdx, rbx    ;Remove SCP/BIOS allocation from the size
    iretq

.fullMemoryMap:
    mov rax, qword [userBase]    ;Start space, returns userbase in r8
    mov rsi, bigmapptr
    mov cl, byte [bigmapSize]   ;Get the number of 24 byte entries
    xor ch, ch                  ;Reserve the upper byte
    iretq

.sysDataTableDispatcher:
; ax = F000h, Register new GDT ptr
; ax = F001h, Register new IDT ptr
; ax = F002h, Get Current GDT ptr
; ax = F003h, Get Current IDT ptr
; ax = F004h, Register New Page Tables
; ax = F005h, Get physical address of PTables
; ax = F006h, Get pointer to BIOS Data Area
; ax = F007h, Read IDT entry
; ax = F008h, Write IDT entry
; ax = F009h, Register new Disk Parameter Table
; ax = F00Ah, Get current DPT
; ax = F00Bh, Register new Fixed Disk Parameter Table
; ax = F00Ch, Get current fDPT
; ax = F00Dh, Register new SysInit parameters 
; ax = F00Eh, Get current SysInit parameters
    cmp al, 4h          
    jb .sdtDT           ;al = 00 - 03, goto sdtDT
    cmp al, 4           
    jz .sdtRegisterPage ;al = 04
    cmp al, 5
    jz .sdtGetPagePtr   ;al = 05
    cmp al, 6
    jz .sdtDataptr      ;al = 06
    cmp al, 7
    jz .sdtReadIDTEntry ;al = 07
    cmp al, 8
    jz .sdtWriteIDTEntry    ;al = 08
    cmp al, 9
    jz .sdtNewDDP       ;al = 09
    cmp al, 0Ah
    jz .sdtReadDDP      ;al = 0A
    cmp al, 0Bh         
    jz .sdtNewfDDP      ;al = 0Bh
    cmp al, 0Ch
    jz .sdtReadfDDP     ;al = 0Ch
    cmp al, 0Dh
    jz .sdtNewSysInit   ;al = 0Dh
    cmp al, 0Eh
    jz .sdtReadSysInit  ;al = 0Eh
    jmp .badFunction

.sdtDT:
;sys data tables Descriptor Table dispatcher
;rbx has/will have I/GDT base pointer (qword)
;ecx has/will have I/GDT limit (word)
;edx has/will have Number of entries in I/GDT (word)
    push rdi
    push rsi
    mov rdi, GDTlength
    mov rsi, IDTlength
    test al, 1  ;If al[0] = 1, want rdi to point to IDT area
    cmovnz rdi, rsi ;If al[0] = 0, rdi will keep pointing to GDT
    test al, 2  ;If bit 2 is set, Get pointers
    jnz .sdtGet
    mov word [rdi], dx
    mov word [rdi + 2], cx
    mov qword [rdi + 4], rbx
    push rsi
    pop rdi
    iretq
.sdtGet:
    movzx edx, word [rdi]
    movzx ecx, word [rdi + 2]
    mov rbx, qword [rdi + 4]
    push rsi
    pop rdi
    iretq
.sdtRegisterPage:
    mov qword [pageTablePtr], rbx   ;Registers pointer as new table space
    iretq
.sdtGetPagePtr:
    mov rbx, qword [pageTablePtr]  ;Return BIOS Page Table ptr
    iretq
.sdtDataptr:
    mov rbx, section.data.start        ;Get BIOS Data area ptr into rax
    iretq
.sdtReadIDTEntry:
;bx = Number of interrupt handler (00h-0FFFFh), uses only bl
;Returns pointer in rbx, 
;Segment selector in ax,
;Attribute word in dx
    movzx rbx, bl
    mov rdx, qword [IDTpointer.Base]    ;Get base address
    shl rbx, 4h         ;Multiply address number by 16
    add rdx, rbx        ;rdx point to IDT entry
    mov eax, dword [rdx + 8]
    shl rax, 20h        ;Shift dword into upper dword
    mov bx, word [rdx + 6]
    shl ebx, 10h        ;Shift word into upper word
    mov bx, word [rdx]  ;Get final word
    or rbx, rax         ;Add upper dword to rbx
    mov ax, word [rdx + 2]  ;Get Segment selector in ax
    mov dx, word [rdx + 4]  ;Get attributes word
    iretq
.sdtWriteIDTEntry:
;rbx = Pointer to new routine
;cx = Number of the interrupt handler (00h-0FFFFh), uses only cl
;dx = IDT entry attributes
;si = Segment selector
    push rax
    push rcx
    push rsi
    push rbx
    mov rax, rbx    ;Move pointer to new routine to rax
    mov ebx, esi    ;Move Segment selector from si to bx 
    movzx rsi, cl   ;Movzx low byte of interrupt number into rsi
    call idtWriteEntry
    pop rbx
    pop rsi
    pop rcx
    pop rax
    iretq
.sdtNewDDP:
    mov qword [diskDptPtr], rbx
    iretq
.sdtNewfDDP:
    mov qword [fdiskDptPtr], rbx
    iretq
.sdtReadDDP:
    mov rbx, qword [diskDptPtr]
    iretq
.sdtReadfDDP:
    mov rbx, qword [fdiskDptPtr]
    iretq
.sdtNewSysInit:
    mov qword [nextFilePtr], rbx
    mov word [numSectors], dx
    iretq
.sdtReadSysInit:
    mov rbx, qword [nextFilePtr]
    mov dx, word [numSectors]
    iretq
.ehciFunctionDispatcher:
;EHCI function dispatcher 0F1h
; al = 00h -> EHCI get crit error handler
; al = 01h -> EHCI set crit error handler
; al = 02h -> Reserved, reset selected EHCI controller
; al = 03h -> Reserved, re-enumerate devices downstream of EHCI Root hub
    test al, al
    jz .ehciDispGetCritPtr
    dec al
    jz .ehciDispSetCritPtr
    dec al
    jz .ehciDispResetCtrlr
    dec al
    jz .echiDispReEnumDevices
    jmp .badFunction

.ehciDispGetCritPtr:
;Gets the address of the current EHCI critical error handler into rbx
    mov rbx, qword [eHCErrorHandler]
    iretq
.ehciDispSetCritPtr:
;Sets the address of the EHCI critical error handler to the ptr in rbx
    mov qword [eHCErrorHandler], rbx
    iretq
.ehciDispResetCtrlr:
.echiDispReEnumDevices:
    mov ah, 86h     ;Unsupported function call
    jmp .badout  
;------------------------End of Interrupt------------------------