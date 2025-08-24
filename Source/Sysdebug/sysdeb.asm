;---------------------MCP Interrupt Int 38h----------------------
;This interrupt superceeds the IBM BASIC routine caller. 
;This is a 64 bit port of my 16 bit MCP monitor program, 
; allowing users to "interactively" get sectors from devices 
; and run them. I might add some nicities to this version of MCP 
; such as a function to list all devices.
;----------------------------------------------------------------
MCPjmptbl:  ;Function jump table
    dq MCP_int.dumpMemory      ;Dump
    dq MCP_int.editMemory      ;Edit
    dq MCP_int.singleStep      ;Single step
    dq MCP_int.jumpProc        ;Go
    dq MCP_int.proceedDefault  ;Proceed
    dq MCP_int.storageRead     ;Load
    dq MCP_int.storageWrite    ;Write
    dq MCP_int.restartMcp      ;Quit   <- To call Int 40h for DOS compatibility
    dq MCP_int.clearscreen     ;Clear screen
    dq MCP_int.xchangeReg      ;Registers
    dq MCP_int.debugRegs       ;Breakpoints
    dq MCP_int.hexCalc         ;Hex
    dq MCP_int.inport          ;In
    dq MCP_int.outport         ;Out
    dq MCP_int.version         ;Version
    dq MCP_int.singleStep      ;Single Step (Alt), temp
    dq MCP_int.memoryMap       ;Print memory map
    dq MCP_int.connect         ;Connect Debugger
    dq MCP_int.disconnect      ;Disconnect Debugger
MCP_int:
    ;Entry point from external programs
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters    ;Save main registers
.z11:
    mov rsp, qword [mcpStackPtr]  ;Point sp to new stack
    mov eax, 1304h    ;Zero extends to rax
    mov rbp, .prompt
    xor bh, bh
    int 30h
.z2:
    xor ax, ax 
    int 36h
    cmp al, 08h        ;If backspace, ignore
    je .z2
    call .print        ;Print input char
    std
    mov rdi, .prompt    ;end of lst is prompt
    mov rcx, .lstl + 1
    repne scasb
    cld
    jne .bad_command    ;Char not found!
.prog_sel:    ;Choose program
    push MCP_int.z11    ;to allow RETurning to application
    jmp qword [MCPjmptbl + 8*rcx]    ;Jump to chosen function         
.memoryMap:
    mov ax,0E0Ah
    int 30h
    mov ax, 0E0Dh
    int 30h
    call e820print  ;Print memory map
    jmp .z11
.singleStepsEP:
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters
    mov rax, qword [rsp]    ;Get next instruction address
    mov qword [mcpUserRip], rax
    call .dumpReg    ;Show register state
    call .dumpDebugRegs
    sti ;Restore interrupts
    jmp .z11
.debugEpHardware:
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters
    sti ;Restore interrupts
    mov al, EOI
    out pic1command, al
    jmp short .dep1
.debugEp:    
;Return here after a single step or int 3. 
;Support Int 3h thru manual encoding only, not via the debugger
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters
    sti ;Restore interrupts
.dep1:
    mov rax, qword [rsp]    ;Get next instruction address
    mov qword [mcpUserRip], rax
    call .dumpReg    ;Show register state
    call .dumpDebugRegs
    jmp .z11
.bad_command:
    mov rax, 1304h
    xor bh, bh
    mov rbp, .bc1
    int 30h
    jmp MCP_int.z11
.bc1: db 0Ah,0Dh," ^ Error",0
;><><><><><><><-Internal Commands Begin Here-><><><><><><><
.connect:
    push rax
    push rbp
    mov eax, 0C501h ;Connect Debugger
    int 35h
    mov eax, 1304h
    mov rbp, .connectString
    int 30h
    pop rbp
    pop rax
    ret
