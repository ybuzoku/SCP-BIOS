;---------------HDD Interrupt IRQ 14/Int 2Eh---------------------
hdd_IRQ14:
    push rax
    mov byte [ir14_mutex], 0
    mov al, EOI
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------