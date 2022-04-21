;-------------------Restart Interrupt Int 39h--------------------
;This interrupt allows the user to soft reboot
;----------------------------------------------------------------
bootstrapInt:
;Bootstrap loader, loads user programmed sector into memory, first from
; device 00h and then from device 80h. If device 00h doesnt exist OR the 
; loadsector doesn't begin with the SCP/BIOS boot signature then the 
; same sector is read from of device 80h. If this also fails due to device 80h
; not existing or the sector not being bootable, the boot loader will return
; to the caller with the carry flag set.

    push rax
    push rbx
    push rcx
    push rdx
    push rsi

    mov ecx, 0C0000100h    ;Select fs register to load base addr
    mov rax, qword [userBase]    ;Load address to fs
    xor edx, edx        ;Zero upper bytes
    wrmsr                ;Write msr to load fs base

    mov esi, 10
;Now load one sector of second prog from device 00h or 80h
    cmp byte [numMSD], 0    ;If we have no removable devices, skip checking rem dev
    jz .e3
    xor dx, dx  ;This also clears carry flag so no checking ah
.e0:
    mov rbx, 7c00h
    mov rcx, qword [nextFilePtr]
    mov ax, word [numSectors]   ;Max 42 sectors, upper byte is always 0
    mov ah, 82h ;LBA Sector Read, dl has device number
    int 33h     ;Read one sector, device number is preserved
    jnc .e1

    dec esi
    jz .e2  ;Try again for fixed disk or if on fixed disk, exit

    xor ah, ah  ;Reset the device in dl
    int 33h
    jmp short .e0
.e1:
    cmp word [7c00h], 0AA55h ;The Boot signature
    je .leaveBIOS
;If we dont goto leaveBIOS, then we try again with device number 80h if it exists
;If already at device 80h, fail.
.e2:
    cmp dl, 80h
    je .efail
    cmp byte [fdiskNum], dl ;Recall, dl is zero here
    je .efail   ;Don't waste time if there are no fixed disks
.e3:
    mov dl, 80h ;Try first fixed disk now
    mov esi, 10 ;Reload repeat count
    clc
    jmp short .e0
.leaveBIOS:
;State when system transferred:
; RSP = DFF8h, 1FFh qword stack from DFFFh to 7C00H + 42*200h sectors = D000h
; FS MSR = userbase pointer, can be used for segment override.
; DX = Int 33h boot device number
; RBX = LBA of first Logical Block after SCP/BIOS
; BDA and BIOS ready to go
    mov rsp, 0DFF8h ;Move Stack pointer to default init stack position
    mov rbx, qword [nextFilePtr]     ;First sector on device after SCP/BIOS
    jmp 7C02h       ;New sector entry point
.efail:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    or byte [rsp + 2*8h], 1 ;Set carry flag
    iretq
;------------------------End of Interrupt------------------------