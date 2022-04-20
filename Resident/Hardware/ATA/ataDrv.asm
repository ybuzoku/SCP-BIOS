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
;Called with dx = ataXbase, 
; ah = al = A0h/B0h (or E0h/F0h for LBA) for master/slave
; Bits ah=al[3:0] may optionally store information (i.e.head bits or LBA bits)
; This function should NOT be used to set the head bits of a CHS or the high LBA bits 
; That should be done only after the drive has been successfully selected.
;Returns the status of the selected drive after selection in al
; or with Carry set to indicate drive not set
;ah is preserved
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
    mov bh, byte [rcx]  ;Now get ataXCmdByte
    and bh, 1   ;Only care for the bottom bit
    ;bh has in memory bit, bl has device bit
    cmp bh, bl
    je .skipSelection   ;If bh and bl are equal, the drive we want is selected
    ;Now set master/slave on host
    mov bh, 11     ;Up to 10 tries to set a device
.sd0:      
    dec bh
    jz .driveNotSelected
    mov al, ah     ;Return A0h/B0h to al from ah
    mov bl, al     ;Save shifted-up drive select bit in bl
    add edx, 6     ;dx at base + 6, drive select register
    out dx, al     ;Select here
    sub edx, 6     ;dx back at base + 0
    ;Now wait 400ns for value to settle
    call .driveSelectWait
    add edx, 7     ;Go to Status Register
    in al, dx      ;Get status
    sub edx, 7     ;Go back to ataXbase
    test al, 88h   ;Test if either BSY and DRQ bits set.
    jnz .sd0       ;If either is set, drive setting failed, try set again!
    ;Here set the bit in ataXCmdByte to confirm drive as selected
    ;ecx still has the value of the ataXCmdbyte
    and byte [rcx], 0FEh    ;Clear the bottom bit
    mov bl, ah              ;Bring A0h/B0h to bl
    shr bl, 4               ;Shift it down to bl[0]
    and bl, 1   ;Save only bottom bit, if set it is slave
    or byte [rcx], bl       ;Set the bit if bl[0] is set
.skipSelection:
    pop rcx
    pop rbx
    ret
.driveNotSelected:
    stc
    jmp short .skipSelection

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
    sub edx, 1FFh   ;Return to ataXbase + 7
    in al, dx       ;Get status and clear pending Interrupt
    sub edx, 7      ;Return to ataXbase
    pop rcx
    ret

.wait400ns:
;Called with dx pointing to a port to read 14 times
    push rcx
    mov ecx, 14     ;14 iterations for 420ns wait
.wns:
    in al, dx
    loop .wns
    pop rcx
    ret

.getChannelBase:
;Given a BIOS drive number in dl, 
; returns wheather it is a master or 
; slave in bit 12 of dx and in 
; bits [11:0] the IO address of the 
; base of the controller for the drive.
    push rbx
    push rcx
    and dl, 3       ;Save only the bottom 2 bits
    mov dh, dl      ;Save in dh
    and dh, 1       ;Save only master/slave bit in dh
    mov ebx, ata0_base
    mov ecx, ata1_base
    test dl, 2      ;If bit 1 is set, it is ata1
    cmovnz ebx, ecx ;Move ata1base into bx
    xor dl, dl      ;Clear bottom byte
    or dx, bx       ;Add the ataXbase into dx
    pop rcx
    pop rdx
    ret 
;==============================:
;    ATA primitive functions
;==============================:
.resetChannel:
    ;Resets a selected ATA channel
    ;Input: edx = ataXbase register for the ata channel to reset
    ;Output: CF=CY -> Channel did not reset.
    ;        CF=NC -> Channel reset
    ;If the channel doesnt reset, the caller will establish an error code
    ;
    push rax
    add edx, 206h   ;Go to alternate base
    mov al, 4h      ;Set the SoftwareReSeT (SRST) bit
    out dx, al      ;Set the bit
    call .wait400ns
    in al, dx       ;Get one more read
    sub edx, 206h   ;Return to base
	and al, 0xc0    ;Get only BSY and DRDY
	cmp al, 0x40	;Check that BSY is clear and that DRDY is set
    jne .rcBad
    ;Here clear the bit in ataXCmdByte
    push rbx
    push rcx
    lea rbx, ata0CmdByte
    lea rcx, ata1CmdByte
    cmp edx, ata0_base
    cmovne rbx, rcx
    and byte [rbx], 0FEh    ;Clear low bit
    pop rcx
    pop rbx
    clc             ;Clear carry
.rcExit:
    pop rax
    ret
.rcBad:
    stc             ;Set carry
    jmp short .rcExit

;CHS functions
.readCHS:
    call .setupCHS
    jc .rCHSend
    ;Send command!
.rCHSend:
    ret

.writeCHS:
    call .setupCHS
    jc .wCHSend

.wCHSend:
    ret

.verifyCHS:
    call .setupCHS
    jc .vCHSend

.vCHSend:
    ret

.setupCHS:
    ;Select the drive, then set up the CHS registers
    ; and return to the caller to enact the transaction
    xchg dl, dh
    mov ebp, edx    ;Have Drive number in bph and Head number in bpl
    xchg dl, dh
    call .getChannelBase    ;Return in bit 12 master/slave bit and in dx[11:0] io addr
    push rax
    mov al, dh  ;Get dx[15:8] in al. Bit 12 of dx becomes bit 4 of al
    and al, 10h ;Save master slave bit
    or al, 0A0h ;Add bit pattern to al
    mov ah, al
    and edx, 0FFFh   ;Clear the upper nybble of data
    call .selectDrive
    pop rax    
    jc .setupCHSFail0
;Drive now selected on channel. channel base in dx[11:0]
    add edx, 2  ;Goto ataXbase + 2, Sector Count
    out dx, al  ;Put out the sector count 
    inc edx     ;Goto ataXbase + 3, Sector Number
    push rax    ;Save sector count
    mov al, cl  ;Upper two bits of cl have a cylinder number. Clear them
    and al, 03Fh
    out dx, al  ;Out the sector to start at
    inc edx     ;Goto ataXbase + 4, Cylinder Low
    mov al, ch
    out dx, al  ;Out the low 8 bits of the cylinder address to start at
    inc edx     ;Goto ataXbase + 5, Cylinder High
    mov al, cl  ;Lower five bits of cl have the sector number. Shift down
    shr al, 6
    out dx, al  ;Out the hight 2 bits of the cylinder address to start at
    inc edx     ;Goto ataXbase + 6, Drive/Head Register
    mov eax, ebp    ;Get back from ebp the value of dx switched into eax
    ;ah has drive number, al has head number
    and al, 0Fh ;Ensure only bottom nybble is alive
    and ah, 1   ;Save only bottom bit (must be 0 for master, 1 for slave)
    or ah, 0Ah  ;Set magic bits for CHS
    shl ah, 4   ;Move low nybble high
    or al, ah   ;Add the nybble to the head number that is low
    out dx, al
    sub edx, 6  ;Goto ataXbase + 0, Data Register
    pop rax     ;Return sector count
    ret
.setupCHSFail0:
    mov ah, 20h ;General controller failure
    ret
    
;LBA functions
.readLBA:
    call .setupLBA
    ret
.writeLBA:
    call .setupLBA
    ret
.verifyLBA:
    call .setupLBA
    ret
.setupLBA:
    ret
;LBA48 functions
.readLBA48:
    call .setupLBA48
    ret
.writeLBA48:
    call .setupLBA48
    ret
.verifyLBA48:
    call .setupLBA48
    ret
.setupLBA48:
    ret
