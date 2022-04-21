;---------------RTC Interrupt IRQ 8/Int 28h----------------------
; This IRQ should only trigger for the periodic and alarm 
; interrupts. If a programmer wishes to use the time update 
; complete interrupt feature, they should hook their own 
; interrupt handler.
;----------------------------------------------------------------
rtc_IRQ8:
    push rax
    cli             ;Disable interrupts
    mov al, 8Ch     ;Register C with NMI disabled
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data    ;Get the data byte to confirm IRQ recieved
    and al, 060h        ;Isolate Alarm and Periodic bits only
    test al, 40h        ;Periodic?
    jz .noPeriodic      ;No, skip the periodic
.periodic:
    dec qword [rtc_ticks]
.noPeriodic:
    test al, 20h        ;Alarm?
    jz .exit
.alarm:
    int 6Ah    ;User Alarm handler, behaves like Int 4Ah on 16-bit BIOS
.exit:
    mov al, 0Dh     ;Read Register D and reenable NMI
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data    
    mov al, EOI
    out pic2command, al
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------