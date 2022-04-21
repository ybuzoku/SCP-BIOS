;----------------------------------------------------------------
;                RTC Initialisation procedure                   :
;----------------------------------------------------------------
rtc_init:
;Set tick rate to 1024Hz and ensure RTC doesnt generate IRQ8
    mov ax, 8A8Ah    ;Status A register with NMI disable
    out cmos_base, al
    out waitp, al    ;Latch wait
    jmp short $+2
    mov al, 00100110b ;32KHz timebase, 1024Hz square wave output
    out cmos_data, al
;Now ensure NO interrupts are cooked
    inc ah    ;ah=8Bh
    mov al, ah
    out cmos_base, al
    out waitp, al  ;Latch wait
    jmp short $+2
    mov al, 02h    ;Zero all int bits, time: BCD, 24hr, Daylight saving off
    out cmos_data, al
;Clear any cooked IRQs
    inc ah    ;ah=8Ch
    mov al, ah
    out cmos_base, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, cmos_data
;Get final CMOS RAM status byte
    mov al, 0Dh     ;Status D register with NMI enable
    out cmos_base, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, cmos_data
;Unmask RTC and PIT here!
    in al, pic2data    ;Get current state
    and al, 0FEh    ;Unmask RTC
    out pic2data, al
    in al, pic1data
    and al, 0FAh    ;Unmask PIT and Cascade
    out pic1data, al
    sti             ;Enable maskable interrupts
;----------------------------------------------------------------
;                     End of Initialisation                     :
;----------------------------------------------------------------