;----------------------------------------------------------------
;                            PCI Enumeration                    :
;----------------------------------------------------------------
; This proc enumerates only the PCI devices we care for
;----------------------------------------------------------------
    xor rbp, rbp
    mov word [lousbtablesize], bp
    mov rcx, rbp    ;reset cx now too, for below
pci_scan:    ;Enumerate PCI devices (formerly, USB devices)
    xor rbx, rbx       ;Used to save the value of eax temporarily
    mov rax, 81000008h ;Set bit 31 and lower byte to 2, for register 2/offset 8
                       ;also make it the largest register so that we enumerate 
                       ;backwards and set up USB controllers in order from 
                       ;newest to oldest.
.u1:
    sub eax, 100h      ;mov eax into valid PCI range, go to next device
    mov dx, pci_index  ;PCI index register
    out dx, eax   ;output the next packed bus,device,function,register combo

    mov ebx, eax       ;save to be used later, to access PCI BARS
    
    mov dx, pci_data   ;PCI data register
    in eax, dx    ;Get Class, subclass and interface value in upper three bytes
    
    shr eax, 8                ;shift down the details by a byte
;IF any of these are satisfied, remember ebx has the device index
    cmp eax, ((usb_class << 16) +(usb_subclass << 8)+uhci_interface)
    je .uhci_found
    cmp eax, ((usb_class << 16) +(usb_subclass << 8)+ohci_interface)
    je .ohci_found
    cmp eax, ((usb_class << 16) +(usb_subclass << 8)+ehci_interface)
    je .ehci_found
    cmp eax, ((usb_class << 16) +(usb_subclass << 8)+xhci_interface)
    je .xhci_found
    push rax
    shr eax, 8              ;roll over rid of function number
    cmp eax, (msd_class << 8) + (ide_subclass)
    je .idePCIEnum
    cmp eax, (msd_class << 8) + (sata_subclass)
    je .sataPCIEnum
    pop rax
.u11:    ;After a device found, jump here to continue enumeration
    and bp, 000Fh       ;Zero the upper nybble again.
    mov eax, ebx        ;Return pci value into eax
    cmp eax, 80000008h  ;The lowest value
    jg .u1
    jmp pciExit
.sataPCIEnum:
    pop rax
    push rax
    push rbp
    mov ax, 1304h
    mov rbp, .spemsg
    int 30h
    pop rbp
    pop rax
    jmp .u11
.spemsg: db 0Ah, 0Dh, "AHCI SATA controller found", 0
.idePCIEnum:
    pop rax
    push rax
    push rbp
    mov ax, 1304h
    mov rbp, .ipemsg
    int 30h
    pop rbp
    pop rax
    push rax
    mov ah, 04h
    int 30h
    pop rax
;If function is 80h, then it will respond to default IO addresses
    test al, 80h ;Check if bus mastery is enabled. Only support DMA transfers
    jz .u11      ;Exit if not enabled
    cmp al, 80h  ;If 80h, device hardwired bus master legacy mode, all good.
    je .ipeWriteTable
;Bit bash, and reread, if it works, yay, if not, fail cancel
    mov dx, pci_index
    mov eax, ebx
    out dx, eax     ;Register offset 8
    add dx, 4       ;Point to pci_data
    and eax, 0FFFFFAFFh     ;Zero bits 0 and 2 of nybble 3
    out dx, eax
    sub dx, 4
    mov eax, ebx
    out dx, eax
    add dx, 4
    in eax, dx
    test eax, 00000500h  ;Test bits 0 and 2 of nybble 3 have been zeroed
    jnz .u11    ;IF not, fail
.ipeWriteTable:
;Now the controller and devices have been set to legacy, they should
; respond to the default IO addresses and IRQ. Save BAR 5 for Bus mastering.
    push rax
    push rbp
    mov rbp, .ipemsg2
    mov ax, 1304h
    int 30h
    pop rbp
    pop rax
    mov eax, ebx    
    mov al, 20h ;BAR4 Address
    mov dx, pci_index
    out dx, eax
    add dx, 4
    in eax, dx  ;Get BAR 4 address
    call IDE.addControllerTable ;Function will not add if we maxed out controllers
    jmp .u11
.ipemsg:    db 0Ah, 0Dh,"IDE ATA Controller found. Type: ", 0
.ipemsg2:   db 0Ah, 0Dh, "IDE ATA Controller set to compatibility mode",0
;bp lo = status register, 
;bp hi = controller being serviced (ie 1000xxxx => xHCI being serviced)
.uhci_found:
    or bp, 00010001b    ;set bit 0/mask = 1
    push rbp
    push rax
    push rbx
    mov ax, 1304h
    xor bh, bh
    mov rbp, .uhci_succ
    int 30h
    pop rbx
    pop rax
    pop rbp
    jmp .controlController
.uhci_succ:    db    0Ah, 0Dh,'UHCI controller found on IRQ ', 0
.ohci_found:
    or bp, 00100010b    ;set bit 1/mask = 2
    jmp .u11
.ehci_found:
    or bp, 01000100b    ;set bit 2/mask = 4
    push rbp
    push rax
    push rbx
    mov ax, 1304h
    xor bh, bh
    mov rbp, .ehci_succ
    int 30h
    pop rbx
    pop rax
    pop rbp
    jmp short .controlController
.ehci_succ:    db    0Ah, 0Dh,'EHCI controller found on IRQ ', 0
.xhci_succ:    db    0Ah, 0Dh,'xHCI controller found on IRQ ', 0
.xhci_found:
    push rbp
    push rax
    push rbx
    mov ax, 1304h
    xor bh, bh
    mov rbp, .xhci_succ
    int 30h
    pop rbx
    pop rax
    pop rbp
    or bp, 10001000b    ;set bit 3/mask = 8

.controlController:
;This for now will get the IRQ line for all controllers,
;and install a USB handler there, then disabling the HC rather than just the 
;legacy support.
;EAX doesnt need to be saved since the first instruction of .u11 is to move the 
;value of ebx back into eax.
;EDX doesnt need to be saved since the port data gets loaded in the proc above
;DO NOT MODIFY EBX
    xor edx, edx
    mov eax, ebx    ;Move a copy of ebx, the PCI config space device address
    mov al, 3Ch     ;offset 3C has interrupt masks in lower word
    mov dx, pci_index
    out dx, eax       ;set to give interrupt masks
    mov dx, pci_data
    in eax, dx        ;Get info into eax (formally, al)
    push rax
    and al, 0Fh
    mov ah, 04h
    int 30h
    pop rax
    test bp, 40h      ;Check if EHCI
    jz .cc1           ;Skip mapping
    and al, 0Fh       ;Clear upper nybble for good measure
    cmp al, 10h
    ja .cc1           ;Cant map it
    cmp al, 08h        
    jae .cc0
    push rsi
    push rdx
    push rax
    push rbx
    movzx rsi, al
    add esi, 20h
    mov dx, 8F00h
    mov rax, ehci_IRQ.pic1    ;PIC1 ep
    mov ebx, codedescriptor
    call idtWriteEntry
    pop rbx
    pop rax
    pop rdx
    pop rsi
    push rcx
    mov cl, al
    mov al, 1
    shl al, cl          ;Shift bit to appropriate position
    not al              ;Turn into a bitmask
    mov ah, al          ;Save in ah
    in al, pic1data
    and al, ah          ;Add bitmask to current mask
    out pic1data, al    ;Unmask this line
    pop rcx
    jmp short .cc1
.cc0:
    push rsi
    push rdx
    push rax
    push rbx
    movzx rsi, al
    add esi, 20h    ;Start of PIC range
    mov dx, 8F00h
    mov rax, ehci_IRQ
    mov ebx, codedescriptor
    call idtWriteEntry
    pop rbx
    pop rax
    pop rdx
    pop rsi
    push rcx
    sub al, 8
    mov cl, al
    in al, pic1data
    and al, 0FBh  ;Clear Cascade bit
    out pic1data, al
    mov al, 1
    shl al, cl    ;Shift bit to appropriate position
    not al        ;Turn into a bitmask
    mov ah, al    ;Save in ah
    in al, pic2data
    and al, ah    ;Add bitmask to current mask
    out pic2data, al    ;Unmask this line
    pop rcx
.cc1:
    mov eax, ebx    ;Bring back a copy of ebx, the PCI config space addr to eax
    mov al, 10h     ;Change the register from Class code to BAR0
    
    mov dx, pci_index
    out dx, eax        ;Set to give BAR0
    mov dx, pci_data
    in eax, dx        ;get unrefined BAR0/BASE pointer into eax

    and eax, 0FFFFFF00h    ;refine eax into an mmio register
    push rax    ;push BASE pointer onto stack

;Write USB controller table:
;Each table entry (tword), as follows:
;Offset:
; 00h - hci type (bp) [word]
; 02h - PCI address (ebx) [dword]
; 06h - MMIO address (eax) [dword]
;ALL REGISTERS PRESERVED, data stored at usbtablebase, size at usbtablesize
    push rsi
    push rcx
    movzx ecx, word [lousbtablesize]    ;get number of table entries
    mov esi, ecx
    shl ecx, 1    ;Multiply by 2
    lea esi, [8*esi + ecx + lousbtablebase] 
    ;multiply esi by 10 to get table offset & add to table base
    ;store table offset back in esi
    mov word [esi], bp    ;Store controller type
    add esi, 2
    mov dword [esi], ebx    
        ;Store PCI device config space address (set to register 2)
    add esi, 4
    mov dword [esi], eax    ;Store device MMIO Address (refined BAR0 value)
    pop rcx
    pop rsi
    inc word [lousbtablesize]

    cmp bp, 80h    ;Are we servicing xHCI, EHCI or UHCI?
    jge .controlxHCI
    cmp bp, 40h    ;Are we servicing EHCI or UHCI? 
    jge .controlEHCI
;If neither of these, collapse into UHCI
.controlUHCI:
;eax points to the refined base pointer
    push rbx                    ;temp stack save 
    mov eax, ebx     ;get the current packed bus,device,function,register combo
    and eax, 0FFFFF800h         ;Clear bottom 10 bytes.
    or eax, 2C0h                ;Function 2, register offset C0h

    push rax                    ;temp save address value on stack

    mov dx, pci_index
    out dx, eax
    add dl, 4                   ;dx now points to pci_index
    in eax, dx                  ;Bring register value into eax

    mov ax, 8F00h               ;Clear all SMI bits (no SMI pls)
    mov ebx, eax                ;save temporarily in ebx

    pop rax                     ;bring back address value from stack

    sub dl, 4                   ;put dx back to pci_index
    out dx, eax                 ;select legsup register

    add dl, 4                   ;aim dx back to pci_data
    mov eax, ebx                ;bring back new legsup value
    out dx, eax                 ;send it back!

;Now set bit 6 of the command register to 1 (semaphore)
    pop rbx                     ;Return original ebx value
    mov eax, ebx  ;Move a copy of ebx, PCI config space device address (index)
    mov al, 20h                 ;Change the register from Class code to BAR4 
    sub dx, 4                   ;Point dx back to pci_index
    out dx, eax                 ;Get the data we want!
    add dx, 4
    in eax, dx              ;Bring the value of BAR4 into eax, to add to BASE
    and eax, 0FFFFFFFCh         ;Refine the IO address that we got
    mov dx, ax                  ;Mov the base IO address into dx
;dx contains the base io address!
    mov ax, 0002h               ;Reset the HC
    out dx, ax
    push rcx
.cu0:
    xor rcx, rcx
    dec cl
.cu1:
    loop .cu1    ;wait

    in ax, dx    ;Bring value in
    and ax, 0002h
    jnz .cu0     ;Reset still in progress, loop again
    pop rcx

    xor ax, ax
    add dx, 4   ;point to USBINTR
    out dx, ax
    sub dx, 4   ;return to cmd
    out dx, ax  ;zero everything.

    pop rax     ;Get BASE (dereferenced BAR0) value back (stack align)
    jmp .u11                     ;return
;End UHCI

.controlxHCI:
;mov HCCPARAMS1 into edx, eax contains BASE pointer from BAR0 (offset 10h for 
; register)
    mov edx, dword [eax + 10h]    
    and edx, 0FFFF0000h
;mov hi word into lo word and shl by 2 to adjust that we are in units of DWORDS
    shr edx, 0Eh            
    add eax, edx            ;add offset from base onto base
                            ;eax now pointing at USBLEGSUP
