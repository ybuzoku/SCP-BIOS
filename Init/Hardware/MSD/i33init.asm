;----------------------------------------------------------------
;                      Int 33h Initialisation                   :
;----------------------------------------------------------------    
int33hinit:
;Create Int 33h data table entry for each MSD/floppy device using steps 1-3.
;Go through MSD table and add devices to diskDevices
    mov rbp, usbDevTbl
    mov rdi, diskDevices
.i33i1:
    cmp byte [rbp + 2], 08h ;MSD USB Class code
    jne .i33proceed
;Successfully found a valid MSD device. Talk to it
    mov ax, word [rbp]  ;Get address/bus pair
    call USB.ehciGetDevicePtr    ;Get pointer to MSD dev in rsi
    call disk_io.deviceInit
    cmp al, 1   ;Critical error
    je USB.ehciCriticalErrorWrapper
    cmp al, 2   ;Device stopped responding, remove from USB data tables
    je .i33ibad 
    cmp al, 3   ;Device not added to data tables
    je .i33proceed
;Valid device added, increment rdi to next diskDevices table entry
    add rdi, int33TblEntrySize
.i33proceed:
    cmp rbp, usbDevTblEnd
    je .i33iend
    add rbp, usbDevTblEntrySize
    jmp .i33i1
.i33ibad:   ;If it goes here, clear table entry
    mov qword [rdi], 0  ;Remove from diskDevice table
    mov ax, word [rsi]
    call USB.ehciRemoveDevFromTables    ;Remove from USB tables
    jmp short .i33proceed ;Goto next device
.i33iend:
    mov al, byte [numMSD]
    add byte [i33Devices], al   ;Add the number of MSD devices to Int 33h total