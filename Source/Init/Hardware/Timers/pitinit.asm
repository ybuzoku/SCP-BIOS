;----------------------------------------------------------------
;                PIT Initialisation procedure                   :
;----------------------------------------------------------------
PITreset:       ;Set Timer 0 to trigger every 55ms
    mov al, 36h    ;Set bitmap for frequency write to channel 0 of pit
    out PITcommand, al    ;43h = PIT command register
    mov ax, word [pit_divisor]
    out PIT0, al    ;mov low byte into divisor register
    mov al, ah      ;bring hi byte into low byte
    out PIT0, al    ;mov hi byte into divisor register
;PIT unmasked below
;----------------------------------------------------------------
;                     End of Initialisation                     :
;----------------------------------------------------------------