;----------------------------------------------------------------
;                End of Enum and Initialisation                 :
;----------------------------------------------------------------   
end:
;Finally, unmask all IRQ lines for usage
    xor al, al
    out pic2data, al
    out pic1data, al

    mov ax, 1304h
    mov rbp, dbgmsg
    int 30h
    mov al, byte [numMSD]
    mov ah, 04h
    int 30h

    mov ax, 1304h
    mov rbp, dbgmsg4
    int 30h
    mov al, byte [fdiskNum]
    mov ah, 04h
    int 30h

    mov ax, 1304h
    mov rbp, dbgmsg2
    int 30h
    mov al, byte [i33Devices]
    mov ah, 04h
    int 30h

    mov ax, 1304h
    mov rbp, dbgmsg3
    int 30h
    mov al, byte [numCOM]
    mov ah, 04h
    int 30h

    cmp byte [i33Devices], 0    ;If there are no i33 devices, skip bootstrap
    jz endNoDevFound

    int 39h             ;Bootstrap loader
endNoDevFound:
    mov rbp, endboot
    mov ax, 1304h
    int 30h
    
    xor ax, ax  ;Pause for any key
    int 36h

    mov bx, 0007h    ;cls attribs
    call cls

    xor cx, cx
    xor dx, dx
    mov ah, 2
    xor bh, bh
    int 30h 

    mov ax, 1304h
    mov rbp, endboot2
    int 30h

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rsi, rsi
    xor rdi, rdi
    xor rbp, rbp
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    int 38h


startboot:  db "Loading SCP/BIOS...", 0Ah, 0Dh, 0
endboot:    db    0Ah,0Dh,"SCP/BIOS system initialisation complete", 0Ah, 0Dh 
        db "No Operating System detected. Strike any key to launch SYSDEBUG."
            db "..",0Ah, 0Dh,0
endboot2:   db "Starting SCP/BIOS SYSDEBUG...",0Ah,0Dh,0
dbgmsg:     db 0Ah,0Ah,0Dh,"USB Rem. Devices: ",0
dbgmsg2:    db 0Ah,0Dh,"Int 33h Devices: ",0
dbgmsg3:    db 0Ah,0Dh,"COM Ports: ",0
dbgmsg4:    db 0Ah,0Dh,"ATA Fixed Devices: ", 0
memprint:
;Simple proc to print memory status
    xor bx, bx 
    mov rbp, .convmemmsg
    mov ax, 1304h
    int 30h
    int 32h    ;Get conv Size
    and eax, 0FFFFh ;Clear upper bits
    call .printdecimalword
    mov rbp, .kb
    mov ax, 1304h
    int 30h

    mov ax, 0E801h
    int 35h
    and eax, 0FFFFh
    and ebx, 0FFFFh
    and ecx, 0FFFFh
    and edx, 0FFFFh
    push rbx
    push rdx
    cmp rax, rcx
    je .sense1    ;Sensible
    test rax, rax
    cmovz rax, rcx
    test rax, rax
    jz .pt2
.sense1:
    push rax
    mov rbp, .extmemmsg
    mov ax, 1304h
    int 30h
    pop rax
    call .printdecimalword
    mov rbp, .kb
    mov ax, 1304h
    int 30h
.pt2:
    pop rax
    pop rcx
    cmp rax, rcx
    je .sense2    ;Sensible
    test rax, rax
    cmovz rax, rcx
    test rax, rax
    jz .pt3
.sense2:
    push rax
    mov rbp, .extmemmsg2
    mov ax, 1304h
    int 30h
    pop rax

    shl rax, 6    ;Turn 64Kb into Kb
    call .printdecimalword
    mov rbp, .kb
    mov ax, 1304h
    int 30h
.pt3:   ;Read total free size from big map
    push rax
    mov rbp, .totalmem
    mov eax, 1304h
    int 30h
    pop rax
    mov rax, qword [sysMem]
    xor ebx, ebx
    mov ebx, dword [scpSize]
    sub rax, rbx
    shr rax, 0Ah                ;Get number of Kb's free
    call .printdecimalword  
    mov rbp, .kb
    mov ax, 1304h
    int 30h

    mov eax, 0E0Ah
    int 30h
    mov eax, 0E0Dh   ;CR/LF
    int 30h

    ret

.printdecimalword:
;Takes the qword in rax and prints its decimal representation
    push rdx
    push rcx
    push rbx
    push rax
    push rbp
    xor rcx, rcx
    xor bp, bp    ;Use bp as #of digits counter
    mov rbx, 0Ah  ;Divide by 10
.pdw0:
    inc ebp
    shl rcx, 8    ;Space for next nybble
    xor edx, edx
    div rbx
    add dl, '0'
    cmp dl, '9'
    jbe .pdw1
    add dl, 'A'-'0'-10
.pdw1:
    mov cl, dl    ;Save remainder byte
    test rax, rax
    jnz .pdw0
.pdw2:
    mov al, cl    ;Get most sig digit into al
    shr rcx, 8    ;Get next digit down
    mov ah, 0Eh
    int 30h
    dec ebp
    jnz .pdw2

    pop rbp
    pop rax
    pop rbx
    pop rcx
    pop rdx
    ret
.convmemmsg:        db 0Ah,0Dh,"Free Conventional Memory: ",0
.extmemmsg:         db 0Ah,0Dh,"Total Low Extended Memory: ",0    
.extmemmsg2:        db 0Ah,0Dh,"Total High Extended Memory: ",0
.totalmem:          db 0Ah,0Dh,"Total Free System Memory: ",0
.kb:                db "K",0