.connectString db 0Ah,0Dh,"SYSDEBUG Connected",0
.disconnect:
    push rax
    push rbp
    mov eax, 0C502h ;Disconnect Debugger
    int 35h
    mov eax, 1304h
    mov rbp, .disconnectString
    int 30h
    pop rbp
    pop rax
    ret
.disconnectString db 0Ah,0Dh,"SYSDEBUG Disconnected",0
.version:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .vstring
    int 30h
    mov rsi, signature + 1    ;Point to BIOS signature string (skip the v char)
.v1:
    lodsb
    cmp al, 20h            ;Check space
    je .v2
    mov ah, 0Eh
    ;xor bh, bh
    int 30h
    jmp short .v1
.v2:
    ret
.vstring:    db 0Ah, 0Dh,"SCP/BIOS SYSDEBUG Version ",0
.debugRegs:
    call .dumpDebugRegs
    mov ax, 1304h
    mov rbp, .crlf    ;Newline
    int 30h

    mov ax, 0E2Eh    ;Print dot byte
    int 30h

    mov ax, 0101h    ;Process one byte
    call .keyb
    test rbp, rbp
    jz .z11    ;If enter pressed, return to command line
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rdi, qword [rbp]
    cmp rdi, 4
    jb .xr11    ;Cant edit dr4, or 5. dr6 is read only
    cmp rdi, 7  ;Can only edit 7
    jne .bad_command
    dec rdi     ;Is the fifth entry in the table
    dec rdi
.xr11:
    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h

    push rdi    ;Save rdi
    shl rdi, 2    ;Multiply by 4
    mov cx, 4    ;4 chars to print
.xr1:   ;Print register name
    mov al, byte [.dregtbl + rdi]
    mov ah, 0Eh
    int 30h
    inc di
    dec cx
    jnz .xr1
;Get the qword into the keybuffer
    pop rdi
    mov ax, 0401h    ;Process one qword
    call .keyb
    test rbp, rbp
    jz .xcnoexit
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rax, qword [rbp]    ;rax has the replacement value
    test rdi, rdi
    jnz .xr2
    mov dr0, rax
    ret
.xr2:
    dec rdi
    jnz .xr3
    mov dr1, rax
    ret
.xr3:
    dec rdi
    jnz .xr4
    mov dr2, rax
    ret
.xr4:
    dec rdi
    jnz .xr5
    mov dr3, rax
    ret
.xr5:
    mov dr7, rax
    ret

.dumpDebugRegs:
    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h
    xor rbp, rbp
    xor rdi, rdi

    mov rax, dr7
    push rax
    mov rax, dr6
    push rax
    mov rax, dr3
    push rax
    mov rax, dr2
    push rax
    mov rax, dr1
    push rax
    mov rax, dr0
    push rax

.ddr1:
    xor rcx, rcx
    cmp rdi, 3      ;3 registers per row
    je .dregcrlf
.ddr11:
    mov al, byte [.dregtbl + rbp + rcx]
    mov ah, 0Eh
    int 30h
    inc cx
    cmp cx, 4
    jnz .ddr11

    mov rcx, 8
.ddr2:
    pop rbx    ;Get debug register
    bswap rbx
.ddr21:
    mov ah, 04h
    mov al, bl
    int 30h
    shr rbx, 8h
    dec cl
    jnz .ddr21
    inc rdi

    mov ah, 3
    int 30h
    add dl, 3
    mov ah, 2
    int 30h
    add rbp, 4
    cmp rbp, 24 ;number of chars in the below typed string
    jb .ddr1

    ret
.dregcrlf:
    xor rdi, rdi
    push rbp
    push rax
    push rbx
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    pop rbx
    pop rax
    pop rbp
    jmp .ddr11
.dregtbl db "DR0=", "DR1=", "DR2=", "DR3=", "DR6=", "DR7="

.xchangeReg:
    call .dumpReg
    mov ax, 1304h
    mov rbp, .crlf    ;Newline
    int 30h

    mov ax, 0E2Eh    ;Print dot byte
    int 30h

    mov ax, 0101h    ;Process one byte
    call .keyb
    test rbp, rbp
    jz .z11    ;If enter pressed, return to command line
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rdi, qword [rbp]    ;move this byte into rdi
    cmp rdi, 11h
    ja .bad_command    ;If the user chooses a value greater than 11, exit!

    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h

    cmp rdi, 11h
    je .xcflags ;If the user typed 10, then xchange flags

    push rdi    ;Save rdi
    shl rdi, 2    ;Multiply by 4
    mov cx, 4    ;4 chars to print
.xcr1:
    mov al, byte [.regtbl + rdi]
    mov ah, 0Eh
    int 30h
    inc di
    dec cx
    jnz .xcr1

    pop rdi
    mov ax, 0401h    ;Process one qword
    call .keyb
    test rbp, rbp
    jz .xcnoexit
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rax, qword [rbp]
    cmp rdi, 10h
    je .xcipchange
    mov rbx, qword [mcpUserBase]
    add rbx, 80h
    shl rdi, 3  ;Multiply by 8
    sub rbx, rdi
    mov qword [rbx], rax    ;Replace element with rax
.xcnoexit:
    ret
.xcipchange:
    mov qword [mcpUserRip], rax
    ret
.xcflags:
    mov rcx, 7
    xor rdi, rdi
.xcf1:
    mov al, byte [.rflgs + rdi]
    mov ah, 0Eh
    int 30h
    inc di
    dec cx
    jnz .xcf1

    mov ax, 0401h    ;Process one qword
    call .keyb
    test rbp, rbp
    jz .xcnoexit
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rax, qword [rbp]
    mov rbp, qword [mcpUserBase]
    mov qword [rbp], rax
    ret
.inport:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h

    mov ax, 0101h    ;Get 1 byte
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rdx, qword [rbp]    ;First arg, word io addr
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    in al, dx
    mov ah, 04h
    int 30h
    ret

.outport:
    mov ax, 1304h
    mov rbx, 7h
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0201h    ;Get 1 word
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rdx, qword [rbp]    ;First arg, word io addr
    mov al, "."
    call .print
    mov ax, 0101h    ;Get 1 byte
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rax, qword [rbp]
    out dx, al
    ret

.hexCalc:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0402h    ;Get 2 qwords
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg

    cmp al, 2
    jne .dmbadexit

    mov r8, qword [rbp + 8] ;First number 
    mov r9, qword [rbp]        ;Second number
    lea r10, qword [r8+r9]

    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h

    mov rdx, r8
    call .hcprintquad
    mov al, "+"
    call .print
    mov rdx, r9
    call .hcprintquad
    mov al, "="
    call .print
    mov rdx, r10
    call .hcprintquad

    mov rax, 1304h
    xor bh, bh
    int 30h

    mov rdx, r8
    call .hcprintquad
    mov al, "-"
    call .print
    mov rdx, r9
    call .hcprintquad
    mov al, "="
    call .print
    sub r8, r9
    mov rdx, r8
    call .hcprintquad
    ret

.hcprintquad:
;Takes whats in rdx, and prints it
    bswap rdx
    mov rcx, 8
.hcpq1:
    mov al, dl
    mov ah, 04h
    int 30h
    shr rdx, 8
    dec cx
    jnz .hcpq1
    ret

.dumpReg:
    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h
    xor rbp, rbp
    xor rdi, rdi
    xor rsi, rsi
    mov rsi, qword [mcpUserBase]
    add rsi, 80h
.dreg1:
    xor rcx, rcx
    cmp rdi, 3
    je .regcrlf
.dreg11:    ;Print register name
    mov al, byte [.regtbl+rbp+rcx]
    mov ah, 0Eh
    int 30h
    inc cx
    cmp cx, 4h
    jnz .dreg11
.dreg2:
    mov rcx, 8h
;Now print register value
    mov rbx, qword [rsi]    ;Get qword from storage
    sub esi, 8
    bswap rbx    ;Change endianness
.dreg21:
    mov ah, 04h
    mov al, bl
    int 30h
    shr rbx, 8h    ;Shift down by a byte
    dec cl
    jnz .dreg21
    inc rdi

    mov ah, 3
    int 30h
    add dl, 3
    mov ah, 2
    int 30h
    add rbp, 4
    cmp rbp, 40h
    jb .dreg1

;Print RIP
.drip0:
    xor rcx, rcx
.drip1:
;Print name
    mov al, byte [.regtbl+rbp+rcx]
    mov ah, 0Eh
    int 30h
    inc cx
    cmp cx, 4h
    jne .drip1

    mov rcx, 8
    mov rsi, qword [mcpUserRip]
    bswap rsi
.drip2:
;Print value
    mov ah, 04h
    mov al, sil
    int 30h
    shr rsi, 8h    ;Shift down by a byte
    dec cl
    jnz .drip2
    add rbp, 4    ;Offset into table

    push rbp
    mov rbp, .ipstrg
    mov ax, 1304h
    int 30h    
    mov cl, 7
    mov rax, qword [mcpUserBase]
    mov rax, qword [rax + 08h]  ;Get the old stack pointer
    mov rbx, qword [rax]    ;Get the address of 8 bytes at that instruction
    mov rbx, qword [rbx]    ;Get the bytes
    mov al, bl
    mov ah, 04h
    int 30h
    shr rbx, 8
    mov ah, 0Eh   ;Add a space to indicate mod r/m + optionals
    mov al, '-'
    int 30h
.ssep0:
    mov al, bl
    mov ah, 04h
    int 30h
    shr rbx, 8
    dec cl
    jnz .ssep0

    mov rbp, .crlf
    mov rax, 1304h
    mov rbx, 7h
    int 30h
    pop rbp

    mov ax, cs
    call .dsegregwrite
    mov ax, ds
    call .dsegregwrite
    mov ax, es
    call .dsegregwrite
    mov ax, ss
    call .dsegregwrite
    mov ax, fs
    call .dsegregwrite
    mov ax, gs
    call .dsegregwrite

    push rbp
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    pop rbp
.drflagwrite:
    xor rcx, rcx
.drflg1:    ;Print register name
    mov al, byte [.regtbl+rbp+rcx]
    mov ah, 0Eh
    int 30h
    inc rcx
    cmp rcx, 7
    jnz .drflg1

    inc rcx
    mov rdx, qword [mcpUserBase]    ;Get flags into rdx
    mov rdx, qword [rdx]
    bswap rdx
.drflg2:
    mov ah, 04h
    mov al, dl
    int 30h
    shr rdx, 8
    dec rcx
    jnz .drflg2

.dregexit:
    ret
.dsegregwrite:
    xor rcx, rcx
    mov dx, ax    ;save
.dsegreg1:    ;Print register name
    mov al, byte [.regtbl+rbp+rcx]
    ;xor bh, bh
    mov ah, 0Eh
    int 30h
    inc rcx
    cmp rcx, 3
    jnz .dsegreg1

    mov al, dh
    mov ah, 04h
    int 30h
    mov al, dl
    mov ah, 04h
    int 30h

    add rbp, rcx
    mov ah, 3
    int 30h
    add dl, 2
    mov ah, 2
    int 30h
    ret

.regcrlf:
    xor rdi, rdi
    push rbp
    push rax
    push rbx
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    pop rbx
    pop rax
    pop rbp
    jmp .dreg11

.regtbl  db "RAX=", "RBX=", "RCX=", "RDX=", "RSI=", "RDI=", "R8 =",
         db "R9 =", "R10=", "R11=", "R12=", "R13=", "R14=", "R15=",
         db "RBP=", "RSP=", "RIP=","CS=", "DS=", "ES=", "SS=", "FS=", 
         db "GS="
.rflgs   db "RFLAGS="
.ipstrg: db "  [RIP]=",0
.dumpMemory:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push rbp
    push r8
    push r9

    mov ax, 1304h
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0402h    ;Get 2 dwords
    call .keyb
    test rbp, rbp
    jz .dmnoargs
    mov al, 2    ;Number of user inputs to convert
    call .arg
    dec al
    jz .dmnoargs1
    dec al    ;More than 2 args, error
    jnz .dmbadexit
    mov r8, qword [rbp + 8]    ;First argument, #Base
    mov r9, qword [rbp]    ;Second argument, #Number of bytes
.dmmain00:
    test r9, r9
    jz .dmbadexit
    mov ax, 1304h
    mov rbp, .crlf
    int 30h
    mov rdx, r8
    call .dmcsaddrprint
    ;xor bh, bh
    mov bh, byte [scr_active_page]
    mov ah, 03h
    int 30h
    mov dl, 25
    mov ah, 02h
    int 30h
    mov rsi, r8    ;point rsi at r8
    test rsi, 08h    ;If it starts between a qword and para

    test rsi, 0Fh
    jz .dmmain0    ;If it starts on paragraph bndry, continue as normal
    push rsi
    and rsi, 0Fh
    cmp rsi, 8
    jb .dmmain01
    mov rcx, 1
    call .dmal1    ;Print one space
.dmmain01:
    pop rsi
    mov rax, 1
    call .dmalign

.dmmain0:
    mov rdi, rsi    ;Save start point at rdi
    push r9
.dmmain1:    ;This loop prints a line
    lodsb
    mov ah, 4h
    int 30h
    dec r9
    jz .dmmain2
    test rsi, 08h    ;This is zero iff rsi has bit 4 set
    jnz .dmhyphen1
    test rsi, 0Fh    ;This is zero iff lower nybble is zero
    jnz .dmmain1
.dmmain2:
;Now the numbers have been printed, get the ascii row too
;First check if numbers have stopped short of 16
    test r9, r9
    jnz .dmmain21    ;end of row

.dmmain21:
    pop r9
    ;xor bh, bh
    mov bh, byte [scr_active_page]
    mov ah, 03h
    int 30h
    mov dl, 62
    mov ah, 02h
    int 30h
    mov rsi, rdi    ;Reload value
    test rsi, 0Fh
    jz .dmmain3    ;If it starts on paragraph bndry, continue as normal
    xor rax, rax    ;no shift
    call .dmalign

.dmmain3:
    lodsb
    dec r9
    cmp al, 30h
    cmovb ax, word [.dmdot]    ;bring the dot to ax
    mov ah, 0Eh
    int 30h
    test r9, r9
    jz .dmexit
    test rsi, 0Fh    ;Check if lower nybble is 0
    jnz .dmmain3

    mov rbp, .crlf
    mov ax, 1304h
    int 30h

    mov rdx, rsi
    call .dmcsaddrprint

    mov ah, 03h
    ;xor bh, bh
    mov bh, byte [scr_active_page]
    int 30h
    mov dl, 25
    mov ah, 02h
    int 30h
    jmp .dmmain0

.dmbadexit:
    mov rbp, .dmbadargs
    mov ax, 1304h
    int 30h
    ret;Reload program, error!
.dmexit:
    pop r9
    pop r8
    pop rbp
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
.dmnoargs:
    mov r8, qword [mcpUserRip]
    ;add r8, 180h    ;Add 180 bytes, to bypass internal work areas
    jmp short .dmnoargscommon
.dmnoargs1:
    mov r8, qword [rbp]
.dmnoargscommon:
    mov r9, 80h
    jmp .dmmain00

