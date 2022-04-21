;------------Screen Mode Parameters Interrupt Int 3Dh-------------
;This Interrupt returns in r8 the pointer to screen mode 
; parameters. It replaces the nice pointers in the IVT of yore.
;Returns in r8 to not conflict with ported apps
;----------------------------------------------------------------
scr_params_io:
    mov r8, scr_mode_params
    iretq
;------------------------End of Interrupt------------------------