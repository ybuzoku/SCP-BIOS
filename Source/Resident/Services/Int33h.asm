;---------------------Storage Interrupt Int 33h------------------
;Input : dl = Drive number, rbx = Address of buffer, 
;        al = number of sectors, ch = Track number, 
;        cl = Sector number, dh = Head number
;Input LBA: dl = Drive Number, rbx = Address of Buffer, 
;           al = number of sectors, rcx = LBA number
;
;All registers not mentioned above, preserved
;----------------------------------------------------------------
disk_io:
    cld ;Ensure all string reads/writes are in the right way
    test dl, 80h
    jnz fdisk_io    ;If bit 7 set, goto Fixed disk routines
    push rdx
    inc dl          ;Inc device number count to absolute value
    cmp dl, byte [numMSD]   ;For now, numMSD, eventually, numRemDrv
    pop rdx
    ja .baddev
    cmp ah, 16h
    jz .deviceChanged   ;Pick it off

    call .busScan   ;Bus scan only in valid cases
    cmp byte [msdStatus], 40h   ;Media seek failed
    je .noDevInDrive

    test ah, ah
    jz .reset           ;ah = 00h Reset Device
    dec ah
    jz .statusreport    ;ah = 01h Get status of last op and req. sense if ok 

    mov byte [msdStatus], 00    ;Reset status byte for following operations

    dec ah
    jz .readsectors     ;ah = 02h CHS Read Sectors
    dec ah
    jz .writesectors    ;ah = 03h CHS Write Sectors
    dec ah
    jz .verify          ;ah = 04h CHS Verify Sectors
    dec ah
    jz .format          ;ah = 05h CHS Format Track (Select Head and Cylinder)

    cmp ah, 02h
    je .formatLowLevel  ;ah = 07h (SCSI) Low Level Format Device

    cmp ah, 7Dh         ;ah = 82h LBA Read Sectors
    je .lbaread
    cmp ah, 7Eh         ;ah = 83h LBA Write Sectors
    je .lbawrite
    cmp ah, 7Fh         ;ah = 84h LBA Verify Sectors
    je .lbaverify
    cmp ah, 80h         ;ah = 85h LBA Format Sectors
    je .lbaformat
    cmp ah, 83h         ;ah = 88h LBA Read Drive Parameters
    je .lbareadparams
.baddev:
    mov ah, 01h
    mov byte [msdStatus], ah   ;Invalid function requested signature
.bad:
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq
.noDevInDrive:
    mov ah, byte [msdStatus]
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq
.reset: ;Device Reset
    push rsi
    push rdx
    call .i33ehciGetDevicePtr
    call USB.ehciAdjustAsyncSchedCtrlr
    call USB.ehciMsdBOTResetRecovery
.rrexit:
    pop rdx
    pop rsi
    jc .rrbad
    mov ah, byte [msdStatus]
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.rrbad:
    mov ah, 5   ;Reset failed
    mov byte [msdStatus], ah
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq
.statusreport:  
;If NOT a host/bus/ctrlr type error, request sense and ret code
    mov ah, byte [msdStatus]    ;Get last status into ah
    test ah, ah ;If status is zero, exit
    jnz .srmain
    and byte [rsp + 2*8h], 0FEh     ;Clear CF
    iretq
.srmain:
    mov byte [msdStatus], 00    ;Reset status byte
    cmp ah, 20h     ;General Controller failure?
    je .srexit
    cmp ah, 80h     ;Timeout?
    je .srexit
;Issue a Request sense command
    push rsi
    push rax    ;Save original error code in ah on stack
    call .i33ehciGetDevicePtr
    call USB.ehciAdjustAsyncSchedCtrlr
    jc .srexitbad1
    call USB.ehciMsdBOTRequestSense
    call USB.ehciMsdBOTCheckTransaction
    test ax, ax
    pop rax         ;Get back original error code
    jnz .srexitbad2
    movzx r8, byte [ehciDataIn + 13]  ;Get ASCQ into r8
    shl r8, 8                        ;Make space in lower byte of r8 for ASC key
    mov r8b, byte [ehciDataIn + 12]   ;Get ASC into r8
    shl r8, 8                    ;Make space in lower byte of r8 for sense key
    mov r8b, byte [ehciDataIn + 2]  ;Get sense key into al
    or r8b, 0F0h                    ;Set sense signature (set upper nybble F)
    pop rsi
.srexit:
    or byte [rsp + 2*8h], 1 ;Non-zero error, requires CF=CY
    iretq
.srexitbad2:
    mov ah, -1  ;Sense operation failed
    jmp short .srexitbad
