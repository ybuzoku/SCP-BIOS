;----------------------Video Interrupt Int 30h-------------------
scr_io_table:
    dq    scr_io.change_mode     ;AH = 0 -> Change Screen Mode (Currently no 
                                 ; options)
    dq    scr_io.set_curs_shape  ;AH = 1 -> Set Cursor Shape
    dq    scr_io.set_curs_pos    ;AH = 2 -> Set Cursor Position
    dq    scr_io.get_curs_pos    ;AH = 3 -> Get Cursor Position
    dq    scr_io.write_register  ;AH = 4 -> Reserved, Undoc, Write al in ASCII 
                                 ; at cursor 
    dq    scr_io.select_page     ;AH = 5 -> Select Active Page
    dq    scr_io.scroll_up       ;AH = 6 -> Scroll Active Page up
    dq    scr_io.scroll_down     ;AH = 7 -> Scroll Active Page down
    dq    scr_io.read_att_char   ;AH = 8 -> Read Attribute and Char at curs pos
    dq    scr_io.write_att_char  ;AH = 9 -> Write Attribute and Char at curs pos
    dq    scr_io.write_char      ;AH = 0Ah -> Write Char at curs position 
                                 ; (using default attribute)
    dq    scr_io.gset_col_palette ;AH = 0Bh -> Graphics, Set Colour Palette
    dq    scr_io.gwritedot       ;AH = 0Ch -> Graphics, Write a Dot to screen
    dq    scr_io.greaddot        ;AH = 0Dh -> Graphics, Read a Dot from screen
    dq    scr_io.write_tty       ;AH = 0Eh -> Write Teletype
    dq    scr_io.get_mode        ;AH = 0Fh -> Get Screen Mode (currently, no 
                                 ; options)
    dq    scr_io.exitf           ;AH = 10h -> Reserved
    dq  scr_io.exitf             ;AH = 11h -> Reserved
    dq    scr_io.exitf           ;AH = 12h -> Reserved
    dq  scr_io.write_string      ;AH = 13h -> Write string
scr_io_table_length    equ    $ - scr_io_table
scr_io:
    cld        ;set direction to read the right way
    push rsi
    push rax
    shl ah, 3  ;Use ah as offset into table
    cmp ah, (scr_io_table_length - 8)    ;Ensure function number is within table
    ja .exitf
    mov al, ah
    movzx rax, al               ;Zero extend ax into rax
    mov rsi, rax                ;Note rsi is not being saved here!
    pop rax                     ;recover back into ax
    mov ah, byte [scr_mode]     ;Get the current mode into ah
    jmp [scr_io_table + rsi]    ;Jump to correct function
.exitf:
    pop rax
    mov ah, 80h ;Function not supported
    or byte [rsp + 3*8h], 1 ;Set Carry flag, invalid function, skip rsi on stack
.exit:
    pop rsi
    iretq
    
.change_mode:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function    
.set_curs_shape:
;Input: CH = Scan Row Start, CL = Scan Row End
    push rdx
    mov word [scr_curs_shape], cx

    mov al, 0Ah
    call .write_crtc_word
    
    pop rdx
    jmp short .exit
.set_curs_pos:
;Input: DH = Row, DL = Column, BH = active page
    push rcx
    push rdx
    
    push rbx
    mov bl, bh
    movzx rbx, bl
    mov word [scr_curs_pos + 2*rbx], dx
    pop rbx
    cmp bh, byte [scr_active_page]
    jne .scpexit    ;if the page is not the active page
    call .cursor_proc
.scpexit:
    pop rdx
    pop rcx
    jmp short .exit
    

.get_curs_pos:
;Return: AX = 0, CH = Start scan line, CL = End scan line, DH = Row, DL = Column
    push rbx

    mov bl, bh
    movzx rbx, bl
    mov dx, word [scr_curs_pos + 2*rbx] 
    mov cx, word [scr_curs_shape]    ;Get cursor shape

    pop rbx
    xor ax, ax 
    jmp .exit

.write_register:    ;al contains the byte to convert
    push rdx
    push rbx
    push rax

    mov dl, al           ;save byte in dl
    and ax, 00F0h        ;Hi nybble
    and dx, 000Fh        ;Lo nybble
    shr ax, 4            ;shift one hex place value pos right
    call .wrchar
    mov ax, dx           ;mov lo nybble, to print
    call .wrchar

    pop rax
    pop rbx
    pop rdx
    jmp .exit