.dmalign:    ;Print blank chars for offset
;Works out from rsi
;rax contains value for shl
    push rsi
    mov rcx, rsi
    and rcx, 0FFFFFFFFFFFFFFF0h    ;Round down
    sub rsi, rcx
    xchg rcx, rsi
    pop rsi
    xchg rcx, rax
    shl rax, cl
    xchg rcx, rax
.dmal1:
    mov ax, 0E20h
    int 30h
    dec rcx
    jnz .dmal1
    ret

.dmhyphen1:
    test rsi, 07h    ;If the rest of the bits are set, go away
    jnz .dmmain1
    mov ax, 0E2Dh    ;2dh="-"
    int 30h
    jmp .dmmain1
.dmcsaddrprint:
    mov ax, cs    ;Get current code segment into ax
    mov al, ah
    mov ah, 04h    ;print upper byte
    int 30h
    mov ax, cs
    mov ah, 04h
    int 30h        ;print lower byte
    mov ax, 0E3Ah

    mov cl, 8
    int 30h

.dmrollprint:
;Takes whats in rdx, rols left by one byte, prints al
;repeats, cl times.
    rol rdx, 8
    mov al, dl
    mov ah, 04h
    int 30h
    dec cl
    jnz .dmrollprint
    ret
.dmdot:    db    ".",0
.dmbadargs:    db 0Ah, 0Dh,"Syntax error",0

.editMemory:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h

    mov ax, 0401h    ;Get up to one qword
    call .keyb
    test rbp, rbp        ;No chars entered?
    jz .bad_command
    call .arg
    mov rdi, qword [rbp]    ;First arg, Dword Address 

    mov rbp, .crlf
    xor bh, bh
    mov rax, 1304h
    int 30h
    
    mov rsi, rdi
    lodsb    ;Get byte into al
    mov ah, 04
    int 30h
    mov al, "."
    call .print
    mov ax, 0101h    ;Get 1 byte
    call .keyb
    test rbp, rbp        ;No chars entered?
    jz .dmbadexit
    call .arg
    mov rsi, rbp    ;Point rsi to the stack
    movsb            ;Move byte from rsi to rdi

    ret

.jumpProc:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0401h    ;Get 1 dword (forbit going too high eh?)
    call .keyb
    test rbp, rbp        ;No chars entered?
    jz .proceedDefault
    call .arg
    dec al
    jnz .dmbadexit
    mov rbp, qword [rbp]    ;First argument, Address of procedure
    mov qword [mcpUserRip], rbp   ;Move first argument into new Rip  
    call .loadMainRegisters
    mov rsp, qword [rax + 08h]
    mov rax, qword [mcpUserRaxStore]
    iretq
.singleStep:
;When s is pressed, the program proceeds by a single step.
;Sets trap flag on
    mov rax, qword [mcpUserBase]
    or qword [rax + 00h], 100h  ;Set trap flag on
.proceedDefault:
    call .loadMainRegisters
    mov rsp, qword [rax + 08h]
    mov rax, qword [mcpUserRaxStore]
    iretq

.storageRead:
    push rax
    mov eax, 8200h ;LBA Read function
    jmp short .storageCommon
.storageWrite:
    push rax
    mov eax, 8300h ;LBA Write function
.storageCommon:
;l/w [Address Buffer] [Drive] [Sector] [Count]
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp

    mov esi, eax        ;Save LBA r/w function number in esi
    mov ax, 1304h
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h

    mov ax, 0404h    ;Get 4 qwords
    call .keyb
    test rbp, rbp
    jz .storageError
    mov al, 4    ;Number of user inputs to convert
    call .arg
    cmp al, 4   ;If not 4 arguments, fail
    jne .storageError
    mov edi, 5
