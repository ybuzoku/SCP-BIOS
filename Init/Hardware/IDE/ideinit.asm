
IDE:
.ideInitialisation:
;Check primary and secondary bus for master and slave drives
; Maximum of 4 "fixed" ATA drives
;Due to being in compatibility mode, they respond to 
; default addresses.
;By default BIOS numbers will be assigned as follows: 
;               80h = Ctrlr 1, Master
;               81h = Ctrlr 1, Slave
;               82h = Ctrlr 2, Master
;               83h = Ctrlr 2, Slave

;To make algorithm work, set ataXCmdByte to 1
    mov byte [ata0CmdByte], 1
    mov byte [ata1CmdByte], 1

;Here, consider resetting drives on both channels
    ;ATA Channel 0 Master
    lea rbx, fdiskTable
    mov al, 0A0h
    mov ah, al  ;Save in ah
    mov edx, ata0_base
    call ATA.selectDrive    ;Ignore status for master
    mov al, ah  ;Bring back
    jc .ii0    ;If Master failed to select, ignore trying to identify it
    call .identifyDrive ;Master ata0
.ii0:
    ;ATA Channel 0 Slave
    add rbx, fdiskEntry_size
    or al, 10h ;Change from A0h to B0h
    mov ah, al
    call ATA.selectDrive ;Master should set slave status to 0 if non-existent
    jnc .ii1   ;If slave successfully was selected, skip the next line
    xor al, al  ;Mock the "00" response that would be placed on the bus by the master
.ii1:
    test al, al
    mov al, ah  ;Bring back
    jz .ii2 ;If al was zero, skip slave identification
    call .identifyDrive  ;Slave ata0

.ii2:
    ;ATA Channel 1 Master
    add rbx, fdiskEntry_size
    mov edx, ata1_base
    and al, 0EFh    ;Clear bit 4
    mov ah, al  ;Save in ah
    call ATA.selectDrive    ;Ignore status for master
    mov al, ah  ;Bring back
    jc .ii3     ;If Master failed to select, ignore trying to identify it
    call .identifyDrive ;Master ata1
.ii3:
    ;ATA Channel 1 Slave
    add rbx, fdiskEntry_size
    or al, 10h ;Change from A0h to B0h
    mov ah, al
    call ATA.selectDrive ;Master should set slave status to 0 if non-existent
    jnc .ii4   ;If slave successfully was selected, skip the next line
    xor al, al  ;Mock the "00" response that would be placed on the bus by the master
.ii4:
    test al, al
    mov al, ah  ;Bring back
    jz .ii5 ;If al was zero, skip slave identification
    call .identifyDrive ;Slave ata1
.ii5:
;Now return the control of each host to the master drives

    mov al, 0A0h
    mov edx, ata0_base
    call ATA.selectDrive

    mov al, 0A0h
    mov edx, ata1_base
    call ATA.selectDrive

    jmp .ideInitEnd
;===========================
;     Callable procs       :
;===========================
.identifyDrive:
;Zeros out the sector buffer entries we check
; and calls identify device. If it succeeds, it then
; proceeds to add the entry to the appropriate position
; in the table.
;If it fails, doesnt inc the fixed drives number counter
;Called with:   dx = ataX base register
;               rbx = Points to table entry to write
;               al = A0h for master, B0h for slave

    push rax
    push rdx
    xor ecx, ecx
    lea rdi, sectorbuffer
    ;Clean entries we want to read before hand
    mov word [rdi + idCurrCyl], cx     ;Clear current cylinders
    mov word [rdi + idCurrHed], cx     ;Clear current heads
    mov word [rdi + idCurrSecTk], cx   ;Clear current sectors/track
    mov word [rdi + 83*2], cx          ;Clear LBA48 supported bit word
    mov dword [rdi + idLBASectrs], ecx ;Clear UserAddressableSectors
    mov qword [rdi + idLBA48Sec], rcx  ;Clear UserAddressableSectors for LBA48
    push rdi
    call ATA.identifyDevice
    pop rdi
    jc .idExit  ;If the carry flag set, the device timed out
    ;Now get information and build tables here
    mov byte [rbx + fdiskEntry.signature], 0    ;Clear signature byte in table
    mov word [rbx + fdiskEntry.ioBase], dx      ;Add iobase and masterslave status
    mov byte [rbx + fdiskEntry.msBit], al       