.wrchar:
    mov rbx, .wrascii
    xlatb    ;point al to entry in ascii table, using al as offset into table
    mov ah, 0Eh
    mov bl, 07h
    int 30h  ;print char
    ret
.wrascii:    db    '0123456789ABCDEF'
.select_page:
;ah contains the current screen mode
;al contains new screen page
;vga just returns as invalid FOR NOW
;Handled differently between vga and classic modes
    cmp ah, 04
    jbe .sp1
    cmp ah, 07
    je .sp1
    cmp ah, 0Dh
    jae .sp_vga
.spbad:
    mov rax, 0FFFFh
    jmp .exit    ;Bad argument
.sp1:
    cmp al, 8
    jae .spbad    ;page should be 0-7
.spmain:
    push rax
    push rbx
    push rcx
    push rdx
    mov byte [scr_active_page], al    ;change active page
;----Modify this proc with data tables when finalised!!----
    mov rsi, 800h    ;mode 0,1 page size
    mov rbx, 1000h    ;mode 2,3,7 page size
    movzx rcx, al    ;Get count into rcx
    cmp ah, 2
    cmovb rbx, rsi
    mov rdx, vga_bpage2
    mov rsi, vga_bpage1    ;Base addr for mode 7
;----Modify this proc with data tables when finalised!!----
    cmp ah, 7
    cmove rdx, rsi
    push rdx    ;Push the saved page 0 address
    jrcxz .spm2    ;If 0th page, dont add
.spm1:
    add rdx, rbx
    dec cl
    jnz .spm1
.spm2:
    pop rsi     ;Get saved base into rsi
    mov dword [scr_page_addr], edx    ;Get new base addr
    sub rdx, rsi    ;rsi has conditionally b8000 or b0000
    push rax
    shr dx, 1    ;Divide dx by 2 to get # of PELs
    mov cx, dx    ;Get offset from crtc base addr
    mov ax, 0Ch    ;6845 Start Addr register
    call .write_crtc_word    ;Change "crtc view window"

    pop rax        ;Get original ax back for page number
    mov bh, al
    call .cursor_proc    ;Move cursor on page
    
    pop rdx
    pop rcx
    pop rbx
    pop rax
    jmp .exit    ;Bad argument
.sp_vga:
    jmp .spbad

.scroll_up:
;Scrolls ACTIVE SCREEN only
;Called with AL=number of lines to scroll, BH=Attribute for new area
;    CH=ycor of top of scroll, CL=xcor of top of scroll
;    DH=ycor of bottom of scroll, DL=xcor of bottom of scroll
;If AL=0 then entire window is blanked, BH is used for blank attrib
;ah contains the current screen mode
    cmp ah, 04    ;Test for Alpha mode
    jb .su0
    cmp ah, 07    ;Test for MDA Alpha mode
    jne .gscrollup    ;We in graphics mode, go to correct proc
.su0:
    push rbp
    push rdi
    push rax    ;Treat AX more or less as clobbered 
    
    test al, al   ;Check if zero
    je .sblank    ;recall ah=06 then reset cursor and exit
    mov bl, al    ;Save number of lines to scroll in bl
.su1:
    mov esi, dword [scr_page_addr]    ;zeros upper dword
    mov rdi, rsi  ;Point both pointers at base of active page
    mov ax, cx    ;Bottom top corner into ax
    call .offset_from_ax    ;Get the page offset of dx
    movzx rax, ax
    shl rax, 1    ;Multiply by two for words
    add rdi, rax  ;point to the top left of window
    add rsi, rax
    movzx rax, byte [scr_cols]
    shl rax, 1      ;number of columns * 2 for words!
    add rsi, rax    ;Point rsi one row down
    push rcx
    push rdx

    sub dh, ch    ;work out number of rows to copy
.su2:
    push rsi
    push rdi
    call .text_scroll_c1    ;Scroll the selected row
    pop rdi
    pop rsi
    add rdi, rax    ;goto next row
    add rsi, rax
    dec dh
    jnz .su2

    pop rdx
    pop rcx
;Draw blank line
    push rax
    push rcx
    push rdi

    mov ax, cx
    mov ah, dh    ;Starting column from cx, starting row from dx
    call .offset_from_ax
    mov edi, dword [scr_page_addr]
    movzx rax, ax
    shl rax, 1
    add edi, eax   ;point to new line
    mov ah, bh
    mov al, 20h    ;Blank char
    mov rcx, rbp   ;move word count into cx
    rep stosw      ;write the word bp number of times
    pop rdi
    pop rcx
    pop rax
    dec bl
    jnz .su1    ;Once we have done bl rows, exit

.suexit:
    pop rax
    pop rdi
    pop rbp
    jmp .exit
.sblank:
;Fast clear function
    push rcx
    push rdx

    mov ah, bh    ;mov attrib into ah
    mov al, 20h    ;Space char
    mov edi, dword [scr_page_addr]
    movzx rdx, byte [scr_rows]
.sbl0:
    movzx rcx, byte [scr_cols]
    rep stosw
    dec dl
    jnz .sbl0

    pop rdx
    pop rcx
    jmp short .suexit

.scroll_down:
;Scrolls ACTIVE SCREEN only
;Called with AL=number of lines to scroll, BH=Attribute for new area
;    CH=ycor of top of scroll, CL=xcor of top of scroll
;    DH=ycor of bottom of scroll, DL=xcor of bottom of scroll
;If AL=0 then entire window is blanked, BH is used for blank attrib
;ah contains the current screen mode
    cmp ah, 04    ;Test for Alpha mode
    jb .sd0
    cmp ah, 07    ;Test for MDA Alpha mode
    jne .gscrolldown    ;We in graphics mode, go to correct proc
.sd0:
    push rbp
    push rdi
    push rax    ;Treat AX more or less as clobbered

    test al, al    ;Check if zero
    je .sblank    ;recall ah=06 then reset cursor and exit
    mov bl, al    ;Save number of lines to scroll in bl
    std    ;change the direction of string operations
.sd1:
    mov esi, dword [scr_page_addr]    ;point esi to bottom
    mov ax, dx    ;point to bottom right 
    call .offset_from_ax
    movzx rax, ax
    shl rax, 1
    add rsi, rax
    mov rdi, rsi
    movzx rax, byte [scr_cols]
    shl rax, 1
    sub rsi, rax    ;Point rsi one row above rdi

    push rcx
    push rdx
    sub dh, ch    ;Number of rows to copy
.sd2:
    push rsi
    push rdi
    call .text_scroll_c1
    pop rdi
    pop rsi
    sub rdi, rax
    sub rsi, rax
    dec dh
    jnz .sd2

    pop rdx
    pop rcx
;Draw blank line
    push rax
    push rcx
    push rdi

    mov ax, dx
    mov ah, ch    ;Starting column from dx, starting row from cx
    call .offset_from_ax
    mov edi, dword [scr_page_addr]
    movzx rax, ax
    shl rax, 1
    add edi, eax    ;Point to appropriate line and col
    mov ah, bh
    mov al, 20h
    mov rcx, rbp
    rep stosw    ;Store backwards
    pop rdi
    pop rcx
    pop rax
    dec bl
    jnz .sd1

.sdexit:
    pop rax
    pop rdi
    pop rbp
    jmp .exit
.read_att_char:
;Get ASCII char and attr at current cursor position on chosen page
;Called with AH=08h, BH=Page number (if supported),
;Returns, AH=Attrib, AL=Char

;On entry, ah contains current screen mode
    cmp ah, 04    ;Test for Alpha mode
    jb .rac1
    cmp ah, 07    ;Test for MDA Alpha mode
    jne .gread    ;We in graphics mode, go to correct proc
.rac1:
    cmp bh, 7
    ja .exitf    ;All A/N modes can have 8 pages, any more, fail

    mov bl, ah    ;Move screen mode into bl for function call
    mov esi, dword [scr_page_addr]
    call .page_cursor_offset    ;bx preserved
    shl rax, 1        
    add rsi, rax    ;rsi should point to attrib/char 
    lodsw            ;Load ah with attrib/char
    jmp .exit    ;Restoring rsi

.write_att_char:
;Puts ASCII char and attribute/colour at cursor
;Called with AH=09h, AL=Char, BH=Page, 
;    BL=Attrib/Color, CX=number of repeats
;Returns nothing (just prints in page)

;When called, ah contains current screen mode
    cmp ah, 04    ;Test for Alpha mode
    jb .wac1
    cmp ah, 07    ;Test for MDA Alpha mode
    jne .gwrite    ;We in graphics mode, go to correct proc
.wac1:
    cmp bh, 7
    ja .exitf    ;All A/N modes can have 8 pages, any more, fail

    xchg bl, ah ;swap attrib and scr mode bytes
    push rdi
    push rax    ;Save the char/attrib word
    mov esi, dword [scr_page_addr]
    call .page_cursor_offset    ;bx preserved
    mov rdi, rsi    ;Change register for string ops
    shl rax, 1
    add rdi, rax    ;rsi now points to right place on right page
    pop rax

    push rcx
    movzx rcx, cx    ;zero upper bytes
    rep stosw        ;Store packed ah/al cx times
    pop rcx
    pop rdi
    jmp .exit    ;Restoring rsi

.write_char:
;Puts ASCII char and attribute/colour at cursor
;Called with AH=0Ah, AL=Char, BH=Page, 
;    BL=Color (G modes ONLY), CX=number of repeats
;Returns nothing (just prints in page)
    cmp ah, 04    ;Test for Alpha mode
    jb .wc1
    cmp ah, 07    ;Test for MDA Alpha mode
    jne .gwrite    ;We in graphics mode, go to correct proc
.wc1:
    cmp bh, 7
    ja .exitf    ;All A/N modes can have 8 pages, any more, fail

    mov bl, ah ;mov scr mode byte into bl
    push rdi
    push rax    ;Save the char word
    mov esi, dword [scr_page_addr]
    call .page_cursor_offset    ;bx preserved
    mov rdi, rsi    ;Change register for string ops
    shl rax, 1
    add rdi, rax    ;rdi now points to right place on right page
    pop rax

    push rcx
    movzx rcx, cx    ;zero upper bytes
    jrcxz .wc3    ;If cx is zero, dont print anything, exit
.wc2:
    stosb
    inc rdi
    dec rcx
    jnz .wc2
.wc3:
    pop rcx
    pop rdi
    jmp .exit    ;Exit restoring rsi

.gset_col_palette:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function
.gwritedot:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function
.greaddot:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function

.write_tty:
;Called with al=char, bl=foreground color (graphics)
;When called, ah contains current screen mode
    push rcx
    push rdx
    push rbx
    push rax

    mov bh, byte [scr_active_page]    ;Get active page
    push rax
    mov ah, 3    ;Get cursor into dx
    int 30h
    pop rax

    cmp al, 08h    ;Check for backspace
    je .wttybspace
    cmp al, 0Ah    ;Check for line feed
    je .wttylf
    cmp al, 0Dh    ;Check for carriage return
    je .wttycr
    cmp al, 07h    ;ASCII bell
    je .wttybell

.wttywrite:
    mov rcx, 1    
    mov ah, 0Ah    ;Write 1 char w/o attrib byte
    int 30h    ;bh contains page to write for

.wttycursorupdate:
    inc dl
    cmp dl, byte [scr_cols]
    jae .wttycu0    ;go down by a line, and start of the line
.wttycursorupdatego:
    mov ah, 2
    int 30h     ;set cursor
.wttyexit:
    pop rax
    pop rbx
    pop rdx
    pop rcx
    jmp .exit

.wttycu0:
    xor dl, dl    ;Return to start of line
    inc dh
    cmp dh, byte [scr_rows]    ;are past the bottom of the screen?
    jb .wttycursorupdatego    ;we are not past the bottom of the screen
.wttyscrollupone:
    push rbx
    mov ah, 08h    ;Read char/attrib at cursor
    int 30h
    mov bh, ah    ;Move attrib byte into bh
    xor rcx, rcx
    mov dx, word [scr_cols]    ;word access all ok
    dec dh
    dec dl
    mov ax, 0601h    ;scroll up one line
    int 30h

    xor dl, dl 
    pop rbx
    jmp .wttycursorupdatego
.wttybspace:
    test dl, dl    ;compare if the column is zero
    jnz .wttybs1   ;if not just decrement row pos
    test dh, dh    ;compare if zero row, if so do nothing
    jz .wttyexit   ;at top left, just exit
    dec dh
    mov dl, byte [scr_cols]    ;move to end of prev row + 1
.wttybs1:
    dec dl
    jmp .wttycursorupdatego

.wttylf:
    push rdx
    mov dl, byte [scr_rows]
    dec dl
    cmp dh, dl
    pop rdx
    je .wttyscrollupone    ;if we need to scroll, scroll
    inc dh    ;otherwise just send cursor down by one
    jmp    .wttycursorupdatego
.wttycr:
    mov dl, 0    ;Set to 0 on row
    jmp .wttycursorupdatego
.wttybell:
    mov rcx, 1000   ;Beep for a second
    mov ebx, 04A9h  ;Frequency divisor for 1000Hz tone
    call beep
    jmp .wttyexit

.get_mode:
;Takes no arguments
;Returns ah=Number of Columns, al=Current Screen mode, bh=active page
    mov ah, byte [scr_cols]
    mov al, byte [scr_mode]
    mov bh, byte [scr_active_page]
    jmp .exit


;Bad string argument for below function
.wsbad:
    mov rax, 0FFFFh
    jmp .exit
.write_string:
;bh=page to print on, bl=attribute, cx=number of chars to print
;dh=y coord to print at, dl=x coord to print at, rbp=string
;al contains subfunction
;al=0 attrib in bl, cursor NOT updated
;al=1 attrib in bl, cursor updated
;al=2 string alt attrib/char, cursor NOT updated
;al=3 string alt attrib/char, cursor updated
;al=4 print 0 terminated string
    cmp al, 4h
    je .wszero    ;If its a zero terminated string, go down
    jrcxz .wsbad
    cmp al, 4h    ;Bad argument
    ja .wsbad
.ws:
    push rsi
    push rcx
    push rdx
    push rbx
    push rax

    push rbx
    mov bl, bh
    movzx ebx, bl
    mov si, word [scr_curs_pos + 2*ebx]    ;Fast get cursor position
    pop rbx
    push rsi    ;Save the current cursor position

    push rax
    mov ah, 02h    ;Set cursor at dx
    int 30h
    pop rax

.ws0:
    push rcx
    push rbx
    push rax
    mov ah, al
    mov al, byte [rbp] ;Get char
    inc rbp
    cmp al, 07h
    je .wsctrlchar
    cmp al, 08h
    je .wsctrlchar
    cmp al, 0Ah
    je .wsctrlchar
    cmp al, 0Dh
    je .wsctrlchar

    cmp ah, 2    ;Check if we need to get the char attrib too
    jb .ws1
    mov bl, byte [rbp]    ;Get char attrib
    inc rbp
.ws1:
    mov cx, 1
    mov ah, 09h    ;Print char and attrib (either given or taken)
    int 30h

    inc dl
    cmp dl, byte [scr_cols]    ;Check if we passed the end of the row
    jne .ws2    ;We havent, skip the reset
    xor dl, dl    ;Reset horizontal pos
    inc dh        ;Goto next row
    cmp dh, byte [scr_cols]    ;Have we passed the last row?
    jne .ws2    ;No, put cursor
    mov ax, 0E0Ah    ;Yes, do  TTY Line feed
    int 30h
    dec dh        ;Mov cursor to start of last row on page
.ws2:
    mov ah, 02
    int 30h    ;Put cursor at new location
.ws3:
    pop rax
    pop rbx
    pop rcx

    dec cx
    jnz .ws0

.wsexitupdate:    ;Exit returning char to original position
    pop rdx
    cmp al, 01h
    je .wsexit
    cmp al, 03h
    je .wsexit
;Exit returning char to original position    
    mov ah, 02h
    int 30h 
.wsexit:
    pop rax
    pop rbx
    pop rdx
    pop rcx
    pop rsi
    jmp .exit
.wsctrlchar:
;Handles Control Characters: ASCII Bell, Bspace, LF and CR
    mov ah, 0Eh
    int 30h    ;Print control char as TTY
    mov bl, bh
    movzx ebx, bl
    mov dx, word [scr_curs_pos + 2*ebx]    ;Fast get cursor position
    jmp .ws3
.wszero:
;Print zero terminated string at cursor on current active page
;Called with ax=1304, rbp=pointer to string
    push rbp
    push rax
.wsz1:
    mov al, byte [rbp]
    test al, al    ;Check al got a zero char
    jz .wsz2
    inc rbp
    mov ah, 0Eh
    int 30h
    jmp short .wsz1
.wsz2:
    pop rax
    pop rbp
    jmp .exit

;Graphics mode specific versions!
.gread:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function
.gwrite:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function
.gscrollup:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function
.gscrolldown:
    mov rax, 0FFFFh
    jmp .exit    ;Currently unsupported function

.write_crtc_word: ;Writes cx to the CRTC register in al and al+1
    push rdx

    mov dx, word [scr_crtc_base]
    out dx, al
    inc dl
    mov ah, al    ;Temp save al
    mov al, ch    ;Set high bits first
    out dx, al

    dec dl
    mov al, ah    ;Bring back al into al
    inc al ;GOTO next CTRC address

    out dx, al
    inc dl
    mov al, cl
    out dx, al 

    pop rdx
    ret

.get_page_base:
;Returns in rsi, the base address of the selected page
;Called with BH = page number, BL=screen mode
;return RSI=Base of selected page, since rsi is already clobbered
    push rcx
    push rbx

    mov cl, bh    ;mov into cl, free bx
    movzx rcx, cl
;----Modify this proc with data tables when finalised!!----
    cmp bl, 2
    mov bx, 1000h    ;Doesnt affect flags
    mov rsi, 800h    ;si is a free register
    cmovb bx, si    ;if below, replace with 800h
    movzx rbx, bx        ;zero extend
    mov esi, dword [scr_page_addr]
    jrcxz .gpb1        ;Dont enter the loop if cx is zero
.gpb0:
    add rsi, rbx    ;add pagesize cx times
    dec rcx
    jnz .gpb0        ;go around

.gpb1:
    pop rbx
    pop rcx
    ret

.page_cursor_offset:
;Returns in rax the offset into the RAM page of the cursor
;Works for A/N modes and graphic, though must be shl by 1 for A/N modes
;bh contains page to work out address 
    push rbx
    mov bl, bh    ;bring the page number from bh into bl
    movzx rbx, bl            
    mov ax, word [scr_curs_pos + 2*rbx]    ;move cursor position into ax
    pop rbx
.offset_from_ax:
;Same as above but now ax needs to be packed as in the cursor
    push rdx
    push rbx
    xor rbx, rbx
    add bl, al    ;move columns into bl
    shr ax, 8    ;mov rows from ah to al to use 8 bit mul
    
    mul byte [scr_cols]    ;multiply the row we are on by columns, store in ax
    add ax, bx        ;add number of columns to this mix!
    movzx rax, ax

    pop rbx
    pop rdx
    ret
.text_scroll_c1:
;Common function
;Scrolls a single pair of lines from column given in cl to dl
;rsi/rdi assumed to be pointing at the right place
;Direction to be set by calling function
;All registers EXCEPT pointers preserved, rbp returns # of words
    push rcx
    push rdx
    xor rbp, rbp
    mov dh, cl    ;Save upper left corner in dh, freeing cx
    mov cl, dl    
    sub cl, dh    ;Get correct number of words to copy into cl
    movzx rcx, cl
    inc rcx    ;absolute value, not offset
    mov rbp, rcx    ;Save number of words in rbp
    rep movsw    ;Move char/attrib for one row
    pop rdx
    pop rcx
    ret
.cursor_proc:
;Called with bh containing page number
;Sets cursor on page in bh
;Returns nothing
    call .page_cursor_offset    ;rax rets offset, no shift needed

    mov cl, bh
    movzx rcx, cl
;----Modify this proc with data tables when finalised!!----
    xor si, si    
    mov dx, 800h ;Most legacy Pages are sized 800h PELs, VGA greater
    cmp byte [scr_mode], 2
    jae .cp1
    shr dx, 1    ;If in modes 0,1, 400h PELs per page
.cp1:
    test cl, cl
    jz .cpwrite
    add si, dx 
    dec cl
    jnz .cp1

.cpwrite:
    mov cx, ax    ;move ax into cx
    add cx, si
    mov al, 0Eh    ;Cursor row
    call .write_crtc_word    ;cx has data to output, al is crtc reg

    ret
;------------------------End of Interrupt------------------------