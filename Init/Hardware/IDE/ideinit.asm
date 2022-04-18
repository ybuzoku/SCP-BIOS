
IDE:
.ideInitialisation:
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
;===========================
;     Callable procs       :
;===========================
.addControllerTable:
;Adds a PCI IDE controller to the internal data tables, if there is space
; If there is no space, returns with carry set.
;Input: eax = BAR5 address
;       ebx = PCI IO address
;Output: CF=NC, all ok, CF=CY, device not added.
    push rsi
    cmp byte [ideNumberOfControllers], 2
    je .actfail ;If it is 2, fail
    inc byte [ideNumberOfControllers]
    mov rsi, ideControllerTable
    cmp byte [rsi], 0   ;Is the first entry empty?
    jz .act0    ;If yes, write entry
    add rsi, ideTableEntrySize  ;Else, goto second entry space
.act0:
    mov dword [rsi], ebx    ;Move first PCI IO addr
    mov byte [rsi], 0       ;Zero the register index
    mov dword [rsi + 4], eax    ;Move next data
    clc
.actexit:
    pop rsi
    ret
.actfail:
    stc
    jmp short .actexit

;============================
;     Exit target label     :
;============================
.ideInitEnd: