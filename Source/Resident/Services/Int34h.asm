;------------------Serial IO Interrupts Int 34h------------------
serial_baud_table:    ;DLAB devisor values
    dw    0417h    ;110 baud,     00
    dw    0300h    ;150 baud,     01
    dw    0180h    ;300 baud,     02
    dw    00C0h    ;600 baud,     03
    dw    0060h    ;1200 baud,    04
    dw    0030h    ;2400 baud,    05 
    dw    0018h    ;4800 baud,    06
    dw    000Ch    ;9600 baud,    07
    dw    0006h    ;19200 baud,   08
    dw    0003h    ;38400 baud,   09
    dw    0002h    ;57600 baud,   0A
    dw    0001h    ;115200 baud,  0B
serial_abt: ;serial port address base table. List of supported addresses!
    dw com1_base
    dw com2_base
    dw com3_base
    dw com4_base
serial_io:
    push rdx        ;Save upper 7 bytes
    cmp dl, 4        ;Check to see if the selected com port is within range
    jge .sbadexit1    ;Bad dx value
    movzx rdx, dl    ;zero the upper 6 bytes of rdx
    mov dx, word [com_addresses + rdx*2]    ;get serial port base addr into dx
    test dx, dx        ;is the address zero?
    jz .sbadexit2    ;com port doesnt exist
    push rax        ;Saves upper 6 bytes
    push rdx        ;Save base for exit algorithm

    test ah, ah
    jz .userinit
    dec ah 
    jz .transmit
    dec ah
    jz .recieve
    dec ah
    jz .sioexit    ;since this puts the status into ax
    dec ah
    jz .extinit
    dec ah
    jz .extstatus
    dec ah
    jz .custombaud

.badin:
    pop rdx
    pop rax
    mov ah, 80h    ;Invalid Function
    jmp short .sbadcommon
.sioexit:
    pop rdx   ;Get base back, to know exact offset
    pop rax        ;Return the upper bytes of rax into rax
    add dx, 5    ;point to the line status register
    in al, dx    ;get status
    mov ah, al    ;save line status in ah
    inc dx        ;point to the modem status register
    in al, dx    ;save modem status in al
    pop rdx
    iretq

.sbadexit1:    
    mov al, 0FFh    ;dx was too large
    jmp short .sbadcommon
.sbadexit2:
    mov al, 0FEh    ;COM port doesnt exist
.sbadcommon:
    pop rdx        ;return original rdx value
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq

.userinit:
    mov ah, al    ;save the data in ah for the baud rate
    add dx, 3    ;Point to the line control register
    and al, 00011111b   ;Zero out the upper three bits
    or al, 10000000b    ;Set the DLAB bit
    out dx, al 

    sub dx, 3    ;return point to base
    shr ax, 0Dh  ;0Dh=move hi bits of hi word into low bits of low word
    movzx rax, al    ;zero upper 7 bytes of rax

    mov ax, word [serial_baud_table + 2*rax]    ;rax is the offset into the table
    out dx, ax    ;dx points to base with dlab on, set divisor! (word out)
;Disable DLAB bit now
    add dx, 3
    in al, dx    ;Get the Line Control Register (preserving the written data)
    and al, 01111111b    ;Clear the DLAB bit, preserve the other bits
    out dx, al    ;Clear the bit

    jmp short .sioexit    ;exit!

.transmit:
    add dx, 5    ;dx contains base address, point to Line status register
    mov ah, al   ;temp save char to send in ah
    push rcx
    xor ecx, ecx
.t1:
    dec ecx
    jz .t2       ;timeout
    in al, dx    ;get the LSR byte in
    and al, 00100000b    ;Check the transmit holding register empty bit
    jz .t1    ;if this is zero, keep looping until it is 1 (aka empty)

    pop rcx
    mov al, ah   ;return data byte down to al
    sub dx, 5    ;reaim to the IO port
    out dx, al   ;output the data byte to the serial line!!
    jmp short .sioexit
.t2:
    pop rcx
    pop rdx      ;Get base back, to know exact offset
    pop rax      ;Return the upper bytes of rax into rax
    add dx, 5    ;point to the line status register
    in al, dx    ;get status
    mov ah, al   ;save line status in ah
    and ah, 80h  ;Set error bit (bit 7)
    inc dx       ;point to the modem status register
    in al, dx    ;save modem status in al
    pop rdx
    iretq
.recieve:
    ;Gets byte out of appropriate buffer head and places it in al
    pop rdx
    pop rax        
    pop rdx    ;Undoes the address entry and returns COM port number into dx    
    push rdx   ;Save it once more
    push rbx
    movzx rdx, dx

    cli    ;Entering a critical area, interrupts off
    mov rbx, qword [comX_buf_head + rdx*8]
    cmp rbx, qword [comX_buf_tail + rdx*8]
    je .r1    ;We are at the head of the buffer, signal error, no char to get.
    mov al, byte [rbx]    ;store byte into al
    mov ah, al ;temp save al in ah
    inc rbx    ;move buffer head
    cmp rbx, qword [comX_buf_end + rdx*8]    ;are we at the end of the buffer
    jne .r0    ;no, save new position
    mov rbx, qword [comX_buf_start + rdx*8]  ;yes, wrap around
.r0:
    mov qword [comX_buf_head + rdx*8], rbx   ;save new buffer position
    sti
    pop rbx
    pop rdx
    jmp short .rexit
.r1:
    sti
    mov ah, 80h    ;Equivalent to a timeout error.
    pop rbx
    pop rdx
    iretq

.rexit:    ;Line status in ah. Char was got so ensure DTR is now high again!
    mov dx, word [com_addresses + rdx*2]    ;Get the base address back into dx
    add dx, 4    ;point to the modem control register
    in al, dx
    test al, 1   ;Test DTR is clear
    jz .getscratch
.gsret:
    or al, 1    ;Set DTR bit on again
    out dx, al
    inc dx      ;point to the line status register
    in al, dx   ;get status
    xchg ah, al ;swap them around
    iretq
.getscratch:
    or al, 00010000b    ;Enable loopback mode with DTR on
    out dx, al
    add dx, 3    ;Point to scratch register
    in al, dx    ;Get overrun char
    sub dx, 7    ;transmit register
    out dx, al   ;send the char (no need to play with DTR, we sending to 
                 ; ourselves, generating an INT)
    add dx, 4    ;point back to modem control register again!
    in al, dx
    and al, 11101111b    ;Clear loopback mode, DTR bit gets set in main proc
    jmp short .gsret    

.extinit:
.extstatus:
.custombaud:
    pop rdx
    pop rax
    mov ah, 86h
    jmp .sbadcommon
;------------------------End of Interrupt------------------------