ideInitialisation:
;Check primary and secondary bus for master and slave drives
; Maximum of 4 "fixed" ATA drives
;Due to being in compatibility mode, they respond to 
; default addresses.
;By default BIOS numbers will be assigned as follows: 
;               80h = Ctrlr 1, Master
;               81h = Ctrlr 1, Slave
;               82h = Ctrlr 2, Master
;               83h = Ctrlr 2, Slave
    mov al, 0A0h
    mov dx, ata0_base
    mov rdi, sectorbuffer
    call ATA.identifyDevice
    ;Now get information and build tables here
    jmp short .ideInitEnd

.ideInitEnd: