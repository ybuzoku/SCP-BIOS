;------------------------Printer Int 37h-------------------------
; Reserved for printer specific functions. Both USB and Parallel.
; Not currently supported
;----------------------------------------------------------------
printer_io:
    mov ah, 86h    ;Function not supported
    or byte [rsp+ 2*8h], 1    ;Set carry
    iretq
;------------------------End of Interrupt------------------------