;----------------FDD Interrupt IRQ 6/Int 26h---------------------
fdd_IRQ6:
    push rax
    mov al, EOI
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------