.suohoc0: 
    mov edx, dword [eax]    ;store upper byte of USBLEGSUP into dl
    or edx, (1<<24)         ;Set the HCOSSEM Semaphore
    mov dword [eax], edx    ;replace the upper byte with HCOSSEM set

    push rcx                ;push poll counter
    xor rcx, rcx            
.suohoc1:    ;Remove control from BIOS and check for confirmation
    dec cx                  ;drop counter by one
    jz .weirdEHCI1          ;temporary label
    pause                   ;wait
    mov edx, dword [eax]    ;Check if owned by BIOS
    and edx, (1<<16)
    jnz .suohoc1            ;not zero, keep polling

    mov cx, 0FFFFh
.suohoc2:    ;Check if control to OS has been given
    dec cx
    jz .suohoc21            ;timeout, assume it has.
    pause                
    mov edx, dword [eax]
    and edx, (1<<24)
    jz .suohoc2             ;if zero, keep polling until bit set => owned by OS
.suohoc21:    ;Check for legsup being present, assume for now.
    pop rcx                   ;return poll counter
.suohoc3:
    mov dword [eax + 4], 0    ;Set all SMI bytes to 0 so no SMIs will be set.
    pop rax                   ;Bring back BAR0 into eax
    jmp .u11                  ;return

.controlEHCI:
    mov edx, dword [eax + 8h]
    and edx, 0000FF00h
    shr dx, 8
    cmp edx, 40h        
    jl .ce0            ;No EECP pointer present, skip BIOS/OS EHCI handover
    call .ehcieecpsetup
.ce0:
    xor edx, edx       ;clear edx
    pop rax            ;Bring back refined base into eax
    mov edx, dword [eax]
    and edx, 000000FFh
    add eax, edx
    and dword [eax + 40h], 0FFFFFFFEh
                            ;located at offset 40 of the opregs.

    jmp .u11                ;return
.ehcieecpsetup:
;eax has hccparams
;ebx has pci register, to get class code
    push rax
    push rdx
    push rbx
    push rcx
    mov bl, dl       ;Move EECP pointer into low byte of PCI address
    mov eax, ebx     ;Move this address to eax
    mov dx, pci_index
    out dx, eax      ;Return EHCI EECP register
    mov dx, pci_data
    in eax, dx       ;Get this register into eax
    or eax, 1000000h ;Set bit 24, to tell bios to give up control!
    xchg eax, ebx    ;Swap these two temporarily
    mov dx, pci_index
    out dx, eax
    xchg eax, ebx    ;Bring back out value to eax
    mov dx, pci_data
    out dx, eax      ;Tell BIOS who is boss of the EHCI controller
    
    xor rcx, rcx
    mov eax, ebx     ;Get address back into eax
.ees1:
    dec cx
    jz .weirdEHCI1
    out waitp, al    ;Wait a bit, for device to process request

    mov dx, pci_index
    out dx, eax
    mov dx, pci_data
    in eax, dx       ;Get word back into eax
    and eax, 10000h  ;BIOS should set this bit to zero
    jnz .ees1        ;Not zero yet, try again!

    xor rcx, rcx
    mov eax, ebx    ;Get address back into eax    
.ees2:
    dec cx
    jz .weirdEHCI1
    out waitp, al    ;Wait a bit, for device to process request

    mov dx, pci_index
    out dx, eax
    mov dx, pci_data
    in eax, dx        ;Get word back into eax
    and eax, 1000000h    ;This should set this bit to one now (OS control)
    jz .ees2        ;Not set yet, try again!
;Now we have control! :D Finally, now lets clear SMI bits
    add ebx, 4h
    mov eax, ebx
    mov dx, pci_index
    out dx, eax
    xor eax, eax
    mov dx, pci_data
    out dx, eax        ;NO MORE SMI INTERRUPTS

    pop rcx
    pop rbx
    pop rdx
    pop rax
    ret

.weirdEHCI1:
    mov rax, 1304h
    mov rbx, 0007h
    mov rcx, failmsglen
    mov rbp, .failmsg
    int 30h    ; write strng
    pause
    hlt
.failmsg: db 0Ah,0Dh,"xHCI or EHCI controller fail, halting system", 0Ah, 0Dh, 0
failmsglen    equ    $ - .failmsg

pciExit:
;----------------------------------------------------------------
;                            End Proc                           :
;----------------------------------------------------------------