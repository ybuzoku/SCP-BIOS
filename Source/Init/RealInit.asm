;First set stack and save the SysInit Ptr, then set A20, check CPUID and 
; exended features. Then tell BIOS that we are going long and perhaps 
; protected then get the Int 11h word, store at 0:800h
realInit:
;The Caller Far Jumps to set cs to 0
    cli     ;Stop interrupts as we dont know where the stack is
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, lowStackPtr ;Set up stack pointer
    sti
    cmp byte [es:bx], 0Ch   ;Check length
    jne .fail   ;If thats not it, error 0
    mov ax, word [es:bx + 1]    ;Get number of sectors into ax 
    mov cx, 42  ;42 sectors maximum
    cmp ax, cx
    cmovnb ax, cx
    mov word [SysInitTable.numSecW], ax
    mov eax, dword [es:bx + 4]      ;Get low dword
    mov dword [SysInitTable.FileLBA], eax
    mov eax, dword [es:bx + 8]      ;Get high dword
    mov dword [SysInitTable.FileLBA + 4], eax
    push es
.a20Proc:
    push ax
    push cx ;preserve ax and cx
    xor cx, cx ;clear to use as a timeout counter
    
.a20FastEnable:
    in al, 92h
    test al, 2
    jnz .no92
    or al, 2
    and al, 0FEh
    out 92h, al
    
    inc cl    ;increments the time out counter
    jmp .a20Check
    
.no92:
    mov cl, 4
    jmp .a20Fail
    
.a20KeybEnable: ;communicating with the keyboard controller
    cli
 
    call .a20wait
    mov al,0ADh
    out 64h,al ;disable the keyboard
    call .a20wait
    mov al,0D0h
    out 64h,al ;read from the keyboard input
    call .a20wait2
    in al,60h
    push eax    ;get the keyboard data and push it to the stack
    call .a20wait
    mov al,0D1h
    out 64h,al    ;output the command to prep to go a20 
    call .a20wait
    pop eax    ;need this be eax and not just ax?
    or  al,2
    out 60h,al    ;output to go a20
    call .a20wait
    mov al,0AEh
    out 64h,al    ;reenable keyboard
    call .a20wait    ;done!
    sti

    inc cl    ;increments the time out counter
    jmp .a20Check
    
.a20wait:
    in al,64h
    test al,2
    jnz .a20wait
    ret
 
.a20wait2: 
    in al,64h
    test al,1
    jz .a20wait2
    ret

.a20Check:
    mov ax, 0FFFFh
    push ax
    pop es ;es to FFFF
    mov di, 0010h ;FFFF:0010 == 0000:0000
    xor si, si    ;remember ds = 0000
    mov al, byte [es:di]
    cmp byte [ds:si], al
    je .a20Fail
    inc al    ;make change to al
    mov byte [ds:si], al ;al is now incremented and saved at address 0000:0000
    cmp byte [es:di], al ;check against overflown version
    je .a20Fail
    
.a20Pass:
    dec al    ;return al to its original value
    mov byte [ds:si], al ;return to original position
    
    pop cx
    pop ax
    pop es
    jmp short .a20Exit
    
.a20Fail:
    cmp cl, 3
    jle .a20FastEnable
    cmp cl, 6
    jle .a20KeybEnable
    
    pop cx
    pop ax
    pop es
    jmp short .noa20

.a20Exit:
    pushfd
    pop eax
    mov ecx, eax ;save original flag state for later
    xor eax, 00200000h ;21st bit - CPUID bit, switch it!!
    push eax
    popfd
    
    pushfd
    pop eax
    test eax, ecx ; compare the registers. If they are the same
    je .noCPUID
    push ecx
    popfd

.extCheck:
    mov eax, 80000000h
    cpuid
    cmp eax, 80000001h ;If this is true, CPU supports extended functionality
    jae tellBIOS
.noa20:
    mov ah, 1    ;noa20 error code
.noCPUID:
    mov ah, 2    ;noCPUID error code
    jmp short .fail
    mov ah, 3    ;no Extended functionality error code
.fail:
    mov dl, ah    ;store ax to get error code printed
    mov si, .msg
    call .write
    mov al, dl
    mov bx, 0007h    ;Attribs
    mov ah, 0Eh        ;TTY print char
    add al, 30h        ;add '0' to digit
    int 10h
    xor ax, ax
    int 16h    ;await keystroke
    int 18h
;Error codes: 
;   00h - Bad SysInit Data
;   01h - No A20 Line
;   02h - No CPUID 
;   03h - No Extended Functionality
.write: ;destroys registers ax and bx
    lodsb
    cmp al, 0 ;check for zero
    je .return
    mov ah, 0Eh    ;TTY output
    mov bx, 0007h ;colour
    int 10h
    jmp short .write
.return:
    ret
.msg: db 'Boot error:',0
tellBIOS:
    mov eax, 0EC00h ;Tell BIOS we are going long
    mov bl, 03h     ;Both Long and Protected modes
    int 15h         ;Ignore response
    int 11h
    mov word [loMachineWord], ax
;Getting Memory Map
rmE820Map:
    push es
    push ds
    mov ax, e820Seg
    mov ds, ax
    mov es, ax
    mov di,    e820BaseOff
    xor ebx, ebx
    xor bp,bp
    mov edx, 0534D4150h    ;Magic dword
    mov eax, 0E820h
    mov dword [es:di + 20], 1
    mov ecx, 24            ;Get 24 bytes
    int 15h
    jc .mapfail            ;Carry set => Fail
    mov edx, 0534D4150h    ;Magic dword
    cmp eax, edx        ;Must be equal on success
    jne .mapfail
    test ebx, ebx         ;One table entry, bad
    jz .mapfail
    jmp short .map1
.map0:
    mov eax, 0E820h
    mov dword  [es:di + 20], 1
    mov ecx, 24
    int 15h
    jc .mapexit
    mov edx, 0534D4150h
.map1:
    jcxz .map3
    cmp cl, 20
    jbe .map2
    test byte [es:di + 20], 1
    je .map3
.map2:
    mov ecx, dword [es:di + 8]
    or ecx, [es:di + 12]
    jz .map3
    inc bp
    add di, 24
.map3:
    test ebx, ebx
    jne .map0
    jmp short .mapexit
.mapfail:
.mapexit:
    mov word [es:e820SizeOff], bp  ;Num entries in var space (3 qwords/entry)
;Second memory test
    xor cx, cx
    xor dx, dx
    mov ax, 0E801h
    int 15h
    jc .badmem2
    cmp ah, 86h    ;unsupported command
    je .badmem2
    cmp ax, 80h    ;invalid command
    je .badmem2
.mem2write:
    stosw
    mov ax, bx
    stosw
    mov ax, cx
    stosw
    mov ax, dx
    stosw
    jmp short .mem3test
.badmem2:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    jmp .mem2write
.mem3test:
    clc
    mov ah, 88h
    int 15h
    xor bx, bx 
    cmovc ax, bx    ;if error, store zero
    cmp ax, 86h
    cmovz ax, bx
    cmp ax, 80h
    cmovz ax, bx
    stosw
.finalmemtest:
    clc
    int 12h
    cmovc ax, bx    ;If carry on, store a zero
    stosw    ;Store the word
rmGetFontPointers:
;Get ROM Font Pointers, immediately after Memory map
;Each entry is 8 bytes long: es=Seg, bp=Off, cx=bytes/char, dx=# of rows - 1
    xor bx, bx         ;Clear bh
.gfp1:    
;Over protective routine in the event that the BIOS routine clobbers registers
    mov si, 1000h    ;Save segment loader
    xor cx, cx
    xor dx, dx
    xor bp, bp
    push bx            ;Save bx

    mov ax, 1130h    ;Get font pointer function
    int 10h

    mov ax, es        ;Get segment into ax to store
    mov es, si        ;Reload segment for stos to work
    stosw
    mov ax, bp        ;Get offset
    stosw
    mov ax, cx        ;bytes/char
    stosw
    mov al, dl        ;dl contains # of rows, but zero extended for alignment
    xor ah, ah
    stosw
    pop bx            ;Get the count back
    inc bh
    cmp bh, 7
    jbe .gfp1        ;Once above 7, fall through

    pop ds
    pop es    ;Bring back original es value
rmSetTables:
;Memory tables live in 0:8000h - 0:E000h range
    mov edi, 8000h
    mov cr3, edi    ;Cannot lsh cr3
    mov cx, 3000h    ;6000h bytes (6x4Kb) of zero to clear table area
    push di
    xor ax, ax
    rep stosw        ;Store 3000h words of zero

    pop di            ;Return zero to the head of the table, at 08000h
    mov ax, 9000h|permissionflags    ;9000h is the low word of the address.
    stosw    ;store the low word of the address
    add di, 0FFEh
    mov cx, 4
rmUtables:            ;di should point to 8000h
    add ax, 1000h
    stosw    ;ax is now A003h,B003h,C003h,D003h
    add di, 6    ;qword alignment
    dec cx
    jnz rmUtables

    mov cx, 800h    ;4x512 consecutive entries
    xor ax, ax
    push ax            ;push for algorithm to work
    mov di, 0A000h
rmPDTentries:
    mov ax, 83h        ;bit 7|permission flags
    stosw            ;di incremented twice
    pop ax            ;get current address
    stosw            ;di incremented twice. store the address
    add ax, 20h        ;add the offset to the next page
    push ax            ;push current address into memory
    add di, 4        ;qword Align
    dec cx
    jnz rmPDTentries

    mov eax, cr4                 
    or eax, 0A0h ;Set PAE and PGE, for glbl page and physical page extensions
    mov cr4, eax 
    
    mov ecx, 0C0000080h    ;Read EFER MSD into EDX:EAX
    rdmsr    ; Read information from the msr.
    or eax, 00000100h ; Set the Long mode bit!
    wrmsr  ; Write the data back
    
    cli
    mov al, 0FFh             ; Out 0xFF to 0xA1 and 0x21 to disable all IRQs.
    out 0A1h, al
    out 21h, al

    lgdt [GDT.Pointer] ;Load the Global Descriptor Table pointer

    mov eax, cr0
    or eax, 80000001h ;Set the Paging and Protected Mode bits (Bits 31 and 0)
    mov cr0, eax  ;write it back!
    jmp GDT.Code:longmode_ep

GDT:                    ;Global Descriptor Table (64-bit).
.Null: equ $ - GDT      ;The null descriptor.
    dq 0
.Code: equ $ - GDT      ;The 32-bit code descriptor. Limit = FFFFFh, Base=0
    dw 0FFFFh           ;Limit 0:15
    dw 00000h           ;Base 0:15
    db 00h              ;Base 16:23
    db 09Ah             ;Access Byte
    db 03Fh             ;Limit 16:19
    db 00b              ;Base 24:31

.Data: equ $ - GDT      ;The 32-bit data descriptor. 
    dw 0FFFFh           ;Limit 0:15
    dw 00000h           ;Base 0:15
    db 0h               ;Base 16:23
    db 092h             ;Access Byte
    db 01Fh             ;Limit 16:19 then Flags
    db 00h              ;Base 24:31
ALIGN 4
    dw 0
.Pointer    dw $ - GDT - 1      ; GDT pointer.
.Base       dq GDT                 ; GDT offset.
;----------------------------------------------------------------