.sc0:
    mov eax, esi                ;Get back LBA r/w function number into eax
    mov rbx, qword [rbp + 24]   ;First argument, Address buffer
    mov rdx, qword [rbp + 16]   ;dl ONLY, Second argument
    and rdx, 0FFh
    mov rcx, qword [rbp + 08]   ;LBA starting sector, third argument
    mov rsi, qword [rbp]        ;Sector count into rsi
    and rsi, 0FFh               ;Sector count can be at most 255
    or eax, esi                 ;Add the sector count to eax
    mov esi, eax                ;Copy the function number into esi for failures
    and esi, 0FF00h             ;Save only byte two of esi, the function number
    int 33h
    jnc .storageExit

    xor eax, eax
    int 33h
    dec edi
    jnz .sc0
.storageExit:
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax   
    jmp MCP_int.z11
.storageError: 
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    jmp .bad_command
.restartMcp:
    int 40h     ;To allow returning to DOS
.clearscreen:
    mov bl, 07h
    call cls
    jmp MCP_int.z11
.storeMainRegisters:
    pushfq
    pop qword [rax + 00h]      ;Flags
    ;mov qword [rax + 08h], rsp
    mov qword [rax + 10h], rbp
    mov qword [rax + 18h], r15
    mov qword [rax + 20h], r14
    mov qword [rax + 28h], r13
    mov qword [rax + 30h], r12
    mov qword [rax + 38h], r11
    mov qword [rax + 40h], r10
    mov qword [rax + 48h], r9
    mov qword [rax + 50h], r8
    mov qword [rax + 58h], rdi
    mov qword [rax + 60h], rsi
    mov qword [rax + 68h], rdx
    mov qword [rax + 70h], rcx
    mov qword [rax + 78h], rbx
    mov rbx, qword [mcpUserRaxStore]
    mov qword [rax + 80h], rbx  ;Store rax
    ret
.loadMainRegisters:
    mov rax, qword [mcpUserBase]
    mov rdx, qword [rax + 08h]  ;Get old stack pointer into rdx
    mov rbx, qword [mcpUserRip]
    mov qword [rdx], rbx    ;Move the userRip into rdx
    mov rbx, qword [rax + 00h]
    mov qword [rdx + 10h], rbx  ;Move new flags into position on stack
    mov rbx, qword [rax + 80h]  ;Get rax
    mov qword [mcpUserRaxStore], rbx
    mov rbx, qword [rax + 78h]
    mov rcx, qword [rax + 70h]
    mov rdx, qword [rax + 68h]
    mov rsi, qword [rax + 60h]
    mov rdi, qword [rax + 58h]
    mov r8,  qword [rax + 50h]
    mov r9,  qword [rax + 48h]
    mov r10, qword [rax + 40h]
    mov r11, qword [rax + 38h]
    mov r12, qword [rax + 30h]
    mov r13, qword [rax + 28h]
    mov r14, qword [rax + 20h]
    mov r15, qword [rax + 18h]
    mov rbp, qword [rax + 10h]
    ret
;ARG    PROC    NEAR
.arg:
;Number of arguments expected in buffer in al (could early terminate due to 
; enter)
;Converted qwords stored on stack with al indicating how many processed
;rbp returns the base of the stack of stored arguments
;rdx is our scratch register
    push rbx
    push rcx
    push rdx
    push rsi
    mov rbp, rsp    ;Preserve stack pointer
    mov rsi, qword [mcpUserkeybf]
    xor cl, cl        ;Keep track of how many arguments processed
.a01:
    xor rdx, rdx    ;Clean rdx
.a1:
    lodsb        ;Get the first byte into al
    cmp al, 11h    ;Offset 11h is the space key
    jz .a2
    cmp al, 12h    ;Offset 12h is the enter key
    jz .aexit        ;Anyway, enter is exit!
    shl rdx, 4    ;Go to next sig fig
    or dl, al    ;Put this byte into dl
    jo .error
    jmp short .a1
.a2:
    push rdx    ;Store argument on stack
    inc cl        ;One more argument processed
    jmp short .a01
