;--------------------IDE Driver and data area--------------------
IDE:
.addControllerTable:
;Adds a PCI IDE controller to the internal data tables, if there is space
; If there is no space, returns with carry set.
;Input: eax = BAR5 address
;       ebx = PCI IO address
;Output: CF=NC, all ok, CF=CY, device not added.
    push rsi
    cmp byte [ideNumberOfControllers], 2
    je .actfail ;If it is 2, fail
    inc byte [ideNumberOfControllers]
    mov rsi, ideControllerTable
    cmp byte [rsi], 0   ;Is the first entry empty?
    jz .act0    ;If yes, write entry
    add rsi, ideTableEntrySize  ;Else, goto second entry space
.act0:
    mov dword [rsi], ebx    ;Move first PCI IO addr
    mov byte [rsi], 0       ;Zero the register index
    mov dword [rsi + 4], eax    ;Move next data
    clc
.actexit:
    pop rsi
    ret
.actfail:
    stc
    jmp short .actexit
.identifyDevice:
;dx should contain the base register
;al should contain either A0/B0 for master/slave
;rdi points to the buffer
;Carry set if failed.
    push rax            ;save the master/slave bit temporarily
    add dx, 7            ;dx at base + 7
.l1:
    in al, dx
    cmp al, 0FFh
    je .exitfail
    test al, 10000000b
    jnz .l1

    jmp short $ + 2            ;IO cycle kill
    cli
.l2:
    in al, dx
    test al, al
    jz .exitfail
    test al, 01000000b
    jz .l2

    xor al, al
    sub dx, 5            ;dx at base + 2
    out dx, al
    inc dx               ;dx at base + 3
    out dx, al
    inc dx               ;dx at base + 4
    out dx, al
    inc dx               ;dx at base + 5
    out dx, al
    inc dx               ;dx at base + 6
    pop rax              ;Get the master/slave bit back
    out dx, al            
    inc dx               ;dx at base + 7
    mov al, 0ECh         ;ECh = Identify drive command
    out dx, al

    jmp short $ + 2      ;IO cycle kill
.l3:
    in al, dx            ;get status byte
    test al, 00001000b   ;Check DRQ, to be set for data ready
    jz .l3

    sub dx, 7            ;dx at base + 0
    push rcx
    mov cx, 100h         ;100h words to be copied
    rep insw
    clc
    sti
    jmp short .exit

.exitfail:
    stc
.exit:
    pop rax
    ret