;----------------Keyboard Interrupt IRQ 1/Int 21h----------------
;This interrupt takes scancodes from the PC keyboard, translates 
; them into scancode/ASCII char pair and stores the pair into 
; the buffer for the software keyboard interrupt to use.
;----------------------------------------------------------------
kb_IRQ1:
    sti        ;Reenable interrupts
    push rax
    push rbx
    push rcx
    push rdi
    xor eax, eax

.k0:
    in al, ps2data    ;Get the scancode (Set 1)
    test eax, eax    ;Check to see if we got an error code from the keyboard.
    jz .kb_error
    cmp rax, 80h
    jle .basickey    ;A normal keypress, nothing too magical.
    cmp rax, 0E0h    ;Compare against special keys
    je .special_keys
    cmp rax, 0E1h    ;Pause
    je .pause
    cmp rax, 0AAh    ;LShift released
    je .lshift_released
    cmp rax, 0B6h    ;RShift released
    je .rshift_released
    cmp rax, 0B8h    ;Alt Shift released
    je .alt_shift_released
    cmp rax, 9Dh    ;Ctrl Shift released
    je .ctrl_shift_released
    cmp rax, 0D2h    ;Toggle Insert
    je .insert_released
    jmp short .kb1_exit    ;Just exit if something weird gets sent

.kb_store_in_buffer:
    mov rbx, qword [kb_buf_tail]    ;point rbx to tail
    mov rdi, rbx ;Save bx in di for storing the data in AX after bx gets inc 
    call kb_io.kb_ptr_adv            ;safely advance the pointer
    cmp rbx, qword [kb_buf_head]    ;Have we wrapped around?
    je .kb_buf_full_beep            ;discard and beep
    mov word [rdi], ax                ;mov scancode/ascii pair into buffer
    mov qword [kb_buf_tail], rbx    ;store new pointer back into tail

.kb1_exit:
    mov al, ~(kb_flag2_e0 | kb_flag2_e1)        ;move the notted version into al
    and byte [kb_flags_2], al        ;Nullify the e0 and e1 flag
.kb1_exit_e0:
    mov al, EOI
    out pic1command, al    ;End of interrupt to pic1 command port

    pop rdi
    pop rcx
    pop rbx
    pop rax
    iretq

.special_keys:    ;An E0 process
    mov al, kb_flag2_e0         ;Set the bit for the flag
    or byte [kb_flags_2], al    ;Set the flag
    and byte [kb_flags_2], ~kb_flag2_e1    ;clear the E1 bit
    jmp short .kb1_exit_e0      ;Exit from IRQ without resetting flags 
.pause:    ;An E1 process
    mov al, kb_flag2_e1         ;Set the bit for the flag
    or byte [kb_flags_2], al    ;Toggle the flag, since 9D and C5 will be 
                                ; ignored by the Int handler
    and byte [kb_flags_2], ~kb_flag2_e0    ;clear the E0 bit
    jmp short .kb1_exit_e0

.insert_released:
    mov al, ~kb_flag_insset     ;Flag negation
    jmp short .shift_release_common
.alt_shift_released:
    mov al, ~kb_flag_alt        ;Flag negation
    jmp short .shift_release_common
.ctrl_shift_released:
    mov al, ~kb_flag_ctrl       ;Flag negation
    jmp short .shift_release_common
.lshift_released:
    mov al, ~kb_flag_lshift     ;Flag negation
    jmp short .shift_release_common
.rshift_released:
    mov al, ~kb_flag_rshift     ;Flag negation
.shift_release_common:
    and byte [kb_flags], al     ;Clear the relevant bit
    jmp short .kb1_exit


.kb_buf_full_beep:
    push rbx
    push rcx
    mov ebx, 04A9h ;Frequency divisor for 1000Hz tone
    mov rcx, 500   ;Beep for a 1/2 second
    call beep
    pop rcx
    pop rbx
    jmp .kb1_exit

.basickey:          ;al contains the scancode
    cmp rax, 46h
    je .e0special   ;ctrl+break checker (E0 46h is make for break haha)
.kbbk1:
    cmp rax, 2Ah    ;Left Shift scancode
    je .lshift_pressed
    cmp rax, 36h    ;Right Shift scancode
    je .rshift_pressed
    cmp rax, 38h    ;Alt Shift key scancode
    je .alt_shift_pressed
    cmp rax, 1Dh    ;Ctrl Shift key scancode
    je .ctrl_shift_pressed
    
    cmp rax, 3Ah    ;Caps lock key
    je .caps_lock
    cmp rax, 45h    ;Num lock key
    je .num_lock
