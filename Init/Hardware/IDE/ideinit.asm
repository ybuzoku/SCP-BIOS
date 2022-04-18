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
    xor eax, eax
    ;Clean entries we want to read before hand
    mov word [rdi + idCurrCyl], ax     ;Clear current cylinders
    mov word [rdi + idCurrHed], ax     ;Clear current heads
    mov word [rdi + idCurrSecTk], ax   ;Clear current sectors/track
    mov dword [rdi + idLBASectrs], eax ;Clear UserAddressableSectors
    mov qword [rdi + idLBA48Sec], rax  ;Clear UserAddressableSectors for LBA48

    mov al, 0A0h
    mov dx, ata0_base
    mov rdi, sectorbuffer
    call ATA.identifyDevice
    ;Now get information and build tables here
    cmp dword [rdi + idLBASectrs], 0    ;Shouldn't be 0

    jmp short .ideInitEnd
.bad:

.ideInitEnd: