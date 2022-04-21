;-------------------Keyboard Interrupt Int 36h-------------------
; Software keyboard interrupt. 
; ah = 0 -> Read the next scancode/ASCII struck from the keyboard
; ah = 1 -> Clear zero flag if there is a new char ready to be 
;           read.
; ah = 2 -> Returns the current shift status in the al register
; ax and flags changed.
;----------------------------------------------------------------
kb_io:
    push rbx
    cli            ;Interrupts off
    test ah, ah
    jz .k0
    dec ah
    jz .k1
    dec ah
    jz .k2
    or byte [rsp + 3*8h], 1    ;Set CF, invalid function, skip rbx on stack
    mov ah, 80h    ;Invalid Function
    jmp short .kexit ;ah > 2, not a valid function
    
.k0:    
;This one moves the head to catch up with the tail.
    sti
    pause    ;Allow a keyboard interrupt to occur
    cli
    mov rbx, qword [kb_buf_head]
    cmp rbx, qword [kb_buf_tail]    ;Are we at the head of the buffer?
    je .k0    ;If we are, then the buffer is empty, await a keystroke
    mov ax, word [ebx]        ;move the word pointed at by rbx to ax
    call .kb_ptr_adv    ;Advance the buffer pointer
    
    mov qword [kb_buf_head], rbx    ;Move rbx into the buffer head variable
    jmp short .kexit

.k1:
    mov rbx, qword [kb_buf_head]
    cmp rbx, qword [kb_buf_tail] ;sets flags, Z is set if equal 
    cmovnz ax, word [rbx]    ;move head of buffer into ax, IF Z clear
    sti     ;renable interrupts 
    pushfq    ;push flags onto stack
    pop rbx    ;pop them into rbx
    mov [rsp + 3*8h], qword rbx    ;Replace with new flags, skip pushed rbx
    jmp short .kexit
    
.k2:
    mov al, byte [kb_flags]
.kexit:
    sti
    pop rbx
    iretq

.kb_ptr_adv:
;Advance the pointer passed by rbx safely and return pointer!
    inc rbx
    inc rbx
    cmp rbx, qword [kb_buf_end]     ;Are we at the end of the buffer space
    jne .kbpa1                      ;If not exit, if we are, wrap around space!
    mov rbx, qword [kb_buf_start]
.kbpa1:
    ret
;------------------------End of Interrupt------------------------