;CHS, none of CHS is allowed to be 0 but may be because obsolete on new drives
    mov ax, word [rdi + idCurrCyl]
    test ax, ax
    jz .id0
    mov word [rbx + fdiskEntry.wCylinder], ax
    mov ax, word [rdi + idCurrHed]
    test ax, ax
    jz .id0
    mov word [rbx + fdiskEntry.wHeads], ax
    mov ax, word [rdi + idCurrSecTk]
    test ax, ax
    jz .id0
    mov word [rbx + fdiskEntry.wSecTrc], ax
.id0:
;LBA28
    mov eax, dword [rdi + idLBASectrs]
    test eax, eax   ;Is this number 0? Check LBA48 or solely on CHS
    jz .id1
    test eax, 0F0000000h ;Test if we above max LBA 28 number
    jnz .id1 ;If above, ignore LBA28
    or byte [rbx + fdiskEntry.signature], fdeLBA28 ;Set LBA28 present bit
    mov dword [rbx + fdiskEntry.lbaMax], eax
.id1:
;LBA48
;Check LBA48 bit first
    test word [rdi + 83*2], 400h    ;If bit 10 set, LBA48 supported
    jz .id2
    mov rax, qword [rdi + idLBA48Sec]
    bswap rax   ;Bring high word low
    test ax, 0FFFFh ;Test if high word was set
    bswap rax
    jnz .id2    ;If above, ignore LBA 48
    mov qword [rbx + fdiskEntry.lbaMax48], rax
    or byte [rbx + fdiskEntry.signature], fdeLBA48
.id2:
;Now check if either LBA28 or LBA48 are set or CHS is non-zero
    test byte [rbx + fdiskEntry.signature], fdeLBA28 | fdeLBA48
    jnz .idDeviceOK ;If either LBA28 or 48 set, confirm device OK!
    ;We arrive here ONLY IF LBA 28 or LBA 48 not set
    ; That means drive must be small, so floating bus values in CHS
    ; cannot be valid.
    ;Check C/H/S values are all non-zero
    ;If any are zero, then device not configured for use
    ;If any values dont make sense (such as 7F7Fh FFFFh) then fail those too
    movzx eax, word [rbx + fdiskEntry.wCylinder]
    test eax, eax
    jz .id3 ;If zero, dont confirm device
    cmp ax, 0FFFFh
    je .id3
    cmp ax, 07F7Fh
    je .id3
    movzx eax, word [rbx + fdiskEntry.wHeads]
    test eax, eax
    jz .id3 ;If zero, dont confirm device
    cmp ax, 0FFFFh
    je .id3
    cmp ax, 07F7Fh
    je .id3
    movzx eax, word [rbx + fdiskEntry.wSecTrc]
    test eax, eax
    jz .id3
    cmp ax, 0FFFFh
    je .id3
    cmp ax, 7F7Fh
    jne .idDeviceOK ;Values are probably sane, all ok
.id3:
;Only arrive here if none of CHS, LBA28 or LBA48 were verified as ok
;Clean any data that mightve been copied (from Floating Bus reads perhaps)
    xor eax, eax
    mov byte [rbx + fdiskEntry.signature], al
    mov dword [rbx + fdiskEntry.lbaMax], eax
    mov qword [rbx + fdiskEntry.lbaMax48], rax
    mov word [rbx + fdiskEntry.wCylinder], ax
    mov word [rbx + fdiskEntry.wHeads], ax
    mov word [rbx + fdiskEntry.wSecTrc], ax
    mov word [rbx + fdiskEntry.ioBase], ax
    mov byte [rbx + fdiskEntry.msBit], al
    jmp short .idExit
.idDeviceOK:
    or byte [rbx + fdiskEntry.signature], fdePresent
    inc byte [fdiskNum] ;Number of usable fixed disks increased
.idExit:
    pop rdx
    pop rax
    ret

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

;============================
;     Exit target label     :
;============================
.ideInitEnd: