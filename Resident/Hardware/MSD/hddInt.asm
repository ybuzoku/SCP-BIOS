;---------------HDD Interrupt IRQ 14/Int 2Eh---------------------
hdd_IRQ14:
    push rax
    push rdx
    and byte [ata0CmdByte], 0FDh    ;Clear bit 1
    mov dx, ata0_base + 7   ;Since this interrupt ONLY occurs on ata0
    in al, dx   ;Read the status, and stop the controller from firing again

    mov al, EOI
    out pic1command, al
    pop rdx
    pop rax
    iretq
;------------------------End of Interrupt------------------------