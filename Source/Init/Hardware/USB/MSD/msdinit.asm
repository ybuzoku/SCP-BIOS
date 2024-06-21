remDevInit:
;Devices on root hubs have been enumerated, and added to tables,
;Now we reset them (in the case of MSD) and enumerate further (on Hubs)
    mov ax, 1304h
    xor bh, 0bh
    mov rbp, .rmhmsg
    int 30h
.hubs_init:
    mov rsi, hubDevTbl
;First we scan for hubs only
.redi1:
    cmp byte [rsi], 0   ;Not an entry
    jz .hubnextentry
    cmp byte [rsi + 5], 0   ;If number of ports on hub is 0, dev uncofigured
    jnz .hubnextentry  ;Device must be already enumerated

    mov al, byte [rsi + 1]  ;Get bus number into al

    call USB.ehciAdjustAsyncSchedCtrlr
    jc .hubnextentry

    call USB.ehciDevSetupHub  ;Only needs a valid device in rsi
    jc .hubnextentry
.hubnextentry:
    add rsi, hubDevTblEntry_size ;Goto next table entry
    cmp rsi, hubDevTbl + hubDevTblSz*hubDevTblEntry_size  ;End of table address
    jb .redi1  ;We are still in table
.hub_rescan:
;Now we check that all hubs are initialised
    mov rsi, hubDevTbl  ;Return to head of table
;Leave as a stub for now. Dont support deeper than 1 level of devices
;The specification allows for a maximum of 7 levels of depth.
.msds_init:
    mov ax, 1304h
    xor bh, 0bh
    mov rbp, .ok
    int 30h
    mov ax, 1304h
    xor bh, 0bh
    mov rbp, .msdmsg
    int 30h
    mov rsi, msdDevTbl
.msd1:
    cmp byte [rsi], 0   ;Not an entry
    jz .msdNextEntry
    call USB.ehciMsdInitialise
    jnc .msdNextEntry
    dec al
    jz USB.ehciCriticalErrorWrapper ;al = 1 => Host error, 
;                                    al = 2 => Bad dev, removed from MSD tables
.msdNextEntry:
    add rsi, msdDevTblEntry_size ;Goto next entry
    cmp rsi, msdDevTbl + msdDevTblSz*msdDevTblEntry_size
    jne .msd1
.rediexit:
    mov ax, 1304h
    xor bh, 0bh
    mov rbp, .ok
    int 30h
    jmp short .exit
.rmhmsg db 0Ah,0Dh,"Initialising USB ports...",0
.ok db " OK",0
.msdmsg db 0Ah,0Dh,"Initialising MSD devices...",0
.exit: