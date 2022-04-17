;-----------------------Basic Config Int 31h---------------------
;This interrupt returns in ax the Hardware Bitfield from the 
; data area and the mass storage device details.
;----------------------------------------------------------------
machineWord_io:
    mov ax, word [MachineWord]    ;Return the legacy bitfield

    movzx r8, byte [i33Devices] ;Get Number of i33h devices
    shl r8, 8   ;Shift up by a byte
    mov r8b, byte [numMSD]  ;Get the number of Mass Storage Devices (on EHCI)
    shl r8, 8   ;Shift up by a byte again
    mov r8b, byte [fdiskNum]    ;Get the number of fixed disks
    shl r8, 8  ;Shift up by a byte again
    mov r8b, byte [numCOM]      ;Get the number of COM ports

    iretq
;------------------------End of Interrupt------------------------