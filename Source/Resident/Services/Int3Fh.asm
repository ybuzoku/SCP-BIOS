;------------------CGA font Interrupt Int 3Fh--------------------
;This Interrupt returns in r8 the pointer to the CGA font.
;It replaces the nice pointers in the IVT of yore.
;Returns in r8 to not conflict with ported apps
;----------------------------------------------------------------
cga_ret_io: ;Get first pointer in list
    movzx r8, word [scr_vga_ptrs]
    shl r8, 4
    add r8w, word [scr_vga_ptrs + 2]
    iretq
;------------------------End of Interrupt------------------------