;    cmp rax, 46h    ;Scroll lock key
;    je .scroll_lock
    cmp rax, 52h    ;Insert key pressed
    je .ins_toggle    
    cmp rax, 53h    ;Delete key, for CTRL+ALT+DEL
    je .ctrl_alt_del
.keylookup:
    mov rbx, .kb_sc_ascii_lookup
                    ; upper 7 bytes of rax are completely clear
    shl ax, 4       ;multiply ax, the scancode, by 16, to offset to correct row
    add rbx, rax    ;offset rbx to the correct row
;Now check shift states, to align with column. rax is free again
    mov al, byte [kb_flags]

    test al, kb_flag_lshift
    jnz .addshiftvalue            ;If that bit is set, jump!
    test al, kb_flag_rshift
    jnz .addshiftvalue
    test al, kb_flag_ctrl
    jnz .addctrlvalue
    test al, kb_flag_alt
    jnz .addaltvalue
    test al, kb_flag_numset
    jnz .addnumvalue
    test al, kb_flag_capsset
    jnz .addcapsvalue

.keyget:
    mov ax, word [rbx] ;Get correct word into ax!
    test ax, ax        ;check if the value is zero, if so, dont store in buffer
    jz .kb1_exit
    jmp .kb_store_in_buffer

.addshiftvalue:    ;first check if we shift with caps or num
    test al, kb_flag_numset
    jnz .addshiftnum
    test al, kb_flag_capsset
    jnz .addshiftcaps
    ;Collapse through, it is just shift, add 2 to rbx
    add rbx, 1h*2h
    jmp short .keyget
.addctrlvalue:
    add rbx, 2h*2h
    jmp short .keyget
.addaltvalue:
    add rbx, 3h*2h
    jmp short .keyget
.addnumvalue:
    add rbx, 4h*2h
    jmp short .keyget
.addcapsvalue:
    add rbx, 5h*2h
    jmp short .keyget
.addshiftcaps:
    add rbx, 6h*2h
    jmp short .keyget
.addshiftnum:
    add rbx, 7h*2h
    jmp short .keyget

.alt_shift_pressed:
    mov al, kb_flag_alt
    jmp short .shift_pressed_common
.ctrl_shift_pressed:
    mov al, kb_flag_ctrl
    jmp short .shift_pressed_common
.lshift_pressed:
    mov al, kb_flag_lshift
    jmp short .shift_pressed_common
.rshift_pressed:
    mov al, kb_flag_rshift
.shift_pressed_common:
    or byte [kb_flags], al    ;toggle flag bits
    jmp .kb1_exit             ;Exit

.ins_toggle:
    mov al, kb_flag_insset
    jmp short .lock_common
.caps_lock:
    mov al, kb_flag_capsset
    jmp short .lock_common
.num_lock:
    mov al, kb_flag_numset
    jmp short .lock_common
.scroll_lock:
    mov al, kb_flag_scrlset
.lock_common:
    xor byte [kb_flags], al    ;toggle bit
    call .set_kb_lights
    jmp .kb1_exit

.e0special:
    test byte [kb_flags_2], 00000010b    ;Check for E0 set
    jnz .ctrl_break
    jmp .scroll_lock    ;Assume scroll lock set
.ctrl_break:
    or byte [break_flag], 1        ;set break_flag
    xor ax, ax
    push rbx
    mov rbx, kb_buffer            ;mov the buffer addr to rbx
    mov qword [kb_buf_head], rbx
    mov qword [kb_buf_tail], rbx
    mov word [rbx], ax    ;Store zero as the first two bytes of the
    pop rbx
    int 3Bh                      ;Call the CTRL+Break handler
    and byte [break_flag], al    ;clear break_flag
    jmp .kb1_exit        ;return clearing E0

.ctrl_alt_del:
    push rax    ;save scancode
    mov al, byte [kb_flags_2]
    test al, kb_flag2_e0    ;Delete scancode is E0, 53, check if we first had E0
    jz .ctrl_alt_del_no_reset

    mov al, byte [kb_flags]
    and al,  kb_flag_ctrl | kb_flag_alt
    cmp al, kb_flag_ctrl | kb_flag_alt    ;Test if Ctrl + Alt is being pressed
    jne .ctrl_alt_del_no_reset
    ;Nuke IDT and tightloop until the CPU triple faults
    lidt [.ctrl_alt_del_reset_idt] ;Triple fault the machine
    jmp short .ctrl_alt_del_to_hell
.ctrl_alt_del_to_hell:
    int 00h ;Call div by 0 to trigger reboot if not somehow failed yet
    jmp short .ctrl_alt_del_to_hell
.ctrl_alt_del_reset_idt:
    dw 0
    dq 0
.ctrl_alt_del_no_reset:
    pop rax        ;return the OG scancode and proceed as normal
    jmp .keylookup


.set_kb_lights:
    push rax

    call ps2wait

    mov al, 0EDh
    out ps2data, al

    call ps2wait
    
    mov al, byte [kb_flags]    ;get flag into al
    shr al, 4
    and al, 111b    ;mask Insert bit off to isolate the NUM,CAPS,SCRL status 
                    ; bits <=> LED status.
    out ps2data, al    ;send the led status away

    pop rax
    ret

.kb_error:     ;If error recieved from Keyboard, hang the system, cold reboot 
               ; needed.
    cli        ;Disable interrupts/Further keystrokes
    mov bx, 0007h    ;cls attribs
    call cls    ;clear the screen
    mov ax, 1304h
    xor bh, bh
    mov rbp, .kb_error_msg
    int 30h
.kber1:
    pause
    jmp short .kber1
.kb_error_msg:    db    "Keyboard Error. Halting...", 0Ah, 0Dh, 0

.kb_sc_ascii_lookup:    ;Scancodes 00h-58h
; Scancodes 00h-0Fh
;   base   shift   ctrl   alt   num    caps   shcap  shnum 
 dw 0000h, 0000h, 0000h, 0000h, 0000h, 0000h, 0000h, 0000h ;NUL
 dw 011Bh, 011Bh, 011Bh, 011Bh, 011Bh, 011Bh, 011Bh, 011Bh ;Esc
 dw 0231h, 0221h, 0000h, 7800h, 0231h, 0231h, 0221h, 0221h ;1 !
 dw 0332h, 0322h, 0300h, 7900h, 0332h, 0332h, 0322h, 0322h ;2 "
 dw 0433h, 049Ch, 0000h, 7A00h, 0433h, 0433h, 049Ch, 049Ch ;3 £
 dw 0534h, 0524h, 0000h, 7B00h, 0534h, 0534h, 0524h, 0524h ;4 $
 dw 0635h, 0625h, 0000h, 7C00h, 0635h, 0635h, 0625h, 0625h ;5 %
 dw 0736h, 075Eh, 071Eh, 7D00h, 0736h, 0736h, 075Eh, 075Eh ;6 ^
 dw 0837h, 0826h, 0000h, 7E00h, 0837h, 0837h, 0826h, 0826h ;7 &
 dw 0938h, 092Ah, 0000h, 7F00h, 0938h, 0938h, 092Ah, 092Ah ;8 *
 dw 0A39h, 0A28h, 0000h, 8000h, 0A39h, 0A39h, 0A28h, 0A28h ;9 (
 dw 0B30h, 0B29h, 0000h, 8100h, 0B30h, 0B30h, 0B29h, 0B29h ;0 )
 dw 0C2Dh, 0C5Fh, 0000h, 8200h, 0C2Dh, 0C2Dh, 0C5Fh, 0C5Fh ;- _
 dw 0D3Dh, 0D2Bh, 0000h, 8300h, 0D3Dh, 0D3Dh, 0D2Bh, 0D2Bh ;= +
 dw 0E08h, 0E08h, 0E7Fh, 0000h, 0E08h, 0E08h, 0E08h, 0E08h ;bksp (ctrl -> del)
 dw 0F09h, 0F00h, 0000h, 0000h, 0F09h, 0F09h, 0F00h, 0F00h ;L2R Horizontal Tab

; Scancodes 10h-1Fh
;   base   shift   ctrl   alt   num    caps   shcap  shnum 
 dw 1071h, 1051h, 1011h, 1000h, 1071h, 1051h, 1071h, 1051h ;q Q
 dw 1177h, 1157h, 1117h, 1100h, 1177h, 1157h, 1177h, 1157h ;w W
 dw 1265h, 1245h, 1205h, 1200h, 1265h, 1245h, 1265h, 1245h ;e E
 dw 1372h, 1352h, 1312h, 1300h, 1372h, 1352h, 1372h, 1352h ;r R
 dw 1474h, 1454h, 1414h, 1400h, 1474h, 1454h, 1474h, 1454h ;t T
 dw 1579h, 1559h, 1519h, 1500h, 1579h, 1559h, 1579h, 1559h ;y Y
 dw 1675h, 1655h, 1615h, 1600h, 1675h, 1655h, 1675h, 1655h ;u U
 dw 1769h, 1749h, 1709h, 1700h, 1769h, 1749h, 1769h, 1749h ;i I
 dw 186Fh, 184Fh, 180Fh, 1800h, 186Fh, 184Fh, 186Fh, 184Fh ;o O
 dw 1970h, 1950h, 1910h, 1900h, 1970h, 1950h, 1970h, 1950h ;p P
 dw 1A5Bh, 1A7Bh, 1A1Bh, 0000h, 1A5Bh, 1A5Bh, 1A7Bh, 1A7Bh ;[ {
 dw 1B5Dh, 1B7Dh, 1B1Dh, 0000h, 1B5Dh, 1B5Dh, 1B7Dh, 1B7Dh ;] }
 dw 1C0Dh, 1C0Dh, 1C0Ah, 0000h, 1C0Dh, 1C0Dh, 1C0Ah, 1C0Ah ;Enter (CR/LF)
 dw 1D00h, 1D00h, 1D00h, 1D00h, 1D00h, 1D00h, 1D00h, 1D00h ;CTRL (left)
 dw 1E61h, 1E41h, 1E01h, 1E00h, 1E61h, 1E41h, 1E61h, 1E41h ;a A
 dw 1F73h, 1F53h, 1F13h, 1F00h, 1F73h, 1F53h, 1F73h, 1F53h ;s S

; Scancodes 20h-2Fh
;   base   shift   ctrl   alt   num    caps   shcap  shnum 
 dw 2064h, 2044h, 2004h, 2000h, 2064h, 2044h, 2064h, 2044h ;d D
 dw 2166h, 2146h, 2106h, 2100h, 2166h, 2146h, 2166h, 2146h ;f F
 dw 2267h, 2247h, 2207h, 2200h, 2267h, 2247h, 2267h, 2247h ;g G
 dw 2368h, 2348h, 2308h, 2300h, 2368h, 2348h, 2368h, 2348h ;h H
 dw 246Ah, 244Ah, 240Ah, 2400h, 246Ah, 244Ah, 246Ah, 244Ah ;j J
 dw 256Bh, 254Bh, 250Bh, 2500h, 256Bh, 254Bh, 256Bh, 254Bh ;k K
 dw 266Ch, 264Ch, 260Ch, 2600h, 266Ch, 264Ch, 266Ch, 264Ch ;l L
 dw 273Bh, 273Ah, 0000h, 0000h, 273Bh, 273Bh, 273Ah, 273Ah ;; :
 dw 2827h, 2840h, 0000h, 0000h, 2827h, 2827h, 2840h, 2840h ;' @
 dw 295Ch, 297Ch, 0000h, 0000h, 295Ch, 295Ch, 297Ch, 297Ch ;\ |
 dw 2A00h, 2A00h, 2A00h, 2A00h, 2A00h, 2A00h, 2A00h, 2A00h ;LShift (2Ah)
 dw 2B23h, 2B7Eh, 2B1Ch, 0000h, 2B23h, 2B23h, 2B7Eh, 2B7Eh ;# ~
 dw 2C7Ah, 2C5Ah, 2C1Ah, 2C00h, 2C7Ah, 2C5Ah, 2C7Ah, 2C5Ah ;z Z
 dw 2D78h, 2D58h, 2D18h, 2D00h, 2D78h, 2D58h, 2D78h, 2D58h ;x X
 dw 2E63h, 2E43h, 2E03h, 2E00h, 2E63h, 2E43h, 2E63h, 2E43h ;c C
 dw 2F76h, 2F56h, 2F16h, 2F00h, 2F76h, 2F56h, 2F76h, 2F56h ;v V

; Scancodes 30h-3Fh
;   base   shift   ctrl   alt   num    caps   shcap  shnum 
 dw 3062h, 3042h, 3002h, 3000h, 3062h, 3042h, 3062h, 3042h ;b B
 dw 316Eh, 314Eh, 310Eh, 3100h, 316Eh, 314Eh, 316Eh, 314Eh ;n N
 dw 326Dh, 324Dh, 320Dh, 3200h, 326Dh, 324Dh, 326Dh, 324Dh ;m M
 dw 332Ch, 333Ch, 0000h, 0000h, 332Ch, 332Ch, 333Ch, 333Ch ;, <
 dw 342Eh, 343Eh, 0000h, 0000h, 342Eh, 342Eh, 343Eh, 343Eh ;. >
 dw 352Fh, 353Fh, 0000h, 0000h, 352Fh, 352Fh, 353Fh, 353Fh ;/ ?
 dw 3600h, 3600h, 3600h, 3600h, 3600h, 3600h, 3600h, 3600h ;RShift
 dw 372Ah, 0000h, 3710h, 0000h, 372Ah, 372Ah, 0000h, 0000h ;KP *
 dw 3800h, 3800h, 3800h, 3800h, 3800h, 3800h, 3800h, 3800h ;Alt
 dw 3920h, 3920h, 3900h, 0000h, 3920h, 3920h, 3920h, 3920h ;Space
 dw 3A00h, 3A00h, 3A00h, 3A00h, 3A00h, 3A00h, 3A00h, 3A00h ;Caps Lock
 dw 3B00h, 5400h, 5E00h, 6800h, 3B00h, 3B00h, 5400h, 5400h ;F1
 dw 3C00h, 5500h, 5F00h, 6900h, 3C00h, 3C00h, 5500h, 5500h ;F2
 dw 3D00h, 5600h, 6000h, 6A00h, 3D00h, 3D00h, 5600h, 5600h ;F3
 dw 3E00h, 5700h, 6100h, 6B00h, 3E00h, 3E00h, 5700h, 5700h ;F4
 dw 3F00h, 5800h, 6200h, 6C00h, 3F00h, 3F00h, 5800h, 5800h ;F5

