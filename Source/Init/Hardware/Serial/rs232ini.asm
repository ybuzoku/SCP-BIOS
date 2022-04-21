;----------------------------------------------------------------
;                Serial Port Initialisation procedure           :
;----------------------------------------------------------------
;Initial init procedure, check which ports exist and 
; write the address to Data area
    mov ax, 5A5Ah
    xor rcx, rcx
    mov rbp, com_addresses
checkCOM:
    mov dx, word [serial_abt + rcx*2]    ;Multiplied by 2 for word offsets
    add dx, 7    ;Scratch register
    out dx, al    ;Output
    jmp short $ + 2
    in al, dx    ;Read the value
    cmp ah, al   ;Check if theyre the same 
    jne COMinitproceed ;Scratch register non-existant, IO registers not present
    sub dx, 7    ;point dx back to base
    mov word [com_addresses + rcx*2], dx    ;Save dx into data area table
    inc cl
    cmp cl, 4
    jne checkCOM    ;Keep looping
COMinitproceed:
;Sets all active COM ports to 2400,N,8,1, FIFO on, hware handshaking
    mov byte [numCOM], cl
    xor cl, cl
serialinit:
    mov dx, word [com_addresses + rcx*2]  ;get the serial port base addr in dx
    test dx, dx
    jz COMinitexit    ;invalid address, port doesnt exist, init complete
;Disable interrupts
    inc dx        ;point at base + 1
    xor al, al    ;get zero to out it to the interrupt register
    out dx, al    ;Disable all interrupts
;Set DLAB
    add dx, 2    ;point dx to the Line Control register (LCR)
    in al, dx    ;get the LCR byte into al
    or al, 10000000b    ;set bit 7, DLAB bit on
    out dx, al    ;output the set bit
;Set baud rate
    sub dx, 3    ;word of baud divisor
    mov ax, 0030h    ;the divisor for 2400 baud (cf table below)
    out dx, ax    ;out put the divisor word
;Clear DLAB, set the parity, break stop and word length
    add dx, 3    ;repoint at LCR (base + 3)
    mov al, 00000011b  ;DLAB off, 8,n,1, no break, no stick
    out dx, al    ;out that byte
;Clear FIFO
    dec dx        ;base + 2, FIFO register
    mov al, 00000110b    ;Clear FIFO, set char mode
    out dx, al    ;out that stuff
;Enable interrupts and RTS/DTR
    dec dx        ;base + 1, Interrupt Enable Register
    mov al, 1     ;ONLY set the data receive interrupt, none of the other 
                  ; status or transmit type interrupts
    out dx, al

    add dx, 3    ;base + 4, Modem control register
    in al, dx    ;preserve reserved upper bits
    and al, 11100000b
    or al, 00001011b    ;Set OUT2 (ie IRQ enable), set RTS/DTR.
    out dx, al
    inc cx
    jmp short serialinit
COMinitexit:
;Unmask com ports here!
    in al, pic1data
    and al, 0E7h    ;Unmask Com lines 1 and 2 (bits 3 and 4)
    out pic1data, al
;----------------------------------------------------------------
;                     End of Initialisation                     :
;----------------------------------------------------------------