;-------------------EHCI Int Handler/Int 2Xh---------------------
;This is installed by the PCI proc at runtime, onto the 
; appropriate IRQ.
;
;If USB Host controller is doing transaction, this HC is 
; nominally turned off. Bits [7:2] in the eAsyncMutex identify 
; how many interrupts to ignore, before switching off the 
; Schedule. This value is nominally zero.
;----------------------------------------------------------------
ehci_IRQ:
    push qword dummy_interrupt.pic2
    jmp short .intr
.pic1:
    push qword dummy_interrupt.pic1
.intr:
;EHCI Interrupt Handler 
    push rbx
    push rax

    mov al, byte [eActiveCtrlr]
    cmp al, -1    ;Spurious case, replace with manual poll then discard proc
    je .spur

    call USB.ehciGetOpBase    ;returns opreg base in rax
.nonIRQmain:
    mov ebx, dword [eax + ehcists]  ;save USBSTS and clear usb interrupt
    or dword [eax + ehcists], ebx   ;WC all interrupt status
    mov byte [eActiveInt], bl    ;save interrupt status

;Test based on which bits are set. Higher bits have higher priority
    ;test bl, 10h            ;Check if host error bit set
    ;test bl, 8              ;Frame List rollover
    ;test bl, 4              ;Port status change detected
    test bl, 2              ;Check if transation error bit is set
    jnz .transactionError
    test bl, 1              ;Check if short packet/interrupt bit set
    jz .exit                ;If none of the bits were set, continue IRQ chain
;IoC and Short Packet section
    mov al, byte [eAsyncMutex]    ;check if we should ignore interrupt
    and al, 11111100b    ;clear out bottom two bits (dont care)
    test al, al            ;Set zero flag if al is zero
    jnz .usbignoreirq    ;If not zero, ignore irq (and dec counter!)

    mov byte [eAsyncMutex], al ;Wait no longer!! Data available

    jmp short .exit    ;Ignore the "ignore usb" section
.usbignoreirq:
    sub byte [eAsyncMutex], 4    ;sub the semaphore 
.exit:
    pop rax
    pop rbx
    ret
.spur:
    xor al, al
.s1:
    call USB.ehciGetOpBase
    mov ebx, dword [eax + ehcists] ;save USBSTS and clear usb interrupt 
    or dword [eax + ehcists], ebx    ;WC all interrupt status
    inc al    ;Clear all interrupts on all controllers
    cmp al, byte [eControllers]
    jb .s1
    jmp short .exit
.transactionError:
    mov byte [eAsyncMutex], 0   ;Unblock wait
    jmp short .exit
.nonIRQep:
    push rbx
    push rax
    jmp short .nonIRQmain
;------------------------End of Interrupt------------------------