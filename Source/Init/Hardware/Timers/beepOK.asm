    ;This is a short routine to just confirm 
    ;that the timer initialisation worked fine
    mov rcx, 200    ;Beep for a 200ms
    mov ebx, 04A9h  ;Frequency divisor for 1000Hz tone
    mov ax, 0C500h
    int 35h