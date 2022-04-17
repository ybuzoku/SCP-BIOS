;A file containing common procs

;---------------------------------Procs--------------------------
e820print:
    push rsi
    push rdx
    push rcx
    push rbx
    push rax
    mov rsi, bigmapptr
    movzx rdx, byte [bigmapSize]    ;Get the number of 24 byte entries
.e0:
    lodsq
    call .printqword
    call .printpipe
    lodsq
    call .printqword
    call .printpipe
    lodsq   
    call .printqword
    call .printcrlf
    xor ax, ax
    int 36h
    dec rdx
    jnz .e0
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    ret
.printqword:
    mov rbx, rax
    bswap rbx
    mov rcx, 8
.pq1:
    mov al, bl
    mov ah, 04h
    int 30h
    shr rbx, 8
    loop .pq1
    ret
.printpipe:
    push rbp
    mov rbp, .pipestr
    mov ax, 1304h
    int 30h
    pop rbp
    ret
.pipestr:   db " | ",0
.printcrlf:
    push rbp
    mov rbp, .crlfstr
    mov ax, 1304h
    int 30h
    pop rbp
    ret
.crlfstr: db 0Ah,0Dh, 0
beep:
;Destroys old PIT2 divisor.
;Input: 
;   bx = Frequency divisor to use for tone
;   rcx = # of ms to beep for
;All registers preserved
    push rax
    mov al, 0B6h ;Get PIT command bitfield, PIT2, lo/hi, Mode 3, Binary
    out PITcommand, al

    mov ax, bx       ;Move frequency divisor into ax
    out PIT2, al     ;Output lo byte of divisor
    mov al, ah
    out PIT2, al     ;Output hi byte of divisor

    in al, port61h  ;Save original state of port 61h in ah
    or al, 3        ;Set bits 0 and 1 to turn on the speaker
    out port61h, al

    mov ah, 86h     ;Wait for beep to complete
    int 35h

    in al, port61h    ;Read state of port 61h afresh
    and al, ~3        ;Clear bits 0 and 1 to turn off the speaker
    out port61h, al

    pop rax
    ret

ps2wait:
    push rax
.wnok:
    jmp short $ + 2
    in al, ps2status
    test al, 1    ;Can something be read from KB?
    jz .wok       ;Zero = no, so loop back. Not zero = proceed to check if 
                  ; something can be written
    jmp short $ + 2
    in al, ps2data    ;Read it in
    jmp short .wnok
.wok:
    test al, 2   ;Can something be written to KB?
    jnz .wnok    ;Zero if yes and proceed.
    pop rax
    ret
    
idtWriteEntry:
;----------------------------------------------------------------
;This proc writes an interrupt handler to a particular IDT entry.
; rax = Interrupt handler ptr    (qword)
; rsi = Interrupt Number         (qword)
; dx = Attributes word           (word)
; bx = Segment selector          (word)
;On return:
; rsi incremented by 1
; Entry written
;----------------------------------------------------------------
    push rsi
    shl rsi, 4h     ;Multiply IDT entry number by 16
    add rsi, qword [IDTpointer.Base]    ;rsx points to IDT entry
    mov word [rsi], ax  ;Get low word into offset 15...0
    mov word [rsi + 2], bx  ;Move segment selector into place
    mov word [rsi + 4], dx  ;Move attribute word into place
    shr rax, 10h    ;Bring next word low
    mov word [rsi + 6], ax  ;Get low word into offset 31...16
    shr rax, 10h    ;Bring last dword low
    mov dword [rsi + 8], eax
    pop rsi
    inc rsi         ;rsi contains number of next interrupt handler
    ret
    
cls:    ;Clear the screen, bl attrib, always clear active scr
    push rax
    push rdx
    mov ah, 0Fh
    int 30h ;Get current active page

    mov ah, 02h    ;Set cursor pos
    xor dx, dx
    int 30h
    mov bh, bl
;No need for coordinates since al=00 means reset fullscreen
    mov ax, 0600h
    int 30h    ;scroll page with grey on black
    pop rdx
    pop rax
    ret