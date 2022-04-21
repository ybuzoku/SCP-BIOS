;------------------Serial Interrupt IRQ 3/Int 23h----------------
;Serves serial ports 1 and 3 should they exist. Only considers 
; data recieving. Disregards all sending data interrupts.
;Puts recieved data into respective buffer and clears RTS 
; (base+5) if buffer full.
;----------------------------------------------------------------
ser_IRQ3:
    cli
    push rax
    push rdx
    push rbp
    push rcx
    push rdi
    push rbx

    mov ebx, 8
    mov dx, com2_base + 2 ;Interrupt ID register
    jmp short ser_common
;------------------------End of Interrupt------------------------
;---------------------Serial Interrupt IRQ 3/Int 23h-------------
;Serves serial ports 1 and 3 should they exist. Only considers 
; data recieving. Disregards all sending data interrupts.
;Puts recieved data into respective buffer and clears RTS 
; (base+5) if buffer full.
;----------------------------------------------------------------
ser_IRQ4:
    cli
    push rax
    push rdx
    push rbp
    push rcx
    push rdi
    push rbx

    mov ebx, 6
    mov dx, com1_base + 2 ;Interrupt ID register
ser_common:
    in al, dx
    test al, 1    ;Check if bit zero is clear ie interrupt pending
    jz .si1       ;Clear, interrupt pending on COM 1 port
.si0:
    mov dx, word [com_addresses + rbx] ;now point to HI COM Interrupt ID registr
    test dx, dx
    jz .siexit            ;Nothing here, exit
    inc dx
    inc dx                ;dx = base + 2
    in al, dx
    test al, 1     ;Check if bit zero is clear
    jnz .siexit    ;Bad behavior, or no Int on com3 after com1 processed, exit
.si1:
;Confirm Data available Interrupt (ie bits 1,2,3 are 010b)
    test al, 00000100b
    jz .siexit   ;bad behavior, exit
    add dx, 3    ;dx = base + 5
.si41:
    in al, dx
    and al, 1
    jz .si41

    sub dx, 5
    in al, dx    ;get char into al
    mov ah, al   ;save al in ah temporarily
    xor rcx, rcx
.si2:    ;Get offset into table structures into cx
    cmp dx, word [com_addresses + rcx*2]    ;table of addresses, dx is at base
    je .si3
    inc cx
    cmp cx, 4    ;rcx should be {0,3}
    jl .si2
    jmp short .siexit    ;bad value, exit
.si3:    ;Store in buffer algorithm
    mov rbx, qword [comX_buf_tail + rcx*8]
    mov rdi, rbx
    inc rbx        ;increment by one char
    cmp rbx, qword [comX_buf_end + rcx*8]
    jne .si4
    mov rbx, qword [comX_buf_start + rcx*8]    ;Wrap around buffer
.si4:
    cmp rbx, qword [comX_buf_head + rcx*8]    ;Check if buffer full
    je .si5    ;Buffer full, indicate wait to data source

    mov byte [rdi], ah    ;store char into buffer
    mov qword [comX_buf_tail + rcx*8], rbx    ;store new tail into variable

    jmp .si0    ;If com1/2, now check that com 3/4 didnt fire interrupt.

.si5:    ;Buffer full, Deassert DTR bit 
;dx points at the base register
    add dx, 4    ;Point at Modem Control Register
    in al, dx
    and al, 11111110b    ;Clear the bottom bit
    out dx, al    ;Set the DTR bit down (not ready to recieve data)
    add dx, 3    ;Point to scratch register
    mov al, ah    ;return ah into al
    out dx, al    ;put the overrun char into scratch register
    cmp cx, 2    ;If this was com1/2, now check for com 3/4.
    jne .si0
;exit since we dont want to take whats in the UART buffer just yet.
.siexit:
    mov al, EOI
    out pic1command, al

    pop rbx
    pop rdi
    pop rcx
    pop rbp
    pop rdx
    pop rax
    sti
    iretq
;------------------------End of Interrupt------------------------