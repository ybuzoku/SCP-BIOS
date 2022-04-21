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
.selectDriveFromTable:
;Selects the drive pointed to by the table entry in rbp
;Input: rbp = Pointer to drive table entry
;Output: CF=NC -> All ok, can proceed with writing data
;        CF=CY -> drive not set
    push rdx
    push rax
    mov al, byte [rbp + fdiskEntry.msBit]
    mov dx, word [rbp + fdiskEntry.ioBase]
    call .selectDrive
    pop rax
    pop rdx
    ret
.selectDrive:
;Selects either master or slave drive
;Sets/clears bit 7 of ataXCmdByte 
;Bit 7 ataX Clear => Master
;Input: dx = ataXbase, 
;       ah = al = A0h/B0h (or E0h/F0h for LBA) for master/slave
;
;Return: If CF=NC, al = the status of the selected drive after selection
;        If CF=CY drive not set
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

.getTablePointer:
;Given a drive number in dl, put the table pointer in rbp
;If entry not valid OR greater than 4, fail with CF=CY
    push rdx
    and dl, 7Fh ;Clear top bit
    cmp dl, 3   ;Only 4 fixed disks allowed!
    ja .gtpBad
    lea rbp, fdiskTable ;Point to the fdisktable
.gtpSearch:
    test dl, dl
    jz .gtpVerifyOk
    dec dl
    add rbp, fdiskEntry_size    ;Goto next entry
    jmp short .gtpSearch
.gtpVerifyOk:
    cmp byte [rbp + fdiskEntry.signature], 1    ;Configured bit must be set
    jz .gtpBad 
    pop rdx
    clc
    ret
.gtpBad:
    stc 
    pop rdx
    ret
;==============================:
;    ATA primitive functions
;==============================:
.resetChannel:
    ;Resets a selected ATA channel
    ;Input: rbp = Fixed Disk Table entry pointer for chosen device
    ;Output: CF=CY -> Channel did not reset.
    ;        CF=NC -> Channel reset
    ;If the channel doesnt reset, the caller will establish an error code
    ;
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 206h   ;Go to alternate base
    mov al, 4h      ;Set the SoftwareReSeT (SRST) bit
    out dx, al      ;Set the bit
    mov ecx, 10     ;Wait 10 milliseconds
    mov ah, 86h
    int 35h
    xor al, al
    out dx, al      ;Clear the SRST bit
    mov ecx, 10     ;Wait 10 milliseconds
    mov ah, 86h
    int 35h
    in al, dx       ;Get one more read
    sub edx, 206h   ;Return to base
	and al, 0xc0    ;Get only BSY and DRDY
	cmp al, 0x40	;Check that BSY is clear and that DRDY is set
    jne .rcBad
    ;Here clear the master/slave bit in ataXCmdByte
    lea rbx, ata0CmdByte
    lea rcx, ata1CmdByte
    cmp word [rbp + fdiskEntry.ioBase], ata0_base
    cmovne rbx, rcx
    and byte [rbx], 0FEh    ;Clear low bit

    clc             ;Clear carry
    ret
.rcBad:
    stc             ;Set carry
    ret
;Common functions:
;Jumped to with: 
; al = Primary function number
; cl = Sector count
; dx = Command register for drive
.read:
    out dx, al  ;Output the command byte!
    mov al, cl  ;Return sector count into al

    ;Now we wait for the DRQ bit in the status register to set
    mov cx, -1  ;Data should be ready within ~67 miliseconds
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 206h  ;Dummy read on Alt status register
    mov rdi, rbx    ;Move the read buffer pointer to rdi
    mov bl, al      ;Save sector count in bl
.rWait:
    call .wait400ns
    dec cx
    jz .rTimeout
    test al, 8      ;If DRQ set?  
    jz .rWait    ;If not, keep waiting
;Now we can read the data
    movzx edx, word [rbp + fdiskEntry.ioBase]   ;Point to base=data register
    movzx eax, bl   ;Zero extend the sector count
.readLoop:
    mov ecx, 256    ;Number of words in a sector
    rep insw    ;Read that many words!
    dec al      ;Reduce the number of sectors read by 1
    jnz .readLoop
    ;Here check status register to ensure error isnt set
    add edx, 7
    mov ecx, -1
.readExitloop:
    dec ecx
    jz .errorExit
    in al, dx
    test al, 80h        ;Check if BSY bit still set (i.e not ready yet)
    jnz .readExitloop   ;If BSY still set keep looping
    test al, 61h        ;Check if DSDY bit or Error bits are set
    jz .readExitloop    ;If DSDY not set, wait
    test al, 21h    ;Check status bits 0 and 5 (error and drive fault)
    jnz .errorExit
.rExit:
    clc
    ret
.rTimeout:
    mov byte [msdStatus], 80h   ;Timeout occured
.errorExit:
    stc
    ret

.write:
    out dx, al  ;Output the command byte!
    mov al, cl  ;Return sector count into al

    ;Now we wait for the DRQ bit in the status register to set
    mov cx, -1  ;Data should be ready within ~67 miliseconds
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 206h  ;Dummy read on Alt status register
    mov rsi, rbx    ;Move the write buffer pointer to rsi
    mov bl, al      ;Save sector count in bl
.writeWait:
    call .wait400ns
    dec cx
    jz .rTimeout
    test al, 8      ;If DRQ set?  
    jz .writeWait    ;If not, keep waiting
;Now we can write the data
    movzx edx, word [rbp + fdiskEntry.ioBase]   ;Point to base=data register
    movzx eax, bl   ;Zero extend the sector count
.w0:
    mov ecx, 256    ;Number of words in a sector
.w1:
    outsw    ;Write that many words!
    jmp short $ + 2
    loop .w1 ;Write one sector, one word at a time
    dec al
    jnz .w0  ;Keep going up by a sector
    ;Here wait for device to stop being busy. 
    ;If it doesnt after ~4 seconds, declare an error
.formatEP:  ;Where the format routine enters the write routine
    mov ecx, -1 ;About 4 seconds
    add edx, 7  ;Goto status register
.wBSYcheck:
    dec ecx
    jz .errorExit   ;If after 4 seconds the device is still BSY, consider it failing
    in al, dx   ;Read status reg
    test al, 80h    ;Check BSY
    jnz .wBSYcheck   ;If it is no longer BSY, check error status
    test al, 61h        ;Check if DSDY bit or Error bits are set
    jz .wBSYcheck    ;If not set, do not send next command
;NOW FLUSH THE DISK BUFFERS TO DISK
    ;Here check status register to ensure error isnt set
    test al, 21h    ;Test bits 0 and 5 (error and drive fault)
    jnz .errorExit
    ;Now we must flush cache on the device
    mov al, 0E7h    ;FLUSH CACHE COMMAND
    out dx, al
    ;This command can take 30 seconds to complete so we check status 
    ; every ms to see if BSY is clear yet.
    mov ebx, 30000   ;30,000 miliseconds in 30 seconds
.wFlushCheck:
    dec ebx
    jz .errorExit
    mov ecx, 1
    mov ah, 86h
    int 35h
    in al, dx   ;Read the status byte
    test al, 80h    ;Are we still busy?
    jnz .wFlushCheck ;IF yes, loop again
    test al, 61h    ;Check if DSDY bit or Error bits are set
    jz .wFlushCheck  ;Whilst it is not set, keep looping
    test al, 21h    ;Test bits 0 and 5 (error and drive fault)
    jnz .errorExit   ;If either are set, return fail
    clc
    ret

.verify:
    out dx, al  ;Output the command byte!
    ;Now we wait for BSY to go low and DRDY to go high
    mov cx, -1  ;Data should be ready within ~67 miliseconds
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto status register
.vLoop:
    dec cx
    jz .errorExit
    in al, dx   ;Get status
    test al, 80h    ;BSY bit set
    jnz .vLoop
    ;Once it clears come here
    test al, 61h    ;Check if DSDY bit or Error bits are set
    jz .vLoop    ;Whilst it is not set, keep looping
    test al, 21h    ;Test bits 0 and 5 (error and drive fault)
    jnz .errorExit   ;If either are set, return fail
    clc
    ret

.format:
    ;A write which writes a byte to disk (0E5h for classical reasons)
    out dx, al  ;Output the command byte!
    mov al, cl  ;Return sector count into al

    ;Now we wait for the DRQ bit in the status register to set
    mov cx, -1  ;Data should be ready within ~67 miliseconds
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 206h  ;Dummy read on Alt status register
    mov bl, al     ;Save sector count in bl
.formatWait:
    call .wait400ns
    dec cx
    jz .rTimeout
    test al, 8      ;If DRQ set?  
    jz .formatWait  ;If not, keep waiting
;Now we can write the data
    movzx edx, word [rbp + fdiskEntry.ioBase]   ;Point to base=data register
    ;movzx eax, bl   ;Zero extend the sector count
    mov bh, bl  ;Move sector count into bh to use as counter
    mov eax, 0E5E5h 
.f0:
    mov ecx, 256    ;Number of words in a sector
.f1:
    out dx, ax  ;Write E5h to the disk!!
    jmp short $ + 2
    loop .f1 ;Write one sector, one word at a time
    dec bh
    jnz .f0  ;Keep going up by a sector
    jmp .formatEP   ;Goto the format entry point

;CHS functions
.readCHS:
;Called with rdi as a free register to use
;All other registers have parameters as in Int 33h function ah=02h
    call .setupCHS
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 20h ;ATA READ COMMAND!
    jmp .read

.writeCHS:
;Called with rsi as a free register to use
;All other registers have parameters as in Int 33h function ah=02h
    call .setupCHS
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 30h ;ATA WRITE COMMAND!
    jmp .write

.verifyCHS:
    call .setupCHS
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov al, 40h ;ATA VERIFY COMMAND!
    jmp .verify

.formatCHS:
;Ignore al (number of sectors) and cl[5:0] (Starting sector number)
    mov ax, word [rbp + fdiskEntry.wSecTrc] ;Get sectors in a track to clear
    ;Sectors per track is always less than 256 so byte is ok!
    and cl, 0C0h    ;Clear bottom 6 bits. 
    or cl, 1        ;All tracks start at sector 1
    call .setupCHS
    jc .errorExit
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 30h ;ATA WRITE COMMAND!
    jmp .format

.setupCHS:
    ;First sets the chosen device, then sets all the registers
    ; except for the command and then returns
    call .selectDriveFromTable
    jc .sCHSFailed
    ;Now the drive has been selected, we can write to it
    push rax    ;Only sector count needs to be preserved
    push rdx    ;Temporarily save drive head bits to use later
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 2  ;Goto base + 2, Sector count
    out dx, al
    inc edx     ;Goto base + 3, Starting sector number
    mov al, cl  ;Bits [5:0] have starting sector number
    and al, 3Fh ;Clear upper two bits
    out dx, al
    inc edx     ;Goto base + 4, Cylinder low bits
    mov al, ch  ;Get the low 8 bits of the cylinder number
    out dx, al
    inc edx     ;Goto base + 5, Cylinder high bits
    mov al, cl  ;Bits [7:6] have top two bits of cylinder number
    shr al, 6   ;Shift them down to clear bottom 6 bits
    out dx, al  
    inc edx     ;Goto base + 6, Drive/Head controller register
    pop rax     ;Get back the drive head number from dh into ah
    mov al, ah  
    and al, 0Fh ;Save only bottom nybble
    or al, byte [rbp + fdiskEntry.msBit]    ;Add the MS bits to al
    out dx, al
    pop rax
    clc
    ret
.sCHSFailed:
    mov byte [msdStatus], 20h   ;General controller failure
    ret ;Carry flag propagated

;LBA functions
.readLBA:
    call .setupLBA
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 20h ;ATA READ COMMAND!
    jmp .read

.writeLBA:
    call .setupLBA
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 30h ;ATA WRITE COMMAND!
    jmp .write

.verifyLBA:
    call .setupLBA
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 40h ;ATA VERIFY COMMAND!
    jmp .verify

.formatLBA:
    call .setupLBA
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 30h ;ATA WRITE COMMAND!
    jmp .format

.setupLBA:
    ;First sets the chosen device, then sets all the registers
    ; except for the command and then returns
    call .selectDriveFromTable
    jc .sLBAFailed
    push rax        ;Save sector count on stack
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 2      ;Goto base + 2, Sector count
    out dx, al      ;Output sector number
    inc edx         ;Goto base + 3, LBA low
    mov al, cl      ;Get LBA low address
    shr ecx, 8      ;Get second byte low
    out dx, al      

    inc edx         ;Goto base + 4, LBA mid
    mov al, cl      ;Get LBA second byte
    shr ecx, 8      ;Get third byte low
    out dx, al

    inc edx         ;Goto base + 5, LBA high
    mov al, cl      ;Get LBA third byte
    shr ecx, 8      ;Get final nybble into cl
    out dx, al

    inc edx         ;Goto base + 6, LBA upper bits and drive select
    mov al, cl      ;Get final nybble into al
    and al, 0Fh     ;Clear extra bits
    or al, byte [rbp + fdiskEntry.msBit]    ;Add the master/slave bit and fixed bits
    or al, 40h      ;Set LBA bit
    out dx, al
    pop rax  ;Return sector count into al
    clc
    ret
.sLBAFailed:
    mov byte [msdStatus], 20h   ;General controller failure
    ret ;Carry flag propagated

;LBA48 functions
.readLBA48:
    call .setupLBA48
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 24h ;ATA READ EXT COMMAND!
    jmp .read

.writeLBA48:
    call .setupLBA48
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 34h ;ATA WRITE EXT COMMAND!
    jmp .write

.verifyLBA48:
    call .setupLBA48
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 42h ;ATA VERIFY EXT COMMAND!
    jmp .verify

.formatLBA48:
    call .setupLBA48
    jc .errorExit
    ;Send command
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto command register
    mov cl, al  ;Save sector count in cl
    mov al, 34h ;ATA WRITE EXT COMMAND!
    jmp .format

.setupLBA48:
;First sets the chosen device, then sets all the registers
    ; except for the command and then returns
    call .selectDriveFromTable
    jc .sLBAFailed
    push rax        ;Save sector count on stack
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 2      ;Goto base + 2, Sector count
    ror rcx, 24     ;Move the upper three bytes low
    xor al, al      ;High byte of sector count is always 0
    out dx, al

    inc edx         ;Goto base + 3, Write LBA byte 4
    mov al, cl      ;Get LBA byte 4 into al
    out dx, al
    shr rcx, 8      ;Shift bytes down by 1

    inc edx         ;Goto base + 4, Write LBA byte 5
    mov al, cl      ;Get LBA byte 5 into al
    out dx, al
    shr rcx, 8      ;Shift bytes down by 1

    inc edx         ;Goto base + 5, Write LBA byte 6
    mov al, cl      ;Get LBA byte 6 into al
    out dx, al

    shr rcx, 24     ;Shift down by an extra two to eliminate two dummy bytes
;cl now has LBA byte 1 again
    sub edx, 3      ;Goto base + 2, Write low byte of sector count
    pop rax         ;Get back sector count from stack
    push rax        ;Push it back onto the stack
    out dx, al

    inc edx         ;Goto base + 3, Write LBA byte 1
    mov al, cl      ;Get LBA byte 1 into al
    out dx, al
    shr rcx, 8      ;Shift bytes down by 1

    inc edx         ;Goto base + 4, Write LBA byte 2
    mov al, cl      ;Get LBA byte 2 into al
    out dx, al
    shr rcx, 8

    inc edx         ;Goto base + 5, Write LBA byte 3
    mov al, cl      ;Get LBA byte 3 into al
    out dx, al

    inc edx         ;Goto base + 6, write drive select
    mov al, byte [rbp + fdiskEntry.msBit]    ;Add the master/slave bit and fixed bits
    or al, 40h      ;Set LBA bit
    out dx, al

    pop rax  ;Return sector count into al
    clc
    ret
