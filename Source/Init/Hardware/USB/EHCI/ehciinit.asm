;            ------------USB section below------------
;                   ---- PCI table parse ----
;Parse the PCI tables for ehci controllers
hciParse:
    mov byte [numMSD], 0
    movzx r9, word [lousbtablesize]
    mov esi, lousbtablebase
    mov edi, eControllerList
.hcip1:
    test word [esi], ehcimask    ;check if we at a ehci mask
    jz .hcip2   ;If not, skip adding to ehci table
    ;First catch all clause (temporary for version 1 of BIOS with max 4 
    ; controllers)
    cmp byte [eControllers], 4
    je .pr0    ;escape this whole setup proc if at 4 controllers
    mov rax, qword [esi + 2]    ;take pci and mmio address into rax
    stosq                        ;store into rdi and inc rdi by 8 to next entry
    inc byte [eControllers]    ;increase the number of controllers variable
.hcip2:
;Any additional data saving occurs here
    add esi, 10    ;Goto next table entry
    dec r9b     ;Once all table entries exhausted, fall through
    jnz .hcip1
    
;               ---- EHCI controller enumeration ----
;Enumerate each ehci ctrlr root hub for valid usb devices (hubs and valid MSD)
    mov cl, byte [eControllers]
    mov ax, 1304h
    mov rbp, .echiInitMsg
    int 30h
.pr0:   ;If ctrlr failure or ports exhausted, ret to here for next ctrlr
    test cl, cl
    jz .noEHCI    ;No EHCI controllers or last controler?
    dec cl    ;Undo the absolute count from above
    mov al, cl
    call USB.setupEHCIcontroller
    jc .pr0    ;Continue to next controller
    call USB.ehciRunCtrlr       ;Activate online controller
    jc .pr0
    call USB.ehciAdjustAsyncSchedCtrlr ;Start schedule and lock ctrlr as online
    jc .pr0
    call USB.ehciCtrlrGetNumberOfPorts
    mov dl, al      ;Save the number of ports in dl
    mov dh, byte [eActiveCtrlr]    ;Save current active ctrlr in dh
    xor r10, r10    ;Host hub 0 [ie Root Hub enum only] (for enum)
.pr1:
    dec dl
    mov r12, 3      ;Attempt three times to enumerate
.pr11:
    call USB.ehciEnumerateRootPort
    jz .pr2
    cmp byte [msdStatus], 20h  ;General Controller Failure
    je USB.ehciCriticalErrorWrapper
    dec r12
    jnz .pr11
.pr2:
    test dl, dl
    jnz .pr1
    test cl, cl ;Once cl is zero we have gone through all controllers
    jnz .pr0

    mov eax, 1304h
    mov rbp, remDevInit.ok  ;Reuse the OK from the other proc
    xor bh, bh
    int 30h
    jmp short .exit
.echiInitMsg db 0Ah,0Dh,"Initialising USB and EHCI root hubs...",0
.noEHCI:
;If no EHCI, skip MSD search on EHCI bus. Goto Int 33h init
    jmp int33hinit.i33iend  ;Could go to int33hinit, but this is minutely faster
.exit: