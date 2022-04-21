;-----------------System Timer Interrupt Int 3Ah-----------------
;System Timer functions:
; ah=0 -> Get tick count
; ah=1 -> Set tick count
; ah=2 -> Read RTC time
; ah=3 -> Set RTC time
; ah=4 -> Read RTC date
; ah=5 -> Set RTC date
; ah=6 -> Set RTC alarm
; ah=7 -> Reset RTC alarm
; ah=80h -> Get PIT divisor
; ah=81h -> Set PIT divisor
;----------------------------------------------------------------
timerInt:
    cmp ah, 80h
    jae .tiext
    test ah, ah
    jz .gett
    cmp ah, 1
    jz .sett
    cmp ah, 2
    jz .readRTCtime
    cmp ah, 3
    jz .setRTCtime
    cmp ah, 4
    jz .readRTCdate
    cmp ah, 5
    jz .setRTCdate
    cmp ah, 6
    jz .setRTCalarm
    cmp ah, 7
    jz .resetRTCalarm
.bad:
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    mov ah, 80h
.exit:
    iretq
.gett:
;Returns:
; al=Rolled over flag (0=not rolled)
; cx=Hi count
; dx=Lo count
    mov eax, dword [pit_ticks]
    mov dx, ax    ;Lo count
    shr eax, 10h    ;Bring high word down
    xor ch, ch
    mov cl, al
    mov al, ah
    movzx eax, al    ;Zero upper bytes
    mov byte [pit_ticks + 3], ah    ;Move 0 into day OF counter
    iretq
.sett:
;Called with:
; cx=Hi count (bzw. cl)
; dx=Lo count
;Returns: Nothing
    mov word [pit_ticks], dx
    xor ch, ch    ;Reset the OF counter
    mov word [pit_ticks + 2], cx
    iretq

.tiext:    ;Extended Timer functions
    sub ah, 80h
    jz .getpitdiv
    dec ah
    jz .setpitdiv
    jmp short .bad
.getpitdiv:
;Returns:
; ax=PIT divisor
    mov ax, word [pit_divisor]
    iretq
.setpitdiv:
;Called with:
; dx=divsor
;Returns: Nothing
    mov word [pit_divisor], dx
    push rax
    mov al, 36h ;Bitmap for frequency write to channel 0 of PIT
    out PITcommand, al
    mov ax, dx
    out PIT0, al    ;Send low byte of new divisor
    mov al, ah
    out PIT0, al    ;Send high byte of new divisor
    pop rax
    iretq

.readRTCtime:
; dh = Seconds
; cl = Minutes
; ch = Hours
; dl = Daylight Savings   
    push rax
    push rcx
    xor ecx, ecx    ;Long counter
.rrt0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah ;Disable NMI and and read bit 7. When 0, read
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .rrt0   ;If zero, fall and read RTC registers

    pop rcx         ;Pop upper word of ecx back
    mov al, 80h     ;Get seconds
    call .readRTC
    mov dh, al      ;Pack seconds in dh
    mov al, 82h     ;Get minutes
    call .readRTC
    mov cl, al      ;Pack minutes in cl
    mov al, 84h     ;Get Hours
    call .readRTC
    mov ch, al      ;Pack Hours in ch
    mov al, 8Bh     ;Get Status B for Daylight Savings
    call .readRTC
    and al, 1       ;Isolate bit 0
    mov dl, al      ;Pack Daylight Savings bit in dl
    mov al, 0Dh     ;Enable NMI
    call .readRTC
    pop rax
    iretq
.rrtbad:
    pop rcx
    pop rax
    stc
    ret 8   ;Set carry and return

.setRTCtime:
; dh = Seconds
; cl = Minutes
; ch = Hours
; dl = Daylight Savings 
    push rax
    push rcx
    xor ecx, ecx
.srt0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah ;Disable NMI and and read bit 7. When 0, write
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .srt0   ;If zero, fall and write RTC registers

    pop rcx
    mov al, 8Bh
    call .readRTC
    and dl, 1   ;Ensure we only have the low bit of dl
    or al, dl   ;Set the daylight savings bit of Status B
    or al, 80h  ;Stop RTC updates
    mov ah, al
    mov al, 8Bh ;Reset Status B Register, and daylight savings
    call .writeRTC

    mov ah, dh  ;Pack seconds
    mov al, 80h
    call .writeRTC
    mov ah, cl  ;Pack minutes
    mov al, 82h
    call .writeRTC
    mov ah, ch  ;Pack hours
    mov al, 84h
    call .writeRTC

    mov al, 8Bh
    call .readRTC
    and al, 7Fh ;Clear the top bit
    mov ah, al  ;Pack byte to send in ah
    mov al, 8Bh
    call .writeRTC  ;Restart RTC

    mov al, 0Dh   ;Enable NMI
    call .readRTC

    pop rax
    iretq
    
.readRTCdate:
; ch = Reserved, Century (19/20/21...), fixed 20h for now
; cl = Year
; dh = Month
; dl = Day
    push rax
    push rcx
    xor ecx, ecx
.rrd0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah     ;Disable NMI and and read bit 7. When 0, write
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .rrd0       ;If zero, fall and read RTC registers

    pop rcx
    mov al, 87h     ;Get Day of the Month
    call .readRTC
    mov dl, al      ;Pack Day of the Month
    mov al, 88h     ;Get Month of the Year
    call .readRTC
    mov dh, al      ;Pack Month of the Year
    mov al, 89h     ;Get bottom two digits of year
    call .readRTC
    mov cl, al      ;Pack Year
    mov ch, 20      ;BCD value for 20

    pop rax
    iretq

.setRTCdate:
; ch = Reserved, Century (19/20/21...), fixed 20h for now
; cl = Year
; dh = Month
; dl = Day
    push rax
    push rcx
    xor ecx, ecx
.srd0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah     ;Disable NMI and and read bit 7. When 0, write
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .srd0       ;If zero, fall and write RTC registers

    pop rcx
    mov al, 8Bh
    call .readRTC
    or al, 80h      ;Stop RTC updates
    mov ah, al
    mov al, 8Bh
    call .writeRTC
    mov ah, dl      ;Pack Day of the Month
    mov al, 87h
    call .writeRTC
    mov ah, dh      ;Pack Month of the Year
    mov al, 88h
    call .writeRTC
    mov ah, cl      ;Pack Year
    mov al, 89h
    call .writeRTC

    mov al, 8Bh
    call .readRTC
    and al, 7Fh ;Clear the top bit
    mov ah, al  ;Pack byte to send in ah
    mov al, 8Bh
    call .writeRTC  ;Restart RTC

    mov al, 0Dh   ;Enable NMI
    call .readRTC

    pop rax
    iretq

.setRTCalarm:
; dh = Seconds for alarm
; cl = Minutes for alarm
; ch = Hours for alarm
    push rax
    mov al, 8BH ;Get status B
    call .readRTC
    test al, 20h
    jnz .srabad ;If The alarm bit is already set, exit CF=CY

    mov ah, dh      ;Pack Seconds for alarm
    mov al, 81h     
    call .writeRTC
    mov ah, cl      ;Pack Minutes for alarm
    mov al, 83h
    call .writeRTC
    mov ah, ch      ;Pack Hours for alarm
    mov al, 85h
    call .writeRTC

    mov al, 8Bh     ;Get Status B
    call .readRTC
    or al, 20h      ;Set Bit 5 - Alarm Interrupt Enable
    mov ah, al      ;Pack new Status B
    mov al, 8Bh
    call .writeRTC 

    mov al, 0Dh     ;Enable NMI
    call .readRTC

    pop rax
    iretq
.srabad:
    pop rax
    or byte [rsp + 2*8], 1 ;Set Carry Flag
    iretq  
.resetRTCalarm:
    push rax
    mov al, 8Bh     ;Get Status B
    call .readRTC
    and al, 0DFh    ;Clear Alarm Interrupt Enable
    mov ah, al
    mov al, 8Bh
    call .writeRTC

    mov al, 0Dh     ;Enable NMI
    call .readRTC 
    pop rax
    iretq

.readRTC:
;Reads an RTC port, interrupts disabled throughout
;Input: al = I/O port to read
;Output: al = I/O data
    cli
    out cmos_base, al
    out waitp, al
    in al, cmos_data
    sti
    ret
.writeRTC:
;Writes to an RTC port, interrupts disabled throughout 
;Input: al = I/O port to read, ah = Data byte to send
    cli
    out cmos_base, al
    out waitp, al
    mov al, ah
    out cmos_data, al
    sti
    ret
;------------------------End of Interrupt------------------------