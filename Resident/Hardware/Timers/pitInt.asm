;----------------Timer Interrupt IRQ 0/Int 20h-------------------
;This interrupt simply increments an internal timer and 
; calls a software interrupt (5Ch) which can be used by user 
; applications.
;----------------------------------------------------------------
timer_IRQ0:
    sti    
    push rax
    inc dword [pit_ticks]
    mov eax, dword [pit_ticks]
    and eax, 1FFFFFh    ;Clear OF bit [mask on bits 20:0]
    cmp eax, 1800B0h    ;Ticks in one full day
    jnz .tret            ;Not quite there
    mov word [pit_ticks], 0     ;Zero lo count
    mov byte [pit_ticks + 2], 0    ;Zero hi count
    inc byte [pit_ticks + 3]    ;Increment day OF counter    
.tret:
    int 3Ch        ;Call user handler

    mov al, EOI
    out pic1command, al
    out waitp, al    ;allow one io cycle to run

    pop rax
    iretq
;-------------------------End of Interrupt-----------------------