.srexitbad1:
    mov ah, 20h ;General Controller Failure
.srexitbad:
    pop rsi
    mov byte [msdStatus], ah
    jmp short .rsbad

.readsectors:
    push rdi
    mov rdi, USB.ehciMsdBOTInSector512
    call .sectorsEHCI
    pop rdi
    mov ah, byte [msdStatus]    ;Return Error code in ah
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.rsbad:
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq

.writesectors:
    push rdi
    mov rdi, USB.ehciMsdBOTOutSector512
    call .sectorsEHCI
    pop rdi
    mov ah, byte [msdStatus]
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq

.verify:
    push rdi
    mov rdi, USB.ehciMsdBOTVerify
    call .sectorsEHCI   ;Verify sector by sector
    pop rdi
    mov ah, byte [msdStatus]
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.format:
;Cleans sectors on chosen track. DOES NOT Low Level Format.
;Fills sectors with fill byte from table
    push rax
    push rbx
    push rcx
    push rsi
    push rdi
    push rbp

    push rcx                    ;Save ch = Cylinder number
    mov rsi, qword [diskDptPtr]
    mov eax, 80h                 ;128 bytes
    mov cl, byte [rsi + 3]  ;Bytes per track
    shl eax, cl                  ;Multiply 128 bytes per sector by multiplier
    mov ecx, eax
    mov al, byte [rsi + 8]  ;Fill byte for format
    mov rdi, sectorbuffer       ;Large enough buffer
    rep stosb                   ;Create mock sector

    mov cl, byte [rsi + 4]  ;Get sectors per track
    movzx ebp, cl               ;Put number of sectors in Cylinder in ebp

    pop rcx                     ;Get back Cylinder number in ch
    mov cl, 1                   ;Ensure start at sector 1 of Cylinder

    call .convertCHSLBA ;Converts to valid 32 bit LBA in ecx for geometry type
    ;ecx now has LBA
.formatcommon:
    call .i33ehciGetDevicePtr
    jc .fbad
    mov edx, ecx    ;Load edx for function call
;Replace this section with a single USB function
    call USB.ehciAdjustAsyncSchedCtrlr
    mov rbx, sectorbuffer
.f0:
    call USB.ehciMsdBOTOutSector512
    jc .sebadBB
    inc edx ;Inc LBA
    dec ebp ;Dec number of sectors to act on
    jnz .f0
    clc
.formatexit:
    pop rbp
    pop rdi
    pop rsi
    pop rcx
    pop rbx
    pop rax
    mov ah, byte [msdStatus]
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.fbadBB:
    mov byte [msdStatus], 0BBh  ;Unknown Error, request sense
.fbad:
    stc
    jmp short .formatexit
.lbaread:
    push rdi
    mov rdi, USB.ehciMsdBOTInSector512
    call .lbaCommon
    pop rdi
    mov ah, byte [msdStatus]    ;Return Error code in ah
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq   
.lbawrite:
    push rdi
    mov rdi, USB.ehciMsdBOTOutSector512
    call .lbaCommon
    pop rdi
    mov ah, byte [msdStatus]    ;Return Error code in ah
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.lbaverify:
    push rdi
    mov rdi, USB.ehciMsdBOTVerify
    call .lbaCommon
    pop rdi
    mov ah, byte [msdStatus]    ;Return Error code in ah
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.lbaformat:
    push rax
    push rbx
    push rcx
    push rsi
    push rdi
    push rbp
    movzx ebp, al ;Save the number of sectors to format in ebp
    push rcx
    push rdx
    mov ecx, 200h
    mov rdi, sectorbuffer
    mov rdx, qword [diskDptPtr]
    mov al, byte [rdx + 8]  ;Fill byte for format
    rep stosb
    pop rdx
    pop rcx
    jmp .formatcommon

.lbaCommon:
    push rax
    push rsi
    push rbx
    push rcx
    push rdx
    push rbp
    test al, al
    jz .se2 ;If al=0, skip copying sectors, clears CF
    movzx ebp, al
    jmp .seCommon

;Low level format, ah=07h
.formatLowLevel:
    push rsi
    push rax
    call .i33ehciGetDevicePtr   ;al = bus num, rsi = ehci device structure ptr
    call USB.ehciMsdBOTFormatUnit
    pop rax
    pop rsi
    mov ah, byte [msdStatus]
    jc .rsbad
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.lbareadparams:
;Reads drive parameters (for drive dl which is always valid at this point)
;Output: rbx = dBlockSize (Dword for LBA block size)
;        rcx = qLastLBANum (Qword address of last LBA)
;         dl = Number of removable devices 
;         ah = 0
    push rdx
    push rax
    movzx rax, dl   ;Move drive number offset into rax
    mov rdx, int33TblEntrySize
    mul rdx
    lea rdx, qword [diskDevices + rax]  ;Move address into rdx
    xor ebx, ebx
    mov ebx, dword [rdx + 3]    ;Get dBlockSize for device
    mov rcx, qword [rdx + 7]    ;Get qLastLBANum for device
    pop rax
    pop rdx
    mov dl, byte [numMSD]
    xor ah, ah
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.sectorsEHCI:
;Input: rdi = Address of USB EHCI MSD BBB function
;Output: CF = CY: Error, exit
;        CF = NC: No Error
    push rax
    push rsi
    push rbx
    push rcx
    push rdx
    push rbp
    test al, al
    jz .se2 ;If al=0, skip copying sectors, clears CF
    movzx ebp, al   ;Move the number of sectors into ebp
    call .convertCHSLBA ;Converts to valid 32 bit LBA in ecx for geometry type
    ;ecx now has LBA
.seCommon:  ;Entered with ebp = Number of Sectors and ecx = Start LBA
    call .i33ehciGetDevicePtr
    jc .sebad
    mov rdx, rcx    ;Load edx for function call
;Replace this section with a single USB function
    call USB.ehciAdjustAsyncSchedCtrlr
    xor al, al      ;Sector counter
.se1:
    inc al  ;Inc Sector counter
    push rax
    call rdi
    pop rax
    jc .sebadBB
    add rbx, 200h   ;Goto next sector
    inc rdx ;Inc LBA
    dec ebp ;Dec number of sectors to act on
    jnz .se1
    clc
.se2:
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    pop rsi
    pop rax
    ret
.sebadBB:
    mov byte [msdStatus], 0BBh  ;Unknown Error, request sense
.sebad:
    stc
    jmp short .se2

.i33ehciGetDevicePtr:
;Input: dl = Int 33h number whose 
;Output: rsi = Pointer to ehci msd device parameter block
;        al = EHCI bus the device is on
    push rbx    ;Need to temporarily preserve rbx
    movzx rax, dl   ;Move drive number offset into rax
    mov rdx, int33TblEntrySize
    mul rdx
    lea rdx, qword [diskDevices + rax]  ;Move address into rdx
    cmp byte [rdx], 0   ;Check to see if the device type is 0 (ie doesnt exist)
    jz .i33egdpbad ;If not, exit
    mov ax, word [rdx + 1]  ;Get address/Bus pair into ax
    call USB.ehciGetDevicePtr   ;Get device pointer into rsi
    mov al, ah          ;Get the bus into al
    pop rbx
    clc
    ret
.i33egdpbad:
    stc
    ret

.convertCHSLBA:
;Converts a CHS address to LBA
;Input: dl = Drive number, if dl < 80h, use diskdpt. If dl > 80h, use hdiskdpt
;       ch = Track number, cl = Sector number, dh = Head number 
;Output: ecx = LBA address
;----------Reference Equations----------
;C = LBA / (HPC x SPT)
;H = (LBA / SPT) mod HPC
;S = (LBA mod SPT) + 1
;+++++++++++++++++++++++++++++++++++++++
;LBA = (( C x HPC ) + H ) x SPT + S - 1
;---------------------------------------
;Use diskdpt.spt for sectors per track value! 
;1.44Mb geometry => H=2, C=80, S=18
    push rax
    push rsi
    mov rsi, qword [diskDptPtr]
    shl ch, 1   ;Multiply by HPC=2
    add ch, dh  ;Add head number
    mov al, ch  ;al = ch = (( C x HPC ) + H )
    mul byte [rsi + 4]  ;Sectors per track
    xor ch, ch  
    add ax, cx  ;Add sector number to ax
    dec ax
    movzx ecx, ax
    pop rsi
    pop rax
    ret
.deviceChanged:
;Entry: dl = Drive number
;Exit: ah = 00h, No device changed occured, CF = CN
;      ah = 01h, Device changed occured, CF = CN
;      CF = CY if an error occured or device removed
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11

    push rax

    movzx r11, byte [msdStatus] ;Preserve the original status byte
    movzx ebp, dl               ;Save the device number in ebp
    call .i33ehciGetDevicePtr   ;Get MSD dev data block ptr in rsi and bus in al
;Check port on device for status change.
    cmp byte [rsi + 2], 0   ;Check if root hub
    jz .dcRoot
;External Hub procedure
    mov ax, word [rsi + 1]  ;Get bus and host hub address
    xchg al, ah             ;Swap endianness
    mov r9, rsi
    call USB.ehciGetDevicePtr   ;Get the hub address in rsi
    mov al, ah
    call USB.ehciAdjustAsyncSchedCtrlr
    mov dword [ehciDataIn], 0
    mov rdx, 00040000000000A3h ;Get Port status
    movzx ebx, byte [r9 + 3]    ;Get the port number from device parameter block
    shl rbx, 4*8    ;Shift port number to right position
    or rbx, rdx
    movzx ecx, byte [rsi + 4]  ;bMaxPacketSize0
    mov al, byte [rsi]      ;Get upstream hub address
    call USB.ehciGetRequest
    jc .dcError

    mov r8, USB.ehciEnumerateHubPort    ;Store address for if bit is set
    mov edx, dword [ehciDataIn]
    and edx, 10000h ;Isolate the port status changed bit
    shr edx, 10h    ;Shift status from bit 16 to bit 0
.dcNoError:
    mov byte [msdStatus], r11b  ;Return back the original status byte
    pop rax
    mov ah, dl                  ;Place return value in ah
    call .dcRetPop
    and byte [rsp + 2*8h], 0FEh ;Clear CF
    iretq
.dcError:
    pop rax ;Just return the old rax value
    call .dcRetPop
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq
.dcRetPop:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
.dcRoot:
;Root hub procedure.
    call USB.ehciAdjustAsyncSchedCtrlr  ;Reset the bus if needed
    call USB.ehciGetOpBase      ;Get opbase into rax
    movzx ebx, byte [rsi + 3]   ;Get MSD port number into dl
    dec ebx                     ;Reduce by one
    mov edx, dword [eax + 4*ebx + ehciportsc]  ;Get port status into eax
    and dl, 2h      ;Only save bit 1, status changed bit
    shr dl, 1       ;Shift down by one bit
    jmp short .dcNoError    ;Exit
.busScan:
;Will request the hub bitfield from the RMH the device is plugged in to.
;Preserves ALL registers.
;dl = Device number

;If status changed bit set, call appropriate enumeration function.
;If enumeration returns empty device, keep current device data blocks in memory,
; but return Int 33h error 40h = Seek operation Failed.
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11

    movzx r11, byte [msdStatus] ;Preserve the original status

    movzx ebp, dl               ;Save the device number in ebp
    call .i33ehciGetDevicePtr   ;Get MSD dev data block ptr in rsi and bus in al
;Check port on device for status change.
    cmp byte [rsi + 2], 0   ;Check if root hub
    jz .bsRoot
;External Hub procedure
    mov ax, word [rsi + 1]  ;Get bus and host hub address
    xchg al, ah             ;Swap endianness
    mov r9, rsi
    call USB.ehciGetDevicePtr   ;Get the hub address in rsi
    mov al, ah
    call USB.ehciAdjustAsyncSchedCtrlr
    mov dword [ehciDataIn], 0
    mov rdx, 00040000000000A3h ;Get Port status
    movzx ebx, byte [r9 + 3]    ;Get the port number from device parameter block
    shl rbx, 4*8    ;Shift port number to right position
    or rbx, rdx
    movzx ecx, byte [rsi + 4]  ;bMaxPacketSize0
    mov al, byte [rsi]      ;Get upstream hub address
    call USB.ehciGetRequest
    jc .bsErrorExit

    mov r8, USB.ehciEnumerateHubPort    ;Store address for if bit is set
    mov edx, dword [ehciDataIn]
    and edx, 10001h
    test edx, 10000h
    jnz .bsClearPortChangeStatus    ;If top bit set, clear port change bit
.bsret:
    test dl, 1h
    jz .bsrExit06h  ;Bottom bit not set, exit media changed Error (edx = 00000h)
.bsexit:    ;The fall through is (edx = 00001h), no change to dev in port
    mov byte [msdStatus], r11b  ;Get back the original status byte
.bsErrorExit:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
.bsrExit06h:    ;If its clear, nothing in port, return media changed error
    mov r11, 06h ;Change the msdStatus byte, media changed or removed
    stc
    jmp short .bsexit
.bsClearPortChangeStatus:
    push rdx
    mov dword [ehciDataIn], 0
    mov rdx, 0000000000100123h  ;Set Port status
    movzx ebx, byte [r9 + 3]    ;Get the port number from device parameter block
    shl rbx, 4*8    ;Shift port number to right position
    or rbx, rdx
    movzx ecx, byte [rsi + 4]  ;bMaxPacketSize0
    mov al, byte [rsi]      ;Get device address
    call USB.ehciSetNoData
    pop rdx
    jc .bsErrorExit  ;If error exit by destroying the old msdStatus

    test dl, 1h
    jz .bsrExit06h  ;Bottom bit not set, exit media changed error (edx = 10000h)
    jmp short .bsCommonEP   ;Else new device in port needs enum (edx = 10001h)
.bsRtNoDev:
    or dword [eax + 4*ebx + ehciportsc], 2  ;Clear the bit
    jmp short .bsrExit06h   ;Exit with seek error
.bsRoot:
;Root hub procedure.
    call USB.ehciAdjustAsyncSchedCtrlr  ;Reset the bus if needed
    call USB.ehciGetOpBase      ;Get opbase into rax
    movzx ebx, byte [rsi + 3]   ;Get MSD port number into dl
    dec ebx                     ;Reduce by one
    mov edx, dword [eax + 4*ebx + ehciportsc]  ;Get port status into eax
    and dl, 3h      ;Only save bottom two bits
    test dl, dl     ;No device in port  (dl=00b)
    jz .bsrExit06h  ;Exit media changed error
    dec dl          ;Device in port     (dl=01b)
    jz .bsexit      ;Exit, no status change
    dec dl          ;New device, Device removed from port   (dl=10b)
    jz .bsRtNoDev   ;Clear state change bit and exit Seek error
;Fallthrough case, New device, Device inserted in port  (dl=11b)
    or dword [eax + 4*ebx + ehciportsc], 2  ;Clear the state change bit
    mov r8,  USB.ehciEnumerateRootPort   ;The enumeration function to call
    mov r9, rsi        ;Store the device pointer in r9
    mov esi, 0         ;Store 0 for root hub parameter block                 
.bsCommonEP:
;Invalidate USB MSD and Int 33h table entries for device
;r9 has device pointer block and rsi has host hub pointer (if on RMH)
    mov bx, word [r9]          ;bl = Address, bh = Bus
    mov dh, bh                 ;dh = Bus
    mov dl, byte [r9 + 3]      ;dl = Device Port
    movzx r10, byte [r9 + 2]   ;r10b = Host hub address (0 = Root hub)
    mov ax, bx                 ;ax needs a copy for RemoveDevFromTables
    call USB.ehciRemoveDevFromTables    ;Removes device from USB tables
    xchg ebp, edx                       ;device number -><- bus/dev pair
    call .i33removeFromTable            ;Removes device from Int 33h table
    xchg ebp, edx                       ;bus/dev pair -><- device number
;Devices enumerated, time to reenumerate!
    mov ecx, 3
    test esi, esi   ;Is device on root hub?
    jnz .bsr0
    dec dl  ;Recall that device port must be device port - 1 for Root hub enum
.bsr0:
    call r8
    jz .bsr1
    cmp byte [msdStatus], 20h   ;General Controller Failure?
    je .bsrFail
    dec ecx
    jnz .bsr0
    jmp short .bsrFail
.bsr1:
    xchg r9, rsi    ;MSD parameter blk -><- Hub parameter blk (or 0 if root)
    call USB.ehciMsdInitialise
    test al, al
    jnz .bsrFail    ;Exit if the device failed to initialise
;Multiply dl by int33TblEntrySize to get the address to write Int33h table
    mov edx, ebp    ;Move the device number into edx (dl)
    mov eax, int33TblEntrySize  ;Zeros the upper bytes
    mul dl  ;Multiply dl by al. ax has offset into diskDevices table
    add rax, diskDevices
    mov rdi, rax    ;Put the offset into the table into rdi
    call .deviceInit
    test al, al
    jz .bsexit  ;Successful, exit!
    cmp al, 3
    je .bsexit  ;Invalid device type, but ignore for now
.bsrFail:
    mov r11, 20h ;Change the msdStatus byte to Gen. Ctrlr Failure
    stc
    jmp .bsexit
.deviceInit:    
;Further initialises an MSD device for use with the int33h interface.
;Adds device data to the allocated int33h data table.
;Input: rdi = device diskDevice ptr (given by device number*int33TblEntrySize)
;       rsi = device MSDDevTbl entry (USB address into getDevPtr)
;Output: al = 0 : Device added successfully
;        al = 1 : Bus error
;        al = 2 : Read Capacities/Reset recovary failed after 10 attempts
;        al = 3 : Invalid device type (Endpoint size too small, temporary)
;   rax destroyed
;IF DEVICE HAS MAX ENDPOINT SIZE 64, DO NOT WRITE IT TO INT 33H TABLES
    push rcx
    mov al, 3   ;Invalid EP size error code
    cmp word [rsi + 9], 200h  ;Check IN max EP packet size
    jne .deviceInitExit
    cmp word [rsi + 12], 200h ;Check OUT max EP packet size
    jne .deviceInitExit

    mov al, byte [rsi + 1]  ;Get bus number
    call USB.ehciAdjustAsyncSchedCtrlr
    mov al, 1       ;Bus error exit
    jc .deviceInitExit
    mov ecx, 10
.deviceInitReadCaps:
    call USB.ehciMsdBOTReadCapacity10   ;Preserve al error code
    cmp byte [msdStatus], 20h   ;General Controller Failure
    je .deviceInitExit
    call USB.ehciMsdBOTCheckTransaction
    test ax, ax     ;Clears CF
    jz .deviceInitWriteTableEntry   ;Success, write table entry
    call USB.ehciMsdBOTResetRecovery    ;Just force a device reset
    cmp byte [msdStatus], 20h   ;General Controller Failure
    je .deviceInitExit
    dec ecx
    jnz .deviceInitReadCaps
    mov al, 2   ;Non bus error exit
    stc ;Set carry, device failed to initialise properly
    jmp short .deviceInitExit
.deviceInitWriteTableEntry:
    mov byte [rdi], 1   ;MSD USB device signature

    mov ax, word [rsi]  ;Get address and bus into ax
    mov word [rdi + 1], ax  ;Store in Int 33h table

    mov eax, dword [ehciDataIn + 4] ;Get LBA block size
    bswap eax
    mov dword [rdi + 3], eax

    mov eax, dword [ehciDataIn] ;Get zx qword LastLBA
    bswap eax
    mov qword [rdi + 7], rax

    mov byte [rdi + 15], 2  ;Temporary, only accept devices with 200h EP sizes
    xor al, al 
.deviceInitExit:
    pop rcx
    ret
.i33removeFromTable:
;Uses Int 33h device number to invalidate the device table entry
;Input: dl = Device number
;Output: Nothing, device entry invalidated
    push rax
    push rdx
    mov al, int33TblEntrySize
    mul dl  ;Multiply tbl entry size by device number, offset in ax
    movzx rax, ax
    mov byte [diskDevices + rax], 0 ;Invalidate entry
    pop rdx
    pop rax
    ret

diskdpt:   ;Imaginary floppy disk parameter table with disk geometry. 
;For more information on layout, see Page 3-26 of IBM BIOS ref
;Assume 2 head geometry due to emulating a floppy drive
.fsb:   db 0    ;First specify byte
.ssb:   db 0    ;Second specify byte
.tto:   db 0    ;Number of timer ticks to wait before turning off drive motors
.bps:   db 2    ;Number of bytes per sector in multiples of 128 bytes, editable.
                ; 0 = 128 bytes, 1 = 256 bytes, 2 = 512 bytes etc
                ;Left shift 128 by bps to get the real bytes per sector
.spt:   db 9    ;Sectors per track
.gpl:   db 0    ;Gap length
.dtl:   db 0    ;Data length
.glf:   db 0    ;Gap length for format
.fbf:   db 0FFh ;Fill byte for format
.hst:   db 0    ;Head settle time in ms
.mst:   db 1    ;Motor startup time in multiples of 1/8 of a second.

fdiskdpt: ;Fixed drive table, only cyl, nhd and spt are valid. 
;           This schema gives roughly 8.42Gb of storage.
;           All fields with 0 in the comments are reserved post XT class BIOS.
.cyl:   dw  1024    ;1024 cylinders
.nhd:   db  255     ;255 heads
.rwc:   dw  0       ;Reduced write current cylinder, 0
.wpc:   dw  -1      ;Write precompensation number (-1=none)
.ecc:   db  0       ;Max ECC burst length, 0
.ctl:   db  08h     ;Control byte (more than 8 heads)
.sto:   db  0       ;Standard timeout, 0
.fto:   db  0       ;Formatting timeout, 0
.tcd:   db  0       ;Timeout for checking drive, 0
.clz:   dw  1023    ;Cylinder for landing zone
.spt:   db  63      ;Sectors per track
.res:   db  0       ;Reserved byte

;----------------------Fixed Disk Int 33h Ext-------------------
; Subfunctions in ah
;Input:  dl = Drive number, 
;        dh = Head number,
;        rbx = Address of buffer, 
;        al = number of sectors, 
;        ch = Cylinder number (low 8 bits), 
;        cl[7:6] = Cylinder number (upper 2 bits), 
;        cl[5:0] = Sector number
;Input LBA: dl = Drive Number, rbx = Address of Buffer, 
;           al = number of sectors, rcx = LBA number
;
;All registers not mentioned above, preserved.
;Still use msdStatus as the error byte dumping ground. For now, 
; do not use the ata specific status bytes. 
; Fixed disk BIOS does NOT return how many sectors were 
; successfully transferred!
;----------------------------------------------------------------
fdisk_io:
    push rbp
    push rax
    push rbx
    push rcx
    push rdx