; Scancodes 40h-4Fh
;   base   shift   ctrl   alt   num    caps   shcap  shnum 
 dw 4000h, 5900h, 6300h, 6D00h, 4000h, 4000h, 5900h, 5900h ;F6
 dw 4100h, 5A00h, 6400h, 6E00h, 4100h, 4100h, 5A00h, 5A00h ;F7
 dw 4200h, 5B00h, 6500h, 6F00h, 4200h, 4200h, 5B00h, 5B00h ;F8
 dw 4300h, 5C00h, 6600h, 7000h, 4300h, 4300h, 5C00h, 5C00h ;F9
 dw 4400h, 5D00h, 6700h, 7100h, 4400h, 4400h, 5D00h, 5D00h ;F10
 dw 4500h, 4500h, 4500h, 4500h, 4500h, 4500h, 4500h, 4500h ;Num Lock
 dw 4600h, 4600h, 4600h, 4600h, 4600h, 4600h, 4600h, 4600h ;Scroll Lock
 dw 4700h, 4737h, 7700h, 0000h, 4737h, 4700h, 4737h, 4700h ;(KP)Home
 dw 4800h, 4838h, 0000h, 0000h, 4838h, 4800h, 4838h, 4800h ;(KP)Up arrow
 dw 4900h, 4939h, 8400h, 0000h, 4939h, 4900h, 4939h, 4900h ;(KP)PgUp 
 dw 4A2Dh, 4A2Dh, 0000h, 0000h, 4A2Dh, 4A2Dh, 4A2Dh, 4A2Dh ;(KP)-
 dw 4B00h, 4B34h, 7300h, 0000h, 4B34h, 4B00h, 4B34h, 4B00h ;(KP)Left arrow
 dw 4C00h, 4C35h, 0000h, 0000h, 4C35h, 4C00h, 4C35h, 4C00h ;(KP)Center
 dw 4D00h, 4D36h, 7400h, 0000h, 4D36h, 4D00h, 4D36h, 4D00h ;(KP)Right arrow
 dw 4E2Bh, 4E2Bh, 0000h, 0000h, 4E2Bh, 4E2Bh, 4E2Bh, 4E2Bh ;(KP)+
 dw 4F00h, 4F31h, 7500h, 0000h, 4F31h, 4F00h, 4F31h, 4F00h ;(KP)End

; Scancodes 50h-58h
;   base   shift   ctrl   alt   num    caps   shcap  shnum 
 dw 5000h, 5032h, 0000h, 0000h, 5032h, 5000h, 5032h, 5000h ;(KB)Down arrow
 dw 5100h, 5133h, 7600h, 0000h, 5133h, 5100h, 5133h, 5100h ;(KB)PgDn
 dw 5200h, 5230h, 0000h, 0000h, 5230h, 5200h, 5230h, 5200h ;(KB)Ins
 dw 5300h, 532Eh, 0000h, 0000h, 532Eh, 5300h, 532Eh, 5300h ;(KB)Del
 dw 5400h, 5400h, 5400h, 5400h, 5400h, 5400h, 5400h, 5400h ;ALT+PRTSC -> Sysreq
 dw 0000h, 0000h, 0000h, 0000h, 0000h, 0000h, 0000h, 0000h ;xxxxNOTUSEDxxxx
 dw 565Ch, 567Ch, 0000h, 0000h, 565Ch, 565Ch, 567Ch, 567Ch ;\ |
 dw 5700h, 0000h, 0000h, 0000h, 5700h, 5700h, 0000h, 0000h ;F11
 dw 5800h, 0000h, 0000h, 0000h, 5800h, 5800h, 0000h, 0000h ;F12
;------------------------End of Interrupt------------------------