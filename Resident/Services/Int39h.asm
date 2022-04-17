;-------------------Restart Interrupt Int 39h--------------------
;This interrupt allows the user to soft reboot
;----------------------------------------------------------------
bootstrapInt:
;Bootstrap loader, loads sector 88 of device 0 to 7C00h and jumps to it
;If not found, will restart the machine, failing that, iretq with CF set
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
;Now load one sector of second prog from first device 
.e0:
    xor dx, dx  ;This also clears carry flag so no checking ah
    mov rbx, 7c00h
    mov rcx, qword [nextFilePtr]
    mov ax, word [numSectors]
    mov ah, 82h ;LBA Sector Read 
    int 33h     ;Read one sector
    jnc .e1

    dec esi
    jz .efail

    xor dl, dl
    xor ah, ah  ;Reset the device
    int 33h
    jmp short .e0
.e1:
    xor edx, edx  ;Device number 0!
    cmp word [7c00h], 0AA55h ;The Boot signature
    jne .efail
;State when system transferred:
; RSP = DFF8h, 1FFh qword stack from DFFFh to 7C00H + 42*200h sectors = D000h
; FS MSR = userbase pointer, can be used for segment override.
; DX = Int 33h boot device number
; RBX = LBA of first Logical Block after SCP/BIOS
; BDA and BIOS ready to go
    mov rsp, 0DFF8h ;Move Stack pointer to default init stack position
    xor edx, edx    ;Device boot number
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