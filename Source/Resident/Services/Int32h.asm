;------------------------Basic RAM Int 32h-----------------------
;This interrupt returns in ax amount of conventional memory in ax
;----------------------------------------------------------------
convRAM_io:
    mov ax, word [convRAM]    ;Return the amount of conventional RAM
    mov r8, qword [userBase]    ;Return the userbase to a caller
    mov r9, qword [bigmapptr]   ;Return the big Map pointer 
    movzx r10, byte [bigmapSize]    ;Return the number of 24 byte entries
    iretq
;------------------------End of Interrupt------------------------