;Cherry pick status to avoid resetting status
    cmp ah, 01h
    je .fdiskStatus

    mov byte [msdStatus], 0 ;Reset the status
    call ATA.getTablePointer    ;Get table pointer in rbp for all functions
    jc .badFunctionRequest  ;If the device doenst exist, bad bad bad!

    test ah, ah
    jz .fdiskReset
    cmp ah, 02h
    je .fdiskReadCHS
    cmp ah, 03h
    je .fdiskWriteCHS
    cmp ah, 04h
    je .fdiskVerifyCHS
    cmp ah, 05h
    je .fdiskFormat
    cmp ah, 08h
    je .fdiskParametersCHS
    cmp ah, 82h
    je .fdiskReadLBA
    cmp ah, 83h
    je .fdiskWriteLBA
    cmp ah, 84h
    je .fdiskVerifyLBA
    cmp ah, 85h
    je .fdiskFormatSector
    cmp ah, 88h 
    je .fdiskParametersLBA

.badFunctionRequest:
    mov ah, 01h
    mov byte [msdStatus], ah   ;Invalid function requested signature
.badExit:
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop rbp
    mov ah, byte [msdStatus]
    or byte [rsp + 2*8h], 1    ;Set Carry flag
    iretq 
.okExit:
    pop rdx
    pop rcx
    pop rbx
.paramExit:
    pop rax
    pop rbp
    mov ah, byte [msdStatus]
    and byte [rsp + 2*8h], 0FEh ;Clear Carry flag    
    iretq
;Misc functions
.fdiskReset:
    call ATA.resetChannel
    mov eax, 0  ;No issue
    mov ebx, 5  ;Reset failed
    cmovc eax, ebx  ;Only move if carry set
    mov byte [msdStatus], al    ;Save status byte
    jc .badExit ;Carry is still preserved
    jmp short .okExit

.fdiskStatus:
    mov ah, byte [msdStatus]    ;Save old status
    mov byte [msdStatus], 0     ;Clear the status
    test ah, ah
    jnz .badExit    ;Set carry flag if status is non-zero
    jmp short .okExit
;CHS functions
.fdiskReadCHS:
    push rdi
    call ATA.readCHS
    pop rdi
    jc .fdiskError
    jmp .okExit
    
.fdiskWriteCHS:
    push rsi
    call ATA.writeCHS
    pop rsi
    jc .fdiskError
    jmp .okExit

.fdiskVerifyCHS:
    call ATA.verifyCHS
    jc .fdiskError
    jmp .okExit

;Format a whole "track" (for now just overwrite)
.fdiskFormat:
    call ATA.formatCHS
    jc .fdiskError
    jmp .okExit

.fdiskParametersCHS:
;Reads CHS drive parameters for given drive 
;Output: dl = Number of fixed disks in system
;        dh = Max head number for chosen drive
;        ch = Cylinder number
;        cl[7:6] = High two bits of Cylinder number
;        cl[5:0] = Sectors per track
;        ebx = Dword, sector size
;        ah = 0
    pop rdx
    pop rcx
    pop rbx
    movzx eax, word [rbp + fdiskEntry.wHeads]
    mov dh, al
    movzx eax, word [rbp + fdiskEntry.wCylinder]
    mov ch, al  ;Low 8 bits 
    shr ax, 2   ;Move bits [1:0] of ah to bits [7:6] of al
    and al, 0C0h    ;Clear lower bits [5:0]
    mov cl, al
    movzx eax, word [rbp + fdiskEntry.wSecTrc]
    and al, 3Fh ;Save only bits [5:0]
    or cl, al   ;Add the sector per track bits here
    mov dl, byte [fdiskNum] ;Get number of fixed disks in dl
    xor ebx, ebx
    mov ebx, 200h       ;Currently, hardcode sector size of 512 bytes
    jmp .paramExit

;LBA functions
.fdiskReadLBA:
    push rdi
    push rsi
    lea rsi, ATA.readLBA
    lea rdi, ATA.readLBA48
    test byte [rbp + fdiskEntry.signature], fdeLBA48
    cmovz rdi, rsi  ;If LBA48 not supported, call LBA instead
    call rdi    ;rdi is a free parameter anyway
    pop rsi
    pop rdi
    jc .fdiskError
    jmp .okExit

.fdiskWriteLBA:
    push rdi
    push rsi
    lea rsi, ATA.writeLBA
    lea rdi, ATA.writeLBA48
    test byte [rbp + fdiskEntry.signature], fdeLBA48
    cmovz rdi, rsi  ;If LBA48 not supported, call LBA instead
    call rdi    ;rdi is a free parameter anyway
    pop rsi
    pop rdi
    jc .fdiskError
    jmp .okExit

.fdiskVerifyLBA:
    push rdi
    push rsi
    lea rsi, ATA.verifyLBA
    lea rdi, ATA.verifyLBA48
    test byte [rbp + fdiskEntry.signature], fdeLBA48
    cmovz rdi, rsi  ;If LBA48 not supported, call LBA instead
    call rdi    ;rdi is a free parameter anyway
    pop rsi
    pop rdi
    jc .fdiskError
    jmp .okExit

.fdiskFormatSector:
;Format a series of sectors (for now just overwrite with fillbyte)
    push rdi
    push rsi
    lea rsi, ATA.formatLBA
    lea rdi, ATA.formatLBA48
    test byte [rbp + fdiskEntry.signature], fdeLBA48
    cmovz rdi, rsi  ;If LBA48 not supported, call LBA instead
    call rdi    ;rdi is a free parameter anyway
    pop rsi
    pop rdi
    jc .fdiskError
    jmp .okExit
.fdiskParametersLBA:
;Output: 
;        ebx = Dword, sector size
;        rcx = qLastLBANum (Qword address of last LBA)
;        dl = Number of fixed disks in system
;        Fixed disks have a fixed sector size of 512 bytes
;Recall last LBA value is the first NON-user usable LBA
;Will return LBA48 if the device uses LBA48 in rcx
    pop rdx
    pop rcx
    pop rbx
    xor ecx, ecx    ;Zero whole of rcx
    mov ecx, dword [rbp + fdiskEntry.lbaMax]
    mov rax, qword [rbp + fdiskEntry.lbaMax48]
    test byte [rbp + fdiskEntry.signature], fdeLBA48
    cmovnz rcx, rax ;Move lba48 value into rcx if LBA48 bit set
    mov dl, byte [fdiskNum] ;Number of fixed disks
    xor ebx, ebx
    mov ebx, 200h       ;Currently, hardcode sector size of 512 bytes
    jmp .paramExit
.fdiskError:
;A common error handler that checks the status and error register 
; to see what the error may have been. If nothing, then the error
; that is in the msdStatus byte is left as is, unless it is 0
; where a Undefined Error is placed.
    movzx edx, word [rbp + fdiskEntry.ioBase]
    add edx, 7  ;Goto status
    call ATA.wait400ns
    in al, dx   ;Get status byte
    test al, 80h    ;If busy is STILL set, controller failure
    jnz .fdiskCtrlrFailed
    test al, 20h    ;Test drive fault error
    jnz .fdiskErrorDriveFault
    test al, 1  ;Test the error bit is set
    jz .fdiskErrorNoBit ;If not set then check if we have an error code 
    sub edx, 6  ;Goto base + 1, Error register
    in al, dx   ;Get Error register
    test al, al 
    jz .fdiskNoErrorData
    mov ah, al
    and ah, 84h ;Save abort and interface crc
    cmp ah, 84h
    je .fdiskCRCError
    test al, 40h    ;Test the uncorrectable Error bit
    jnz .fdiskCRCError
    mov ah, al
    and ah, 14h ;If either bit is set, then it is a bad sector number
    jnz .fdiskBadAddress
.fdiskErrorUnknown: ;Fallthrough here
    mov byte [msdStatus], 0BBh  ;Unknown Error code
    jmp .badExit
.fdiskBadAddress:
    mov byte [msdStatus], 04h   ;Sector not found
    jmp .badExit
.fdiskCRCError:
    mov byte [msdStatus], 10h   ;Uncorrectable CRC error
    jmp .badExit
.fdiskNoErrorData:
    mov byte [msdStatus], 0E0h  ;Status error = 0
    jmp .badExit
.fdiskErrorNoBit:
    mov ah, byte [msdStatus]
    test ah, ah
    jnz .badExit    ;If there is a code, leave it in situ and exit service

.fdiskErrorDriveFault:
    mov byte [msdStatus], 07h  ;Drive parameter activity failed
    jmp .badExit
.fdiskCtrlrFailed:
    mov byte [msdStatus], 020h  ;Controller failure code
    jmp .badExit
;------------------------End of Interrupt------------------------