i0:
    xor rax, rax
    jmp cpu_2args
i1:
    mov rax, 1
    jmp cpu_2args
i2:
    mov rax, 2
    jmp cpu_2args
i3:
    mov rax, 3
    jmp cpu_2args
i4:
    mov rax, 4
    jmp cpu_2args
i5:
    mov rax, 5
    jmp cpu_2args
i6:
    mov rax, 6
    jmp cpu_2args
i7:
    mov rax, 7
    jmp cpu_2args
i8:
    mov rax, 8
    jmp cpu_3args
i9:
    mov rax, 9
    jmp cpu_2args
i10:
    mov rax, 0Ah
    jmp cpu_3args
i11:
    mov rax, 0Bh
    jmp cpu_3args
i12:
    mov rax, 0Ch
    jmp cpu_3args
i13:
    mov rax, 0Dh
    jmp short cpu_3args
i14:
    mov rax, 0Eh
    jmp short cpu_4args
i15:
    mov rax, 0Fh
    jmp short cpu_2args
i16:
    mov rax, 10h
    jmp short cpu_2args
i17:
    mov rax, 11h
    jmp short cpu_3args
i18:
    mov rax, 12h
    jmp short cpu_2args
i19:
    mov rax, 13h
    jmp short cpu_2args
i20:
    mov rax, 14h
    jmp short cpu_2args
i21:
    mov rax, 15h
cpu_4args:
    mov rcx, 3
    jmp short cpu_exception
cpu_3args:
    mov rcx, 2
    jmp short cpu_exception
cpu_2args:
    mov rcx, 1
cpu_exception:
    push rax
    push rcx
    mov bx, 001Fh    ;cls attribs
    call cls

    mov rax, 0200h
    xor rbx, rbx
    mov rdx, 0722h    ;7 Rows down, 24 columns across
    mov rbp, .fatalt0
    mov bx, 0071h     ;blue grey attribs, page 0
    mov ax, 1301h     ;print zero 8 chars, with bh attrib
    mov rcx, 8
    int 30h

    mov rax, 0200h
    xor bh, bh
    mov rdx, 0A04h    ;11 Rows down, 24 columns across
    int 30h
    mov rbp, .fatal1
    xor bh, bh        ;blue grey attribs, page 0
    mov ax, 1304h            ;print zero terminated string
    int 30h

    pop rcx
    pop rax                ;pop the exception number back into rax
    call .printbyte

    mov rax, 1304h
    xor bh, bh
    mov rbp, .fatal2
    int 30h

    cmp cl, 1
    ja .cpuextendederror    ;rax contains error code, or extra cr2 value
.cpurollprint:
    mov rdx, qword [rsp]    ;Get address
;Takes whats in rdx, rols left by one byte, prints al
    mov cl, 8    ;8 bytes
.cpurollprint1:
    rol rdx, 8
    mov al, dl
    push rdx
    call .printbyte
    pop rdx
    dec cl
    jnz .cpurollprint1

.cpuexendloop:
    xor ax, ax
    int 36h
    cmp al, 1Bh    ;Check for escape pressed (unlikely?)
    je .cpu_exception_appret
    cmp al, 0Dh ;Check for enter pressed
    jne .cpuexendloop

    mov bx, 0007h    ;cls attribs
    call cls
    int 38h    ;Jump to debugger
.cpu_exception_appret:
    mov bx, 0007h    ;cls attribs
    call cls
    iretq ;Return to address on stack

.cpuextendederror:
    pop rdx
    dec rcx
    push rcx
    mov cl, 2    ;CAN CHANGE TO 4 BYTES IN THE FUTURE
.pr1:
    rol edx, 8    ;Print just edx
    mov al, dl
    push rdx
    call .printbyte
    pop rdx
    dec cl
    jnz .pr1

    mov rax, 1304h
    mov rbx, 17h
    mov rbp, .fatal2
    int 30h
    pop rcx    ;Bring the comparison value back into rcx
    
    dec rcx
    jz .cpurollprint

    mov cl, 8
    mov rdx, cr2    ;Get page fault address
.pr2:
    rol rdx, 8    ;Print rdx
    mov al, dl
    push rdx
    call .printbyte
    pop rdx
    dec cl
    jnz .pr2

    mov rax, 1304h
    mov rbx, 17h
    mov rbp, .fatal2
    int 30h
    
    jmp .cpurollprint


.char:    ;Print a single character
    mov rbx, .ascii
    xlatb    ;point al to entry in ascii table, using al as offset into table
    ;xor bh, bh
    mov ah, 0Eh
    int 30h    ;print char
    ret
.printbyte:
    mov dl, al            ;save byte in dl
    and ax, 00F0h        ;Hi nybble
    and dx, 000Fh        ;Lo nybble
    shr ax, 4            ;shift one hex place value pos right
    call .char
    mov ax, dx            ;mov lo nybble, to print
    call .char
    ret    
.fatalt0:  db "SCP/BIOS"
.fatal1:   db "A potentially fatal error has occured. To continue: ",0Ah,0Ah,0Dh
db "    Press Enter to launch SYSDEBUG, or",0Ah,0Ah,0Dh 
db "    Press ESC to try and return to the application which caused the error," 
db "or", 0Ah, 0Ah,0Dh,
db "    Press CTRL+ALT+DEL to restart your system. If you do this,",0Ah,0Dh
db "    you will lose any unsaved information in all open applications.",0Ah, 
db 0Ah, 0Dh
db "    Error: ",0
.fatal2:   db " : ",0
.ascii:    db '0123456789ABCDEF'