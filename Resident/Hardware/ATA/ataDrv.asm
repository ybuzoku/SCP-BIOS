;ATA driver!
ATA:
.identifyDevice:
;dx should contain the base register
;al should contain either A0/B0 for master/slave
;rdi points to the buffer
;Carry set if failed.
    xchg bx, bx
    push rax
    push rbx
    mov bl, al            ;save the master/slave bit temporarily
    add edx, 7            ;dx at base + 7
.l1:
    in al, dx             ;Check for float
    cmp al, 0FFh
    je .exitfail
    test al, 10000000b
    jnz .l1

    jmp short $ + 2            ;IO cycle kill
    cli
    
    xor al, al
    sub edx, 5            ;dx at base + 2
    out dx, al
    inc edx               ;dx at base + 3
    out dx, al
    inc edx               ;dx at base + 4
    out dx, al
    inc edx               ;dx at base + 5
    out dx, al
    inc edx               ;dx at base + 6
    mov al, bl            ;Get the master/slave bit back
    out dx, al            
    inc dx               ;dx at base + 7
    mov al, 0ECh         ;ECh = Identify drive command
    out dx, al

    jmp short $ + 2      ;IO cycle kill
    mov bl, 10           ;10 retries ok
.l2:
    in al, dx            ;get status byte
    test al, 00001000b   ;Check DRQ, to be set for data ready
    jnz .l3 ;If set we good to go
    ;Else timeout, wait for 1 ms before reading again
    dec bl
    jz .exitfail
    push rcx
    mov ecx, 1
    mov ah, 86h
    int 35h
    pop rcx
    jmp short .l2
.l3:
    sub edx, 7            ;dx at base + 0
    mov ecx, 100h         ;100h words to be copied
    rep insw
    clc
    jmp short .exit

.exitfail:
    stc
.exit:
    sti
    pop rbx
    pop rax
    ret

.switchDrive:
;Switches drive from master/slave to slave/master
;Sets/clears bit 7 of irq14/15Mutex 
;Bit 7 ataX Clear => Master
;Bit