;----------------------------------------------------------------
;                PIC Initialisation procedure                   :
;----------------------------------------------------------------
;Remapping the IO ports to Interrupt 0x40
PICremap:
    mov al, 11h        ;bit 10h and 1h = Start initialisation
    out pic1command, al
    out waitp, al    
    out pic2command, al
    out waitp, al    
    
    mov al, 20h       ;PIC1 to take Int 20h - 27h
    out pic1data, al
    out waitp, al    
    add al, 8        ;PIC2 to take Int 28h - 2Fh
    out pic2data, al 
    out waitp, al    
    
    mov al, 4
    out pic1data, al    ;Tell PIC 1 that there is a PIC 2 at IRQ2 (00000100)
    out waitp, al    
    dec al
    dec al
    out pic2data, al    ;Tell PIC 2 its cascade identity (00000010)
    out waitp, al
    
    mov al, 01h        ;Initialise in 8086 mode
    out pic1data, al
    out waitp, al    
    out pic2data, al
    out waitp, al    
    
    mov al, 0FFh    ;Mask all interrupts 
    out pic1data, al
    out pic2data, al

;Ensure that interrupts are still masked
;----------------------------------------------------------------
;                        End of Initialisation                  :
;----------------------------------------------------------------