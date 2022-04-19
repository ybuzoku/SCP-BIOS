;ATA driver!
ATA:
.identifyDevice:
;Drive to be identified should be selected already
;dx should contain the base register
;rdi points to the buffer
;Carry set if failed.

    push rax
    push rbx

    xor al, al
    add edx, 2            ;dx at base + 2
    out dx, al
    inc edx               ;dx at base + 3
    out dx, al
    inc edx               ;dx at base + 4
    out dx, al
    inc edx               ;dx at base + 5
    out dx, al
    add edx, 2           ;dx at base + 7
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
    pop rbx
    pop rax
    ret

.selectDrive:
;Selects either master or slave drive
;Sets/clears bit 7 of ataXCmdByte 
;Bit 7 ataX Clear => Master
;Called with dx = ataXbase, al = A0h/B0h for master/slave
;Returns the status of the selected drive after selection
;First check if this is the presently active device
    push rbx
    push rcx
    ;First find if ata0CmdByte or ata1CmdByte
    lea ecx, ata0CmdByte
    lea ebx, ata1CmdByte
    cmp edx, ata0_base
    cmovne ecx, ebx    ;Move ata1CmdByte to ecx
    ;Now isolate master/slave bit
    mov bl, al  ;Save master/slave byte in bl
    shr bl, 4   ;Bring nybble low
    and bl, 1   ;Save only bottom bit, if set it is slave
    ;Now check if the bits are the same
    mov bh, byte [rcx]
    and bh, 1   ;Only care for the bottom bit
    ;bh has in memory bit, bl has device bit
    cmp bh, bl
    je .skipSelection   ;If bh and bl are equal, the drive we want is selected
    and byte [rcx], 0FEh    ;Clear the bottom bit
    or byte [rcx], bl       ;Set the bit if bl[0] is set
    ;Now set master/slave on host
    add edx, 6            ;dx at base + 6, drive select
    out dx, al  ;Select here
    sub edx, 6            ;dx back at base + 0
    ;Now wait 400ns for value to settle
    call .driveSelectWait
.skipSelection:
    pop rcx
    pop rbx
    ret

.driveSelectWait:
; Called with dx = ataXbase
; Reads the alternate status register 14 times
; Returns the alternate status after a 15th read
    push rcx
    add edx, 206h   ;Move to alt base
    mov ecx, 14     ;14 iterations for 420ns wait
.dsw0:
    in al, dx
    loop .dsw0
    in al, dx
    sub edx, 206h   ;Return to ataXbase
    pop rcx
    ret