;---------------HDD Interrupt IRQ 14/Int 2Eh---------------------
hdd_IRQ14:
    push rax
    and byte [ata0CmdByte], 0FDh    ;Clear bit 1
    mov al, EOI
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------