;----------------------------------------------------------------
;             PS/2 Keyboard Initialisation procedure            :
;----------------------------------------------------------------
keybsetup:    ;proc near
    mov ax, 0E0Ah
    int 30h
    mov ax, 0E0Dh
    int 30h    ;Send a crlf to con

    mov ax, 1304h
    xor bh, bh
    mov rbp, ps2stage.startMsg ;Prompt to strike a key
    int 30h

    mov al, 05Fh        ;PS/2 Stage signature
    out waitp, al
    out bochsout, al    

    xor r8, r8          ;use as an stage counter 
    jmp .step1
.kbscdetermine:
    mov al, 0F0h    
    call ps2talk.p3
    call ps2talk.p1
    cmp al, 0FAh        ;ACK?
    jne .kbscdetermine  ;Not ack, try again
.pt1:
    xor al, al
    call ps2talk.p3
    call ps2talk.p1     ;Get ack into al, 
    cmp al, 0FAh
    jne .pt1
    call ps2talk.p1     ;Get scancode into al
    ret

;----------------------------------------------------------------
;Do all writes using ps2talk:
;    ah = 0 - Read Status port into al
;    ah = 1 - Read Data port into al
;    ah = 2 - Write al into Command port 
;    ah = 3 - Write al into Data port
;----------------------------------------------------------------
; Step 1) Disable ps2 port 1 using command word ADh and port 2 using command 
;  word A7h.
; Step 2) Flush buffer and check bit 2 is set (else fail)
; Step 3) Read controller configuration byte (command word 20h)
; Step 4) Disable IRQs bits 0,1 (clear bit 0,1) [and manually disable second 
;  ps2 port (bit 5 set)]
; Step 5) Write controller config byte back (command word 60h)
; Step 6) Test controller using AAh command word. Return 55h or fail.
; Step 7) Test ps2 port 1 using ABh command word. Return 00h or fail.
; Step 8) Enable ps2 port 1 using AEh command word. Enable IRQ by setting bit 0 
;  of the config byte.
; Step 9) Reset ps2 port 1 device using FFh data word. If AAh returned, 
;  proceed, else if ACK (FAh), await AAh. FCh and FDh indicate fail. FEh = 
;  resend command.
; Step 10) Reset scan code set to 1 using F0h data word with 01h data word. If 
;  ACK (FAh) proceed, if RESEND (FEh), resend 10h tries.
; Setp 11) Enable scanning (ie keyboard sends scan codes) using data word F4h.
;----------------------------------------------------------------
;Step 1
.step1:
    mov al, 0ADh
    call ps2talk.p2
    mov al, 0A7h        ;Cancel second interface if it exists (DO NOT REENABLE)
    call ps2talk.p2
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 1
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 2

    in al, ps2data     ;manually flush ps2data port
    
;Step 3
keyb0:
    mov al, 20h
    call ps2talk.p2    ;out ps2command, al
    call ps2talk.p1    ;Read config byte into al
;Step 4
    mov bl, al         ;copy al into bl to check for bit 2
    and bl, 10111100b  ;Disable translation, enable later if needed
;Step 5
    mov al, 60h
    call ps2talk.p2    ;Write config byte command
    mov al, bl
    call ps2talk.p3    ;Out new config byte
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8             ;Checkpoint 2
    call ps2stage      ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 6
    mov al, 0AAh ;Can reset the config byte, out bl to ps2data at end of stage
    call ps2talk.p2
    call ps2talk.p1
    cmp al, 55h
    jne ps2error
    
    mov al, 60h  ;Previous code may have reset our new config byte, resend it!
    call ps2talk.p2            ;Write config byte command
    mov al, bl
    call ps2talk.p3            ;Out new config byte
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8             ;Checkpoint 3
    call ps2stage      ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 7
    mov al, 0ABh            ;Test controller 1
    call ps2talk.p2
    call ps2talk.p1
    test al, al                ;Check al is zero
    jnz ps2error
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8             ;Checkpoint 4
    call ps2stage      ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 8
    mov al, 0AEh
    call ps2talk.p2

;Set IRQ 1 to connect to port 1
    mov al, 20h
    call ps2talk.p2        ;Write
    call ps2talk.p1        ;Read
    or al, 00000001b    ;Set bit 0
    and al, 11101111b    ;Zero bit 4, First port Clock
    mov bl, al
    mov al, 60h
    call ps2talk.p2
    mov al, bl
    call ps2talk.p3
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 5
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 9
    xor cx, cx
keyb1:
    dec cx ;timeout counter
    jz ps2error
    mov al, 0FFh
    call ps2talk.p3
.k1:
    call ps2talk.p1 ;read from ps2data
    cmp al, 0AAh    ;success
    je keyb20
    cmp al, 0FAh    ;ACK    
    je .k1          ;Loop if ACK recieved, just read ps2data
    jmp keyb1       ;Else, loop whole thing (assume fail recieved)
;Step 10
keyb20:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 6
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    xor ecx, ecx
keyb2:
    dec ecx
    jz ps2error
.k0:
    mov al, 0F0h
    call ps2talk.p3
    
    mov ah, 01h
    call ps2talk.p1
    cmp al, 0FEh    ;Did we recieve an resend?
    je .k0          ;Resend the data!
    cmp al, 0FAh    ;Compare to Ack?
    jne keyb2       ;If not equal, dec one from the loop counter and try again
    
    mov al, 01h     ;write 01 to data port (set scan code set 1)
    call ps2talk.p3
.k1:
    call ps2talk.p1    ;read data port for ACK or resend response
    cmp al, 0FAh
    je keyb30    ;IF ack revieved, scancode set, advance.
    loop .k1     ;Keep polling port
    jmp keyb2
;Step 11
keyb30:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 7
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    xor ecx, ecx
keyb3:
    dec cx
    jz ps2error
    
    mov al, 0F4h
    call ps2talk.p3
.k1:
    call ps2talk.p1 ;read data port for ACK or resend response
    cmp al, 0FAh
    je keyb40
    loop .k1        ;Keep polling port
    jmp keyb3       ;Fail, retry the whole process
    
;Step 12
keyb40:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 8
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
keyb4:
    mov al, 0EDh     ;Set lights
    call ps2talk.p3
    call ps2talk.p1  ;get response, remember ps2talk does its own timeout
    cmp al, 0FAh
    jne keyb4        ;No ack, try again.
.k1:
    mov al, 00h        ;Flash lock on and off
    call ps2talk.p3
    call ps2talk.p1    ;flush, remember ps2talk does its own timeout
    
;End Proc
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 9
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

keyb5:
    mov al, 0EEh     ;Echo command
    call ps2talk.p3
    xor al, al       ;Zero al to ensure that the result is EEh
.k1:
    call ps2talk.p1
    cmp al, 0EEh
    je .k2           ;If equal, continue
    mov rbp, .noecho
    mov ax, 1304h
    xor bh, bh
    int 30h
    pause
    jmp short .k2
.noecho:        db    "No Echo recieved", 0Ah, 0Dh, 0
.k2:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 0Ah
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
keyb6:    ;Set typematic rate/delay, 250ms, 30 reports/second
    mov al, 0F3h     ;Set typematic rate
    call ps2talk.p3
    xor al, al       ;Set rate
    call ps2talk.p3
    xor cx, cx
.k1:
    dec cx
    jz ps2error
    call ps2talk.p1
    cmp al, 0FAh    ;Ack?
    jnz .k1
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 0Bh
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
scancode_faff:
    mov al, 20h      ;Get command byte from command port
    call ps2talk.p2  ;al should contain command byte
    mov ah, al       ;temp save cmd byte in ah

    xor ecx, ecx
.p1:
    dec cx
    jz keybflushe
    call keybsetup.kbscdetermine ;Get the current scancode set id
    or ah, 00000001b    ;Do basic or, ie set IRQ for port 1

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 0Ch
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

    cmp al, 43h      ;43h is sc1 signature
    je .writeback
    cmp al, 01h      ;Untranslated value
    je .writeback
    cmp al, 0FAh     ;Got an ACK for some reason, manually get next byte
    je .get_next_byte

    or ah, 01000000b    ;Neither value passed the test, invoke translation
.writeback:
    mov r15, rax     ;Save the scancode value to print later
    mov al, 60h
    call ps2talk.p2
    mov al, ah       ;return command byte
    call ps2talk.p3
    jmp short keybflush
.get_next_byte:
    call ps2talk.p1  ;Get the byte safely into al!
    jmp short .p1    ;Recheck the scancode signature

keybflushe:
    or r15b,0F0h    ;Add signature to scancode value denoting error
keybflush:    ;Flush internal ram of random bytes before enabling IRQ1
    mov cx, 10h
.kbf1:
    dec cx
    jz keybinitend
    in al, ps2data        ;Read 16 bytes out (even if empty) and discard
    jmp short .kbf1

keybinitend:
    xor bh, bh  ;We are on page 0
    mov ah, 03h ;Get current cursor row number in dh 
    int 30h
    mov dl, 17  ;End of PS/2 Keyboard message at column 17
    xor bh, bh  ;Page 0
    mov ah, 02h ;Set cursor
    int 30h

    push rdx    ;Save row/column in dx on stack
    mov ecx, 27 ;27 chars in keystrike message
.kbe0:
    mov eax, 0E20h 
    int 30h
    loop .kbe0

    pop rdx
    xor bh, bh  ;Page 0
    mov ah, 02h ;Set cursor
    int 30h

    mov rbp, ps2stage.okMsg
    mov rax, 1304h    ;print 0 terminated string
    xor bh, bh
    int 30h

;Unmask IRQ1 here
    in al, pic1data
    and al, 0FDh    ;Unmask bit 1
    out pic1data, al

    jmp endPS2Init
;Relevant Procs for PS/2 keyboard setup
ps2talk:
;   ah = 0 - Read Status port into al
;   ah = 1 - Read Data port into al
;   ah = 2 - Write al into Command port 
;   ah = 3 - Write al into Data port
    test ah, ah
    jz .p0
    dec ah
    jz .p1
    dec ah
    jz .p2
    jmp .p3
.p0:
    in al, ps2status
    ret
.p1:
    jmp short $ + 2
    in al, ps2status
    test al, 1    ;Can something be read from KB?
    jz .p1        ;Zero if no. Not zero = read.
    jmp short $ + 2
    in al, ps2data  ;Read it in
    ret
.p2:
    call ps2wait    ;preserves ax
    out ps2command, al
    ret
.p3:
    call ps2wait
    out ps2data, al
    ret
ps2error:
    mov rbp, .ps2errormsg
    mov ax, 1304h
    xor bh, bh
    int 30h
.loop:
    pause
    jmp short .loop
.ps2errormsg: db 0Ah, 0Dh,"PS/2 stage init error...", 0Ah, 0Dh, 0

ps2stage:
;Outputs r8b to waitport and Bochs out
    push rax
    mov al, r8b
    out waitp, al
    out bochsout, al
    pop rax
    ret
.startMsg db 0Ah, 0Dh,'PS/2 Keyboard... Strike a key to continue...',0 
.okMsg db 'OK', 0 ;This should go 17 chars in
endPS2Init:
;----------------------------------------------------------------
;                      End of Initialisation                    :
;----------------------------------------------------------------