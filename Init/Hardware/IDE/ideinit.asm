ideInitialisation:
;This is truly read once code
;Check primary and secondary bus for master and slave drives
; Maximum of 4 "fixed" ATA drives
;Use PIO for identification of drives on bus
    jmp short .ideInitEnd
    mov al, 0A0h
    mov dx, ata0_base
    mov rdi, sectorbuffer
    call IDE.identifyDevice
.ideInitEnd: