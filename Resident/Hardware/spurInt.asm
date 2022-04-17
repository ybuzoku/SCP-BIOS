;-----------------Spurious Int Handler/Int 27h-------------------
; Catches and handles spurious interrupts on the first pic.
;----------------------------------------------------------------
default_IRQ7:
    push rax
    mov al, 0Bh    ;Read ISR 
    out pic1command, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, pic1command    ;Get the ISR
    test al, 80h
    jne .exit
    inc byte [spurint1]
    jmp short .e2    ;Avoid sending EOI
.exit:
    mov al, EOI
    out pic1command, al
.e2:
    pop rax
    iretq

;-----------------Spurious Int Handler/Int 2Fh-------------------
; Catches and handles spurious interrupts on the second pic.
;----------------------------------------------------------------
default_IRQ15:
    push rax
    cmp byte [ir15_mutex], 1    ;Check if mutex set
    jne .spurcheck              ;If not set, then just check spur
    mov byte [ir15_mutex], 0    ;Exit and check spur
.spurcheck:
    mov al, 0Bh    ;Read ISR 
    out pic2command, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, pic2command    ;Get the ISR
    test al, 80h
    mov al, EOI    ;Still need to send EOI to pic1
    jne .exit
    inc byte [spurint2]
    jmp short .e2    ;Avoid sending EOI
.exit:
    out pic2command, al
.e2:
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------