.aexit:
    movzx rax, cl    ;Return #of args processed
    xchg rsp, rbp    ;rbp points to bottom of argument stack 
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
.error:
    mov rbp, .emsg
    xor bh, bh
    mov ax, 1304h
    int 30h
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
.emsg:    db 0Ah, 0Dh,"Argument error",0
;ARG    ENDP

;KEYB     PROC     NEAR
.keyb:
;Number of arguments to accept is passed in al, in units of ah
;ah=4 => Qwords, ah=3 => dwords... ah=2 => word, ah=1 => bytes
;Arguments are stored in buffer, after USB area, of size 2*al qwords
;All arguments CAN be up to qword in size, though not all subprogs,
;    may use the full qword.
;ch returns number of chars not processed
    push rax
    push rbx
    ;push rcx
    push rdi
    push rdx

    xor rcx, rcx
    mov cl, al
    push rcx
    mov cl, ah
    shl al, cl  ;Multiply by 16 to get the number of bytes needed w/o spaces
    pop rcx
    add al, cl  ;Add space for spaces
    dec al      ;We reserve one space for a "non-user accessible" EOL at the end

    mov rdi, qword [mcpUserkeybf]    ;Data area in command tail
    push rax
    mov rax, 10h
    push rdi
    rep stosq    ;Clear buffer space for al qwords (max 8)
    pop rdi
    pop rax

    mov ch, al    ;Rememebr 1 Qword is 16 ASCII chars
    mov dl, al    ;Let dl save this number
    xor rbp, rbp    ;Cheap cop out char counter

.k1:
    xor ax, ax
    int 36h
    cmp al, "q"    ;Quit option
    je .z11
    cmp al, 08h    ;Backspace
    je .kb2
    cmp al, 0Dh    ;Enter key pressed, we done
    je .kend

    test ch, ch    ;Have we filled a 16 char buffer?
    jz .k1        ;Yes, await control key

    mov rbx, rdi    ;Save current offset into bbuffer
    push rcx
    mov rdi, .ascii
    mov rcx, .asciil
    repne scasb        ;Find the offset of the char in al in the table
    pop rcx            ;Doesnt affect flags
    xchg rdi, rbx    ;Return value back to rdi 
    jne .k1            ;Not a key from our buffer, loop again
    inc rbp
    call .print        ;Print typed char

    lea rax, qword [rbx - .ascii -1]    ;Work out difference

    stosb            ;Store the value in storage buffer, inc rdi
    dec ch            ;Decrement the number of typable chars
    jmp short .k1    ;Get next char
.kend:
    mov ax, 1211h    ;Store a space and EOF at the end (little endian!)
    stosw

    pop rdx
    pop rdi
    ;pop rcx    ;Return in cl the number of processed chars
    pop rbx
    pop rax
.kb1:        
    ret
.kb2:
;When a backspace is entered, DONT MOVE THIS PROC!
    push .k1
    cmp ch, dl    ;If bbuf is empty, ignore backspace 
    jz .kb1
    dec rdi        ;Decrement pointer and print the bspace char
    inc ch        ;Increment the number of typable chars
    test rbp, rbp
    jz .print    ;Dont decrement if rbp is zero
    dec rbp
;KEYB    ENDP
.print:    ;Print char in al
    mov ah, 0Eh
    ;xor bh, bh
    int 30h
    ret
.ascii       db    "0123456789abcdef", 08h, 20h, 0Dh ;b/space, enter
.asciil       equ    $ - .ascii
.lst       db    'desgplwqcrbhiovamkx';dump,edit,go,single step,read,write,quit,
;clearscreen,registers,deBug regs,hex,in,out,version,Single Step alt, memory map
; (k)connect, dixonnect
.lstl    equ    $ - .lst
.prompt       db    0Ah, 0Dh, "-", 0    ;3Eh = >
.prompt2    db 20h,0
.crlf       db    0Ah, 0Dh, 0
;------------------------End of Interrupt------------------------