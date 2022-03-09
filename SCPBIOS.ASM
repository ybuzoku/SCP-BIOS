[map all scpio64.map]
;-----------------------------------SCPIO.SYS-----------------------------------
;------------------------------------Equates------------------------------------
permissionflags equ 003h    ;Page table Permission flags
codedescriptor     equ 0008h

BIOSStartAddr   equ 00110000h   ;Start just after HMA + 16 bytes
BIOSInitAddr    equ 800h

e820Seg         equ 1000h
e820SizeOff     equ 0000h    ;First word is # of entries
e820BaseOff     equ e820SizeOff + 2
e820SizeAddr    equ (e820Seg<<4) + e820SizeOff
;---------------------PIC Chip IO values---------------------
pic1command     equ 020h        ;Command port
pic2command     equ 0A0h        ;Command port
pic1data        equ 021h        ;Data port
pic2data        equ 0A1h        ;Data port
;------------------------------------------------------------
;-----------------PS/2 IO port commands----------------------
ps2command      equ 64h            ;Command Port (write)
ps2status       equ 64h            ;Status Port  (read)
ps2data         equ 60h           ;Data Port     (read/write)
;------------------------------------------------------------
;--------------------Serial port equates---------------------
com1_base       equ 03F8h
com2_base       equ 02F8h
com3_base       equ 03E8h
com4_base       equ 02E8h
;------------------------------------------------------------
;---------------------PIT port equates-----------------------
PITbase         equ 40h
PIT0            equ PITbase
PIT1            equ PITbase + 1
PIT2            equ PITbase + 2
PITcommand      equ PITbase + 3
;------------------------------------------------------------
;---------------------CMOS port equates----------------------
cmos_base        equ 70h
cmos_data        equ 71h
;------------------------------------------------------------
;--------------------Keyboard equates------------------------
kb_flag_rshift   equ    01h    ;Right Shift is being held
kb_flag_lshift   equ    02h    ;Left Shift is being held
kb_flag_ctrl     equ    04h    ;Ctrl is being held
kb_flag_alt      equ    08h    ;Alt is being held
kb_flag_scrlset  equ    10h    ;Scroll lock is set
kb_flag_numset   equ    20h    ;Num lock is set
kb_flag_capsset  equ    40h    ;Caps lock is set
kb_flag_insset   equ    80h    ;Insert mode is set

kb_flag2_e1      equ    01h    ;0E1h scancode procedure being processed
kb_flag2_e0      equ    02h    ;0E0h scancode procedure being processed
;------------------------------------------------------------
;--------------------Screen equates--------------------------
vga_index        equ    03D4h
vga_data         equ    03D5h
;---------------- New Equates ----------------
vga_aindex       equ    03B4h    ;Alt (MDA) IO Base
vga_adata        equ    03B5h
;These equates are SEGMENTS, need to be SHL 4 to become addrs
vga_bpage0       equ    0A0000h
vga_bpage1       equ    0B0000h
vga_bpage2       equ    0B8000h
;------------------------------------------------------------
;----------------------PCI equates---------------------------
pci_index        equ    0CF8h
pci_data         equ    0CFCh
;------------------------------------------------------------
;----------------------USB equates---------------------------
usb_class        equ    0Ch    ;pci class
usb_subclass     equ    03h    ;pci subclase
uhci_interface   equ    00h    ;usb 1.0
uhcimask         equ    10h
ohci_interface   equ    10h    ;usb 1.0 alt
ohcimask         equ    20h
ehci_interface   equ    20h    ;usb 2.0
ehcimask         equ    40h
xhci_interface   equ    30h    ;usb 3.0
xhcimask         equ    80h
lousbtablesize   equ    0000E000h    ;Location of the table size, uword
lousbtablebase   equ    lousbtablesize + 2 ;base of the table, tword entries
debounceperiod   equ 200 ;double 200ms as per Windows, for inaccuracies
;                ------EHCI equates------
ehcicaplength    equ    00h    ;Add this to base addr in table to find opparams
ehciversion      equ    02h    ;Interface Version number
ehcistrucparams  equ    04h    ;Structural Parameters
ehcihccparams    equ    08h    ;Capability Parameters
ehciportroute    equ    0Ch    ;Companion Port Route Description (v1 ignore)

;Operational registers below

ehcicmd          equ    00h    ;USB command register
ehcists          equ    04h    ;USB status register
ehciintr         equ    08h    ;USB Interrupt Enable
ehcifrindex      equ    0Ch    ;USB Frame Index
ehcictrlseg      equ    10h    ;4Gb Segment Selector
ehciperiodbase   equ    14h    ;Frame List Base Address
ehciasyncaddr    equ    18h    ;Next Asynchronus List Address
ehciconfigflag   equ    40h    ;Configured Flag Register
ehciportsc       equ    44h    ;Read = 1 - # of ports, Write = port ctrl
;                ------------------------
;                -------MSD equates------
setupReset       equ 0FFh
setupGetMaxLUN   equ 0FEh
;                ------------------------
;                ------Bulk Storage equates------
CBWSig           equ    043425355h
CSWSig           equ 053425355h
CBWFlagOut       equ    00h    ;Switch to send to device
CBWFlagIn        equ    80h    ;Switch to recieve from
bCSWPassed       equ    00h
bCSWFailed       equ    01h
bCSWPhase        equ    02h
;                ------------------------
;------------------USB Device table entry sizes------------------
msdDevTblEntrySize    equ 10h
hubDevTblEntrySize    equ 8h
usbDevTblEntrySize    equ 3h
usbMaxDevices         equ 10
;                ------------------------
;------------------EHCI Transfer Descriptor size------------------
ehciSizeOfQH    equ 60h
ehciSizeOfTD    equ 40h
;------------------------------------------------------------
;----------------------ATA equates---------------------------
ata0_base       equ    1F0h
ata0_ctrl       equ    3F6h
ata1_base       equ    170h
ata1_ctrl       equ    376h

msd_class       equ    01h
ide_subclass    equ    01h
sata_subclass   equ    06h
;------------------------------------------------------------
;----------------------IDE equates---------------------------
ideTableEntrySize     equ 10h
;----------------------FDD equates---------------------------
fdd_base        equ    3F0h
;----------------------Int 33h Equates-----------------------
fdiskTableEntrySize   equ 10h
int33TblEntrySize     equ 10h
;------------------------------------------------------------
;------------------------------------------------------------
;------------------------Misc--------------------------------
port61h         equ 61h         ;I/O port 61h
EOI             equ 20h         ;End of interrupt signal
waitp           equ 80h         ;debug port used to wait for io cycles
bochsout        equ 0E9h        ;Emulator debug port
BREAKPOINT      equ 0CCh        ;Use to manually encode breakpoints in program
sizeOfMCPAlloc  equ 800h        ;2Kb allocated space
;------------------------------------------------------------
;----------------------------------------------------------------
;                 BIOS SYSTEM TABLE AREA                        :
;----------------------------------------------------------------
Segment BIOSTables nobits start=BIOSStartAddr align=1
BIOSIDTable     resq 2*256  ;256 paragraph entries reserved for IDT
BIOSPageTbl     resq 0C00h  ;6000 bytes for page tables
BIOSGDTable     resq 3      ;3 entries in basic GDT
                resq 1      ;Alignment qword
;----------------------------------------------------------------
;                    BIOS DATA AREA STARTS HERE                 :
;----------------------------------------------------------------
Segment data nobits follows=BIOSTables align=1 
;Refer to MEMMAP.TXT for memory address reference!
;If Interrupt call is faulty, Carry will be set AND either:
;                    ah=80h => Invalid function.
;                    ah=86h => Not (yet) supported.
;------------------------------Data Area-------------------------
IDTlength       resw 1 ;Maximum number of Interrupts is 256
IDTpointer:
.Limit          resw 1
.Base           resq 1

GDTlength       resw 1
GDTpointer:
.Limit          resw 1
.Base           resq 1

pageTablePtr:   resq 1
;----------------------------------------
;       Spurious Interrupt counter      :
;----------------------------------------
spurint1        resb 1    ;Keep track of how many spur ints on pic1
spurint2        resb 1    ;pic 2
;----------------------------------------
;            Keyboard Data Area         :
;----------------------------------------
kb_buffer       resw 10h
kb_buf_head     resq 1    ;Pointer to Keyboard buffer head
kb_buf_tail     resq 1    ;Pointer to Keyboard buffer tail 
kb_buf_start    resq 1    ;Pointer for circular buffer start
kb_buf_end      resq 1    ;Ditto..., for end
kb_flags        resb 1    ;Keyboard state flags
kb_flags_1      resb 1    ;Extended flags, empty for now
kb_flags_2      resb 1    ;Bit 0 = E1 present, Bit 1 = E0 present
break_flag      resb 1    ;Well, its not for the Print Screen key
;----------------------------------------
;            Serial Data Area           :
;----------------------------------------
numCOM          resb 1  ;Number of Serial Ports
com_addresses   resw 4     ;Space for 4 IO addresses

comX_buffer:
com1_buffer     resb 10h 
com2_buffer     resb 10h
com3_buffer     resb 10h
com4_buffer     resb 10h

comX_buf_head:
com1_buf_head   resq 1
com2_buf_head   resq 1
com3_buf_head   resq 1
com4_buf_head   resq 1

comX_buf_tail:
com1_buf_tail   resq 1
com2_buf_tail   resq 1
com3_buf_tail   resq 1
com4_buf_tail   resq 1

comX_buf_start:
com1_buf_start  resq 1
com2_buf_start  resq 1
com3_buf_start  resq 1
com4_buf_start  resq 1

comX_buf_end:
com1_buf_end    resq 1
com2_buf_end    resq 1
com3_buf_end    resq 1
com4_buf_end    resq 1

;----------------------------------------
;            Printer Data Area          :
;----------------------------------------
prt_addresses   resw 3    ;Space for 3 IO addresses
;----------------------------------------
;            Timer Data Area            :
;----------------------------------------
pit_divisor     resw 1
pit_ticks       resd 1    ;Similar to IBM PC, only with default divisor
;[31]=OF cnt, [30:21]=Res [20:16]=Hi cnt, [15,0]=Lo cnt
rtc_ticks       resq 1
;----------------------------------------
;            Screen Data Area           :
;----------------------------------------
scr_curs_pos    resw 8    ;Cursor pos, hi byte = row / lo byte = column
scr_cols        resb 1    ;80 Cols
scr_rows        resb 1    ;25 Rows
scr_curs_shape  resw 1    ;Packed start/end scan line
scr_char_attr   resb 1    ;Grey text on black background
scr_mode        resb 1    ;80x25, 16 colours default
scr_active_page resb 1    ;Mode dependent
scr_crtc_base   resw 1    ;03D4h for Graphics, 03B4h for MDA
scr_page_addr   resd 1    ;CRTC Register 12 changes base address accessed
scr_mode_params resq 1    ;Stub pointer location for future mode parameters
scr_vga_ptrs    resq 8  ;VGA pointers
;----------------------------------------
;       Mass storage Data Area          :
;----------------------------------------
i33Devices      resb 1  ;Number of devices Int 33h is aware of
msdStatus       resb 1  ;Status byte. Used by BIOS for all transfers with MSD.
fdiskNum        resb 1  ;Number of fixed disks
ir14_mutex      resb 1
ir14_status     resb 1
ir15_mutex      resb 1
ir15_status     resb 1
diskDptPtr      resq 1
fdiskDptPtr     resq 1
;----------------------------------------
;            SysInit Data Area          :
;----------------------------------------
nextFilePtr     resq 1  ;Pointer to next file to load
numSectors      resw 1  ;Number of sectors to copy 
;----------------------------------------
;            Memory Data Area           :
;----------------------------------------
MachineWord     resw 1    ;Really Legacy Hardware Bitfield
convRAM         resw 1  ;Conventional memory word
userBase        resq 1    ;Start address of the user space
bigmapSize      resb 1    ;First byte, in units of 24 bytes
srData          resw 4  ;4 words for memory64MB word 0 is ax word 1 is bx etc.
srData1         resw 1  ;Reserve 1 word for memory16MB
sysMem          resq 1  ;Size of usable system RAM (without SCP/BIOS)
scpSize         resd 1  ;Size of SCP/BIOS allocation
;----------------------------------------
;            MCP Data Area              :
;----------------------------------------
mcpUserBase     resq 1  ;Pointer to register save space
mcpUserRip      resq 1  ;Save the custom user RIP for new jumps
mcpUserkeybf    resq 1  ;Pointer to the keyboard buffer
mcpUserRaxStore resq 1  ;Temp rax save space
mcpStackPtr     resq 1  ;Address of base of user Stack Pointer
;----------------------------------------
;            USB Data Area              :
;----------------------------------------
eControllers    resb 1    ;Number of EHCI controllers
eControllerList resq 4    ;Entry = PCI space addr|MMIO addrs
usbDevices      resb 1    ;Max value, 10 for now!
eHCErrorHandler resq 1  ;Address of default error handler
;----------------------------------------
;            EHCI Async Area            :
;----------------------------------------
eCurrAsyncHead  resq 1      ;Point to the current head of the async list
eNewBus         resb 1      ;Default to 0, if 1, a new bus was selected
eActiveCtrlr    resb 1        ;Current working controller (default -1)
eActiveInt      resb 1        ;Gives a copy of the usbsts intr bits
eAsyncMutex     resb 1    
    ;Mutex, x1b=data NOT ready, wait. x0b=ready, data ready to access.
    ;        1xb=Internal buffer. 0xb=user provided buffer.
    ;        bits [7:2], number of interrupts to ignore (if any)
    ;            a value of 0 means dont ignore
;----------------------------------------
;            MSD Data Area              :
;----------------------------------------
cbwTag          resb 1        ;cbw transaction unique id (inc post use)
numMSD          resb 1        ;Number of MSD devices
;----------------------------------------
;           USB Tables                  :
;----------------------------------------
usbDevTbl       resb 10*usbDevTblEntrySize
usbDevTblEnd    equ $
usbDevTblE      equ ($ - usbDevTbl)/usbDevTblEntrySize ;Number of Entries
;Byte 0 = Dev Addr, Byte 1 = Root hub, Byte 2 = Class Code (USB standard)
; i.e. 08h=MSD, 09h=Hub
hubDevTbl       resb 10*hubDevTblEntrySize
hubDevTblEnd    equ $
hubDevTblE      equ ($ - hubDevTbl)/hubDevTblEntrySize
;bAddress - The assigned device address
;bBus - Host Bus [Root hub]
;bHostHub - Address of Hub we are attached to or 0 for Root
;bHubPort - Port number we are inserted in
;bMaxPacketSize0 - Max packet size to endpoint 0
;bNumPorts - Number of downstream ports on hub
;bPowerOn2PowerGood - Time in units of 2ms for device on port to turn on
;bRes- Endpoint address, for when we add interrupt eps
;   If bNumPorts=0 => Hub needs to undergo Hub Config
msdDevTbl       resb 10*msdDevTblEntrySize
msdDevTblEnd    equ $
msdDevTblE      equ    ($ - msdDevTbl)/msdDevTblEntrySize
;bAddress - The assigned device address [+ 0]
;bBus - Host Bus [Root hub] [+ 1]
;bHostHub - Address of Hub we are attached to or 0 for Root [+ 2]
;bHubPort - Port number we are inserted in  [+ 3]
;bInerfaceNumber - Interface number being used  [+ 4]
;bInterfaceSubclass - 00h (defacto SCSI), 06h (SCSI), 04h (UFI)     [+ 5]
;bInterfaceProtocol - 50h (BBB), 00h (CBI), 01h (CBI w/o interrupt) [+ 6]
;bMaxPacketSize0 - Max packet size to endpoint 0                    [+ 7]
;bEndpointInAddress - 4 bit address of IN EP                        [+ 8]
;wMaxPacketSizeIn - Max packet size to chosen In endpoint           [+ 9]
;bEndpointOutAddress - 4 bit address of OUT EP                      [+ 11]
;wMaxPacketSizeOut - Max packet size to OUT endpoint                [+ 12]
;bInEPdt - In Endpoints' dt bit                                     [+ 14]
;bOutEPdt - Out Endpoints' dt bit                                   [+ 15]
;These past two bytes are temporarily kept separate! Will bitstuff later
;----------------------------------------
;           IDE Tables                  :
;----------------------------------------
;Support up to two IDE controllers
ideNumberOfControllers: resb 1
ideControllerTable:     resb  2*ideTableEntrySize ;Max 2 controllers
;dPCIAddress   - PCI IO address of controller   [+0]
;dPCIBAR4 - PCI BAR4, the Bus Mastery address [+4]
; Note that this address is given with the bottom nybble indicating
; if the address is IO or MMIO. Bit set => IO
;----------------------------------------
;           ATA Tables                  :
;----------------------------------------
fdiskTable:     resb 4*fdiskTableEntrySize  ;Max 4 fixed disks
; - BIOS address of device
;----------------------------------------
;            Int33h Table Area          :
;----------------------------------------
diskDevices:    resb 10*int33TblEntrySize
diskDevicesE    equ ($ - diskDevices)/int33TblEntrySize
;bDevType - 0 = Unasigned, 1 = MSD EHCI, 2 = MSD xHCI, 3 = Floppy Physical,
;           4 = ATA device, 5 = ATAPI device   [+ 0]
;wDeviceAddress - USB Address/Bus pair OR local device table address  [+ 1]
;dBlockSize - Dword size of LBA block (should be 512 for remdev) [+ 3]
;qLastLBANum - Last LBA address (OS MAY minus 1 to avoid crashing device) [+ 7]
;bEPSize - 1 = 64 byte, 2 = 512 byte (EP size for sector transfer)  [+ 15]
;NOTE: LBA SECTOR 0 IS CHS SECTOR 0,0,1 !!
;----------------------------------------------------------------
;----------------------------------------------------------------
;                   MCP Transaction area                        :
;----------------------------------------------------------------
Segment MCPseg nobits follows=codeResident align=1
                resb sizeOfMCPAlloc   ;2KB space
MCPsegEnd:  ;Pointer to the end of the segment
;----------------------------------------------------------------
;                  BIOS Transaction area                        :
;                                                               :
;                   Must be the last segment                    :
;----------------------------------------------------------------
Segment xdata nobits follows=MCPseg align=40h    ;eXtra data seg
;This segment comes after the resident code and is the transaction
;area. The ehci async schedule (and eventually periodic) live here.
;They are BOTH always postfixed by the big memory map.
ehciAschedule:                  ;Static label for head of the asyncschedule
ehciQHead0      resb ehciSizeOfQH ;96 bytes, for address 0 device only
    alignb 40h
ehciQHead1      resb ehciSizeOfQH ;Used for cmds with an addressed usb device
    alignb 40h
ehciTDSpace     resb 10*ehciSizeOfTD   ;640 bytes of transfer space
    alignb 40h
ehciDataOut     resb 20h               ;32 bytes
    alignb 40h
sectorbuffer:                       ;Same buffer for multiple purposes
ehciDataIn      resb 200h           ;512 bytes, to get as much data as needed
    alignb 40h
msdCSW          resb 10h                
;13 bytes, special, to be saved after each transfer
    alignb 20h      
prdt:           resq 2      ;2 entries in the prdt
bigmapptr:                        ;Pointer to big mem map
;----------------------------------------------------------------
;                      SysInit Table                            :
;----------------------------------------------------------------
Segment SysInitParams   nobits start=600h
;Use the bootsector reload space (600h-800h) as a temporary stack
; and a storage space for the SysInit table
SysInitTable:
.numSecW        resw 1
.FileLBA        resq 1
loMachineWord   resw 1
;----------------------------------------------------------------
;                      Real Mode Stack                          :
;----------------------------------------------------------------
Segment lowStack    nobits  start=700h
                resb 100h
lowStackPtr:
;----------------------------------------------------------------
ORG 800h
;----------------------------------------------------------------
;                    INIT CODE STARTS HERE                      :
;----------------------------------------------------------------
Segment codeInit start=BIOSInitAddr align=1
BITS 16
;First set stack and save the SysInit Ptr, then set A20, check CPUID and 
; exended features. Then tell BIOS that we are going long and perhaps 
; protected then get the Int 11h word, store at 0:800h
realInit:
;The Caller Far Jumps to set cs to 0
    cli     ;Stop interrupts as we dont know where the stack is
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, lowStackPtr ;Set up stack pointer
    sti
    cmp byte [es:bx], 0Ch   ;Check length
    jne .fail   ;If thats not it, error 0
    mov ax, word [es:bx + 1]    ;Get number of sectors into ax 
    mov cx, 42  ;42 sectors maximum
    cmp ax, cx
    cmovnb ax, cx
    mov word [SysInitTable.numSecW], ax
    mov eax, dword [es:bx + 4]      ;Get low dword
    mov dword [SysInitTable.FileLBA], eax
    mov eax, dword [es:bx + 8]      ;Get high dword
    mov dword [SysInitTable.FileLBA + 4], eax
    push es
.a20Proc:
    push ax
    push cx ;preserve ax and cx
    xor cx, cx ;clear to use as a timeout counter
    
.a20FastEnable:
    in al, 92h
    test al, 2
    jnz .no92
    or al, 2
    and al, 0FEh
    out 92h, al
    
    inc cl    ;increments the time out counter
    jmp .a20Check
    
.no92:
    mov cl, 4
    jmp .a20Fail
    
.a20KeybEnable: ;communicating with the keyboard controller
    cli
 
    call .a20wait
    mov al,0ADh
    out 64h,al ;disable the keyboard
    call .a20wait
    mov al,0D0h
    out 64h,al ;read from the keyboard input
    call .a20wait2
    in al,60h
    push eax    ;get the keyboard data and push it to the stack
    call .a20wait
    mov al,0D1h
    out 64h,al    ;output the command to prep to go a20 
    call .a20wait
    pop eax    ;need this be eax and not just ax?
    or  al,2
    out 60h,al    ;output to go a20
    call .a20wait
    mov al,0AEh
    out 64h,al    ;reenable keyboard
    call .a20wait    ;done!
    sti

    inc cl    ;increments the time out counter
    jmp .a20Check
    
.a20wait:
    in al,64h
    test al,2
    jnz .a20wait
    ret
 
.a20wait2: 
    in al,64h
    test al,1
    jz .a20wait2
    ret

.a20Check:
    mov ax, 0FFFFh
    push ax
    pop es ;es to FFFF
    mov di, 0010h ;FFFF:0010 == 0000:0000
    xor si, si    ;remember ds = 0000
    mov al, byte [es:di]
    cmp byte [ds:si], al
    je .a20Fail
    inc al    ;make change to al
    mov byte [ds:si], al ;al is now incremented and saved at address 0000:0000
    cmp byte [es:di], al ;check against overflown version
    je .a20Fail
    
.a20Pass:
    dec al    ;return al to its original value
    mov byte [ds:si], al ;return to original position
    
    pop cx
    pop ax
    pop es
    jmp short .a20Exit
    
.a20Fail:
    cmp cl, 3
    jle .a20FastEnable
    cmp cl, 6
    jle .a20KeybEnable
    
    pop cx
    pop ax
    pop es
    jmp short .noa20

.a20Exit:
    pushfd
    pop eax
    mov ecx, eax ;save original flag state for later
    xor eax, 00200000h ;21st bit - CPUID bit, switch it!!
    push eax
    popfd
    
    pushfd
    pop eax
    test eax, ecx ; compare the registers. If they are the same
    je .noCPUID
    push ecx
    popfd

.extCheck:
    mov eax, 80000000h
    cpuid
    cmp eax, 80000001h ;If this is true, CPU supports extended functionality
    jae tellBIOS
.noa20:
    mov ah, 1    ;noa20 error code
.noCPUID:
    mov ah, 2    ;noCPUID error code
    jmp short .fail
    mov ah, 3    ;no Extended functionality error code
.fail:
    mov dl, ah    ;store ax to get error code printed
    mov si, .msg
    call .write
    mov al, dl
    mov bx, 0007h    ;Attribs
    mov ah, 0Eh        ;TTY print char
    add al, 30h        ;add '0' to digit
    int 10h
    xor ax, ax
    int 16h    ;await keystroke
    int 18h
;Error codes: 
;   00h - Bad SysInit Data
;   01h - No A20 Line
;   02h - No CPUID 
;   03h - No Extended Functionality
.write: ;destroys registers ax and bx
    lodsb
    cmp al, 0 ;check for zero
    je .return
    mov ah, 0Eh    ;TTY output
    mov bx, 0007h ;colour
    int 10h
    jmp short .write
.return:
    ret
.msg: db 'Boot error:',0
tellBIOS:
    mov eax, 0EC00h ;Tell BIOS we are going long
    mov bl, 03h     ;Both Long and Protected modes
    int 15h         ;Ignore response
    int 11h
    mov word [loMachineWord], ax
;Getting Memory Map
rmE820Map:
    push es
    push ds
    mov ax, e820Seg
    mov ds, ax
    mov es, ax
    mov di,    e820BaseOff
    xor ebx, ebx
    xor bp,bp
    mov edx, 0534D4150h    ;Magic dword
    mov eax, 0E820h
    mov dword [es:di + 20], 1
    mov ecx, 24            ;Get 24 bytes
    int 15h
    jc .mapfail            ;Carry set => Fail
    mov edx, 0534D4150h    ;Magic dword
    cmp eax, edx        ;Must be equal on success
    jne .mapfail
    test ebx, ebx         ;One table entry, bad
    jz .mapfail
    jmp short .map1
.map0:
    mov eax, 0E820h
    mov dword  [es:di + 20], 1
    mov ecx, 24
    int 15h
    jc .mapexit
    mov edx, 0534D4150h
.map1:
    jcxz .map3
    cmp cl, 20
    jbe .map2
    test byte [es:di + 20], 1
    je .map3
.map2:
    mov ecx, dword [es:di + 8]
    or ecx, [es:di + 12]
    jz .map3
    inc bp
    add di, 24
.map3:
    test ebx, ebx
    jne .map0
    jmp short .mapexit
.mapfail:
.mapexit:
    mov word [es:e820SizeOff], bp  ;Num entries in var space (3 qwords/entry)
;Second memory test
    xor cx, cx
    xor dx, dx
    mov ax, 0E801h
    int 15h
    jc .badmem2
    cmp ah, 86h    ;unsupported command
    je .badmem2
    cmp ax, 80h    ;invalid command
    je .badmem2
.mem2write:
    stosw
    mov ax, bx
    stosw
    mov ax, cx
    stosw
    mov ax, dx
    stosw
    jmp short .mem3test
.badmem2:
    xor ax, ax
    xor bx, bx
    xor cx, cx
    xor dx, dx
    jmp .mem2write
.mem3test:
    clc
    mov ah, 88h
    int 15h
    xor bx, bx 
    cmovc ax, bx    ;if error, store zero
    cmp ax, 86h
    cmovz ax, bx
    cmp ax, 80h
    cmovz ax, bx
    stosw
.finalmemtest:
    clc
    int 12h
    cmovc ax, bx    ;If carry on, store a zero
    stosw    ;Store the word
rmGetFontPointers:
;Get ROM Font Pointers, immediately after Memory map
;Each entry is 8 bytes long: es=Seg, bp=Off, cx=bytes/char, dx=# of rows - 1
    xor bx, bx         ;Clear bh
.gfp1:    
;Over protective routine in the event that the BIOS routine clobbers registers
    mov si, 1000h    ;Save segment loader
    xor cx, cx
    xor dx, dx
    xor bp, bp
    push bx            ;Save bx

    mov ax, 1130h    ;Get font pointer function
    int 10h

    mov ax, es        ;Get segment into ax to store
    mov es, si        ;Reload segment for stos to work
    stosw
    mov ax, bp        ;Get offset
    stosw
    mov ax, cx        ;bytes/char
    stosw
    mov al, dl        ;dl contains # of rows, but zero extended for alignment
    xor ah, ah
    stosw
    pop bx            ;Get the count back
    inc bh
    cmp bh, 7
    jbe .gfp1        ;Once above 7, fall through

    pop ds
    pop es    ;Bring back original es value
rmSetTables:
;Memory tables live in 0:8000h - 0:E000h range
    mov edi, 8000h
    mov cr3, edi    ;Cannot lsh cr3
    mov cx, 3000h    ;6000h bytes (6x4Kb) of zero to clear table area
    push di
    xor ax, ax
    rep stosw        ;Store 3000h words of zero

    pop di            ;Return zero to the head of the table, at 08000h
    mov ax, 9000h|permissionflags    ;9000h is the low word of the address.
    stosw    ;store the low word of the address
    add di, 0FFEh
    mov cx, 4
rmUtables:            ;di should point to 8000h
    add ax, 1000h
    stosw    ;ax is now A003h,B003h,C003h,D003h
    add di, 6    ;qword alignment
    dec cx
    jnz rmUtables

    mov cx, 800h    ;4x512 consecutive entries
    xor ax, ax
    push ax            ;push for algorithm to work
    mov di, 0A000h
rmPDTentries:
    mov ax, 83h        ;bit 7|permission flags
    stosw            ;di incremented twice
    pop ax            ;get current address
    stosw            ;di incremented twice. store the address
    add ax, 20h        ;add the offset to the next page
    push ax            ;push current address into memory
    add di, 4        ;qword Align
    dec cx
    jnz rmPDTentries

    mov eax, cr4                 
    or eax, 0A0h ;Set PAE and PGE, for glbl page and physical page extensions
    mov cr4, eax 
    
    mov ecx, 0C0000080h    ;Read EFER MSD into EDX:EAX
    rdmsr    ; Read information from the msr.
    or eax, 00000100h ; Set the Long mode bit!
    wrmsr  ; Write the data back
    
    cli
    mov al, 0FFh             ; Out 0xFF to 0xA1 and 0x21 to disable all IRQs.
    out 0A1h, al
    out 21h, al

    lgdt [GDT.Pointer] ;Load the Global Descriptor Table pointer

    mov eax, cr0
    or eax, 80000001h ;Set the Paging and Protected Mode bits (Bits 31 and 0)
    mov cr0, eax  ;write it back!
    jmp GDT.Code:longmode_ep

GDT:                    ;Global Descriptor Table (64-bit).
.Null: equ $ - GDT      ;The null descriptor.
    dq 0
.Code: equ $ - GDT      ;The 32-bit code descriptor. Limit = FFFFFh, Base=0
    dw 0FFFFh           ;Limit 0:15
    dw 00000h           ;Base 0:15
    db 00h              ;Base 16:23
    db 09Ah             ;Access Byte
    db 03Fh             ;Limit 16:19
    db 00b              ;Base 24:31

.Data: equ $ - GDT      ;The 32-bit data descriptor. 
    dw 0FFFFh           ;Limit 0:15
    dw 00000h           ;Base 0:15
    db 0h               ;Base 16:23
    db 092h             ;Access Byte
    db 01Fh             ;Limit 16:19 then Flags
    db 00h              ;Base 24:31
ALIGN 4
    dw 0
.Pointer    dw $ - GDT - 1      ; GDT pointer.
.Base       dq GDT                 ; GDT offset.
;----------------------------------------------------------------
BITS 64
;----------------------------------------------------------------
;                    Long Mode Initialisation                   :
;----------------------------------------------------------------
; Sets up Segment registers, copies the resident portion of SCPBIOS
; high, initialises the BDA, copies data from real mode BIOS to 
; SCPBIOS internal area, Identity maps the first 4 Gb, creates 
; an IVT and moves the GDT to its final resting place,
; and directs cr3, gdtr and idtr to the BDA vars and reinits the video
; to VGA Mode 3. Finish by printing boot message and memory sizes.
;----------------------------------------------------------------
longmode_ep:
    mov ax, 10h
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
;-----------------Write BDA constants-----------------
    mov rdi, section.data.start
    mov ax, 100h
    stosw            ;IDT Length
    mov ax, (100h*10h) - 1    ;IDT Limit
    stosw
    mov rax, BIOSIDTable    ;IDT Base
    stosq
    mov ax, 3h
    stosw
    mov ax, (3h*8h)-1
    stosw
    mov rax, BIOSGDTable
    stosq
    mov rax, BIOSPageTbl
    stosq
    xor eax, eax    ;Clears upper dword too
;Clear spur int counters
    stosw
;Keyboard area
    mov ecx, 4h
    rep stosq    ;Clear kb buffer for 16 words
    mov rax, kb_buffer
    mov cx, 3h    ;Circular pointers
    rep stosq
    add rax, 20h    ;End of buffer pointer
    stosq
    xor eax, eax
    stosd    ;Store keyboard flags bytes
;Serial Area
    stosb   ;Clear number of COM devices byte
    stosq    ;Clear com_addresses (4 words)
    mov cx, 8
    rep stosq    ;Store 8 qwords for COM buffers
;Buffer heads
    mov rax, com1_buffer
    stosq
    add rax, 10h    ;Com2
    stosq
    add rax, 10h    ;Com3
    stosq
    add rax, 10h    ;Com4
    stosq
;Buffer Tails
    sub rax, 30h
    stosq
    add rax, 10h    ;Com2
    stosq
    add rax, 10h    ;Com3
    stosq
    add rax, 10h    ;Com4
    stosq
;Buffer start
    sub rax, 30h
    stosq
    add rax, 10h    ;Com2
    stosq
    add rax, 10h    ;Com3
    stosq
    add rax, 10h    ;Com4
    stosq
;Buffer end
    sub rax, 20h
    stosq
    add rax, 10h    ;Com2
    stosq
    add rax, 10h    ;Com3
    stosq
    add rax, 10h    ;Com4
    stosq
;Printer area
    xor eax, eax
    mov cx, 3h
    rep stosw
;Timers area
    stosw   ;Default pit_divisor, 0 = 65536
    stosd    ;pit_ticks
    stosq    ;rtc_ticks
;Screen area
    mov cx, 2h
    rep stosq    ;rax, is 0
    mov ax, 50h
    stosb
    mov ax, 19h
    stosb
    xor ax, ax
    stosw
    mov ax, 07
    stosb
    mov ax, 03
    stosb
    xor ax, ax
    stosb
    mov ax, vga_index
    stosw
    mov eax, vga_bpage2
    stosd
    xor eax, eax    ;zero rax
;Store scr_mode_params and scr_vga_ptrs
    mov ecx, 9
    rep stosq
;HDD/FDD data area
    xor eax, eax
    stosw   ;Int 33h entries and msdStatus
    stosb   ;Fixed disk entries
    stosd   ;Hard drive status entries
    mov rax, diskdpt
    stosq   ;Store the address of the default remdev format table
    mov rax, fdiskdpt
    stosq
    xor eax, eax
;SysInit area
    mov rax, qword [SysInitTable.FileLBA]
    stosq   ;NextFileLBA
    movzx eax, word [SysInitTable.numSecW] 
    stosw   ;numSectors Word
    xor eax, eax
;Memory Data area
    stosd    ;0 MachineWord and convRAM 
    stosq   ;0 userBase
    stosb    ;0 bigmapSize
    stosq   ;0 srData, 4 words
    stosw   ;0 srData1, 1 word
    stosq   ;0 sysMem, 1 qword
    stosd   ;0 scpSize, 1 dword
;MCP data area
    mov qword [mcpUserBase], section.MCPseg.start
    mov qword [mcpUserRip], section.MCPseg.start + 180h
    mov qword [mcpUserkeybf], section.MCPseg.start + 100h
    mov qword [mcpStackPtr], MCPsegEnd
    mov qword [mcpUserRaxStore], 0
    add rdi, 5*8    ;Go forwards by 5 entries
;USB Area
    stosb
    mov cx, 4
    rep stosq    ;eControllerList
    stosb
    mov rax, USB.ehciCriticalErrorHandler ;Get the critical error handler ptr
    stosq       ;Install eHCErrorHandler
    xor eax, eax    ;Rezero rax
    dec ax
    stosq       ;eCurrAsyncHead
    stosb       ;eActiveAddr
    stosb        ;eActiveCtrlr
    inc ax
    stosd
;USB Tables
    mov cx, 10*usbDevTblEntrySize
    rep stosb
    mov cx, 10*hubDevTblEntrySize
    rep stosb
    mov cx, 10*msdDevTblEntrySize
    rep stosb
;IDE and Int 33h stuff
    stosb       ;ideNumberOfControllers
    mov cx, 2*ideTableEntrySize ;ideControllerTable
    rep stosb
    mov cx, 4*fdiskTableEntrySize
    rep stosb
    mov cx, 10*int33TblEntrySize
    rep stosb
;End of BDA variable init

;Copy the resident portion of SCPBIOS.SYS to its offset
Relocate:
    mov rsi, section.codeResident.start
    mov rdi, section.codeResident.vstart    ;address for the end of the section
    mov rcx, (residentLength/8) + 1
    rep movsq    ;Copy resident portion high

;Copy machine word into var from 600h
    mov ax, word [loMachineWord]
    mov word [MachineWord], ax

;Copy Memory Maps DIRECTLY after USB dynamic space.
    mov rdi, bigmapptr
.move820_0:    ;Add to the end
    mov rsi, e820SizeAddr
    lodsw    ;Get number of entries for big map
    movzx rax, al    ;zero extend
    lea rcx, qword [rax + 2*rax]    ;Save 3*#of entries for countdown loop
.mv0:
    rep movsq    ;Transfer 3*al qwords
    add al, 2    ;Two more entries for BIOS
    mov byte [bigmapSize], al    ;Save entries in al
;Compute the size of BIOS allocation + space for two more entries up to next KB
    add rdi, 3*8 ;rdi now points to start of last allocated entry (added)
    mov rbx, rdi 
    add rbx, 3*8h   ;Add size of last new entry
;Round to nearest KB
    and rbx, ~3FFh
    add rbx, 400h
    mov qword [userBase], rbx    ;Save userbase
    sub rbx, BIOSStartAddr 
    mov dword [scpSize], ebx    ;Save Size
;Calculate amount of system RAM available
.readSystemSize:
    mov rbx, bigmapptr
    mov rdx, 0000000100000001h      ;Valid entry signature
    movzx ecx, al       ;Get the number of 24 byte entries
    sub ecx, 2          ;Remove the allocated entries from the count
    xor eax, eax                    ;Zero rax, use to hold cumulative sum
.rss1:
    cmp qword [rbx + 2*8], rdx   ;Check valid entry
    jnz .rss2
    add rax, qword [rbx + 8]    ;Add size to rax
.rss2:
    add rbx, 3*8                ;Goto next entry
    dec ecx                     ;Decrement count
    jnz .rss1                   ;Not at zero, keep going
    mov qword [sysMem], rax
;Create and insert new entry. If no space found for new, just add to end
.addEntry:
    movzx ecx, byte [bigmapSize]
    sub ecx, 2          ;Remove the allocated entries from the count   
    xor edx, edx    ;Use as index pointer
.ae0:
    cmp qword [bigmapptr+rdx], 100000h    ;Start of extended memory
    je .ae1
    add rdx, 18h    ;Go to next entry
    dec ecx 
    jnz .ae0
;If address not found, just add it to the end, deal with that here
;Ignore the extra calculated allocated entry
;rdi points to last new entry, so sub rdi to point to second to last entry
    sub rdi, 3*8h
    mov qword [rdi], BIOSStartAddr
    mov rax, qword [scpSize]
    mov qword [rdi + 8h], rax
    mov rax, 100000002h
    mov qword [rdi + 8h], rax
    jmp .altRAM
.ae1:
;Address found, add new entry
;ecx contains number of entries that need to be shifted + 1
    push rsi
    push rdi
    mov rsi, rdi
    sub rsi, 2*18h
    dec ecx
    mov eax, ecx    ;Use eax as row counter
.ae2:
    mov ecx, 3      ;3 8 byte entries
    rep movsq
    sub rsi, 2*18h
    sub rdi, 2*18h
    dec eax
    jnz .ae2
    pop rdi
    pop rsi
;Values copied, time to change values
;Change HMA entry
    add rdx, bigmapptr    ;Add offset into table to rdx
    mov rcx, qword [rdx + 8h]       ;Save size from entry into rax
    mov qword [rdx + 8h], 10000h    ;Free 64Kb entry (HMA)
    add rdx, 3*8h   ;Move to new SCP reserved entry
;Now Create the SCPBIOS Space Entry
    mov qword [rdx], BIOSStartAddr
    xor ebx, ebx
    mov ebx, dword [scpSize]
    mov qword [rdx + 8h], rbx
    mov rbx, 100000002h
    mov qword [rdx + 10h], rbx  ;Reserved flags
    add rdx, 3*8h
;Now modify the Free space entry
    mov rax, qword [userBase]
    mov qword [rdx], rax
    xor eax, eax
    mov eax, dword [scpSize]
    sub rcx, rax
    sub rcx, 10000h ;Sub HMA size
    mov qword [rdx + 8h], rcx    ;Put entry back
    mov rbx, 100000001h
    mov qword [rdx + 10h], rbx  ;Free flags
.altRAM:
;Copy Alt RAM values
    mov ebx, dword [scpSize]
    shr ebx, 0Ah    ;Rescale from byts to KB
    add ebx, 40h    ;Add the HMA (64Kb)
    mov rdi, srData    ;Save qword in srData ah=E801h
    lodsq    ;Get into rax, inc rsi
    sub ax, bx      ;bx preserved, contains number of KB's plus 1
    ror rax, 20h    ;Rotate over 32 bits
    sub ax, bx
    ror rax, 20h    ;Rotate over 32 bits again
    stosq            ;Save, inc rdi
    mov rdi, srData1    ;Save word for ah=88h
    movsw    ;Save value, then reduce by BIOS size
    sub word [rdi - 2], bx    ;Reduce the size of the previous stored val
    mov rdi, convRAM    ;Int 12h value
    movsw
;Copy VGA fonts to Internal Int 30h area
    mov rdi, scr_vga_ptrs
    mov rcx, 8
    rep movsq
;-----------------Write Long Mode Page Tables-----------------
;Creates a 4Gb ID mapped page 
    mov rdi, BIOSPageTbl
    push rdi
Ptablefinal:
    mov rcx, 6000h/8;6000h bytes (6x4Kb) of zero to clear table area
    push rdi
    xor rax, rax
    rep stosq        ;Clear the space

    pop rdi            ;Return zero to the head of the table, at 08000h
    mov rax, rdi    ;Load rax with the PML4 table location
    add rax, 1000h  ;Move rax to point to PDPT
    or rax, permissionflags    ;Write the PDPT entry as present and r/w
    stosq    ;store the low word of the address
    add rdi, 0FF8h
    mov ecx, 4
.utables:
    add rax, 1000h  ;Write four entries in PDPT for each GB range
    stosq
    dec ecx
    jnz .utables

    add rdi, 0FE0h  ;rdi points to the new page tables, copy!
    mov rsi, 0A000h ;Get the first Page table
    mov ecx, 4000h/8 ;Number of bytes to copy 
    rep movsq       ;Get the 4Gb tables into place
    pop rdi            ;Bring back Table base
    mov cr3, rdi    ;Finalise change in paging address

;----------------------Write Interrupts----------------------
    mov rcx, 0100h    ;256 entries
    mov rax, dummy_return_64
    mov ebx, codedescriptor
    xor esi, esi
    mov dx, 8F00h    
    ;Toggle attribs. 8F = Interrupt Present, accessable from ring 0 and greater,
    ;0 (so collectively 08h) and gate type 0Fh (64-bit trap gate (gate which 
    ;leaves interrupts on))
idtFillDummy:
    call idtWriteEntry
    dec cx
    jnz idtFillDummy

    xor esi, esi
    mov rcx, ((IDT_TABLE_Length >> 3))
    mov rbp, IDT_TABLE
idtLoop:
    mov rax, qword [rbp+(rsi*8)]
    call idtWriteEntry
    dec rcx
    jnz idtLoop

    mov rsp, 80000h    ;Realign stack pointer
;Reload the interrupt table
    lidt [IDTpointer]
;Write GDT to its final High location
    mov rsi, GDT
    mov rdi, BIOSGDTable
    mov rcx, 3
    rep movsq    ;copy the three descriptors high
;Reload the GDT Pointer
    lgdt [GDTpointer]

;Video Initialisation: VGA mode, CRTC at 3D4h, Mode 03h, 128k VRAM
;For now, only unlock upper WO CRTC registers, by using undocumented 
; CRTC register 11h.
    mov dx, word [scr_crtc_base]    ;Get current set CRTC index register
    mov al, 11h     ;Register 11
    mov al, bl
    out dx, al
    out waitp, al   ;Wait an I/O cycle
    inc dx  ;Point to data register
    in al, dx   ;get register 11h
    and al, 7Fh ;Clear upper bit
    xchg al, bl ;Get address back into al, save new register value in bl  
    dec dx  ;Return to index
    out dx, al
    inc dl
    xchg al, bl
    out dx, al  ;Output new byte, unlock upper WO CRTC registers for use!
;Boot message/Verification of successful VGA card reset!
;Print Boot Message
    mov ax, 1304h
    mov rbp, startboot
    int 30h

    call memprint    ;Print Memory status

;----------------------------------------------------------------
;                        End of Initialisation                  :
;----------------------------------------------------------------
;----------------------------------------------------------------
;                PIC Initialisation procedure                   :
;----------------------------------------------------------------
;Remapping the IO ports to Interrupt 0x40
PICremap:
    mov al, 11h        ;bit 10h and 1h = Start initialisation
    out pic1command, al
    out waitp, al    
    out pic2command, al
    out waitp, al    
    
    mov al, 20h       ;PIC1 to take Int 20h - 27h
    out pic1data, al
    out waitp, al    
    add al, 8        ;PIC2 to take Int 28h - 2Fh
    out pic2data, al 
    out waitp, al    
    
    mov al, 4
    out pic1data, al    ;Tell PIC 1 that there is a PIC 2 at IRQ2 (00000100)
    out waitp, al    
    dec al
    dec al
    out pic2data, al    ;Tell PIC 2 its cascade identity (00000010)
    out waitp, al
    
    mov al, 01h        ;Initialise in 8086 mode
    out pic1data, al
    out waitp, al    
    out pic2data, al
    out waitp, al    
    
    mov al, 0FFh    ;Mask all interrupts 
    out pic1data, al
    out pic2data, al

;Ensure that interrupts are still masked
;----------------------------------------------------------------
;                        End of Initialisation                  :
;----------------------------------------------------------------
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
    ;call IDE.addControllerTable
    ;jc .u11     ;If this fails, exit gracefully
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
;----------------------------------------------------------------
;                PIT Initialisation procedure                   :
;----------------------------------------------------------------
PITreset:       ;Set Timer 0 to trigger every 55ms
    mov al, 36h    ;Set bitmap for frequency write to channel 0 of pit
    out PITcommand, al    ;43h = PIT command register
    mov ax, word [pit_divisor]
    out PIT0, al    ;mov low byte into divisor register
    mov al, ah      ;bring hi byte into low byte
    out PIT0, al    ;mov hi byte into divisor register
;PIT unmasked below
;----------------------------------------------------------------
;                     End of Initialisation                     :
;----------------------------------------------------------------
;----------------------------------------------------------------
;                RTC Initialisation procedure                   :
;----------------------------------------------------------------
rtc_init:
;Set tick rate to 1024Hz and ensure RTC doesnt generate IRQ8
    mov ax, 8A8Ah    ;Status A register with NMI disable
    out cmos_base, al
    out waitp, al    ;Latch wait
    jmp short $+2
    mov al, 00100110b ;32KHz timebase, 1024Hz square wave output
    out cmos_data, al
;Now ensure NO interrupts are cooked
    inc ah    ;ah=8Bh
    mov al, ah
    out cmos_base, al
    out waitp, al  ;Latch wait
    jmp short $+2
    mov al, 02h    ;Zero all int bits, time: BCD, 24hr, Daylight saving off
    out cmos_data, al
;Clear any cooked IRQs
    inc ah    ;ah=8Ch
    mov al, ah
    out cmos_base, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, cmos_data
;Get final CMOS RAM status byte
    mov al, 0Dh     ;Status D register with NMI enable
    out cmos_base, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, cmos_data
;Unmask RTC and PIT here!
    in al, pic2data    ;Get current state
    and al, 0FEh    ;Unmask RTC
    out pic2data, al
    in al, pic1data
    and al, 0FAh    ;Unmask PIT and Cascade
    out pic1data, al
    sti             ;Enable maskable interrupts
;----------------------------------------------------------------
;                     End of Initialisation                     :
;----------------------------------------------------------------
    mov rcx, 200    ;Beep for a 200ms
    mov ebx, 04A9h  ;Frequency divisor for 1000Hz tone
    mov ax, 0C500h
    int 35h
;----------------------------------------------------------------
;                Serial Port Initialisation procedure           :
;----------------------------------------------------------------
;Initial init procedure, check which ports exist and 
; write the address to Data area
    mov ax, 5A5Ah
    xor rcx, rcx
    mov rbp, com_addresses
checkCOM:
    mov dx, word [serial_abt + rcx*2]    ;Multiplied by 2 for word offsets
    add dx, 7    ;Scratch register
    out dx, al    ;Output
    jmp short $ + 2
    in al, dx    ;Read the value
    cmp ah, al   ;Check if theyre the same 
    jne COMinitproceed ;Scratch register non-existant, IO registers not present
    sub dx, 7    ;point dx back to base
    mov word [com_addresses + rcx*2], dx    ;Save dx into data area table
    inc cl
    cmp cl, 4
    jne checkCOM    ;Keep looping
COMinitproceed:
;Sets all active COM ports to 2400,N,8,1, FIFO on, hware handshaking
    mov byte [numCOM], cl
    xor cl, cl
serialinit:
    mov dx, word [com_addresses + rcx*2]  ;get the serial port base addr in dx
    test dx, dx
    jz COMinitexit    ;invalid address, port doesnt exist, init complete
;Disable interrupts
    inc dx        ;point at base + 1
    xor al, al    ;get zero to out it to the interrupt register
    out dx, al    ;Disable all interrupts
;Set DLAB
    add dx, 2    ;point dx to the Line Control register (LCR)
    in al, dx    ;get the LCR byte into al
    or al, 10000000b    ;set bit 7, DLAB bit on
    out dx, al    ;output the set bit
;Set baud rate
    sub dx, 3    ;word of baud divisor
    mov ax, 0030h    ;the divisor for 2400 baud (cf table below)
    out dx, ax    ;out put the divisor word
;Clear DLAB, set the parity, break stop and word length
    add dx, 3    ;repoint at LCR (base + 3)
    mov al, 00000011b  ;DLAB off, 8,n,1, no break, no stick
    out dx, al    ;out that byte
;Clear FIFO
    dec dx        ;base + 2, FIFO register
    mov al, 00000110b    ;Clear FIFO, set char mode
    out dx, al    ;out that stuff
;Enable interrupts and RTS/DTR
    dec dx        ;base + 1, Interrupt Enable Register
    mov al, 1     ;ONLY set the data receive interrupt, none of the other 
                  ; status or transmit type interrupts
    out dx, al

    add dx, 3    ;base + 4, Modem control register
    in al, dx    ;preserve reserved upper bits
    and al, 11100000b
    or al, 00001011b    ;Set OUT2 (ie IRQ enable), set RTS/DTR.
    out dx, al
    inc cx
    jmp short serialinit
COMinitexit:
;Unmask com ports here!
    in al, pic1data
    and al, 0E7h    ;Unmask Com lines 1 and 2 (bits 3 and 4)
    out pic1data, al
;----------------------------------------------------------------
;                     End of Initialisation                     :
;----------------------------------------------------------------

;----------------------------------------------------------------
;             PS/2 Keyboard Initialisation procedure            :
;----------------------------------------------------------------
keybsetup:    ;proc near
    mov ax, 0E0Ah
    int 30h
    mov ax, 0E0Dh
    int 30h    ;Send a crlf to con

    mov ax, 1304h
    xor bh, bh
    mov rbp, ps2stage.startMsg ;Prompt to strike a key
    int 30h

    mov al, 05Fh        ;PS/2 Stage signature
    out waitp, al
    out bochsout, al    

    xor r8, r8          ;use as an stage counter 
    jmp .step1
.kbscdetermine:
    mov al, 0F0h    
    call ps2talk.p3
    call ps2talk.p1
    cmp al, 0FAh        ;ACK?
    jne .kbscdetermine  ;Not ack, try again
.pt1:
    xor al, al
    call ps2talk.p3
    call ps2talk.p1     ;Get ack into al, 
    cmp al, 0FAh
    jne .pt1
    call ps2talk.p1     ;Get scancode into al
    ret

;----------------------------------------------------------------
;Do all writes using ps2talk:
;    ah = 0 - Read Status port into al
;    ah = 1 - Read Data port into al
;    ah = 2 - Write al into Command port 
;    ah = 3 - Write al into Data port
;----------------------------------------------------------------
; Step 1) Disable ps2 port 1 using command word ADh and port 2 using command 
;  word A7h.
; Step 2) Flush buffer and check bit 2 is set (else fail)
; Step 3) Read controller configuration byte (command word 20h)
; Step 4) Disable IRQs bits 0,1 (clear bit 0,1) [and manually disable second 
;  ps2 port (bit 5 set)]
; Step 5) Write controller config byte back (command word 60h)
; Step 6) Test controller using AAh command word. Return 55h or fail.
; Step 7) Test ps2 port 1 using ABh command word. Return 00h or fail.
; Step 8) Enable ps2 port 1 using AEh command word. Enable IRQ by setting bit 0 
;  of the config byte.
; Step 9) Reset ps2 port 1 device using FFh data word. If AAh returned, 
;  proceed, else if ACK (FAh), await AAh. FCh and FDh indicate fail. FEh = 
;  resend command.
; Step 10) Reset scan code set to 1 using F0h data word with 01h data word. If 
;  ACK (FAh) proceed, if RESEND (FEh), resend 10h tries.
; Setp 11) Enable scanning (ie keyboard sends scan codes) using data word F4h.
;----------------------------------------------------------------
;Step 1
.step1:
    mov al, 0ADh
    call ps2talk.p2
    mov al, 0A7h        ;Cancel second interface if it exists (DO NOT REENABLE)
    call ps2talk.p2
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 1
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 2

    in al, ps2data     ;manually flush ps2data port
    
;Step 3
keyb0:
    mov al, 20h
    call ps2talk.p2    ;out ps2command, al
    call ps2talk.p1    ;Read config byte into al
;Step 4
    mov bl, al         ;copy al into bl to check for bit 2
    and bl, 10111100b  ;Disable translation, enable later if needed
;Step 5
    mov al, 60h
    call ps2talk.p2    ;Write config byte command
    mov al, bl
    call ps2talk.p3    ;Out new config byte
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8             ;Checkpoint 2
    call ps2stage      ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 6
    mov al, 0AAh ;Can reset the config byte, out bl to ps2data at end of stage
    call ps2talk.p2
    call ps2talk.p1
    cmp al, 55h
    jne ps2error
    
    mov al, 60h  ;Previous code may have reset our new config byte, resend it!
    call ps2talk.p2            ;Write config byte command
    mov al, bl
    call ps2talk.p3            ;Out new config byte
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8             ;Checkpoint 3
    call ps2stage      ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 7
    mov al, 0ABh            ;Test controller 1
    call ps2talk.p2
    call ps2talk.p1
    test al, al                ;Check al is zero
    jnz ps2error
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8             ;Checkpoint 4
    call ps2stage      ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 8
    mov al, 0AEh
    call ps2talk.p2

;Set IRQ 1 to connect to port 1
    mov al, 20h
    call ps2talk.p2        ;Write
    call ps2talk.p1        ;Read
    or al, 00000001b    ;Set bit 0
    and al, 11101111b    ;Zero bit 4, First port Clock
    mov bl, al
    mov al, 60h
    call ps2talk.p2
    mov al, bl
    call ps2talk.p3
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 5
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
;Step 9
    xor cx, cx
keyb1:
    dec cx ;timeout counter
    jz ps2error
    mov al, 0FFh
    call ps2talk.p3
.k1:
    call ps2talk.p1 ;read from ps2data
    cmp al, 0AAh    ;success
    je keyb20
    cmp al, 0FAh    ;ACK    
    je .k1          ;Loop if ACK recieved, just read ps2data
    jmp keyb1       ;Else, loop whole thing (assume fail recieved)
;Step 10
keyb20:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 6
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    xor ecx, ecx
keyb2:
    dec ecx
    jz ps2error
.k0:
    mov al, 0F0h
    call ps2talk.p3
    
    mov ah, 01h
    call ps2talk.p1
    cmp al, 0FEh    ;Did we recieve an resend?
    je .k0          ;Resend the data!
    cmp al, 0FAh    ;Compare to Ack?
    jne keyb2       ;If not equal, dec one from the loop counter and try again
    
    mov al, 01h     ;write 01 to data port (set scan code set 1)
    call ps2talk.p3
.k1:
    call ps2talk.p1    ;read data port for ACK or resend response
    cmp al, 0FAh
    je keyb30    ;IF ack revieved, scancode set, advance.
    loop .k1     ;Keep polling port
    jmp keyb2
;Step 11
keyb30:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 7
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    xor ecx, ecx
keyb3:
    dec cx
    jz ps2error
    
    mov al, 0F4h
    call ps2talk.p3
.k1:
    call ps2talk.p1 ;read data port for ACK or resend response
    cmp al, 0FAh
    je keyb40
    loop .k1        ;Keep polling port
    jmp keyb3       ;Fail, retry the whole process
    
;Step 12
keyb40:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 8
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
keyb4:
    mov al, 0EDh     ;Set lights
    call ps2talk.p3
    call ps2talk.p1  ;get response, remember ps2talk does its own timeout
    cmp al, 0FAh
    jne keyb4        ;No ack, try again.
.k1:
    mov al, 00h        ;Flash lock on and off
    call ps2talk.p3
    call ps2talk.p1    ;flush, remember ps2talk does its own timeout
    
;End Proc
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 9
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

keyb5:
    mov al, 0EEh     ;Echo command
    call ps2talk.p3
    xor al, al       ;Zero al to ensure that the result is EEh
.k1:
    call ps2talk.p1
    cmp al, 0EEh
    je .k2           ;If equal, continue
    mov rbp, .noecho
    mov ax, 1304h
    xor bh, bh
    int 30h
    pause
    jmp short .k2
.noecho:        db    "No Echo recieved", 0Ah, 0Dh, 0
.k2:
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 0Ah
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
keyb6:    ;Set typematic rate/delay, 250ms, 30 reports/second
    mov al, 0F3h     ;Set typematic rate
    call ps2talk.p3
    xor al, al       ;Set rate
    call ps2talk.p3
    xor cx, cx
.k1:
    dec cx
    jz ps2error
    call ps2talk.p1
    cmp al, 0FAh    ;Ack?
    jnz .k1
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 0Bh
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
scancode_faff:
    mov al, 20h      ;Get command byte from command port
    call ps2talk.p2  ;al should contain command byte
    mov ah, al       ;temp save cmd byte in ah

    xor ecx, ecx
.p1:
    dec cx
    jz keybflushe
    call keybsetup.kbscdetermine ;Get the current scancode set id
    or ah, 00000001b    ;Do basic or, ie set IRQ for port 1

;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
    inc r8           ;Checkpoint 0Ch
    call ps2stage    ;print which stage is complete
;<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

    cmp al, 43h      ;43h is sc1 signature
    je .writeback
    cmp al, 01h      ;Untranslated value
    je .writeback
    cmp al, 0FAh     ;Got an ACK for some reason, manually get next byte
    je .get_next_byte

    or ah, 01000000b    ;Neither value passed the test, invoke translation
.writeback:
    mov r15, rax     ;Save the scancode value to print later
    mov al, 60h
    call ps2talk.p2
    mov al, ah       ;return command byte
    call ps2talk.p3
    jmp short keybflush
.get_next_byte:
    call ps2talk.p1  ;Get the byte safely into al!
    jmp short .p1    ;Recheck the scancode signature

keybflushe:
    or r15b,0F0h    ;Add signature to scancode value denoting error
keybflush:    ;Flush internal ram of random bytes before enabling IRQ1
    mov cx, 10h
.kbf1:
    dec cx
    jz keybinitend
    in al, ps2data        ;Read 16 bytes out (even if empty) and discard
    jmp short .kbf1

keybinitend:
    xor bh, bh  ;We are on page 0
    mov ah, 03h ;Get current cursor row number in dh 
    int 30h
    mov dl, 17  ;End of PS/2 Keyboard message at column 17
    xor bh, bh  ;Page 0
    mov ah, 02h ;Set cursor
    int 30h

    push rdx    ;Save row/column in dx on stack
    mov ecx, 27 ;27 chars in keystrike message
.kbe0:
    mov eax, 0E20h 
    int 30h
    loop .kbe0

    pop rdx
    xor bh, bh  ;Page 0
    mov ah, 02h ;Set cursor
    int 30h

    mov rbp, ps2stage.okMsg
    mov rax, 1304h    ;print 0 terminated string
    xor bh, bh
    int 30h

;Unmask IRQ1 here
    in al, pic1data
    and al, 0FDh    ;Unmask bit 1
    out pic1data, al

    jmp debuggerInit
;Relevant Procs for PS/2 keyboard setup
ps2talk:
;   ah = 0 - Read Status port into al
;   ah = 1 - Read Data port into al
;   ah = 2 - Write al into Command port 
;   ah = 3 - Write al into Data port
    test ah, ah
    jz .p0
    dec ah
    jz .p1
    dec ah
    jz .p2
    jmp .p3
.p0:
    in al, ps2status
    ret
.p1:
    jmp short $ + 2
    in al, ps2status
    test al, 1    ;Can something be read from KB?
    jz .p1        ;Zero if no. Not zero = read.
    jmp short $ + 2
    in al, ps2data  ;Read it in
    ret
.p2:
    call ps2wait    ;preserves ax
    out ps2command, al
    ret
.p3:
    call ps2wait
    out ps2data, al
    ret
ps2error:
    mov rbp, .ps2errormsg
    mov ax, 1304h
    xor bh, bh
    int 30h
.loop:
    pause
    jmp short .loop
.ps2errormsg: db 0Ah, 0Dh,"PS/2 stage init error...", 0Ah, 0Dh, 0

ps2stage:
;Outputs r8b to waitport and Bochs out
    push rax
    mov al, r8b
    out waitp, al
    out bochsout, al
    pop rax
    ret
.startMsg db 0Ah, 0Dh,'PS/2 Keyboard... Strike a key to continue...',0 
.okMsg db 'OK', 0 ;This should go 17 chars in
;----------------------------------------------------------------
;                      End of Initialisation                    :
;----------------------------------------------------------------
;----------------------------------------------------------------
;              Debugger Initialisation procedures               :
;----------------------------------------------------------------
debuggerInit:
;Int 40h can be used by the Debugger to return to it or if a DOS present, 
; to return to DOS.
    mov rax, MCP_int ;The application return point
    mov rsi, 40h
    mov dx, 8F00h    ;Attribs
    mov ebx, codedescriptor
    call idtWriteEntry    
;----------------------------------------------------------------
;              Drive Enum and Initialisation procedures         :
;----------------------------------------------------------------
ideInitialisation:
;This is truly read once code
;Check primary and secondary bus for master and slave drives
; Maximum of 4 "fixed" ATA drives
;Use PIO for identification of drives on bus
    jmp short hciParse
    mov al, 0A0h
    mov dx, ata0_base
    mov rdi, sectorbuffer
    call IDE.identifyDevice

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
    jz end    ;No EHCI controllers or last controler? Exit
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
    mov rbp, remDevInit.ok
    xor bh, bh
    int 30h
    jmp remDevInit
.echiInitMsg db 0Ah,0Dh,"Initialising USB and EHCI root hubs...",0
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
    add rsi, hubDevTblEntrySize ;Goto next table entry
    cmp rsi, hubDevTbl + 10*hubDevTblEntrySize  ;End of table address
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
    add rsi, msdDevTblEntrySize ;Goto next entry
    cmp rsi, msdDevTbl + 10*msdDevTblEntrySize
    jne .msd1
.rediexit:
    mov ax, 1304h
    xor bh, 0bh
    mov rbp, .ok
    int 30h
    jmp int33hinit
.rmhmsg db 0Ah,0Dh,"Initialising USB ports...",0
.ok db " OK",0
.msdmsg db 0Ah,0Dh,"Initialising MSD devices...",0
;----------------------------------------------------------------
;                         End of Enum                           :
;----------------------------------------------------------------    
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
;----------------------------------------------------------------
;                End of Enum and Initialisation                 :
;----------------------------------------------------------------    
end:
    mov ax, 1304h
    mov rbp, dbgmsg
    int 30h
    mov al, byte [numMSD]
    mov ah, 04h
    int 30h

    mov ax, 1304h
    mov rbp, dbgmsg2
    int 30h
    mov al, byte [i33Devices]
    mov ah, 04h
    int 30h

    mov ax, 1304h
    mov rbp, dbgmsg3
    int 30h
    mov al, byte [numCOM]
    mov ah, 04h
    int 30h

    cmp byte [i33Devices], 0    ;If there are no i33 devices, skip bootstrap
    jz endNoDevFound

    mov word [7DFEh], 0 ;Clear out the old bootloader signature
    int 39h             ;Bootstrap loader
endNoDevFound:
    mov rbp, endboot
    mov ax, 1304h
    int 30h
    
    xor ax, ax  ;Pause for any key
    int 36h

    mov bx, 0007h    ;cls attribs
    call cls

    xor cx, cx
    xor dx, dx
    mov ah, 2
    xor bh, bh
    int 30h 

    mov ax, 1304h
    mov rbp, endboot2
    int 30h

    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rsi, rsi
    xor rdi, rdi
    xor rbp, rbp
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15

    int 38h


startboot:  db "Loading SCP/BIOS...", 0Ah, 0Dh, 0
endboot:    db    0Ah,0Dh,"SCP/BIOS system initialisation complete", 0Ah, 0Dh 
        db "No Operating System detected. Strike any key to launch SYSDEBUG."
            db "..",0Ah, 0Dh,0
endboot2:   db "Starting SCP/BIOS SYSDEBUG...",0Ah,0Dh,0
dbgmsg:     db 0Ah,0Ah,0Dh,"MSD devices: ",0
dbgmsg2:    db 0Ah,0Dh,"Int 33h devices: ",0
dbgmsg3:    db 0Ah,0Dh,"COM ports: ",0
memprint:
;Simple proc to print memory status
    xor bx, bx 
    mov rbp, .convmemmsg
    mov ax, 1304h
    int 30h
    int 32h    ;Get conv Size
    and eax, 0FFFFh ;Clear upper bits
    call .printdecimalword
    mov rbp, .kb
    mov ax, 1304h
    int 30h

    mov ax, 0E801h
    int 35h
    and eax, 0FFFFh
    and ebx, 0FFFFh
    and ecx, 0FFFFh
    and edx, 0FFFFh
    push rbx
    push rdx
    cmp rax, rcx
    je .sense1    ;Sensible
    test rax, rax
    cmovz rax, rcx
    test rax, rax
    jz .pt2
.sense1:
    push rax
    mov rbp, .extmemmsg
    mov ax, 1304h
    int 30h
    pop rax
    call .printdecimalword
    mov rbp, .kb
    mov ax, 1304h
    int 30h
.pt2:
    pop rax
    pop rcx
    cmp rax, rcx
    je .sense2    ;Sensible
    test rax, rax
    cmovz rax, rcx
    test rax, rax
    jz .pt3
.sense2:
    push rax
    mov rbp, .extmemmsg2
    mov ax, 1304h
    int 30h
    pop rax

    shl rax, 6    ;Turn 64Kb into Kb
    call .printdecimalword
    mov rbp, .kb
    mov ax, 1304h
    int 30h
.pt3:   ;Read total free size from big map
    push rax
    mov rbp, .totalmem
    mov eax, 1304h
    int 30h
    pop rax
    mov rax, qword [sysMem]
    xor ebx, ebx
    mov ebx, dword [scpSize]
    sub rax, rbx
    shr rax, 0Ah                ;Get number of Kb's free
    call .printdecimalword  
    mov rbp, .kb
    mov ax, 1304h
    int 30h

    mov eax, 0E0Ah
    int 30h
    mov eax, 0E0Dh   ;CR/LF
    int 30h

    ret

.printdecimalword:
;Takes the qword in rax and prints its decimal representation
    push rdx
    push rcx
    push rbx
    push rax
    push rbp
    xor rcx, rcx
    xor bp, bp    ;Use bp as #of digits counter
    mov rbx, 0Ah  ;Divide by 10
.pdw0:
    inc ebp
    shl rcx, 8    ;Space for next nybble
    xor edx, edx
    div rbx
    add dl, '0'
    cmp dl, '9'
    jbe .pdw1
    add dl, 'A'-'0'-10
.pdw1:
    mov cl, dl    ;Save remainder byte
    test rax, rax
    jnz .pdw0
.pdw2:
    mov al, cl    ;Get most sig digit into al
    shr rcx, 8    ;Get next digit down
    mov ah, 0Eh
    int 30h
    dec ebp
    jnz .pdw2

    pop rbp
    pop rax
    pop rbx
    pop rcx
    pop rdx
    ret
.convmemmsg:        db 0Ah,0Dh,"Free Conventional Memory: ",0
.extmemmsg:         db 0Ah,0Dh,"Total Low Extended Memory: ",0    
.extmemmsg2:        db 0Ah,0Dh,"Total High Extended Memory: ",0
.totalmem:          db 0Ah,0Dh,"Total Free System Memory: ",0
.kb:                db "K",0
;----------------------Interrupt Tables--------------------------
IDT_TABLE:
CPU_IDT:
    dq i0
    dq i1
    dq i2
    dq i3
    dq i4
    dq i5
    dq i6
    dq i7
    dq i8
    dq i9
    dq i10
    dq i11
    dq i12
    dq i13
    dq i14
    dq i15
    dq i16
    dq i17
    dq i18
    dq i19
    dq i20
    dq i21
    times 0Ah dq dummy_return_64    ;just return, reserved interrupts!
HW_IDT:
;--------PIC1--------:    ;Int 20h-27h
    dq timer_IRQ0
    dq kb_IRQ1
    dq dummy_interrupt.pic1
    dq ser_IRQ3
    dq ser_IRQ4
    dq dummy_interrupt.pic1
    dq fdd_IRQ6
    dq default_IRQ7
;--------PIC2--------:    ;Int 28h-2Fh
    dq rtc_IRQ8
    dq dummy_interrupt.pic2
    dq dummy_interrupt.pic2
    dq dummy_interrupt.pic2
    dq dummy_interrupt.pic2
    dq dummy_interrupt.pic2
    dq hdd_IRQ14
    dq default_IRQ15
SW_IDT:    ;Int 30h onwards!
    dq scr_io            ;Int 30h, VGA Screen drawing/TTY functions
    dq machineWord_io    ;Int 31h, Give the BIOS hardware bitfield
    dq convRAM_io        ;Int 32h, Give conv memory available
    dq disk_io           ;Int 33h, Storage device Functions
    dq serial_io         ;Int 34h, Serial Port Functions
    dq misc_io           ;Int 35h, Misc functions
    dq kb_io             ;Int 36h, Keyboard functions
    dq printer_io        ;Int 37h, Reserved [Who uses parallel anymore?]
    dq MCP_int           ;Int 38h, launch MCP, and install its "API" handle
    dq bootstrapInt      ;Int 39h, restart the PC using an interrupt
    dq timerInt          ;Int 3Ah, Time of day
    dq ctrlbreak_io      ;Int 3Bh, user Break
    dq dummy_return_64   ;Int 3Ch, user IRQ0 hook
    dq scr_params_io     ;Int 3Dh, Screen Mode parameters return function
    dq disk_params_io    ;Int 3Eh, disk parameters return function
    dq cga_ret_io        ;Int 3Fh, video extention return function
IDT_TABLE_Length equ $ - IDT_TABLE
seg0len equ ($ - $$)

;----------------------------------------------------------------
;                BIOS RESIDENT CODE AREA STARTS HERE            :
;----------------------------------------------------------------
Segment codeResident follows=codeInit vfollows=data align=1 valign=1
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

;--------------------Interrupt Service routines------------------

;======================HARDWARE INTERRUPTS=======================
;----------------Timer Interrupt IRQ 0/Int 20h-------------------
;This interrupt simply increments an internal timer and 
; calls a software interrupt (5Ch) which can be used by user 
; applications.
;----------------------------------------------------------------
timer_IRQ0:
    sti    
    push rax
    inc dword [pit_ticks]
    mov eax, dword [pit_ticks]
    and eax, 1FFFFFh    ;Clear OF bit [mask on bits 20:0]
    cmp eax, 1800B0h    ;Ticks in one full day
    jnz .tret            ;Not quite there
    mov word [pit_ticks], 0     ;Zero lo count
    mov byte [pit_ticks + 2], 0    ;Zero hi count
    inc byte [pit_ticks + 3]    ;Increment day OF counter    
.tret:
    int 3Ch        ;Call user handler

    mov al, EOI
    out pic1command, al
    out waitp, al    ;allow one io cycle to run

    pop rax
    iretq
;-------------------------End of Interrupt-----------------------
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
    xor rax, rax

.k0:
    in al, ps2data    ;Get the scancode (Set 1)
    test rax, rax    ;Check to see if we got an error code from the keyboard.
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
    cmp rax, 0D2Bh    ;Toggle Insert
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
.ctrl_alt_del_killPC:
    in al, 64h    ;Check if the input buffer is empty
    test al, 2    ;Check if clear
    jne .ctrl_alt_del_killPC    ;keep waiting
    mov al, 0FEh    ;Pulse kill lines
    out 64h, al    
    ;PC dead, time to reboot!
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
;------------------Serial Interrupt IRQ 3/Int 23h----------------
;Serves serial ports 1 and 3 should they exist. Only considers 
; data recieving. Disregards all sending data interrupts.
;Puts recieved data into respective buffer and clears RTS 
; (base+5) if buffer full.
;----------------------------------------------------------------
ser_IRQ3:
    cli
    push rax
    push rdx
    push rbp
    push rcx
    push rdi
    push rbx

    mov ebx, 8
    mov dx, com2_base + 2 ;Interrupt ID register
    jmp short ser_common
;------------------------End of Interrupt------------------------
;---------------------Serial Interrupt IRQ 3/Int 23h-------------
;Serves serial ports 1 and 3 should they exist. Only considers 
; data recieving. Disregards all sending data interrupts.
;Puts recieved data into respective buffer and clears RTS 
; (base+5) if buffer full.
;----------------------------------------------------------------
ser_IRQ4:
    cli
    push rax
    push rdx
    push rbp
    push rcx
    push rdi
    push rbx

    mov ebx, 6
    mov dx, com1_base + 2 ;Interrupt ID register
ser_common:
    in al, dx
    test al, 1    ;Check if bit zero is clear ie interrupt pending
    jz .si1       ;Clear, interrupt pending on COM 1 port
.si0:
    mov dx, word [com_addresses + rbx] ;now point to HI COM Interrupt ID registr
    test dx, dx
    jz .siexit            ;Nothing here, exit
    inc dx
    inc dx                ;dx = base + 2
    in al, dx
    test al, 1     ;Check if bit zero is clear
    jnz .siexit    ;Bad behavior, or no Int on com3 after com1 processed, exit
.si1:
;Confirm Data available Interrupt (ie bits 1,2,3 are 010b)
    test al, 00000100b
    jz .siexit   ;bad behavior, exit
    add dx, 3    ;dx = base + 5
.si41:
    in al, dx
    and al, 1
    jz .si41

    sub dx, 5
    in al, dx    ;get char into al
    mov ah, al   ;save al in ah temporarily
    xor rcx, rcx
.si2:    ;Get offset into table structures into cx
    cmp dx, word [com_addresses + rcx*2]    ;table of addresses, dx is at base
    je .si3
    inc cx
    cmp cx, 4    ;rcx should be {0,3}
    jl .si2
    jmp short .siexit    ;bad value, exit
.si3:    ;Store in buffer algorithm
    mov rbx, qword [comX_buf_tail + rcx*8]
    mov rdi, rbx
    inc rbx        ;increment by one char
    cmp rbx, qword [comX_buf_end + rcx*8]
    jne .si4
    mov rbx, qword [comX_buf_start + rcx*8]    ;Wrap around buffer
.si4:
    cmp rbx, qword [comX_buf_head + rcx*8]    ;Check if buffer full
    je .si5    ;Buffer full, indicate wait to data source

    mov byte [rdi], ah    ;store char into buffer
    mov qword [comX_buf_tail + rcx*8], rbx    ;store new tail into variable

    jmp .si0    ;If com1/2, now check that com 3/4 didnt fire interrupt.

.si5:    ;Buffer full, Deassert DTR bit 
;dx points at the base register
    add dx, 4    ;Point at Modem Control Register
    in al, dx
    and al, 11111110b    ;Clear the bottom bit
    out dx, al    ;Set the DTR bit down (not ready to recieve data)
    add dx, 3    ;Point to scratch register
    mov al, ah    ;return ah into al
    out dx, al    ;put the overrun char into scratch register
    cmp cx, 2    ;If this was com1/2, now check for com 3/4.
    jne .si0
;exit since we dont want to take whats in the UART buffer just yet.
.siexit:
    mov al, EOI
    out pic1command, al

    pop rbx
    pop rdi
    pop rcx
    pop rbp
    pop rdx
    pop rax
    sti
    iretq
;------------------------End of Interrupt------------------------
;----------------FDD Interrupt IRQ 6/Int 26h---------------------
fdd_IRQ6:
    push rax
    mov al, EOI
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------
;-----------------Spurious Int Handler/Int 27h-------------------
; Catches and handles spurious interrupts on the first pic.
;----------------------------------------------------------------
default_IRQ7:
    push rax
    mov al, 0Bh    ;Read ISR 
    out pic1command, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, pic1command    ;Get the ISR
    test al, 80h
    jne .exit
    inc word [spurint1]
    jmp short .e2    ;Avoid sending EOI
.exit:
    mov al, EOI
    out pic1command, al
.e2:
    pop rax
    iretq
;---------------RTC Interrupt IRQ 8/Int 28h----------------------
; This IRQ should only trigger for the periodic and alarm 
; interrupts. If a programmer wishes to use the time update 
; complete interrupt feature, they should hook their own 
; interrupt handler.
;----------------------------------------------------------------
rtc_IRQ8:
    push rax
    cli             ;Disable interrupts
    mov al, 8Ch     ;Register C with NMI disabled
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data    ;Get the data byte to confirm IRQ recieved
    and al, 060h        ;Isolate Alarm and Periodic bits only
    test al, 40h        ;Periodic?
    jz .noPeriodic      ;No, skip the periodic
.periodic:
    dec qword [rtc_ticks]
.noPeriodic:
    test al, 20h        ;Alarm?
    jz .exit
.alarm:
    int 6Ah    ;User Alarm handler, behaves like Int 4Ah on 16-bit BIOS
.exit:
    mov al, 0Dh     ;Read Register D and reenable NMI
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data    
    mov al, EOI
    out pic2command, al
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------
;---------------HDD Interrupt IRQ 14/Int 2Eh---------------------
hdd_IRQ14:
    push rax
    mov byte [ir14_mutex], 0
    mov al, EOI
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------
;-----------------Spurious Int Handler/Int 2Fh-------------------
; Catches and handles spurious interrupts on the second pic.
;----------------------------------------------------------------
default_IRQ15:
    push rax
    cmp byte [ir15_mutex], 1    ;Check if mutex set
    jne .spurcheck              ;If not set, then just check spur
    mov byte [ir15_mutex], 0    ;Exit and check spur
.spurcheck:
    mov al, 0Bh    ;Read ISR 
    out pic2command, al
    out waitp, al    ;Latch wait
    jmp short $+2
    in al, pic2command    ;Get the ISR
    test al, 80h
    mov al, EOI    ;Still need to send EOI to pic1
    jne .exit
    inc word [spurint2]
    jmp short .e2    ;Avoid sending EOI
.exit:
    out pic2command, al
.e2:
    out pic1command, al
    pop rax
    iretq
;------------------------End of Interrupt------------------------
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
;========================SOFTWARE INTERRUPTS=====================
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
;-----------------------Basic Config Int 31h---------------------
;This interrupt returns in ax the Hardware Bitfield from the 
; data area and the mass storage device details.
;----------------------------------------------------------------
machineWord_io:
    mov ax, word [MachineWord]    ;Return the legacy bitfield

    movzx r8, byte [i33Devices] ;Get Number of i33h devices
    shl r8, 8   ;Shift up by a byte
    mov r8b, byte [numMSD]  ;Get the number of Mass Storage Devices (on EHCI)
    shl r8, 8   ;Shift up by a byte again
    mov r8b, byte [fdiskNum]    ;Get the number of fixed disks
    shl r8, 8  ;Shift up by a byte again
    mov r8b, byte [numCOM]      ;Get the number of COM ports

    iretq
;------------------------End of Interrupt------------------------
;------------------------Basic RAM Int 32h-----------------------
;This interrupt returns in ax amount of conventional memory in ax
;----------------------------------------------------------------
convRAM_io:
    mov ax, word [convRAM]    ;Return the amount of conventional RAM
    mov r8, qword [userBase]    ;Return the userbase to a caller
    mov r9, qword [bigmapptr]   ;Return the big Map pointer 
    movzx r10, byte [bigmapSize]    ;Return the number of 24 byte entries
    iretq
;------------------------End of Interrupt------------------------
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
    jnz .baddev    ;If bit 7 set, exit (temp for v0.9)
    push rdx
    inc dl          ;Inc device number count to absolute value
    cmp dl, byte [i33Devices]
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
;Output: rax = dBlockSize (Dword for LBA block size)
;        rcx = qLastLBANum (Qword address of last LBA)
    push rdx
    movzx rax, dl   ;Move drive number offset into rax
    mov rdx, int33TblEntrySize
    mul rdx
    lea rdx, qword [diskDevices + rax]  ;Move address into rdx
    mov eax, dword [rdx + 3]    ;Get dBlockSize for device
    mov rcx, qword [rdx + 7]    ;Get qLastLBANum for device
    pop rdx
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
;------------------------End of Interrupt------------------------
;------------------Serial IO Interrupts Int 34h------------------
serial_baud_table:    ;DLAB devisor values
    dw    0417h    ;110 baud,     00
    dw    0300h    ;150 baud,     01
    dw    0180h    ;300 baud,     02
    dw    00C0h    ;600 baud,     03
    dw    0060h    ;1200 baud,    04
    dw    0030h    ;2400 baud,    05 
    dw    0018h    ;4800 baud,    06
    dw    000Ch    ;9600 baud,    07
    dw    0006h    ;19200 baud,   08
    dw    0003h    ;38400 baud,   09
    dw    0002h    ;57600 baud,   0A
    dw    0001h    ;115200 baud,  0B
serial_abt: ;serial port address base table. List of supported addresses!
    dw com1_base
    dw com2_base
    dw com3_base
    dw com4_base
serial_io:
    push rdx        ;Save upper 7 bytes
    cmp dx, 4        ;Check to see if the selected com port is within range
    jge .sbadexit1    ;Bad dx value
    movzx rdx, dx    ;zero the upper 6 bytes of rdx
    mov dx, word [com_addresses + rdx*2]    ;get serial port base addr into dx
    test dx, dx        ;is the address zero?
    jz .sbadexit2    ;com port doesnt exist
    push rax        ;Saves upper 6 bytes
    push rdx        ;Save base for exit algorithm

    test ah, ah
    jz .userinit
    dec ah 
    jz .transmit
    dec ah
    jz .recieve
    dec ah
    jz .sioexit    ;since this puts the status into ax
    dec ah
    jz .extinit
    dec ah
    jz .extstatus
    dec ah
    jz .custombaud

.badin:
    pop rdx
    pop rax
    mov ah, 80h    ;Invalid Function
    jmp short .sbadcommon
.sioexit:
    pop rdx   ;Get base back, to know exact offset
    pop rax        ;Return the upper bytes of rax into rax
    add dx, 5    ;point to the line status register
    in al, dx    ;get status
    mov ah, al    ;save line status in ah
    inc dx        ;point to the modem status register
    in al, dx    ;save modem status in al
    pop rdx
    iretq

.sbadexit1:    
    mov al, 0FFh    ;dx was too large
    jmp short .sbadcommon
.sbadexit2:
    mov al, 0FEh    ;COM port doesnt exist
.sbadcommon:
    pop rdx        ;return original rdx value
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq

.userinit:
    mov ah, al    ;save the data in ah for the baud rate
    add dx, 3    ;Point to the line control register
    and al, 00011111b   ;Zero out the upper three bits
    or al, 10000000b    ;Set the DLAB bit
    out dx, al 

    sub dx, 3    ;return point to base
    shr ax, 0Dh  ;0Dh=move hi bits of hi word into low bits of low word
    movzx rax, al    ;zero upper 7 bytes of rax
    cmp al, 00000111b    ;Check if set to 9600baud (for extension)
    je .ui2
.ui1:
    mov ax, word [serial_baud_table + rax]    ;rax is the offset into the table
    out dx, ax    ;dx points to base with dlab on, set divisor! (word out)
;Disable DLAB bit now
    add dx, 3
    in al, dx    ;Get the Line Control Register (preserving the written data)
    and al, 01111111b    ;Clear the DLAB bit, preserve the other bits
    out dx, al    ;Clear the bit

    jmp short .sioexit    ;exit!
.ui2:    ;Check r8b to make sure it is 0-4 inclusive.
    cmp r8b, 4    ;greater than four defaults to 4
    jg .ui3    ;r8b is greater than four, error!
    add al, r8b    ;increase the offset into the table
    jmp short .ui1    ;return to the get value from table
.ui3:    ;If r8b greater than 4, default to 4
    mov r8b, 4   ;Error caught, user used a value greater than 4, default to 4
    jmp short .ui2    ;return to checker

.transmit:
    add dx, 5    ;dx contains base address, point to Line status register
    mov ah, al   ;temp save char to send in ah
    push rcx
    xor cx, cx
.t1:
    dec cx
    jz .t2       ;timeout
    in al, dx    ;get the LSR byte in
    and al, 00100000b    ;Check the transmit holding register empty bit
    jz .t1    ;if this is zero, keep looping until it is 1 (aka empty)

    pop rcx
    mov al, ah   ;return data byte down to al
    sub dx, 5    ;reaim to the IO port
    out dx, al   ;output the data byte to the serial line!!
    jmp short .sioexit
.t2:
    pop rcx
    pop rdx      ;Get base back, to know exact offset
    pop rax      ;Return the upper bytes of rax into rax
    add dx, 5    ;point to the line status register
    in al, dx    ;get status
    mov ah, al   ;save line status in ah
    and ah, 80h  ;Set error bit (bit 7)
    inc dx       ;point to the modem status register
    in al, dx    ;save modem status in al
    pop rdx
    iretq
.recieve:
    ;Gets byte out of appropriate buffer head and places it in al
    pop rdx
    pop rax        
    pop rdx    ;Undoes the address entry and returns COM port number into dx    
    push rdx   ;Save it once more
    push rbx
    movzx rdx, dx

    cli    ;Entering a critical area, interrupts off
    mov rbx, qword [comX_buf_head + rdx*8]
    cmp rbx, qword [comX_buf_tail + rdx*8]
    je .r1    ;We are at the head of the buffer, signal error, no char to get.
    mov al, byte [rbx]    ;store byte into al
    mov ah, al ;temp save al in ah
    inc rbx    ;move buffer head
    cmp rbx, qword [comX_buf_end + rdx*8]    ;are we at the end of the buffer
    jne .r0    ;no, save new position
    mov rbx, qword [comX_buf_start + rdx*8]  ;yes, wrap around
.r0:
    mov qword [comX_buf_head + rdx*8], rbx   ;save new buffer position
    sti
    pop rbx
    pop rdx
    jmp short .rexit
.r1:
    sti
    mov ah, 80h    ;Equivalent to a timeout error.
    pop rbx
    pop rdx
    iretq

.rexit:    ;Line status in ah. Char was got so ensure DTR is now high again!
    mov dx, word [com_addresses + rdx*2]    ;Get the base address back into dx
    add dx, 4    ;point to the modem control register
    in al, dx
    test al, 1   ;Test DTR is clear
    jz .getscratch
.gsret:
    or al, 1    ;Set DTR bit on again
    out dx, al
    inc dx      ;point to the line status register
    in al, dx   ;get status
    xchg ah, al ;swap them around
    iretq
.getscratch:
    or al, 00010000b    ;Enable loopback mode with DTR on
    out dx, al
    add dx, 3    ;Point to scratch register
    in al, dx    ;Get overrun char
    sub dx, 7    ;transmit register
    out dx, al   ;send the char (no need to play with DTR, we sending to 
                 ; ourselves, generating an INT)
    add dx, 4    ;point back to modem control register again!
    in al, dx
    and al, 11101111b    ;Clear loopback mode, DTR bit gets set in main proc
    jmp short .gsret    

.extinit:
.extstatus:
.custombaud:
    pop rdx
    pop rax
    mov ah, 86h
    jmp .sbadcommon
;------------------------End of Interrupt------------------------
;-------------------Misc IO Interrupts Int 35h-------------------
;Misc features int that can be used for a variety of things.
;This will break compatibility with BIOS, since hopefully more 
; advanced features will be present.
;
; ah = 0 - 82h System Reserved
; ah = 83h -> Reserved, Event wait
; ah = 86h -> Delay rcx = # of milliseconds to wait
; ah = 88h -> Basic High Mem Map 1 (First 16MB only)
; ah = 89h to C4h - System Reserved
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ah = C5h - FFh BIOS device class dispatcher extensions
; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; ah = C5h -> Misc sys function dispatcher      (3 funct)
; ah = E8h -> Adv mem management sys dispatcher (4 funct)
; ah = F0h -> Sys data table dispatcher         (15 funct)
; ah = F1h -> EHCI system dispatcher            (4 funct)
;----------------------------------------------------------------
misc_io:
    cmp ah, 86h
    jb .badFunction
    jz .delay
    cmp ah, 88h
    jz .memory16MB

    cmp ah, 0C5h    ;Miscellaneous function dispatcher
    jz .miscDispatcher 
    cmp ah, 0E8h    ;Advanced memory management system dispatcher
    jz .advSysMemDispatcher
    cmp ah, 0F0h    ;System table dispatcher
    jz .sysDataTableDispatcher
    cmp ah, 0F1h    ;EHCI function dispatcher
    jz .ehciFunctionDispatcher
.badFunction:
    mov ah, 80h    ;Invalid Function
.badout:
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    iretq

.delay:
;Input: rcx = milliseconds to wait (rcx < 7FFFFFFFFFFFFFFFh)
;Init IRQ 8, wait for loop to end, deactivate
    cli    ;NO INTERRUPTS
    test rcx, rcx
    jz .return  ;Can avoid sti since we return caller flags
    push rax
;Ensure PIC is saved
    in al, pic1data
    push rax    ;Save unaltered pic1 value
    and al, 0FBh ;Ensure Cascading pic1 line unmasked
    out pic1data, al

    in al, pic2data
    push rax    ;Save unaltered pic2 value
    and al, 0FEh ;Ensure line 0 of pic2 unmasked 
    out pic2data, al

    mov qword [rtc_ticks], rcx
    mov ax, 8B8Bh       
    out cmos_base, al   ;NMI disabled
    out waitp, al
    jmp short $+2
    in al, cmos_data
    and al, 7Fh    ;Clear upper bit
    or al, 40h    ;Set periodic interrupt bit
    xchg ah, al
    out cmos_base, al
    out waitp, al
    jmp short $+2
    xchg al, ah
    out cmos_data, al
    mov al, 0Dh     ;Read Register D and reenable NMI
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data  
    sti        ;Reenable interrupts
.loopdelay:
    pause ;allow an interrupt to occur
    cmp qword [rtc_ticks], 0        ;See if we at 0 yet
    jg .loopdelay    ;If not, keep looping
;Return CMOS to default state
    cli
    mov ax, 8B8Bh   ;NMI disabled
    out cmos_base, al
    out waitp, al
    jmp short $+2
    in al, cmos_data
    and al, 0Fh    ;Clear all upper 4 bits
    xchg ah, al
    out cmos_base, al
    out waitp, al
    jmp short $+2
    xchg ah, al
    out cmos_data, al
    mov al, 0Dh     ;Read Register D and reenable NMI
    out cmos_base, al
    out waitp, al    ;allow one io cycle to run
    jmp short $+2
    in al, cmos_data  

    pop rax ;Return pic2 value
    out pic2data, al
    pop rax    ;Return pic1 value
    out pic1data, al

    pop rax    ;Return rax value
    sti
.return:
    iretq
.memory16MB:    ;ah=88 function
    mov ax, word [srData1]
    iretq

.miscDispatcher:
; ax = C500h -> Beep PC speaker
; ax = C501h -> Connect Debugger 
; ax = C502h -> Disconnect Debugger
    test al, al     ;Play a tone using PC speaker
    jz .mdBeeper
    cmp al, 01h     ;Connect Debugger
    jz .mdConnectDebugger
    cmp al, 02h     ;Disconnect Debugger
    jz .mdDisconnectDebugger
    jmp .badFunction
.mdConnectDebugger:
    push rax
    push rbx
    push rdx
    push rsi
    mov edx, 8F00h
    mov ebx, codedescriptor
    mov rax, MCP_int.singleStepsEP  ;Pointer
    mov rsi, 01 ;Interrupt number, Single Step
    call idtWriteEntry
    mov rax, MCP_int.debugEp  ;Pointer
    mov rsi, 03 ;Interrupt number, Software Breakpoint
    call idtWriteEntry
    mov rax, MCP_int.debugEpHardware  ;Pointer
    mov rsi, 3Bh ;Interrupt number, Invoke debugger through hardware CTRL+BREAK
    call idtWriteEntry
    jmp short .mdDebugExit
.mdDisconnectDebugger:
    push rax
    push rbx
    push rdx
    push rsi
    mov edx, 8F00h
    mov ebx, codedescriptor
    mov rax, i1  ;Pointer
    mov rsi, 01 ;Interrupt number, Single Step
    call idtWriteEntry
    mov rax, i3  ;Pointer
    mov rsi, 03 ;Interrupt number, Software Breakpoint
    call idtWriteEntry
    mov rax, ctrlbreak_io  ;Pointer
    mov rsi, 3Bh ;Interrupt number, CTRL+Break
    call idtWriteEntry
.mdDebugExit:
    pop rsi
    pop rdx
    pop rbx
    pop rax
    iretq

.mdBeeper:
;Input: 
;   bx = Frequency divisor to use for tone
;   rcx = # of ms to beep for
; All registers including ax preserved
    call beep
    iretq

.advSysMemDispatcher:
; ax = E800h -> Return userBase pointer
; ax = E801h -> Give RAM count, minus the size of SCPBIOS, in ax, bx, cx, dx.
; ax = E802h -> Total RAM count (without SCP/BIOS)
; ax = E820h -> Full Memory Map, including entry for SCPBIOS
    test al, al
    jz .retUserBase
    cmp al, 01h
    je .memory64MB
    cmp al, 02h
    je .memoryBIOSseg
    cmp al, 20h
    je .fullMemoryMap
    jmp .badFunction

.retUserBase:
    mov rax, qword [userBase]
    iretq
.memory64MB:
    mov ax, word [srData]
    mov bx, word [srData + 2]
    mov cx, word [srData + 4]
    mov dx, word [srData + 6]
    iretq    
.memoryBIOSseg:
;This gives information about the SCP/BIOS segment
    mov rax, BIOSStartAddr  ;Start address of BIOS
    xor ebx, ebx
    mov ebx, dword [scpSize]    ;Total sum of segment sizes
    mov rdx, qword [sysMem]     ;Get total usable memory count
    sub rdx, rbx    ;Remove SCP/BIOS allocation from the size
    iretq

.fullMemoryMap:
    mov rax, qword [userBase]    ;Start space, returns userbase in r8
    mov rsi, bigmapptr
    mov cl, byte [bigmapSize]   ;Get the number of 24 byte entries
    xor ch, ch                  ;Reserve the upper byte
    iretq

.sysDataTableDispatcher:
; ax = F000h, Register new GDT ptr
; ax = F001h, Register new IDT ptr
; ax = F002h, Get Current GDT ptr
; ax = F003h, Get Current IDT ptr
; ax = F004h, Register New Page Tables
; ax = F005h, Get physical address of PTables
; ax = F006h, Get pointer to BIOS Data Area
; ax = F007h, Read IDT entry
; ax = F008h, Write IDT entry
; ax = F009h, Register new Disk Parameter Table
; ax = F00Ah, Get current DPT
; ax = F00Bh, Register new Fixed Disk Parameter Table
; ax = F00Ch, Get current fDPT
; ax = F00Dh, Register new SysInit parameters 
; ax = F00Eh, Get current SysInit parameters
    cmp al, 4h          
    jb .sdtDT           ;al = 00 - 03, goto sdtDT
    cmp al, 4           
    jz .sdtRegisterPage ;al = 04
    cmp al, 5
    jz .sdtGetPagePtr   ;al = 05
    cmp al, 6
    jz .sdtDataptr      ;al = 06
    cmp al, 7
    jz .sdtReadIDTEntry ;al = 07
    cmp al, 8
    jz .sdtWriteIDTEntry    ;al = 08
    cmp al, 9
    jz .sdtNewDDP       ;al = 09
    cmp al, 0Ah
    jz .sdtReadDDP      ;al = 0A
    cmp al, 0Bh         
    jz .sdtNewfDDP      ;al = 0Bh
    cmp al, 0Ch
    jz .sdtReadfDDP     ;al = 0Ch
    cmp al, 0Dh
    jz .sdtNewSysInit   ;al = 0Dh
    cmp al, 0Eh
    jz .sdtReadSysInit  ;al = 0Eh
    jmp .badFunction

.sdtDT:
;sys data tables Descriptor Table dispatcher
;rbx has/will have I/GDT base pointer (qword)
;ecx has/will have I/GDT limit (word)
;edx has/will have Number of entries in I/GDT (word)
    push rdi
    push rsi
    mov rdi, GDTlength
    mov rsi, IDTlength
    test al, 1  ;If al[0] = 1, want rdi to point to IDT area
    cmovnz rdi, rsi ;If al[0] = 0, rdi will keep pointing to GDT
    test al, 2  ;If bit 2 is set, Get pointers
    jnz .sdtGet
    mov word [rdi], dx
    mov word [rdi + 2], cx
    mov qword [rdi + 4], rbx
    push rsi
    pop rdi
    iretq
.sdtGet:
    movzx edx, word [rdi]
    movzx ecx, word [rdi + 2]
    mov rbx, qword [rdi + 4]
    push rsi
    pop rdi
    iretq
.sdtRegisterPage:
    mov qword [pageTablePtr], rbx   ;Registers pointer as new table space
    iretq
.sdtGetPagePtr:
    mov rbx, qword [pageTablePtr]  ;Return BIOS Page Table ptr
    iretq
.sdtDataptr:
    mov rbx, section.data.start        ;Get BIOS Data area ptr into rax
    iretq
.sdtReadIDTEntry:
;bx = Number of interrupt handler (00h-0FFFFh), uses only bl
;Returns pointer in rbx, 
;Segment selector in ax,
;Attribute word in dx
    movzx rbx, bl
    mov rdx, qword [IDTpointer.Base]    ;Get base address
    shl rbx, 4h         ;Multiply address number by 16
    add rdx, rbx        ;rdx point to IDT entry
    mov eax, dword [rdx + 8]
    shl rax, 20h        ;Shift dword into upper dword
    mov bx, word [rdx + 6]
    shl ebx, 10h        ;Shift word into upper word
    mov bx, word [rdx]  ;Get final word
    or rbx, rax         ;Add upper dword to rbx
    mov ax, word [rdx + 2]  ;Get Segment selector in ax
    mov dx, word [rdx + 4]  ;Get attributes word
    iretq
.sdtWriteIDTEntry:
;rbx = Pointer to new routine
;cx = Number of the interrupt handler (00h-0FFFFh), uses only cl
;dx = IDT entry attributes
;si = Segment selector
    push rax
    push rcx
    push rsi
    push rbx
    mov rax, rbx    ;Move pointer to new routine to rax
    mov ebx, esi    ;Move Segment selector from si to bx 
    movzx rsi, cl   ;Movzx low byte of interrupt number into rsi
    call idtWriteEntry
    pop rbx
    pop rsi
    pop rcx
    pop rax
    iretq
.sdtNewDDP:
    mov qword [diskDptPtr], rbx
    iretq
.sdtNewfDDP:
    mov qword [fdiskDptPtr], rbx
    iretq
.sdtReadDDP:
    mov rbx, qword [diskDptPtr]
    iretq
.sdtReadfDDP:
    mov rbx, qword [fdiskDptPtr]
    iretq
.sdtNewSysInit:
    mov qword [nextFilePtr], rbx
    mov word [numSectors], dx
    iretq
.sdtReadSysInit:
    mov rbx, qword [nextFilePtr]
    mov dx, word [numSectors]
    iretq
.ehciFunctionDispatcher:
;EHCI function dispatcher 0F1h
; al = 00h -> EHCI get crit error handler
; al = 01h -> EHCI set crit error handler
; al = 02h -> Reserved, reset selected EHCI controller
; al = 03h -> Reserved, re-enumerate devices downstream of EHCI Root hub
    test al, al
    jz .ehciDispGetCritPtr
    dec al
    jz .ehciDispSetCritPtr
    dec al
    jz .ehciDispResetCtrlr
    dec al
    jz .echiDispReEnumDevices
    jmp .badFunction

.ehciDispGetCritPtr:
;Gets the address of the current EHCI critical error handler into rbx
    mov rbx, qword [eHCErrorHandler]
    iretq
.ehciDispSetCritPtr:
;Sets the address of the EHCI critical error handler to the ptr in rbx
    mov qword [eHCErrorHandler], rbx
    iretq
.ehciDispResetCtrlr:
.echiDispReEnumDevices:
    mov ah, 86h     ;Unsupported function call
    jmp .badout  
;------------------------End of Interrupt------------------------
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
;------------------------Printer Int 37h-------------------------
; Reserved for printer specific functions. Both USB and Parallel.
; Not currently supported
;----------------------------------------------------------------
printer_io:
    mov ah, 86h    ;Function not supported
    or byte [rsp+ 2*8h], 1    ;Set carry
    iretq
;------------------------End of Interrupt------------------------
;---------------------MCP Interrupt Int 38h----------------------
;This interrupt superceeds the IBM BASIC routine caller. 
;This is a 64 bit port of my 16 bit MCP monitor program, 
; allowing users to "interactively" get sectors from devices 
; and run them. I might add some nicities to this version of MCP 
; such as a function to list all devices.
;----------------------------------------------------------------
MCPjmptbl:  ;Function jump table
    dq MCP_int.dumpMemory      ;Dump
    dq MCP_int.editMemory      ;Edit
    dq MCP_int.singleStep      ;Single step
    dq MCP_int.jumpProc        ;Go
    dq MCP_int.proceedDefault  ;Proceed
    dq MCP_int.storageRead     ;Load
    dq MCP_int.storageWrite    ;Write
    dq MCP_int.restartMcp      ;Quit   <- To call Int 40h for DOS compatibility
    dq MCP_int.clearscreen     ;Clear screen
    dq MCP_int.xchangeReg      ;Registers
    dq MCP_int.debugRegs       ;Breakpoints
    dq MCP_int.hexCalc         ;Hex
    dq MCP_int.inport          ;In
    dq MCP_int.outport         ;Out
    dq MCP_int.version         ;Version
    dq MCP_int.singleStep      ;Single Step (Alt), temp
    dq MCP_int.memoryMap       ;Print memory map
    dq MCP_int.connect         ;Connect Debugger
    dq MCP_int.disconnect      ;Disconnect Debugger
MCP_int:
    ;Entry point from external programs
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters    ;Save main registers
.z11:
    mov rsp, qword [mcpStackPtr]  ;Point sp to new stack
    mov eax, 1304h    ;Zero extends to rax
    mov rbp, .prompt
    xor bh, bh
    int 30h
.z2:
    xor ax, ax 
    int 36h
    cmp al, 08h        ;If backspace, ignore
    je .z2
    call .print        ;Print input char
    std
    mov rdi, .prompt    ;end of lst is prompt
    mov rcx, .lstl + 1
    repne scasb
    cld
    jne .bad_command    ;Char not found!
.prog_sel:    ;Choose program
    push MCP_int.z11    ;to allow RETurning to application
    jmp qword [MCPjmptbl + 8*rcx]    ;Jump to chosen function         
.memoryMap:
    mov ax,0E0Ah
    int 30h
    mov ax, 0E0Dh
    int 30h
    call e820print  ;Print memory map
    jmp .z11
.singleStepsEP:
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters
    mov rax, qword [rsp]    ;Get next instruction address
    mov qword [mcpUserRip], rax
    call .dumpReg    ;Show register state
    call .dumpDebugRegs
    sti ;Restore interrupts
    jmp .z11
.debugEpHardware:
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters
    sti ;Restore interrupts
    mov al, EOI
    out pic1command, al
    jmp short .dep1
.debugEp:    
;Return here after a single step or int 3. 
;Support Int 3h thru manual encoding only, not via the debugger
    mov qword [mcpUserRaxStore], rax
    mov rax, qword [mcpUserBase]
    mov qword [rax + 08h], rsp
    call .storeMainRegisters
    sti ;Restore interrupts
.dep1:
    mov rax, qword [rsp]    ;Get next instruction address
    mov qword [mcpUserRip], rax
    call .dumpReg    ;Show register state
    call .dumpDebugRegs
    jmp .z11
.bad_command:
    mov rax, 1304h
    xor bh, bh
    mov rbp, .bc1
    int 30h
    jmp MCP_int.z11
.bc1: db 0Ah,0Dh," ^ Error",0
;><><><><><><><-Internal Commands Begin Here-><><><><><><><
.connect:
    push rax
    push rbp
    mov eax, 0C501h ;Connect Debugger
    int 35h
    mov eax, 1304h
    mov rbp, .connectString
    int 30h
    pop rbp
    pop rax
    ret
.connectString db 0Ah,0Dh,"SYSDEBUG Connected",0
.disconnect:
    push rax
    push rbp
    mov eax, 0C502h ;Disconnect Debugger
    int 35h
    mov eax, 1304h
    mov rbp, .disconnectString
    int 30h
    pop rbp
    pop rax
    ret
.disconnectString db 0Ah,0Dh,"SYSDEBUG Disconnected",0
.version:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .vstring
    int 30h
    mov rsi, signature + 1    ;Point to BIOS signature string (skip the v char)
.v1:
    lodsb
    cmp al, 20h            ;Check space
    je .v2
    mov ah, 0Eh
    ;xor bh, bh
    int 30h
    jmp short .v1
.v2:
    ret
.vstring:    db 0Ah, 0Dh,"SCP/BIOS SYSDEBUG Version ",0
.debugRegs:
    call .dumpDebugRegs
    mov ax, 1304h
    mov rbp, .crlf    ;Newline
    int 30h

    mov ax, 0E2Eh    ;Print dot byte
    int 30h

    mov ax, 0101h    ;Process one byte
    call .keyb
    test rbp, rbp
    jz .z11    ;If enter pressed, return to command line
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rdi, qword [rbp]
    cmp rdi, 4
    jb .xr11    ;Cant edit dr4, or 5. dr6 is read only
    cmp rdi, 7  ;Can only edit 7
    jne .bad_command
    dec rdi     ;Is the fifth entry in the table
    dec rdi
.xr11:
    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h

    push rdi    ;Save rdi
    shl rdi, 2    ;Multiply by 4
    mov cx, 4    ;4 chars to print
.xr1:   ;Print register name
    mov al, byte [.dregtbl + rdi]
    mov ah, 0Eh
    int 30h
    inc di
    dec cx
    jnz .xr1
;Get the qword into the keybuffer
    pop rdi
    mov ax, 0401h    ;Process one qword
    call .keyb
    test rbp, rbp
    jz .xcnoexit
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rax, qword [rbp]    ;rax has the replacement value
    test rdi, rdi
    jnz .xr2
    mov dr0, rax
    ret
.xr2:
    dec rdi
    jnz .xr3
    mov dr1, rax
    ret
.xr3:
    dec rdi
    jnz .xr4
    mov dr2, rax
    ret
.xr4:
    dec rdi
    jnz .xr5
    mov dr3, rax
    ret
.xr5:
    mov dr7, rax
    ret

.dumpDebugRegs:
    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h
    xor rbp, rbp
    xor rdi, rdi

    mov rax, dr7
    push rax
    mov rax, dr6
    push rax
    mov rax, dr3
    push rax
    mov rax, dr2
    push rax
    mov rax, dr1
    push rax
    mov rax, dr0
    push rax

.ddr1:
    xor rcx, rcx
    cmp rdi, 3      ;3 registers per row
    je .dregcrlf
.ddr11:
    mov al, byte [.dregtbl + rbp + rcx]
    mov ah, 0Eh
    int 30h
    inc cx
    cmp cx, 4
    jnz .ddr11

    mov rcx, 8
.ddr2:
    pop rbx    ;Get debug register
    bswap rbx
.ddr21:
    mov ah, 04h
    mov al, bl
    int 30h
    shr rbx, 8h
    dec cl
    jnz .ddr21
    inc rdi

    mov ah, 3
    int 30h
    add dl, 3
    mov ah, 2
    int 30h
    add rbp, 4
    cmp rbp, 24 ;number of chars in the below typed string
    jb .ddr1

    ret
.dregcrlf:
    xor rdi, rdi
    push rbp
    push rax
    push rbx
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    pop rbx
    pop rax
    pop rbp
    jmp .ddr11
.dregtbl db "DR0=", "DR1=", "DR2=", "DR3=", "DR6=", "DR7="

.xchangeReg:
    call .dumpReg
    mov ax, 1304h
    mov rbp, .crlf    ;Newline
    int 30h

    mov ax, 0E2Eh    ;Print dot byte
    int 30h

    mov ax, 0101h    ;Process one byte
    call .keyb
    test rbp, rbp
    jz .z11    ;If enter pressed, return to command line
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rdi, qword [rbp]    ;move this byte into rdi
    cmp rdi, 11h
    ja .bad_command    ;If the user chooses a value greater than 11, exit!

    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h

    cmp rdi, 11h
    je .xcflags ;If the user typed 10, then xchange flags

    push rdi    ;Save rdi
    shl rdi, 2    ;Multiply by 4
    mov cx, 4    ;4 chars to print
.xcr1:
    mov al, byte [.regtbl + rdi]
    mov ah, 0Eh
    int 30h
    inc di
    dec cx
    jnz .xcr1

    pop rdi
    mov ax, 0401h    ;Process one qword
    call .keyb
    test rbp, rbp
    jz .xcnoexit
    call .arg
    cmp al, 1
    jne .dmbadexit

    mov rax, qword [rbp]
    cmp rdi, 10h
    je .xcipchange
    mov rbx, qword [mcpUserBase]
    add rbx, 80h
    shl rdi, 3  ;Multiply by 8
    sub rbx, rdi
    mov qword [rbx], rax    ;Replace element with rax
.xcnoexit:
    ret
.xcipchange:
    mov qword [mcpUserRip], rax
    ret
.xcflags:
    mov rcx, 7
    xor rdi, rdi
.xcf1:
    mov al, byte [.rflgs + rdi]
    mov ah, 0Eh
    int 30h
    inc di
    dec cx
    jnz .xcf1

    mov ax, 0401h    ;Process one qword
    call .keyb
    test rbp, rbp
    jz .xcnoexit
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rax, qword [rbp]
    mov rbp, qword [mcpUserBase]
    mov qword [rbp], rax
    ret
.inport:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h

    mov ax, 0101h    ;Get 1 byte
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rdx, qword [rbp]    ;First arg, word io addr
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    in al, dx
    mov ah, 04h
    int 30h
    ret

.outport:
    mov ax, 1304h
    mov rbx, 7h
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0201h    ;Get 1 word
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rdx, qword [rbp]    ;First arg, word io addr
    mov al, "."
    call .print
    mov ax, 0101h    ;Get 1 byte
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg
    cmp al, 1
    jne .dmbadexit
    mov rax, qword [rbp]
    out dx, al
    ret

.hexCalc:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0402h    ;Get 2 qwords
    call .keyb
    test rbp, rbp
    jz .bad_command
    call .arg

    cmp al, 2
    jne .dmbadexit

    mov r8, qword [rbp + 8] ;First number 
    mov r9, qword [rbp]        ;Second number
    lea r10, qword [r8+r9]

    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h

    mov rdx, r8
    call .hcprintquad
    mov al, "+"
    call .print
    mov rdx, r9
    call .hcprintquad
    mov al, "="
    call .print
    mov rdx, r10
    call .hcprintquad

    mov rax, 1304h
    xor bh, bh
    int 30h

    mov rdx, r8
    call .hcprintquad
    mov al, "-"
    call .print
    mov rdx, r9
    call .hcprintquad
    mov al, "="
    call .print
    sub r8, r9
    mov rdx, r8
    call .hcprintquad
    ret

.hcprintquad:
;Takes whats in rdx, and prints it
    bswap rdx
    mov rcx, 8
.hcpq1:
    mov al, dl
    mov ah, 04h
    int 30h
    shr rdx, 8
    dec cx
    jnz .hcpq1
    ret

.dumpReg:
    mov rbp, .crlf
    mov ax, 1304h
    xor bh, bh
    int 30h
    xor rbp, rbp
    xor rdi, rdi
    xor rsi, rsi
    mov rsi, qword [mcpUserBase]
    add rsi, 80h
.dreg1:
    xor rcx, rcx
    cmp rdi, 3
    je .regcrlf
.dreg11:    ;Print register name
    mov al, byte [.regtbl+rbp+rcx]
    mov ah, 0Eh
    int 30h
    inc cx
    cmp cx, 4h
    jnz .dreg11
.dreg2:
    mov rcx, 8h
;Now print register value
    mov rbx, qword [rsi]    ;Get qword from storage
    sub esi, 8
    bswap rbx    ;Change endianness
.dreg21:
    mov ah, 04h
    mov al, bl
    int 30h
    shr rbx, 8h    ;Shift down by a byte
    dec cl
    jnz .dreg21
    inc rdi

    mov ah, 3
    int 30h
    add dl, 3
    mov ah, 2
    int 30h
    add rbp, 4
    cmp rbp, 40h
    jb .dreg1

;Print RIP
.drip0:
    xor rcx, rcx
.drip1:
;Print name
    mov al, byte [.regtbl+rbp+rcx]
    mov ah, 0Eh
    int 30h
    inc cx
    cmp cx, 4h
    jne .drip1

    mov rcx, 8
    mov rsi, qword [mcpUserRip]
    bswap rsi
.drip2:
;Print value
    mov ah, 04h
    mov al, sil
    int 30h
    shr rsi, 8h    ;Shift down by a byte
    dec cl
    jnz .drip2
    add rbp, 4    ;Offset into table

    push rbp
    mov rbp, .ipstrg
    mov ax, 1304h
    int 30h    
    mov cl, 7
    mov rax, qword [mcpUserBase]
    mov rax, qword [rax + 08h]  ;Get the old stack pointer
    mov rbx, qword [rax]    ;Get the address of 8 bytes at that instruction
    mov rbx, qword [rbx]    ;Get the bytes
    mov al, bl
    mov ah, 04h
    int 30h
    shr rbx, 8
    mov ah, 0Eh   ;Add a space to indicate mod r/m + optionals
    mov al, '-'
    int 30h
.ssep0:
    mov al, bl
    mov ah, 04h
    int 30h
    shr rbx, 8
    dec cl
    jnz .ssep0

    mov rbp, .crlf
    mov rax, 1304h
    mov rbx, 7h
    int 30h
    pop rbp

    mov ax, cs
    call .dsegregwrite
    mov ax, ds
    call .dsegregwrite
    mov ax, es
    call .dsegregwrite
    mov ax, ss
    call .dsegregwrite
    mov ax, fs
    call .dsegregwrite
    mov ax, gs
    call .dsegregwrite

    push rbp
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    pop rbp
.drflagwrite:
    xor rcx, rcx
.drflg1:    ;Print register name
    mov al, byte [.regtbl+rbp+rcx]
    mov ah, 0Eh
    int 30h
    inc rcx
    cmp rcx, 7
    jnz .drflg1

    inc rcx
    mov rdx, qword [mcpUserBase]    ;Get flags into rdx
    mov rdx, qword [rdx]
    bswap rdx
.drflg2:
    mov ah, 04h
    mov al, dl
    int 30h
    shr rdx, 8
    dec rcx
    jnz .drflg2

.dregexit:
    ret
.dsegregwrite:
    xor rcx, rcx
    mov dx, ax    ;save
.dsegreg1:    ;Print register name
    mov al, byte [.regtbl+rbp+rcx]
    ;xor bh, bh
    mov ah, 0Eh
    int 30h
    inc rcx
    cmp rcx, 3
    jnz .dsegreg1

    mov al, dh
    mov ah, 04h
    int 30h
    mov al, dl
    mov ah, 04h
    int 30h

    add rbp, rcx
    mov ah, 3
    int 30h
    add dl, 2
    mov ah, 2
    int 30h
    ret

.regcrlf:
    xor rdi, rdi
    push rbp
    push rax
    push rbx
    mov rbp, .crlf
    mov rax, 1304h
    xor bh, bh
    int 30h
    pop rbx
    pop rax
    pop rbp
    jmp .dreg11

.regtbl  db "RAX=", "RBX=", "RCX=", "RDX=", "RSI=", "RDI=", "R8 =",
         db "R9 =", "R10=", "R11=", "R12=", "R13=", "R14=", "R15=",
         db "RBP=", "RSP=", "RIP=","CS=", "DS=", "ES=", "SS=", "FS=", 
         db "GS="
.rflgs   db "RFLAGS="
.ipstrg: db "  [RIP]=",0
.dumpMemory:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push rsi
    push rbp
    push r8
    push r9

    mov ax, 1304h
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0402h    ;Get 2 dwords
    call .keyb
    test rbp, rbp
    jz .dmnoargs
    mov al, 2    ;Number of user inputs to convert
    call .arg
    dec al
    jz .dmnoargs1
    dec al    ;More than 2 args, error
    jnz .dmbadexit
    mov r8, qword [rbp + 8]    ;First argument, #Base
    mov r9, qword [rbp]    ;Second argument, #Number of bytes
.dmmain00:
    test r9, r9
    jz .dmbadexit
    mov ax, 1304h
    mov rbp, .crlf
    int 30h
    mov rdx, r8
    call .dmcsaddrprint
    xor bh, bh
    mov ah, 03h
    int 30h
    mov dl, 25
    mov ah, 02h
    int 30h
    mov rsi, r8    ;point rsi at r8
    test rsi, 08h    ;If it starts between a qword and para

    test rsi, 0Fh
    jz .dmmain0    ;If it starts on paragraph bndry, continue as normal
    push rsi
    and rsi, 0Fh
    cmp rsi, 8
    jb .dmmain01
    mov rcx, 1
    call .dmal1    ;Print one space
.dmmain01:
    pop rsi
    mov rax, 1
    call .dmalign

.dmmain0:
    mov rdi, rsi    ;Save start point at rdi
    push r9
.dmmain1:    ;This loop prints a line
    lodsb
    mov ah, 4h
    int 30h
    dec r9
    jz .dmmain2
    test rsi, 08h    ;This is zero iff rsi has bit 4 set
    jnz .dmhyphen1
    test rsi, 0Fh    ;This is zero iff lower nybble is zero
    jnz .dmmain1
.dmmain2:
;Now the numbers have been printed, get the ascii row too
;First check if numbers have stopped short of 16
    test r9, r9
    jnz .dmmain21    ;end of row

.dmmain21:
    pop r9
    xor bh, bh
    mov ah, 03h
    int 30h
    mov dl, 62
    mov ah, 02h
    int 30h
    mov rsi, rdi    ;Reload value
    test rsi, 0Fh
    jz .dmmain3    ;If it starts on paragraph bndry, continue as normal
    xor rax, rax    ;no shift
    call .dmalign

.dmmain3:
    lodsb
    dec r9
    cmp al, 30h
    cmovb ax, word [.dmdot]    ;bring the dot to ax
    mov ah, 0Eh
    int 30h
    test r9, r9
    jz .dmexit
    test rsi, 0Fh    ;Check if lower nybble is 0
    jnz .dmmain3

    mov rbp, .crlf
    mov ax, 1304h
    int 30h

    mov rdx, rsi
    call .dmcsaddrprint

    mov ah, 03h
    xor bh, bh
    int 30h
    mov dl, 25
    mov ah, 02h
    int 30h
    jmp .dmmain0

.dmbadexit:
    mov rbp, .dmbadargs
    mov ax, 1304h
    int 30h
    ret;Reload program, error!
.dmexit:
    pop r9
    pop r8
    pop rbp
    pop rsi
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret
.dmnoargs:
    mov r8, qword [mcpUserRip]
    ;add r8, 180h    ;Add 180 bytes, to bypass internal work areas
    jmp short .dmnoargscommon
.dmnoargs1:
    mov r8, qword [rbp]
.dmnoargscommon:
    mov r9, 80h
    jmp .dmmain00

.dmalign:    ;Print blank chars for offset
;Works out from rsi
;rax contains value for shl
    push rsi
    mov rcx, rsi
    and rcx, 0FFFFFFFFFFFFFFF0h    ;Round down
    sub rsi, rcx
    xchg rcx, rsi
    pop rsi
    xchg rcx, rax
    shl rax, cl
    xchg rcx, rax
.dmal1:
    mov ax, 0E20h
    int 30h
    dec rcx
    jnz .dmal1
    ret

.dmhyphen1:
    test rsi, 07h    ;If the rest of the bits are set, go away
    jnz .dmmain1
    mov ax, 0E2Dh    ;2dh="-"
    int 30h
    jmp .dmmain1
.dmcsaddrprint:
    mov ax, cs    ;Get current code segment into ax
    mov al, ah
    mov ah, 04h    ;print upper byte
    int 30h
    mov ax, cs
    mov ah, 04h
    int 30h        ;print lower byte
    mov ax, 0E3Ah

    mov cl, 8
    int 30h

.dmrollprint:
;Takes whats in rdx, rols left by one byte, prints al
;repeats, cl times.
    rol rdx, 8
    mov al, dl
    mov ah, 04h
    int 30h
    dec cl
    jnz .dmrollprint
    ret
.dmdot:    db    ".",0
.dmbadargs:    db 0Ah, 0Dh,"Syntax error",0

.editMemory:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h

    mov ax, 0401h    ;Get up to one qword
    call .keyb
    test rbp, rbp        ;No chars entered?
    jz .bad_command
    call .arg
    mov rdi, qword [rbp]    ;First arg, Dword Address 

    mov rbp, .crlf
    xor bh, bh
    mov rax, 1304h
    int 30h
    
    mov rsi, rdi
    lodsb    ;Get byte into al
    mov ah, 04
    int 30h
    mov al, "."
    call .print
    mov ax, 0101h    ;Get 1 byte
    call .keyb
    test rbp, rbp        ;No chars entered?
    jz .dmbadexit
    call .arg
    mov rsi, rbp    ;Point rsi to the stack
    movsb            ;Move byte from rsi to rdi

    ret

.jumpProc:
    mov ax, 1304h
    xor bh, bh
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h
    mov ax, 0401h    ;Get 1 dword (forbit going too high eh?)
    call .keyb
    test rbp, rbp        ;No chars entered?
    jz .proceedDefault
    call .arg
    dec al
    jnz .dmbadexit
    mov rbp, qword [rbp]    ;First argument, Address of procedure
    mov qword [mcpUserRip], rbp   ;Move first argument into new Rip  
    call .loadMainRegisters
    mov rsp, qword [rax + 08h]
    mov rax, qword [mcpUserRaxStore]
    iretq
.singleStep:
;When s is pressed, the program proceeds by a single step.
;Sets trap flag on
    mov rax, qword [mcpUserBase]
    or qword [rax + 00h], 100h  ;Set trap flag on
.proceedDefault:
    call .loadMainRegisters
    mov rsp, qword [rax + 08h]
    mov rax, qword [mcpUserRaxStore]
    iretq

.storageRead:
    push rax
    mov eax, 8200h ;LBA Read function
    jmp short .storageCommon
.storageWrite:
    push rax
    mov eax, 8300h ;LBA Write function
.storageCommon:
;l/w [Address Buffer] [Drive] [Sector] [Count]
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp

    mov esi, eax        ;Save LBA r/w function number in esi
    mov ax, 1304h
    mov rbp, .prompt2    ;Give the user the prompt
    int 30h

    mov ax, 0404h    ;Get 4 qwords
    call .keyb
    test rbp, rbp
    jz .storageError
    mov al, 4    ;Number of user inputs to convert
    call .arg
    cmp al, 4   ;If not 4 arguments, fail
    jne .storageError
    mov edi, 5
.sc0:
    mov eax, esi                ;Get back LBA r/w function number into eax
    mov rbx, qword [rbp + 24]   ;First argument, Address buffer
    mov rdx, qword [rbp + 16]   ;dl ONLY, Second argument
    and rdx, 0FFh
    mov rcx, qword [rbp + 08]   ;LBA starting sector, third argument
    mov rsi, qword [rbp]        ;Sector count into rsi
    and rsi, 0FFh               ;Sector count can be at most 255
    or eax, esi                 ;Add the sector count to eax
    mov esi, eax                ;Copy the function number into esi for failures
    and esi, 0FF00h             ;Save only byte two of esi, the function number
    int 33h
    jnc .storageExit

    xor eax, eax
    int 33h
    dec edi
    jnz .sc0
.storageExit:
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax   
    jmp MCP_int.z11
.storageError: 
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    jmp .bad_command
.restartMcp:
    int 40h     ;To allow returning to DOS
.clearscreen:
    mov bl, 07h
    call cls
    jmp MCP_int.z11
.storeMainRegisters:
    pushfq
    pop qword [rax + 00h]      ;Flags
    ;mov qword [rax + 08h], rsp
    mov qword [rax + 10h], rbp
    mov qword [rax + 18h], r15
    mov qword [rax + 20h], r14
    mov qword [rax + 28h], r13
    mov qword [rax + 30h], r12
    mov qword [rax + 38h], r11
    mov qword [rax + 40h], r10
    mov qword [rax + 48h], r9
    mov qword [rax + 50h], r8
    mov qword [rax + 58h], rdi
    mov qword [rax + 60h], rsi
    mov qword [rax + 68h], rdx
    mov qword [rax + 70h], rcx
    mov qword [rax + 78h], rbx
    mov rbx, qword [mcpUserRaxStore]
    mov qword [rax + 80h], rbx  ;Store rax
    ret
.loadMainRegisters:
    mov rax, qword [mcpUserBase]
    mov rdx, qword [rax + 08h]  ;Get old stack pointer into rdx
    mov rbx, qword [mcpUserRip]
    mov qword [rdx], rbx    ;Move the userRip into rdx
    mov rbx, qword [rax + 00h]
    mov qword [rdx + 10h], rbx  ;Move new flags into position on stack
    mov rbx, qword [rax + 78h]
    mov rcx, qword [rax + 70h]
    mov rdx, qword [rax + 68h]
    mov rsi, qword [rax + 60h]
    mov rdi, qword [rax + 58h]
    mov r8,  qword [rax + 50h]
    mov r9,  qword [rax + 48h]
    mov r10, qword [rax + 40h]
    mov r11, qword [rax + 38h]
    mov r12, qword [rax + 30h]
    mov r13, qword [rax + 28h]
    mov r14, qword [rax + 20h]
    mov r15, qword [rax + 18h]
    mov rbp, qword [rax + 10h]
    ret
;ARG    PROC    NEAR
.arg:
;Number of arguments expected in buffer in al (could early terminate due to 
; enter)
;Converted qwords stored on stack with al indicating how many processed
;rbp returns the base of the stack of stored arguments
;rdx is our scratch register
    push rbx
    push rcx
    push rdx
    push rsi
    mov rbp, rsp    ;Preserve stack pointer
    mov rsi, qword [mcpUserkeybf]
    xor cl, cl        ;Keep track of how many arguments processed
.a01:
    xor rdx, rdx    ;Clean rdx
.a1:
    lodsb        ;Get the first byte into al
    cmp al, 11h    ;Offset 11h is the space key
    jz .a2
    cmp al, 12h    ;Offset 12h is the enter key
    jz .aexit        ;Anyway, enter is exit!
    shl rdx, 4    ;Go to next sig fig
    or dl, al    ;Put this byte into dl
    jo .error
    jmp short .a1
.a2:
    push rdx    ;Store argument on stack
    inc cl        ;One more argument processed
    jmp short .a01
.aexit:
    movzx rax, cl    ;Return #of args processed
    xchg rsp, rbp    ;rbp points to bottom of argument stack 
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
.error:
    mov rbp, .emsg
    xor bh, bh
    mov ax, 1304h
    int 30h
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    ret
.emsg:    db 0Ah, 0Dh,"Argument error",0
;ARG    ENDP

;KEYB     PROC     NEAR
.keyb:
;Number of arguments to accept is passed in al, in units of ah
;ah=4 => Qwords, ah=3 => dwords... ah=2 => word, ah=1 => bytes
;Arguments are stored in buffer, after USB area, of size 2*al qwords
;All arguments CAN be up to qword in size, though not all subprogs,
;    may use the full qword.
;ch returns number of chars not processed
    push rax
    push rbx
    ;push rcx
    push rdi
    push rdx

    xor rcx, rcx
    mov cl, al
    push rcx
    mov cl, ah
    shl al, cl  ;Multiply by 16 to get the number of bytes needed w/o spaces
    pop rcx
    add al, cl  ;Add space for spaces
    dec al      ;We reserve one space for a "non-user accessible" EOL at the end

    mov rdi, qword [mcpUserkeybf]    ;Data area in command tail
    push rax
    mov rax, 10h
    push rdi
    rep stosq    ;Clear buffer space for al qwords (max 8)
    pop rdi
    pop rax

    mov ch, al    ;Rememebr 1 Qword is 16 ASCII chars
    mov dl, al    ;Let dl save this number
    xor rbp, rbp    ;Cheap cop out char counter

.k1:
    xor ax, ax
    int 36h
    cmp al, "q"    ;Quit option
    je .z11
    cmp al, 08h    ;Backspace
    je .kb2
    cmp al, 0Dh    ;Enter key pressed, we done
    je .kend

    test ch, ch    ;Have we filled a 16 char buffer?
    jz .k1        ;Yes, await control key

    mov rbx, rdi    ;Save current offset into bbuffer
    push rcx
    mov rdi, .ascii
    mov rcx, .asciil
    repne scasb        ;Find the offset of the char in al in the table
    pop rcx            ;Doesnt affect flags
    xchg rdi, rbx    ;Return value back to rdi 
    jne .k1            ;Not a key from our buffer, loop again
    inc rbp
    call .print        ;Print typed char

    lea rax, qword [rbx - .ascii -1]    ;Work out difference

    stosb            ;Store the value in storage buffer, inc rdi
    dec ch            ;Decrement the number of typable chars
    jmp short .k1    ;Get next char
.kend:
    mov ax, 1211h    ;Store a space and EOF at the end (little endian!)
    stosw

    pop rdx
    pop rdi
    ;pop rcx    ;Return in cl the number of processed chars
    pop rbx
    pop rax
.kb1:        
    ret
.kb2:
;When a backspace is entered, DONT MOVE THIS PROC!
    push .k1
    cmp ch, dl    ;If bbuf is empty, ignore backspace 
    jz .kb1
    dec rdi        ;Decrement pointer and print the bspace char
    inc ch        ;Increment the number of typable chars
    test rbp, rbp
    jz .print    ;Dont decrement if rbp is zero
    dec rbp
;KEYB    ENDP
.print:    ;Print char in al
    mov ah, 0Eh
    ;xor bh, bh
    int 30h
    ret
.ascii       db    "0123456789abcdef", 08h, 20h, 0Dh ;b/space, enter
.asciil       equ    $ - .ascii
.lst       db    'desgplwqcrbhiovamkx';dump,edit,go,single step,read,write,quit,
;clearscreen,registers,deBug regs,hex,in,out,version,Single Step alt, memory map
; (k)connect, dixonnect
.lstl    equ    $ - .lst
.prompt       db    0Ah, 0Dh, "-", 0    ;3Eh = >
.prompt2    db 20h,0
.crlf       db    0Ah, 0Dh, 0
;------------------------End of Interrupt------------------------
;-------------------Restart Interrupt Int 39h--------------------
;This interrupt allows the user to soft reboot
;----------------------------------------------------------------
bootstrapInt:
;Bootstrap loader, loads sector 88 of device 0 to 7C00h and jumps to it
;If not found, will restart the machine, failing that, iretq with CF set
    push rax
    push rbx
    push rcx
    push rdx
    push rsi

    mov ecx, 0C0000100h    ;Select fs register to load base addr
    mov rax, qword [userBase]    ;Load address to fs
    xor edx, edx        ;Zero upper bytes
    wrmsr                ;Write msr to load fs base

    mov esi, 10
;Now load one sector of second prog from first device 
.e0:
    xor dx, dx  ;This also clears carry flag so no checking ah
    mov rbx, 7c00h
    mov rcx, qword [nextFilePtr]
    mov ax, word [numSectors]
    mov ah, 82h ;LBA Sector Read 
    int 33h     ;Read one sector
    jnc .e1

    dec esi
    jz .efail

    xor dl, dl
    xor ah, ah  ;Reset the device
    int 33h
    jmp short .e0
.e1:
    xor edx, edx  ;Device number 0!
    cmp word [7c00h], 0AA55h ;The Boot signature
    jne .efail
;State when system transferred:
; RSP = DFF8h, 1FFh qword stack from DFFFh to 7C00H + 42*200h sectors = D000h
; FS MSR = userbase pointer, can be used for segment override.
; DX = Int 33h boot device number
; RBX = LBA of first Logical Block after SCP/BIOS
; BDA and BIOS ready to go
    mov rsp, 0DFF8h ;Move Stack pointer to default init stack position
    xor edx, edx    ;Device boot number
    mov rbx, qword [nextFilePtr]     ;First sector on device after SCP/BIOS
    jmp 7C02h       ;New sector entry point
.efail:
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    or byte [rsp + 2*8h], 1 ;Set carry flag
    iretq
;------------------------End of Interrupt------------------------
;-----------------System Timer Interrupt Int 3Ah-----------------
;System Timer functions:
; ah=0 -> Get tick count
; ah=1 -> Set tick count
; ah=2 -> Read RTC time
; ah=3 -> Set RTC time
; ah=4 -> Read RTC date
; ah=5 -> Set RTC date
; ah=6 -> Set RTC alarm
; ah=7 -> Reset RTC alarm
; ah=80h -> Get PIT divisor
; ah=81h -> Set PIT divisor
;----------------------------------------------------------------
timerInt:
    cmp ah, 80h
    jae .tiext
    test ah, ah
    jz .gett
    cmp ah, 1
    jz .sett
    cmp ah, 2
    jz .readRTCtime
    cmp ah, 3
    jz .setRTCtime
    cmp ah, 4
    jz .readRTCdate
    cmp ah, 5
    jz .setRTCdate
    cmp ah, 6
    jz .setRTCalarm
    cmp ah, 7
    jz .resetRTCalarm
.bad:
    or byte [rsp + 2*8h], 1    ;Set Carry flag on for invalid function
    mov ah, 80h
.exit:
    iretq
.gett:
;Returns:
; al=Rolled over flag (0=not rolled)
; cx=Hi count
; dx=Lo count
    mov eax, dword [pit_ticks]
    mov dx, ax    ;Lo count
    shr eax, 10h    ;Bring high word down
    xor ch, ch
    mov cl, al
    mov al, ah
    movzx eax, al    ;Zero upper bytes
    mov byte [pit_ticks + 3], ah    ;Move 0 into day OF counter
    iretq
.sett:
;Called with:
; cx=Hi count (bzw. cl)
; dx=Lo count
;Returns: Nothing
    mov word [pit_ticks], dx
    xor ch, ch    ;Reset the OF counter
    mov word [pit_ticks + 2], cx
    iretq

.tiext:    ;Extended Timer functions
    sub ah, 80h
    jz .getpitdiv
    dec ah
    jz .setpitdiv
    jmp short .bad
.getpitdiv:
;Returns:
; ax=PIT divisor
    mov ax, word [pit_divisor]
    iretq
.setpitdiv:
;Called with:
; dx=divsor
;Returns: Nothing
    mov word [pit_divisor], dx
    push rax
    mov al, 36h ;Bitmap for frequency write to channel 0 of PIT
    out PITcommand, al
    mov ax, dx
    out PIT0, al    ;Send low byte of new divisor
    mov al, ah
    out PIT0, al    ;Send high byte of new divisor
    pop rax
    iretq

.readRTCtime:
; dh = Seconds
; cl = Minutes
; ch = Hours
; dl = Daylight Savings   
    push rax
    push rcx
    xor ecx, ecx    ;Long counter
.rrt0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah ;Disable NMI and and read bit 7. When 0, read
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .rrt0   ;If zero, fall and read RTC registers

    pop rcx         ;Pop upper word of ecx back
    mov al, 80h     ;Get seconds
    call .readRTC
    mov dh, al      ;Pack seconds in dh
    mov al, 82h     ;Get minutes
    call .readRTC
    mov cl, al      ;Pack minutes in cl
    mov al, 84h     ;Get Hours
    call .readRTC
    mov ch, al      ;Pack Hours in ch
    mov al, 8Bh     ;Get Status B for Daylight Savings
    call .readRTC
    and al, 1       ;Isolate bit 0
    mov dl, al      ;Pack Daylight Savings bit in dl
    mov al, 0Dh     ;Enable NMI
    call .readRTC
    pop rax
    iretq
.rrtbad:
    pop rcx
    pop rax
    stc
    ret 8   ;Set carry and return

.setRTCtime:
; dh = Seconds
; cl = Minutes
; ch = Hours
; dl = Daylight Savings 
    push rax
    push rcx
    xor ecx, ecx
.srt0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah ;Disable NMI and and read bit 7. When 0, write
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .srt0   ;If zero, fall and write RTC registers

    pop rcx
    mov al, 8Bh
    call .readRTC
    and dl, 1   ;Ensure we only have the low bit of dl
    or al, dl   ;Set the daylight savings bit of Status B
    or al, 80h  ;Stop RTC updates
    mov ah, al
    mov al, 8Bh ;Reset Status B Register, and daylight savings
    call .writeRTC

    mov ah, dh  ;Pack seconds
    mov al, 80h
    call .writeRTC
    mov ah, cl  ;Pack minutes
    mov al, 82h
    call .writeRTC
    mov ah, ch  ;Pack hours
    mov al, 84h
    call .writeRTC

    mov al, 8Bh
    call .readRTC
    and al, 7Fh ;Clear the top bit
    mov ah, al  ;Pack byte to send in ah
    mov al, 8Bh
    call .writeRTC  ;Restart RTC

    mov al, 0Dh   ;Enable NMI
    call .readRTC

    pop rax
    iretq
    
.readRTCdate:
; ch = Reserved, Century (19/20/21...), fixed 20h for now
; cl = Year
; dh = Month
; dl = Day
    push rax
    push rcx
    xor ecx, ecx
.rrd0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah     ;Disable NMI and and read bit 7. When 0, write
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .rrd0       ;If zero, fall and read RTC registers

    pop rcx
    mov al, 87h     ;Get Day of the Month
    call .readRTC
    mov dl, al      ;Pack Day of the Month
    mov al, 88h     ;Get Month of the Year
    call .readRTC
    mov dh, al      ;Pack Month of the Year
    mov al, 89h     ;Get bottom two digits of year
    call .readRTC
    mov cl, al      ;Pack Year
    mov ch, 20      ;BCD value for 20

    pop rax
    iretq

.setRTCdate:
; ch = Reserved, Century (19/20/21...), fixed 20h for now
; cl = Year
; dh = Month
; dl = Day
    push rax
    push rcx
    xor ecx, ecx
.srd0:
    dec ecx
    jz .rrtbad
    mov al, 8Ah     ;Disable NMI and and read bit 7. When 0, write
    call .readRTC
    test al, 80h    ;Check bit 7 is zero
    jnz .srd0       ;If zero, fall and write RTC registers

    pop rcx
    mov al, 8Bh
    call .readRTC
    or al, 80h      ;Stop RTC updates
    mov ah, al
    mov al, 8Bh
    call .writeRTC
    mov ah, dl      ;Pack Day of the Month
    mov al, 87h
    call .writeRTC
    mov ah, dh      ;Pack Month of the Year
    mov al, 88h
    call .writeRTC
    mov ah, cl      ;Pack Year
    mov al, 89h
    call .writeRTC

    mov al, 8Bh
    call .readRTC
    and al, 7Fh ;Clear the top bit
    mov ah, al  ;Pack byte to send in ah
    mov al, 8Bh
    call .writeRTC  ;Restart RTC

    mov al, 0Dh   ;Enable NMI
    call .readRTC

    pop rax
    iretq

.setRTCalarm:
; dh = Seconds for alarm
; cl = Minutes for alarm
; ch = Hours for alarm
    push rax
    mov al, 8BH ;Get status B
    call .readRTC
    test al, 20h
    jnz .srabad ;If The alarm bit is already set, exit CF=CY

    mov ah, dh      ;Pack Seconds for alarm
    mov al, 81h     
    call .writeRTC
    mov ah, cl      ;Pack Minutes for alarm
    mov al, 83h
    call .writeRTC
    mov ah, ch      ;Pack Hours for alarm
    mov al, 85h
    call .writeRTC

    mov al, 8Bh     ;Get Status B
    call .readRTC
    or al, 20h      ;Set Bit 5 - Alarm Interrupt Enable
    mov ah, al      ;Pack new Status B
    mov al, 8Bh
    call .writeRTC 

    mov al, 0Dh     ;Enable NMI
    call .readRTC

    pop rax
    iretq
.srabad:
    pop rax
    or byte [rsp + 2*8], 1 ;Set Carry Flag
    iretq  
.resetRTCalarm:
    push rax
    mov al, 8Bh     ;Get Status B
    call .readRTC
    and al, 0DFh    ;Clear Alarm Interrupt Enable
    mov ah, al
    mov al, 8Bh
    call .writeRTC

    mov al, 0Dh     ;Enable NMI
    call .readRTC 
    pop rax
    iretq

.readRTC:
;Reads an RTC port, interrupts disabled throughout
;Input: al = I/O port to read
;Output: al = I/O data
    cli
    out cmos_base, al
    out waitp, al
    in al, cmos_data
    sti
    ret
.writeRTC:
;Writes to an RTC port, interrupts disabled throughout 
;Input: al = I/O port to read, ah = Data byte to send
    cli
    out cmos_base, al
    out waitp, al
    mov al, ah
    out cmos_data, al
    sti
    ret
;------------------------End of Interrupt------------------------
;-----------------CTRL+BREAK Interrupt Int 3Bh-------------------
;CTRL+Break will call this!
;----------------------------------------------------------------
ctrlbreak_io:
    iretq
;------------------------End of Interrupt-------------------------
;------------Screen Mode Parameters Interrupt Int 3Dh-------------
;This Interrupt returns in r8 the pointer to screen mode 
; parameters. It replaces the nice pointers in the IVT of yore.
;Returns in r8 to not conflict with ported apps
;----------------------------------------------------------------
scr_params_io:
    mov r8, scr_mode_params
    iretq
;------------------------End of Interrupt------------------------
;-----------------Disk Params Interrupt Int 3Eh------------------
disk_params_io:
    mov r8, qword [diskDptPtr]    
    mov r9, qword [fdiskDptPtr]
    iretq
;------------------------End of Interrupt------------------------
;------------------CGA font Interrupt Int 3Fh--------------------
;This Interrupt returns in r8 the pointer to the CGA font.
;It replaces the nice pointers in the IVT of yore.
;Returns in r8 to not conflict with ported apps
;----------------------------------------------------------------
cga_ret_io: ;Get first pointer in list
    movzx r8, word [scr_vga_ptrs]
    shl r8, 4
    add r8w, word [scr_vga_ptrs + 2]
    iretq
;------------------------End of Interrupt------------------------
;--------------------IDE Driver and data area--------------------
IDE:
.addControllerTable:
;Adds a PCI IDE controller to the internal data tables, if there is space
; If there is no space, returns with carry set.
;Input: eax = BAR5 address
;       ebx = PCI IO address
;Output: CF=NC, all ok, CF=CY, device not added.
    push rsi
    cmp byte [ideNumberOfControllers], 2
    je .actfail ;If it is 2, fail
    inc byte [ideNumberOfControllers]
    mov rsi, ideControllerTable
    cmp byte [rsi], 0   ;Is the first entry empty?
    jz .act0    ;If yes, write entry
    add rsi, ideTableEntrySize  ;Else, goto second entry space
.act0:
    mov dword [rsi], ebx    ;Move first PCI IO addr
    mov byte [rsi], 0       ;Zero the register index
    mov dword [rsi + 4], eax    ;Move next data
    clc
.actexit:
    pop rsi
    ret
.actfail:
    stc
    jmp short .actexit
.identifyDevice:
;dx should contain the base register
;al should contain either A0/B0 for master/slave
;rdi points to the buffer
;Carry set if failed.
    push rax            ;save the master/slave bit temporarily
    add dx, 7            ;dx at base + 7
.l1:
    in al, dx
    cmp al, 0FFh
    je .exitfail
    test al, 10000000b
    jnz .l1

    jmp short $ + 2            ;IO cycle kill
    cli
.l2:
    in al, dx
    test al, al
    jz .exitfail
    test al, 01000000b
    jz .l2

    xor al, al
    sub dx, 5            ;dx at base + 2
    out dx, al
    inc dx               ;dx at base + 3
    out dx, al
    inc dx               ;dx at base + 4
    out dx, al
    inc dx               ;dx at base + 5
    out dx, al
    inc dx               ;dx at base + 6
    pop rax              ;Get the master/slave bit back
    out dx, al            
    inc dx               ;dx at base + 7
    mov al, 0ECh         ;ECh = Identify drive command
    out dx, al

    jmp short $ + 2      ;IO cycle kill
.l3:
    in al, dx            ;get status byte
    test al, 00001000b   ;Check DRQ, to be set for data ready
    jz .l3

    sub dx, 7            ;dx at base + 0
    push rcx
    mov cx, 100h         ;100h words to be copied
    rep insw
    clc
    sti
    jmp short .exit

.exitfail:
    stc
.exit:
    pop rax
    ret
;--------------------USB Driver and data area--------------------
USB:
;------------------------EHCI functions--------------------------
;eActiveCtrlr must be set with the offset of the controller
; IFF the controller is about to enter a state in which it could
; fire an interrupt. These functions must safeguard against it by
; checking that this byte is -1 first and then setting the byte
; with the selected controller index, ending by resetting this 
; byte to -1 (even on fail). 
;
;Certain functions may be called to act upon the CURRENT ACTIVE
; controller, these functions dont need these safeguards, though
; they may need to ensure that there is a valid controller number 
; in the eActiveCtrlr byte.
;----------------------------------------------------------------
.ehciCriticalErrorWrapper:
;Currently just jumps to the installed address.
;Conditional error calls MUST call this wrapper to allow for
; host operating systems to install their own USB error handlers
; and have the system continue working.
    jmp qword [eHCErrorHandler]
.ehciCriticalErrorHandler:
;Currently just halts the system
    mov ebx, 07h
    call cls
    mov rbp, .ecehmsg
    mov ax, 1304h
    int 30h
    mov al, 0FFh
    out pic1data, al
    out pic2data, al
    cli
    hlt
    jmp $ - 2
.ecehmsg db "EHCI Check 1", 0
.setupEHCIcontroller:
;Resets, initialises variables to default
;Input: al = Controller to setup (0 based)
;Output: CF=CY - Controller failed to reset
;        CF=NC - No problems
; al = Controller that was reset
    push rcx
    push rbx
    push rbp
    call .ehciResetCtrlr    ;Reset the controller
    jc .secexit
    xor bx, bx ;No schedule, no interrupts
    xor ecx, ecx
    mov rbp, ehciAschedule
    call .ehciInitCtrlrRegs    ;Initialise controller registers
    clc
.secexit:
    pop rbp
    pop rbx
    pop rcx
    ret

.ehciResetControllerPort:
;A function that enacts an EHCI reset on a port.
;Works ONLY on the current active controller.
;Input:
; al = Port number [0,N-1] (Checked against ctrlr struc params entry)
;Returns:
; CF set if failed, clear if success
; ax=Error code, 0h=No active controller
;             1h=Invalid port number
;             2h=No device on port
;             3h=Port not enabled (Low speed device)
;             4h=Device not entering reset
;             5h=Device not clearing reset
;             6h=Port not enabled (Full speed device)
; rax destroyed
    push rbx
    push rcx
    push rdx
    push rbp

    xor bp, bp
    movzx edx, al    ;Save port number into dl (edx)
    movzx ebx, byte [eActiveCtrlr]
    cmp bl, -1
    je .ercperr    ;Error, No active controller (ec=0)
    inc bp        ;Inc error counter
    mov ebx, dword [eControllerList + 4 + 8*rbx]    ;get mmiobase into ebx
    mov eax, dword [ebx+ehcistrucparams]    ;Get # of ports in al
    and al, 7Fh    ;al contains port number, clear upper bit
    dec al        ;Zero based port number
    movzx eax, al
    cmp dl, al    ;dl contains called port number
    ja .ercperr    ;Error, invalid port number (ec=1)
    inc bp        ;Inc error counter


    movzx eax, byte [ebx]    ;Byte access for caplength!
    add ebx, eax    ;eax now points to opregs    
    mov cx, 10
.erclp0:    ;Remember ebx=opregs, edx=port number    
    or dword [ebx+4*edx+ehciportsc], 1000h ;Set power bit

    push rcx
    mov ecx, 10
    mov ah, 86h
    int 35h        ;Wait for 10 ms
    pop rcx

.erclp1:
    dec cx
    jz .ercperr ;Error, No device on port (ec=2)
    test dword [ebx+4*edx+ehciportsc], 1h    ;Test device on port
    jz .erclp0
    inc bp        ;Inc error counter

    mov eax, dword [ebx+4*edx+ehciportsc]
    and ax, 0C00h
    sub ax, 400h
    dec ax
    jz .ercperr    ;Error, Low speed device (ec=3)
    inc bp        ;Inc error counter

    mov cx, 10
.erclp2:
    dec cx
    jz .ercperr ;Error, Device not entering reset (ec=4)
    or dword [ebx+4*edx+ehciportsc], 100h    ;Set bit 8, port reset bit
    
    push rcx
    mov ecx, 10
    mov ah, 86h
    int 35h        ;Wait for 10 ms
    pop rcx

    test dword [ebx+4*edx+ehciportsc], 100h    ;Check if entered reset
    jz .erclp2

    inc bp        ;Inc error counter
    mov cx, 10
    and dword [ebx+4*edx+ehciportsc], 0FFFFFEFFh    ;Clear reset bit
.erclp3:
    dec ecx
    jz .ercperr ;Error, Device not leaving reset (ec=5)

    push rcx
    mov ecx, 10
    mov ah, 86h
    int 35h        ;Wait for 10 ms
    pop rcx

    test dword [ebx+4*edx+ehciportsc], 100h
    jnz .erclp3
    inc bp        ;Inc error counter

    test dword [ebx+4*edx+ehciportsc], 4h    ;Bit 2 is the port enabled bit
    jz .ercperr    ;Error, Full speed device (ec=6)
;We get here IFF device on port is high speed
    
;High Speed Device successfully reset. Now print message or whatever
    xor rax, rax
    clc
.ercpexit:
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    ret
.ercperr:
    mov ax, bp    ;Get error code in ax
    stc
    jmp short .ercpexit

.ehciResetCtrlr:
;A function that resets a controller. 
;No other controllers may be running during a ctrlr reset
;Input:
; al = Offset into the ehci controller table
;Returns:
; CF=CY if failed, CF=NC if reset
;All registers preserved
    push rax
    push rcx
    ;cmp byte [eActiveCtrlr], -1
    ;jne .erc2    ;A controller already active, exit fail (ec=0)
    ;mov byte [eActiveCtrlr], al    ;For added security (may be removed later)
    call .ehciGetOpBase
    mov dword [eax + ehciintr], 0h    ;No interrupts
    mov dword [eax + ehcists], 3Fh    ;Clear any outstanding interrupts
    ;Set the reset bit, check to see if run bit has cleared first!
    xor ecx, ecx
.erc0:
    and dword [eax + ehcicmd], 0FFFFFFFEh    ;Force stop the controller
    dec ecx
    jz .erc2    ;Controller not resetting, exit fail  (ec=1)

    test dword [eax + ehcists], 1000h    ;Test if bit 12 has been set
    jz .erc0
    or dword [eax + ehcicmd], 02h ;Set bit 1, reset HC
    ;Spin and wait to give device time to respond and reset.
    xor cx, cx
.erc1:
    dec cx        ;Wait for reset to happen
    jz .erc2    ;Not resetting, exit fail (ec=2)

    push rax
    push rcx
    mov ah, 86h
    mov ecx, 5    ;5ms wait
    int 35h
    pop rcx
    pop rax

    test dword [eax + ehcicmd], 2h    ;Whilst this bit is set, keep looping
    jnz .erc1
    xor eax, eax
    clc
.ercexit:
    mov byte [eActiveCtrlr], -1    ;No controllers active
    pop rcx
    pop rax
    ret
.erc2:
    stc
    jmp short .ercexit

.ehciRunCtrlr:
;A function that runs a controller to process set schedules
;Input:
;   al = Offset into the controller table
;Returns:
; CF = CY if failed, CF = NC if success
    push rax
    push rcx
    call .ehciGetOpBase
    test dword [eax + ehcists], 1000h    ;bit 12 must be set to write 1 in cmd
    jz .esc2
    or dword [eax + ehcicmd], 1h ;Set bit 0 to run
    xor ecx, ecx
.esc0:
    dec cx
    jz .esc2
    test dword [eax + ehcists], 1000h    ;bit 12 must be clear
    jnz .esc0
    xor eax, eax
    clc
.esc1:
    pop rcx
    pop rax
    ret
.esc2:    ;Bad exit
    stc
    jmp short .esc1

.ehciStopCtrlr:
;A function that stops current active controller from running
;Input:
; al=Controller to stop processing
;Returns:
; CF set if failed to stop, clear if success
    push rax
    push rcx
    movzx rax, byte [eActiveCtrlr]
    call .ehciGetOpBase
    and dword [eax + ehcicmd], 0FFFFFFFEh    ;Stop controller
    xor ecx, ecx
.estc0:
    dec cx
    jz .estc1
    test dword [eax + ehcists], 1000h    ;test hchalted until set
    jz .estc0
    clc
.estcexit:
    pop rcx
    pop rax
    ret
.estc1:
    stc
    jmp short .estcexit
.ehciAdjustAsyncSchedCtrlr:
;This function checks the currently online controller and compares it to
; the value provided in al. 
;If they are equal, do nothing.
;If not, turn off controller, update active ctrlr byte and indicate a new bus 
; was activated.
;If no controller active, update active ctrlr byte and indicate which bus 
; has been activated.
;
; Input: al = Controller to activate, preserved.
; Output: CF=CY: Error, turn off all controllers
;         CF=NC: All ok, proceed
    cmp al, byte [eActiveCtrlr]
    je .eacOkExit
    cmp byte [eActiveCtrlr], -1
    je .eacStart
    call .ehciStopAsyncSchedule ;Stop currently transacting controller
    jc .eacBad
.eacStart:
    mov byte [eActiveCtrlr], al ;Set new active controller
    mov byte [eNewBus], 1   ;Set flag that a new bus has been selected
.eacOkExit:
    clc
    ret
.eacBad:
    stc
    ret
.ehciInitCtrlrRegs:
;A function that initialises a given controllers registers as needed.
;Controller is left ready to process data start schedules
;MUST NOT BE CALLED ON A RUNNING CONTROLLER
;Input:
; al = Offset into the ehci controller table
; bl = ehciintr mask
; bh = Schedule mask, bits [7:2] reserved
;        00b = No schedule, 01b=Periodic, 10b=Async, 11b=Both
; ecx = Frame Index
; rbp = Schedule address
;Returns:
; Nothing
    push rax
    push rbx
    push rcx
    push rbx
    call .ehciGetOpBase    ;Get opbase 
    movzx ebx, bx
    mov dword [eax + ehciintr], 0
    mov dword [eax + ehcifrindex], ecx
    mov dword [eax + ehciasyncaddr], ebp
    ror rbp, 20h    ;Get upper dword low
    mov dword [eax + ehcictrlseg], ebp
    pop rbx    ;Get back bh
    xor bl, bl    ;Zero lo byte
    shr bx, 4    ;Shift to hi nybble of lo byte
    and dword [eax + ehcicmd], 0CFh    ;Clear schedule enable bits
    or ebx, dword [eax + ehcicmd]    ;Add ehcicmd to schedule mask
    and ebx, 0FF00FFF3h    ;Clear the Int Threshold and Frame List bits
    or ebx, 000080000h ;Set 8 microframes (1 ms) per interrupt
    mov dword [eax + ehcicmd], ebx    ;Write back
    mov dword [eax + ehciconfigflag], 1h    ;Route all ports to EHCI ctrlr
    pop rcx
    pop rbx
    pop rax
    ret
.ehciCtrlrGetNumberOfPorts:
;Gets the number of ports on a Host Controller.
;Ports are zero addressed so ports numbers are 0 to NUMBER_OF_PORTS - 1
;Input:  al = Offset into the controller table
;Output: rax = Number of ports on controller.
;Warning, input NOT bounds checked.
    movzx eax, al
    mov eax, dword [eControllerList + 4 + 8*rax]
    mov eax, dword [eax + ehcistrucparams]
    and eax, 7Fh    ;Clear upper bits
    ret
.ehciGetNewQHeadAddr:
;Picks which QHead position to put the new Qhead into
;Input: Nothing
;Output: rdi = Position in RAM for QHead
;        r8  = Link to next QHead
;           r8 NEEDS to be or'ed with 2 when used as a QHead pointer
    mov r8, ehciQHead1
    mov rdi, ehciQHead0
    cmp rdi, qword [eCurrAsyncHead]   ;Compare head to start of buffer
    jne .egnqaexit
    xchg rdi, r8
.egnqaexit:
    ret

.ehciToggleTransactingQHead:
;Toggles the transacting Qhead position
;This is called AFTER the old Qhead has been delinked from the AsynchSchedule
    cmp qword [eCurrAsyncHead], ehciQHead0
    jne .ettqh0
    mov qword [eCurrAsyncHead], ehciQHead1
    ret
.ettqh0:
    mov qword [eCurrAsyncHead], ehciQHead0
    ret

.ehciDelinkOldQHead:
;Delinks the old Qhead from the list async list
    push rdi
    push r8
    call .ehciGetNewQHeadAddr
    mov r8, rdi
    or r8, 2
    mov dword [rdi], r8d    ;Point the new qhead to itself
    or dword [rdi + 4], 8000h   ;Toggle H-bit in the current transacting QHead
    pop r8
    pop rdi
    ret

.ehciLinkNewQHead:
;Links the inserted qhead into the async list
    push rdi
    push r8
    call .ehciGetNewQHeadAddr   ;Get bus addresses
    cmp byte [eNewBus], 1
    je .elnqadjusted   ;If equal, exit
    or rdi, 2
    mov dword [r8], edi
.elnqhexit:
    clc
    pop r8
    pop rdi
    ret
;Only here if a new bus was Adjusted
.elnqadjusted:
;The first qhead in a new queue must always point to itself and be
; the head of the reclaim list.
;The same address is provided to the function which writes the qhead
; and in the above function call into rdi, thus allowing us to point
; the new qhead to itself and set the H-bit on, in ALL instances 
    mov r8, rdi
    or r8, 2
    mov dword [rdi], r8d    ;Point the QHead to itself
    or dword [rdi + 4], 8000h   ;Set H bit on
    push rax
    mov al, byte [eActiveCtrlr]
    call .ehciGetOpBase
    mov dword [eax + ehciasyncaddr], edi ;Set the address in the ctrlr register
    pop rax
    call .ehciStartAsyncSchedule    ;Start schedule
    jc .elnqhbad
    dec byte [eNewBus]  ;Reset back to zero if successfully onlined
    jmp short .elnqhexit
.elnqhbad:  ;If Async fails to start, exit
    pop r8
    pop rdi
    stc
    ret

.ehciSetNoData:
;A function that does a set request with no data phase to the device
;at address al.
;Input:
; al = Address number (7 bit value)
; rbx = Setup packet
; cx = Max Packet Length 
;Returns:
; CF = NC if no Host error, CF = CY if Host error
; Caller MUST check the schedule to ensure that the transfer was successful,
; and without transaction errors as these dont constitute Host system errors.
;
; All registers except for CF preserved
    push rdi
    push r8
    push r9
    push r10
    push r11
    push rcx
    push rdx
    cld    ;Set right direction for string ops
    
    ;Write setup packet
    mov qword [ehciDataOut], rbx
    call .ehciGetNewQHeadAddr
    or r8, 2    ;Process qH TDs
    mov r9d, 80006000h  ;Bit 15 not set here!!!!! Important
    movzx ecx, cx
    shl ecx, 8*2
    or r9d, ecx
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    mov r11, ehciTDSpace  ;First TD is the head of the buffer

    call .ehciWriteQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    lea r8, qword [rdi + ehciSizeOfTD]    ;Point to next TD
    mov r9, 1
    mov r10d, 00080E80h ;Active TD, SETUP EP, Error ctr = 3, 8 byte transfer
    mov r11, ehciDataOut ; Data out buffer

    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD     ;Go to next TD space
    mov r8, 1
    mov r9, r8
    mov r10d, 80008D80h        ;Status stage opposite direction of last transfer
    mov r11, msdCSW         ;Nothing should be returned but use this point

    call .ehciWriteQHeadTD
    mov cl, 011b   ;Lock out internal buffer
    jmp .egddproceed

.ehciGetRequest:
;A function which does a standard get request from a device at
;address al.
;Input:
; al = Address number (7 bit value)
; rbx = Setup packet
; ecx = Max Packet Length 
;Returns:
; CF = NC if no Host error, CF = CY if Host error
; Caller MUST check the schedule to ensure that the transfer was successful,
; and without transaction errors as these dont constitute Host system errors.
;
; All registers except for CF preserved
    push rdi
    push r8
    push r9
    push r10
    push r11
    push rcx
    push rdx
    cld    ;Ensure right direction

    ;Write setup packet
    mov qword [ehciDataOut], rbx
    call .ehciGetNewQHeadAddr
    or r8, 2    ;Process qH TDs
    mov r9d, 80006000h  ;Bit 15 not set here!!!!! Important
    movzx ecx, cx
    shl ecx, 8*2
    or r9d, ecx
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    mov r11, ehciTDSpace  ;First TD is the head of the buffer
    
    call .ehciWriteQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    lea r8, qword [rdi + ehciSizeOfTD]    ;Point to next TD
    mov r9, 1
    mov r10d, 00080E80h ;Active TD, SETUP EP, Error ctr = 3, 8 byte transfer
    mov r11, ehciDataOut ; Data out buffer

    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD    ;Go to next TD space
    lea r8, qword [rdi + ehciSizeOfTD]
    mov r9, r8    ;Alt pointer also points to next TD since this is expected!
    mov r10d, 80400D80h ;Active TD, IN EP, Error ctr = 3, max 64 byte transfer
    mov r11, ehciDataIn

    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD     ;Go to next TD space
    mov r8, 1
    mov r9, r8
    mov r10d, 80008C80h
    mov r11, msdCSW

    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer, ignore one interrupt
;Now set controller to process the schedule
.egddproceed:
    call .ehciProcessCommand
;The carry status of the previous function will propagate
.egddexit:
    pop rdx
    pop rcx
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    ret

.ehciStartAsyncSchedule:
    push rax
    push rcx

    mov al, byte [eActiveCtrlr]    ;Deals with current active controller
    call .ehciGetOpBase            ;Return opregs ADDRESS in eax
    or dword [eax + ehcicmd], 20h    ;Process asyncschedule
    xor ecx, ecx
.esas0:
    dec ecx
    jz .esasfail
    test dword [eax + ehcists], 08000h ;Asyncschedule bit should be on
    jz .esas0

    clc
.esasok:
    pop rcx
    pop rax
    ret
.esasfail:
    stc
    jmp short .esasok

.ehciStopAsyncSchedule:
;This function stops the processing of the current active Async Schedule
;Output: CF=CY: Failed to stop Async Schedule CF=NC: Stopped Async Schedule
    push rax
    push rcx
    mov al, byte [eActiveCtrlr]    ;Deals with current active controller
    call .ehciGetOpBase            ;Return opregs ADDRESS in eax
    xor cx, cx
    and dword [eax + ehcicmd], 0FFFFFFDFh ;Stop processing async
.espc0:
    dec cx
    jz .espcfail
    test dword [eax + ehcists], 08000h
    jnz .espc0

    clc
    pop rcx
    pop rax
    ret
.espcfail:
    stc
    pop rcx
    pop rax
    ret

.ehciProcessCommand:
; Allows EHCI async schedule to process commands.
; Preserves all registers except CF
; Returns: CF=CY if error detected 
;          CF=NC if no error detected
;
; If returned with CF=CY, caller must read the msdStatus byte
    push rax
    push rbx
    push rcx
    push rdi

    mov byte [eAsyncMutex], cl  ;Set mutex
    mov al, byte [eActiveCtrlr]    ;Deals with current active controller
    call .ehciGetOpBase            ;Return opregs ADDRESS in eax
    mov rbx, rax
    mov di, 5000
    call .ehciLinkNewQHead
    jc .epcfailedstart
.epc1:
    test dword [ebx + ehcists], 13h
    jnz .epc2     ;If bits we care about are set, call IRQ proceedure
    pause       
    dec di
    jz .epcfailtimeout
    mov ah, 86h
    mov ecx, 1    ;Max 5s in 1ms chunks
    int 35h
    jmp short .epc1
.epc2:
    mov eax, ebx    ;Get opreg base into eax before we proceed into IRQ handler
    call ehci_IRQ.nonIRQep ;Manually call IRQ
    test byte [eActiveInt], 10h ;HC error bit
    jnz .epcHostError   ;HC error detected
    test byte [eAsyncMutex], 0
    jnz .epc1    ;If the mutex isnt cleared, go back to sts check
    call .ehciDelinkOldQHead   ;Perform delink
    call .ehciToggleTransactingQHead    ;Toggle the active Qheads
;Now set doorbell
    or dword [ebx + ehcicmd], 40h   ;Ring Doorbell
    mov di, 5000
.epc3:
    test dword [ebx + ehcists], 20h ;Test for doorbell set high
    jnz .epc4
    pause
    dec di
    jz .epcfaildelinked
    mov ah, 86h
    mov ecx, 1    ;Max 5s in 1ms chunks
    int 35h
    jmp short .epc3
.epc4:
;Clear once more to clear the doorbell bit
    mov ecx, dword [ebx + ehcists]  
    or dword  [ebx + ehcists], ecx    ;WC high bits
;Check if it was a stall
    test byte [eActiveInt], 2h  ;Check USBError bit
    jnz .epcexit
    mov byte [msdStatus], 00h   ;No error... yet
    clc
.epcexit:
    pop rdi
    pop rcx
    pop rbx
    pop rax
    ret 
.epcStall:
    mov byte [msdStatus], 21h   ;General Controller Failure - Stall
    stc
    jmp short .epcexit
.epcfail:
    call .ehciDelinkOldQHead   ;Perform delink
    call .ehciToggleTransactingQHead    ;Toggle the active Qheads
.epcfailedstart: ;No need to delink as that data structure is considered garbage
.epcfaildelinked:
    mov ecx, dword [ebx + ehcists]
    or dword  [ebx + ehcists], ecx    ;WC selected bits
.epcHostError:  ;Host error detected in interrupt register
    mov byte [msdStatus], 20h   ;General Controller Error
    stc
    jmp short .epcexit
.epcfailtimeout:
;Called in the event that the schedule fails to process the QHead.
;Emergency stops the currently transacting schedule
    call .ehciDelinkOldQHead   ;Perform delink
    call .ehciToggleTransactingQHead    ;Toggle the active Qheads
    mov ecx, dword [ebx + ehcists]
    or dword  [ebx + ehcists], ecx    ;WC selected bits
    mov byte [msdStatus], 80h   ;Timeout Error
    stc
    jmp short .epcexit  ;Delink

.ehciEnumerateRootPort:
;This function discovers whether a device is of a valid type
;or not.
;Input: dl=port number - 1 (0 based), dh = bus [0-3]
;       r10b = Host hub address (if the device is on a hub, 0 else)
;Output:     CF=CY if error, CF=NC if bus transaction occured 
;           ZF=ZR if passed enum: ah = bus number, al = Address number
;            ZF=NZ if the device failed enumeration: ax=error code
;                ah = Enum stage, al = Sub function stage
    push rbx
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11

.eebinit:
    xor bp, bp    ;Use as error counter    (Stage 0)
    mov al, dl
    call .ehciResetControllerPort    ;Reset port
    jc .ehciedbadnotimeout
;Power on debounce!
    mov ecx, debounceperiod    ;debounce period
    mov ah, 86h
    int 35h

    inc bp    ;Increment Error Counter    (Stage 1)
.eeb0:
    mov rbx, 00008000001000680h    ;Pass get minimal device descriptor
    mov qword [ehciDataOut], rbx
    mov cx, 40h    ;Pass default endpoint size
    xor al, al
    call .ehciGetRequest
    jc .ehciedexit  ;Fast exit with carry set
.eeb1:
    inc bp    ;Increment Error Counter    (Stage 2)
    xor al, al    ;Increment Error subcounter    (Substage 0)
    mov rbx, ehciDataIn
    cmp byte [rbx + 1], 01h    ;Verify this is a valid dev descriptor
    jne .ehciedbad
    inc al    ;Increment Error subcounter    (Substage 1)
    cmp word [rbx + 2], 0200h    ;Verify this is a USB 2.0 device or above
    jb .ehciedbad
    inc al    ;Increment Error subcounter    (Substage 2)
    cmp byte [rbx + 4], 0    ;Check interfaces
    je .eeb2
    cmp byte [rbx + 4], 08h    ;MSD?
    je .eeb2
    cmp byte [rbx + 4], 09h    ;Hub?
    jne .ehciedbad
.eeb2:
    inc bp    ;Increment Error Counter    (Stage 3)
    movzx r8d, byte [rbx + 7]    ;Byte 7 is MaxPacketSize0, save in r8b
    mov al, dl

    call .ehciResetControllerPort    ;Reset port again
    jc .ehciedbad
    mov r11, 10
.ehciEnumCommonEp:
    inc bp    ;Increment Error Counter    (Stage 4)
    mov al, dh    ;Put bus number into al

    call .ehciGiveValidAddress    ;Get a valid address for device
    cmp al, 80h    
    jae .ehciedbad    ;Invalid address

    inc bp    ;Increment Error Counter    (Stage 5)
    mov r9b, al        ;Save the new device address number in r9b
.eeb3:
    mov ebx, 0500h    ;Set address function
    movzx ecx, r9b    ;move new address into ecx
    shl ecx, 8*2
    or ebx, ecx    ;Add address number to ebx
    mov cx, r8w    ;Move endpoint size into cx
    xor al, al    ;Device still talks on address 0, ax not preserved
    call .ehciSetNoData    ;Set address
    jc .ehciedexit  ;Fast exit with carry set
.eeb4:
    mov ah, 86h
    mov rcx, r11
    int 35h

    inc bp    ;Increment Error Counter    (Stage 6)
.eeb5:
    mov rbx, 00012000001000680h    ;Now get full device descriptor
    mov al, r9b    ;Get address
    mov cx, r8w
    call .ehciGetRequest    ;Get full device descriptor and discard
    jc .ehciedexit  ;Fast exit with carry set
    inc bp    ;Increment Error Counter    (Stage 7/0Bh)
.eeb6:
    mov rbx, 00000000002000680h ;Get config descriptor
    mov ecx, r8d    ;Adjust the packet data with bMaxPacketSize0
    shl rcx, 8*6    ;cx contains bMaxPacketSize0
    or rbx, rcx
    mov al, r9b    ;Get address
    mov cx, r8w    ;Move endpoint size into cx
    call .ehciGetRequest
    jc .ehciedexit  ;Fast exit with carry set
.eeb7:
    inc bp    ;Increment Error Counter    (Stage 8/0Ch)
;Find a valid interface in this config
    call .ehciFindValidInterface
    jc .ehciedbad    ;Dont set config, exit bad
;If success, ah has device type (0=msd, 1=hub), al = Interface to use
;rbx points to interface descriptor
    inc bp    ;Increment Error Counter    (Stage 9/0Dh)
    call .ehciAddDeviceToTables
    jc .ehciedbad    ;Failed to be added to internal tables
    inc byte [usbDevices]   ;Device added successfully, inc byte
;Set configuration 1 (wie OG Windows, consider upgrading soon)
    inc bp    ;Increment Error Counter    (Stage 0Ah/0Ch)
.eeb8:
    mov rbx, 00000000000010900h    ;Set configuration 1 (function 09h)
    mov al, r9b    ;Get address
    mov cx, r8w    ;Move endpoint size into cx
    call .ehciSetNoData
    jc .ehciedexit  ;Fast exit with carry set
.eeb9:
    inc bp    ;Increment Error Counter    (Stage 0Bh/0Dh)
.eeb10:
    mov rbx, 0001000000000880h  ;Get device config (sanity check)
    movzx ecx, r8w              ;bMaxPacketSize0
    mov al, r9b                 ;Get device address
    call .ehciGetRequest
    jc .ehciedexit  ;Fast exit with carry set
.eeb11:
    inc bp    ;Increment Error Counter    (Stage 0Ch/0Eh)
    cmp byte [ehciDataIn], 01
    jne .ehcibadremtables
;Device is now configured and ready to go to set/reset
    mov ah, dh  ;Move bus number
    mov al, r9b ;Move address number
    xor edx, edx  ;This will always set the zero flag
.ehciedexit:
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdx
    pop rcx
    pop rbx
    ret
.ehciedbad:
.ehciedbadnoport:
    push rax
    mov ah, 86h
    mov ecx, 500    ;500 ms wait between failed attempts
    int 35h
    pop rax
.ehciedbadnotimeout:
    mov ah, al    ;Save subproc error code
    xor al, al    ;Zero byte
    or ax, bp    ;Add proc error stage code into al
    xchg ah, al
    xor bp, bp
    inc bp      ;This will always clear the Zero flag
    clc         ;This will force clear the Carry flag
    jmp short .ehciedexit
.ehcibadremtables:
    mov al, r9b ;Get address low
    mov ah, dh  
    call .ehciRemoveDevFromTables
    jmp short .ehciedbadnotimeout

.ehciAddDeviceToTables:
;This function adds a valid device to the internal tables.
;Interrupts are off for this to avoid dead entries
;Input: ah = device type (0=msd, 1=hub)
;       al = Interface Value to use (USB bInterfaceNumber)
;       rbx = Ptr to valid Interface descriptor
;       r8b = MaxPacketSize0
;       r9b = Device Address
;       dh = Bus number
;       dl = Physical Port number - 1
;       r10b = Host hub address
    push r11
    push rbp    ;Error counter
    push rdi
    push rbx
    push rdx
    pushfq
    inc dl      ;Add one to the Physical port number (kludge for root hub enum)
    xor bp, bp  ;Zero error counter (Stage 0)
    mov ecx, usbMaxDevices
    cmp byte [usbDevices], cl   ;Max number of devices, check
    je .eadttbad        ;If max, fail
    inc bp      ;Increment error counter (Stage 1)
    mov rdi, usbDevTbl
    mov cl, usbDevTblE  ;Within the length of the table
;Write Common table first
.eadtt0:
    or byte [rdi], 0   ;Check if there exists a free entry
    jz .eadtt1
    add rdi, usbDevTblEntrySize ;Go to next entry
    dec cl
    jz .eadttbad
    jmp short .eadtt0
.eadtt1:
    inc bp      ;Increment error counter (Stage 2)
    add ah, 08h ;hub is 09h
;Add device here, rdi points to entry
    mov byte [rdi], r9b
    mov byte [rdi + 1], dh
    mov byte [rdi + 2], ah
;Entry written
    inc bp      ;Increment error counter (Stage 3)
;Individual Device table writing
    cmp ah, 08h
    je .eadttmsd
    cmp ah, 09h
    je .eadtthub
    jmp .eadttbad
.eadttmsd:
    mov rdi, msdDevTbl
    mov cl, msdDevTblE  ;Max entries possible
    inc bp      ;Increment error counter (Stage 4)
.eadttmsd0:
    or byte [rdi], 0
    jz .eadttmsd1
    add rdi, msdDevTblEntrySize
    dec cl
    jz .eadttbad
    jmp short .eadttmsd0
.eadttmsd1:
;rdi points to correct offset into table
;rbx points to interface
    mov cl, byte [rbx + 4]   ;Get number of endpoints to check
    mov ch, cl
    inc bp      ;Increment error counter (Stage 5)
    mov r11, rbx    ;Save Interface Pointer in r11
    add rbx, 9  ;Go to first IF
.eadttmsd11:
    push rax
    mov ax, word [rbx + 2]
    shr ax, 4   ;Remove low 4 bits
    cmp ax, 28h     ;Bulk/In bits
    pop rax         ;Doesnt ruin flags
    je .eadttmsd2   ;Not zero only if valid
    add rbx, 7   ;Go to next endpoint
    dec cl
    jz .eadttbad
    jmp short .eadttmsd11
.eadttmsd2:
    mov byte [rdi], r9b      ;Device Address
    mov byte [rdi + 1], dh   ;Root hub/bus
    mov byte [rdi + 2], r10b ;Address of parent device if not root
    mov byte [rdi + 3], dl   ;Port number we are inserted in
    mov byte [rdi + 4], al   ;Save Interface number
    mov al, byte [r11 + 6]   ;bInterfaceSubclass is +6
    mov byte [rdi + 5], al
    mov al, byte [r11 + 7]   ;Protocol
    mov byte [rdi + 6], al
    mov byte [rdi + 7], r8b  ;MaxPacketSize0
;Valid In EP found, write table entries
    mov al, byte [rbx + 2]  ;Get address
    mov byte [rdi + 8], al
    mov ax, word [rbx + 4]  ;Get maxPacketSizeIn
    mov word [rdi + 9], ax

    lea rbx, qword [r11 + 9]   ;Return rbx to first IF
    inc bp      ;Increment error counter (Stage 6)
.eadttmsd21:
    mov ax, word [rbx + 2]  ;Bulk/Out bits
    shr ax, 4
    cmp ax, 20h
    je .eadttmsd3   ;Not zero only if valid
    add rbx, 7   ;Go to next endpoint
    dec ch
    jz .eadttbad
    jmp short .eadttmsd21
.eadttmsd3:
    mov al, byte [rbx + 2]  ;Get address
    mov byte [rdi + 11], al
    mov ax, word [rbx + 4]  ;Get maxPacketSizeIn
    mov word [rdi + 12], ax
    xor ax, ax  ;Zero ax
    mov word [rdi + 14], ax ;Make dt bits for I/O EPs zero
;Table entry written for MSD device
    jmp .eadttpass
.eadtthub:
    mov rdi, hubDevTbl
    mov cl,  hubDevTblE ;Max entries possible
    mov bp, 7      ;Increment error counter (Stage 7)
.eadtthub0:
    or byte [rdi], 0
    jz .eadtthub1
    add rdi, hubDevTblEntrySize
    dec cl
    jz .eadttbad
    jmp short .eadtthub0
.eadtthub1:
;Valid table space found
    mov byte [rdi], r9b      ;Device Address
    mov byte [rdi + 1], dh   ;Root hub/bus
    mov byte [rdi + 2], r10b ;Address of parent device if not root
    mov byte [rdi + 3], dl   ;Port number we are inserted in
    mov byte [rdi + 4], r8b  ;MaxPacketSize0
    mov ax, 0FF00h  ;Res byte is 0FFh, Num ports (byte 6) is 0
    mov word [rdi + 5], ax   ;Number of ports and PowerOn2PowerGood
    mov byte [rdi + 7], 0FFh    ;EP address, currently reserved
.eadttpass:
    popfq   ;If IF was clear, it will be set clear by popf
    xor ax, ax  ;Clear ax and clc
.eadttexit:
    pop rdx
    pop rbx
    pop rdi
    pop rbp
    pop r11
    ret
.eadttbad:
    popfq   ;If IF was clear, it will be set clear by popf
    stc
    mov ax, bp
    jmp short .eadttexit
.ehciRemoveDevFromTables:
;This function removes a function from internal tables
;Input: al = Address number, ah = Bus number
;Output: Internal tables zeroed out, ax destroyed, Carry clear
;    If invalid argument, Carry set
    push rdi
    push rcx
    push rbx
    mov rdi, usbDevTbl
    mov cl, usbDevTblE    ;10 entries possible
.erdft0:
    scasw
    je .erdft1    ;Device signature found
    inc rdi
    dec cl
    jz .erdftbad
    jmp short .erdft0
.erdft1:
    sub rdi, 2  ;scasw pointers to the next word past the comparison
    mov ah, byte [rdi + 2]    ;Save class code in ah
    cmp ah, 08h ;USB MSD Class device
    jne .erdft11    ;Skip the dec if it is a hub class device
    dec byte [numMSD]   ;Device is being removed from tables, decrement count
.erdft11:
;Clear usbDevTbl entry for usb device
    push rax
    mov ecx, usbDevTblEntrySize    ;Table entry size
    xor al, al
    rep stosb    ;Store zeros for entry
    pop rax

    mov rbx, hubDevTbl
    mov rcx, msdDevTbl
    cmp ah, 09h
    cmove rcx, rbx ;If 09h (Hub), change table pointed to by rcx
    mov rdi, rcx    ;Point rdi to appropriate table
    mov ebx, hubDevTblEntrySize    ;Size of hub table entry
    mov ecx, msdDevTblEntrySize    ;Size of msd table entry
    cmp ah, 09h
    cmove ecx, ebx    ;If hub, move size into cx
;cx has entry size, rdi points to appropriate table
    mov rbx, rdi
    xor edi, edi
    sub edi, ecx
    mov ah, 11h
.erdft2:
    dec ah
    jz .erdftbad    ;Somehow, address not found
    add edi, ecx
    cmp al, byte [rbx + rdi]
    jne .erdft2
    add rdi, rbx    ;point rdi to table entry
    xor al, al
    rep stosb    ;ecx contains table entry size in bytes
    dec byte [usbDevices]   ;Decrement total usb devices
    clc
.erdftexit:
    pop rbx
    pop rcx
    pop rdi
    ret
.erdftbad:
    stc
    jmp short .erdftexit 
.ehciGiveValidAddress:
;This function will return a valid value to use as an address
;for a new device.
;Input: al = Controller number [0-3]
;Output: al = Address, or 80h => No valid available address
    push rdi
    push rcx
    mov ah, al    ;Move bus number high
    mov al, 0 ;Address 0, start at addr 1
.egva0:
    inc al
    cmp al, 80h
    jae .egvaexit
    mov rdi, usbDevTbl
    mov cl, usbDevTblE    ;10 entries possible
.egva1:
    scasw
    je .egva0
    inc rdi    ;Pass third byte in table entry
    dec cl
    jnz .egva1    ;Check every entry for any addresses being used
.egvaexit:
    pop rcx
    pop rdi
    ret 
.ehciFindValidInterface:
;A proc to check a valid interface descriptor is present. 
;Input: Nothing [Assumes Get Config was called in standard buffer]
;Output: Carry set if invalid. Carry clear if valid.
;    On success: ah = device type (0 is msd, 1 is hub)
;                al = interface number to set
;               rbx = Pointer to Interface Descriptor
;   On fail: al contains error code, registers rbx, cx, dx destroyed
    push rsi
    push rdi
    push rcx
    push rdx

    mov rsi, ehciDataIn    ;Shift to buffer
    xor dl, dl    ;Error code counter
    cmp byte [rsi + 1], 02h    ;Check if valid config descriptor
    jne .ecvifail
    inc dl
;cl counts ep's per interface, ch counts possible interfaces
    mov ch, byte [rsi + 5]        ;Get number of interfaces
.ecvi0:
    test ch, ch
    jz .ecvifail    ;Zero interfaces is invalid for us
    inc dl

    mov rbx, rsi    ;Save this descriptor in rbx
    movzx rsi, byte [rbx]    ;get the size of the config to skip
    add rsi, rbx    ;point rsi to head of first interface descriptor
    cmp byte [rsi + 1], 04h    ;Check if valid interface descriptor
    jne .ecvifail
    inc dl
    mov cl, byte [rsi + 4]
;Cmp IF has valid class/prototcol
    xor rax, rax    ;Device signature, 0 is msd, 1 is hub
    call .ehciCheckMsdIf
    jnc    .ecviif    ;Not clear => valid interface
    inc ah    ;Device signature, 0 is msd, 1 is hub
    call .ehciCheckHubIf
    jc    .ecvibadif    ;Clear => bad interface
.ecviif:    ;Valid interface found
    mov al, byte [rsi + 2]    ;Get interface number into al
    mov rbx, rsi    ;Save pointer in rbx for return
    clc ;Clear carry
.ecviexit:
    pop rdx
    pop rcx
    pop rdi
    pop rsi
    ret
.ecvifail:
    xor ebx, ebx    ;Zero rbx for bad returns
    stc
    mov al, dl    ;Move error code
    jmp short .ecviexit
.ecvibadif:    ;Bad interface, goto next interface
    test cl, cl
    jz .ecvibadif1
    dec cl
    add rsi, 7
    jmp short .ecvibadif
.ecvibadif1:
    add rsi, 9
    dec ch
    mov dl, 1
    jmp short .ecvi0
.ehciCheckHubIf:
;Input: rsi points to interface descriptor
;Output: All registers preserved, carry set if NOT valid hub
    push rsi
    cmp byte [rsi + 5], 09h
    jne .ecdhfail
    cmp byte [rsi + 6], 0
    jne .ecdhfail
    cmp byte [rsi + 7], 2
    ja .ecdhfail
    cmp byte [rsi + 4], 1    ;One endpoint to rule them all
    jne .ecdhfail
    clc 
.ecdhexit:
    pop rsi
    ret
.ecdhfail:
    stc
    jmp short .ecdhexit
.ehciCheckMsdIf:
;Input: rsi points to interface descriptor
;Output: Carry set if fail, ax destroyed
;    rsi points to good descriptor if all ok
;Note we only accept 09/00/50 and 09/06/50
    push rsi
    push rbx
    push rcx
    cmp byte [rsi + 5], 08h    ;MSD class
    jne .ecdmfail
;Subclass check
    cmp byte [rsi + 6], 06h    ;SCSI actual
    je .ecdmprot
    cmp byte [rsi + 6], 00h    ;SCSI defacto
    jne .ecdmfail
.ecdmprot:
    cmp byte [rsi + 7], 50h    ;BBB
    jne .ecdmfail
.ecdmprotUAF:   ;Dummy label to find where to add this later
.ecdmpass:
    clc
.ecdmexit:
    pop rcx
    pop rbx
    pop rsi
    ret
.ecdmfail:
    stc
    jmp short .ecdmexit
.ehciGetDevicePtr:
;Gets address/bus pair and returns in rax a pointer to the data
;structure of the device, in the data table.
;Input: ah = bus number, al = Address number
;Output: ax = Preserved, rsi = Pointer to table structure, bl = USB Class Code
    push rcx
    push rdx
    push rbp
    mov ecx, usbMaxDevices
    mov rsi, usbDevTbl
.egdp0:
    cmp ax, word [rsi]
    je .egdp1   ;Device found
    add rsi, usbDevTblEntrySize
    dec cx
    jz .egdpfail    ;Got to the end with no dev found, exit
    jmp short .egdp0
.egdp1:
    mov rbp, hubDevTbl
    mov ecx, hubDevTblEntrySize
    movzx ebx, byte [rsi + 2]  ;Return bl for device type
    cmp bl, 09h ;Are we hub?
    mov rsi, msdDevTbl  ;Set to msd
    mov edx, msdDevTblEntrySize
    cmove rsi, rbp  ;If hub, reload rsi pointer to hub table
    cmove edx, ecx    ;If hub, reload dx with hub table size
    mov ecx, usbMaxDevices
.egdp2:
    cmp ax, word [rsi]
    je .egdp3
    add rsi, rdx    ;rdx contains size of entry for either table
    dec cx
    jz .egdpfail
    jmp short .egdp2
.egdp3:
    clc
.egdpexit:
    pop rbp
    pop rdx
    pop rcx
    ret
.egdpfail:
    xor bx, bx
    stc
    jmp short .egdpexit

.ehciProbeQhead:
;A proc that returns a Queue Heads' status byte in bl.
;Input:
;   rbx = Address of QHead to probe
;Output: 
;   bl = Status byte, if 0, successful transfer!
    mov bl, byte [rbx + 18h]  ;08h is offset in qTD
    ret
.ehciStandardErrorHandler:
;Attempts to verify if something went wrong in previous transaction.
;May only be called if eActiveInt has bit USBSTS bit set
;Input:  al = Device Address
;        cx = Default Endpoint Size
;Output: CF=CY: Host error, Reset host system
;        CF=NC: Proceed with below
;        al = 0 => Benign error, Make request again/Verify data.
;        al = 1 => Stall, Transaction error or Handshake error, corrected.
;        al = 80h => Fatal error, EPClear errored out, but no clear reason why
;        al > 80h => Bits 6-0 give the status byte for the error on EP Clear.
;                  Bit 7 is the fatal error bit. 
;                  If set, recommend device is port reset.
;All other registers preserved
    push rbx
    push r8
    push r9

    mov r8, rax
    mov r9, rcx
    xor al, al                  ;Set error counter and clear CF
    test byte [eActiveInt], 2   ;Error Interrupt
    jz .esehexit                ;No error found, should not have been called
    mov rbx, qword [eCurrAsyncHead] ;Get the current transacting QHead address
    call .ehciProbeQhead    ;Ret in bl status byte
    and bl, 01111000b       ;Check if it is something we should clear EP for
    jz .esehexit            ;If it is not, benign error. al = 0

    mov rbx, qword [eCurrAsyncHead] ;Get current AsyncHead again
    mov al, r8b        ;Device Address
    mov cx, r9w        ;EP size
    mov bl, byte [rbx + 05h]  ;Get Endpoint to reset
    and bl, 0Fh ;Lo nybble only
    call .ehciClearEpStallHalt
    jc .esehexit        ;HC error!
    mov al, 1           ;Stall cleared
    test byte [eActiveInt], 2   ;Check if interrupt returned an error
    jz .esehexit                ;No error found, return al=1, stall cleared
    mov al, 80h                 ;Fatal error indication
    mov rbx, qword [eCurrAsyncHead] ;Get the current transacting QHead address
    call .ehciProbeQhead   
    or al, bl          ;Add error bits to al for Fatal error indication.
.esehexit:
    mov rcx, r9
    pop r9
    pop r8
    pop rbx
    ret

.ehciClearEpStallHalt:
;Clears a halt or stall on an endpoint.
;Input: bl=Endpoint (0 for control)
;       al=Device Address
;       cx=Ctrl Endpoint Size
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check interrupt error bit for confirmation
    push rbx
    movzx rbx, bl
    shl rbx, 2*10h  ;Shift wIndex by two words
    or rbx, 0102h   ;01=bRequest(CLEAR_FEATURE) 02h=bmRequestType (Endpoint)
    call .ehciSetNoData
    pop rbx ;Get original bx
    ret

.ehciWriteQHead:
;Writes a Queue head at rdi, and clears the space for the transfer descriptor
;rdi points at the head of the qhead on return
;All non argument registers preserved
;r8d=Horizontal Ptr + Typ + T
;r9d=Endpoint Characteristics
;r10d=Endpoint Capabilities
;r11d=Next qTD Pointer
    push rax
    push rcx
    push rdi
    xor eax, eax
    mov eax, r8d
    stosd
    mov eax, r9d
    stosd
    mov eax, r10d
    stosd
    xor eax, eax
    stosd            ;Enter 0 for the current qTD pointer entry
    mov eax, r11d
    stosd
    mov ecx, 10
    xor eax, eax
    rep stosd
    pop rdi
    pop rcx
    pop rax
    ret
.ehciWriteQHeadTD:
;Writes a transfer descriptor at the location pointed at by rdi
;rdi points at the head of the qheadTD on return
;All registers except passed arguments, preserved
;rdi=location for current linked list element
;r8d=Next qTD ptr
;r9d=Alternate Next qTD ptr
;r10d=Transfer Descriptor Token
;r11=Buffer Ptr 0 + Current Offset
    push rax
    push rdi
    mov eax, r8d
    stosd
    mov eax, r9d
    stosd
    mov eax, r10d
    stosd
    mov eax, r11d
    stosd
    and eax, 0FFFFF000h
    add eax, 1000h
    stosd
    add eax, 1000h
    stosd
    add eax, 1000h
    stosd
    add eax, 1000h
    stosd

    mov rax, r11
    ror rax, 20h
    stosd
    ror rax, 20h
    and rax, 0FFFFFFFFFFFFF000h
    add rax, 1000h
    ror rax, 20h
    stosd
    ror rax, 20h
    add rax, 1000h
    ror rax, 20h
    stosd  
    ror rax, 20h
    add rax, 1000h
    ror rax, 20h
    stosd
    ror rax, 20h
    add rax, 1000h
    ror rax, 20h
    stosd
    pop rdi
    pop rax
    ret


.ehciDevSetupHub:
;Device specific setup. Takes rsi as a ptr to the 
; specific device parameter block.
    push rbx
    push rcx
    push rsi
    push rbp
    xor bp, bp    ;Error Stage 0
.edshub:
    call .ehciHubClassDescriptor
    jc .edsfail
    inc bp  ;Error Stage 1
    mov cl, byte [rsi + 5] ;Get number of ports here
    mov dl, 1   ;Start port number to begin enum on (hub ports start at 1)
.edshub1:
    mov r12, 3
.edshub11:
    call .ehciEnumerateHubPort    ;dl for port to scan/enumerate
    jz .edshub13    ;If ZF=ZR, valid device found!
    cmp byte [msdStatus], 20h  ;General Controller Failure
    je USB.ehciCriticalErrorWrapper
    dec r12
    jnz .edshub11   ;Still not zero but failed, try again.
.edshub13:
    inc dl  ;Start with port 1
    cmp cl, dl
    jae .edshub1
.edshub2:
;Need to write bHostHub for any detected devices here
    clc    ;Common success exit
    pop rbp
    pop rsi
    pop rcx
    pop rbx
    ret

.ehciDeviceSetupMsd:
; Input:  rsi = MSD Device Parameter Block
; Output: CF=CY if catastrophic host error.
;         CF=NC then ax = Return code
;         ax = 0 if successful setup
;         ax = 1 if device did not reset the first time
;         ax = 2 if device did not return a valid LUN
;         ax = 3 if device did not reset the second time
;         Device must me removed from tables and port reset if ax != 0
    push rcx
    push rbp
    push r8
    xor bp, bp    ;Error Stage 0
.edsmsd:
    mov r8, 10h ;Loop counter setup
.edsm1:
    call .ehciMsdDeviceReset
    jc .edsexit
;Check eActiveInterrupt for confirmation if we need to handle error
    test byte [eActiveInt], 2   ;If this is set, handle error
    jz .edsms2
    mov cx, word [rsi + 7]    ;Pass endpoint size
    mov al, byte [rsi]  ;Device address
    call .ehciStandardErrorHandler
    test al, 80h 
    jnz .edsfail   ;If bit 7 is set, something is seriously wrong, fail dev!
    dec r8                ;Dec loop counter
    jz .edsfail           ;Fatal error if after 16 goes nothing was resolved
    jmp short .edsm1
.edsms2:
    inc bp  ;Error Stage 1
.edsms3:
    call .ehciMsdGetMaxLun  ;If stall, clear endpoint and proceed. No loop
    jc .edsexit
    test byte [eActiveInt], 2   ;If this is set, handle error
    jz .edsms4

    mov cx, word [rsi + 7]    ;Pass endpoint size
    mov al, byte [rsi]  ;Device address
    call .ehciStandardErrorHandler
    test al, 80h 
    jnz .edsfail   ;If bit 7 is set, something is seriously wrong, fail dev!
.edsms4:
    inc bp  ;Error Stage 2
    mov r8, 10h ;Loop counter setup
.edsms5:
    call .ehciMsdDeviceReset  ;Reset once again to clear issues
    jc .edsexit
    test byte [eActiveInt], 2   ;If this is set, handle error
    jz .edsms6

    mov cx, word [rsi + 7]    ;Pass endpoint size
    mov al, byte [rsi]  ;Device address
    call .ehciStandardErrorHandler
    test al, 80h 
    jnz .edsfail   ;If bit 7 is set, something is seriously wrong, fail dev!
    dec r8                 ;Dec loop counter
    jz .edsfail           ;Fatal error if after 16 goes nothing was resolved
    jmp short .edsms5
.edsms6:
    inc byte [numMSD] 
    xor ax, ax  ;Note that xor also clears CF
.edsexit:
    pop r8
    pop rbp
    pop rcx
    ret
.edsfail:
;If a fail occurs, then the entry needs to be removed from the data tables
    mov ax, bp
    jmp .edsexit

.ehciEnumerateHubPort:
;Enumerates devices on an external Hub.
;Use rsi to get device properties
;Input: rsi = ptr to hub device block
;       dl = Port number to reset
;Output: None, CF

    push rbx
    push rcx
    push rdx
    push rbp
    push r8
    push r9
    push r10
    push r11

    movzx edx, dl
    shl rdx, 4*8    ;Shift port number to right bits
.eehdeinit:
    xor bp, bp  ;Error counter
    movzx r9, word [rsi]        ;Save hub bus/addr in r9w
    movzx r8, byte [rsi + 4]    ;Get MaxPacketSize0

.eehde0:
    mov rbx, 0000000000080323h  ;Set port power feature
    or rbx, rdx ;Add port number into descriptor
    mov cx, r8w
    mov al, r9b
    call .ehciSetNoData   ;Turn on power to port on device in addr al
    jc .eehdecritical  ;Fast exit with carry set
.eehde1:
;Power on debounce!
    mov ah, 86h
    movzx ecx, byte [rsi + 6]   ;poweron2powergood
    shl ecx, 1
    int 35h

    inc bp      ;Increment Error Counter    (Stage 1)
.eehde2:
    mov rbx, 0000000000100123h  ;Clear port set connection bit
    or rbx, rdx ;Add port number into descriptor
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
    jc .eehdecritical  ;Fast exit with carry set
.eehde3:

    inc bp      ;Increment Error Counter    (Stage 2)
.eehde31:
    mov rbx, 00040000000000A3h ;Get port status
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciGetRequest
    jc .eehdecritical  ;Fast exit with carry set
.eehde4:
    inc bp      ;Increment Error Counter    (Stage 3)

    mov cl, byte [ehciDataIn]   ;Get the first byte in into cx
    test cl, 1  ;Check device in port
    jz .eehdebadnotimeout

.eehde41:   ;EP for first port reset state
    inc bp      ;Increment Error Counter    (Stage 4)
    call .eehdereset    ;First port reset
    jc .eehdecritical  ;Fast exit with carry set

    inc bp      ;Increment Error Counter    (Stage 5)

    mov r11, 10h
.eehde5:
    mov rbx, 00040000000000A3h ;Get port status again
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciGetRequest
    jc .eehdecritical  ;Fast exit with carry set
.eehde6:
    inc bp      ;Increment Error Counter    (Stage 6)
;Now check for high speed

    mov cx, word [ehciDataIn]
    and cx, 7FFh    ;Zero upper bits
    shr cx, 9   ;Bring bits [10:9] low
    cmp cx, 2   ;2 is High Speed device
    jne .eehdebadnotimeout
    mov qword [ehciDataIn], 0

    inc bp      ;Increment Error Counter    (Stage 7)

    push rdi
    mov rdi, ehciDataIn
    mov ecx, 8
    xor eax, eax
    rep stosq
    pop rdi
.eehde7:
    mov rbx, 0000000000120123h  ;Clear port suspend
    or rbx, rdx ;Add port number into descriptor
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
    jc .eehdecritical  ;Fast exit with carry set

.eehde10:
    mov rbx, 00008000001000680h    ;Pass get minimal device descriptor
    mov cx, 40h    ;Pass default endpoint size
    xor al, al
    call .ehciGetRequest
    jc .eehdecritical  ;Fast exit with carry set
.eehde101:
    inc bp      ;Increment Error Counter    (Stage 8)

    cmp byte [ehciDataIn + 1], 01h    ;Verify this is a valid dev descriptor
    jne .eehdebad       ;ehciDataIn contains error signature

;Sanity check the returned descriptor here
.eehde11:
    cmp word [ehciDataIn + 2], 0200h    ;Verify this is a USB 2.0+ device or
    jb .eehdebad
    cmp byte [ehciDataIn + 4], 0    ;Check interfaces
    je .eehde12
    cmp byte [ehciDataIn + 4], 08h    ;MSD?
    je .eehde12
    cmp byte [ehciDataIn + 4], 09h    ;Hub?
    jne .eehdebad

.eehde12:    ;Valid device detected
    movzx r8d, byte [ehciDataIn + 7]   ;Save attached device max ep size
.eehde13: 
    call .eehdereset    ;Do second reset
    jc .eehdecritical  ;Fast exit with carry set
;Clear the data in buffer
    push rdi
    mov rdi, ehciDataIn
    mov ecx, 8
    xor eax, eax
    rep stosq
    pop rdi

;Device on port now ready to have an address set to it, and be enumerated
    shr rdx, 4*8    ;Shift port number back down to dl
    mov ax, word [rsi]  ;Get hub bus/addr pair
    mov dh, ah          ;Move the bus number into dh
    movzx r10d, al      ;Move hub address into r10b
;Ensure dl=port number - 1, dh=Root hub (Bus) number, r10b=Host hub number
;       r8b=Max Control EP endpoint size
    mov r11, 100    ;Address settle time
    dec dl
    jmp .ehciEnumCommonEp

.eehdebad:
.eehdebadnoport:    ;EP if done without disabling port
    jmp .ehciedbadnoport
.eehdebadnotimeout:
    jmp .ehciedbadnotimeout
.eehdebadremtables:
    jmp .ehcibadremtables
.eehdecritical:
    jmp .ehciedexit  ;Fast exit with carry set
.eehdereset:
;rsi must point to valid Hub device block
    mov rbx, 0000000000040323h  ;Reset port 
    or rbx, rdx ;Add device address
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
    jc .eehcritexit

    mov r11, 5000 ;Just keep trying
.eehder1:
    mov ah, 86h
    mov ecx, 20     ;20 ms is max according to USB 2.0 standard
    int 35h

    mov rbx, 00040000000000A3h ;Get port status
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciGetRequest
    mov cl, byte [ehciDataIn]   ;Get low byte of in data
    test cl, 10h    ;If bit not set, reset over, proceed
    jz .eehder2
    dec r11
    jnz .eehder1
.eehder2:
    mov rbx, 0000000000140123h ;Clear port reset bit
    or rbx, rdx
    mov cl, r8b
    mov al, r9b
    call .ehciSetNoData
.eehcritexit:
    ret

.ehciHubClassDescriptor:
;Gets the Hub class descriptor
;Get Hub descriptor for device pointed to by rsi
;If invalid data, returns error
;Input: rsi = Ptr to hub data block
;Output:
;   Carry Clear if success
;   Carry Set if fail, al contains error code
    push rbx
    push rcx
    push rbp
    mov bp, 3

    mov rbx, 00070000290006A0h  ;Get Hub descriptor (only first 7 bytes)
    movzx ecx, byte [rsi + 4]  ;bMaxPacketSize0
    mov al, byte [rsi]      ;Get device address
    call .ehciGetRequest
    jc .ehcdfail    ;Errors 0-2 live here

    inc bp
    cmp byte [ehciDataIn + 1], 29h  ;Is this a valid hub descriptor
    jne .ehcdfail

    mov cl, byte [ehciDataIn + 2]   ;Get number of downstream ports
    mov byte [rsi + 5], cl  ;Store in variable, marking device as configured

    mov cl, byte [ehciDataIn + 5]   ;Get PowerOn2PowerGood
    mov byte [rsi + 6], cl  ;Store in variable
    clc
.ehcdexit:
    pop rbp
    pop rcx
    pop rbx
    ret
.ehcdfail:
    mov al, bpl
    stc
    jmp short .ehcdexit
;                        ---------MSD functions---------
.ehciMsdInitialise:
;Initialises an MSD device.
;Input: rsi = Valid MSD device block
;Output: CF=CY: Init did not complete
;        al = 0 => Device initialised
;        al = 1 => Host/Schedule error
;        al = 2 => Device failed to initialise
;        CF=NC: Init complete, rsi points to complete USB MSD device block
    push rcx
    mov al, byte [rsi + 1]  ;Get the bus number into al
    call .ehciAdjustAsyncSchedCtrlr
    mov al, 1
    jc .ehciMsdInitFail
    call .ehciDeviceSetupMsd
    mov al, 2
    jc .ehciMsdInitFail
    call .ehciMsdBOTInquiry
    jc .ehciMsdInitFail
    mov ecx, 5
.emi0:
    call .ehciMsdBOTReadFormatCapacities
    cmp byte [msdStatus], 20h   ;Host error
    je .ehciMsdInitialisePfail  ;Protocol fail
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emipf0
    call .ehciMsdBOTModeSense6
    cmp byte [msdStatus], 20h   ;Host error
    je .ehciMsdInitialisePfail  ;Protocol fail
    call .ehciMsdBOTCheckTransaction
    test ax, ax     ;Also clears CF if zero
    jnz .emipf0
.ehciMsdInitExit:
    pop rcx
    ret
.ehciMsdInitFail:
    mov ax, word [rsi]
    call .ehciRemoveDevFromTables
    dec byte [numMSD]   ;Device was removed from tables, decrement
    stc
    mov al, 2
    jmp short .ehciMsdInitExit
.ehciMsdInitialisePfail:
    call .ehciMsdBOTResetRecovery
    dec ecx
    jz .ehciMsdInitFail
.emipf0:
    call .ehciMsdBOTRequestSense
    cmp byte [msdStatus], 20h
    je .ehciMsdInitialisePfail
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jz .emi0
    jmp short .ehciMsdInitialisePfail

.ehciMsdDeviceReset:
;Reset an MSD device on current active EHCI bus
;Input: rsi = Pointer to table data structure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check reset occurred successfully 
;          (If eActiveIntr AND 2 != 0, then error in transfer)
    push rcx
    push rdx
    push rbx
    push rax

    movzx ecx, byte [rsi + 7]  ;Get bMaxPacketSize0
    movzx rdx, byte [rsi + 4]  ;Get Interface Number
    shl rdx, 5*8 ;Send to 5th byte
    mov rbx, 0FF21h            ;MSD Reset
    or rbx, rdx                ;And those bytes
    mov al, byte [rsi]
    call .ehciSetNoData

    pop rax
    pop rbx
    pop rdx
    pop rcx
    ret

.ehciMsdGetMaxLun:
;Get max LUN of an MSD device on current active EHCI bus
;Input: rsi = Pointer to table data structure
;       al = Address
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
;   Max Lun saved at DataIn Buffer (first byte)
;   Check this was transferred, by checking total data transferred value
    push rcx
    push rdx
    push rbx
    push rax

    movzx ecx, byte [rsi + 7]  ;Get bMaxPacketSize0
    movzx rdx, byte [rsi + 4]  ;Get Interface Number
    shl rdx, 5*8 ;Send to 5th byte
    mov rbx, 000100000000FEA1h            ;MSD Get Max LUN
    or rbx, rdx                ;And those bytes
    mov al, byte [rsi]
    call .ehciGetRequest

    pop rax
    pop rbx
    pop rdx
    pop rcx
    ret

.ehciMsdBOTResetRecovery:
;----------------------------------------------------------------
;Calls the reset recovery procedure on a device ptd to by rsi   :
;Input:  rsi = Pointer to MSD device parameter block            :
;Output: CF=CY if something went wrong. Else CF=NC              :
;----------------------------------------------------------------
;Calls an MSDBBB reset then calls StandardErrorHandler AFTER    : 
; writing the Qhead for each Bulk EP.                           :
;----------------------------------------------------------------
    push rax
    push rbx
    push rcx
    mov word [rsi + 14], 00h    ;Reset clear both endpoint dt bits 

    call .ehciMsdDeviceReset    ;Call the device reset
    jc .embrrexit
;Now clear stall on IN EP
    mov al, byte [rsi]          ;Get the address
    mov bl, byte [rsi + 8]      ;Get the 4 byte EP address
    movzx ecx, byte [rsi + 7]   ;Get the Max packet size for the ctrl EP
    call .ehciClearEpStallHalt
    jc .embrrexit
;Now clear stall on OUT EP
    mov al, byte [rsi]          ;Get the address
    mov bl, byte [rsi + 11]     ;Get the 4 byte EP address
    movzx ecx, byte [rsi + 7]   ;Get the Max packet size for the ctrl EP
    call .ehciClearEpStallHalt
.embrrexit:
    pop rcx
    pop rbx
    pop rax
    ret
.ehciMsdBOTCheckValidCSW:
; This function checks that the recieved CSW was valid.
; If this function returns a non-zero value in al, 
; a reset recovery of the device is required
; Output: al = 0 : valid CSW
;         If CSW not valid, al contains a bitfield describing what failed
;         al = 1h   : CSW is not 13 bytes in length
;         al = 2h   : dCSWSignature is not equal to 053425355h
;         al = 4h   : dCSWTag does not match the dCBWTag
;         al = 0F8h : Reserved
;   rax destroyed
    push rbx
    push rcx
    xor eax, eax
    mov cx, 1
    mov bx, word [ehciTDSpace + 2*ehciSizeOfTD + 0Ah]   
;Get total bytes to transfer from third QHeadTD to see if 13h bytes were 
; transferred
    and bx, 7FFFh   ;Clear upper bit
    cmovnz ax, cx   ;If the result for the and is not zero, <>13 bytes were sent

    shl cx, 1     
    or cx, ax
    cmp dword [msdCSW], CSWSig
    cmovne ax, cx

    mov cx, 4h
    or cx, ax
    movzx ebx, byte [cbwTag]
    dec bl
    cmp bl, byte [msdCSW + 4h]
    cmovne ax, cx

    pop rcx
    pop rbx
    ret

.ehciMsdBOTCheckMeaningfulCSW:
; This function checks if the CSW was meaningful.
; If this function returns a non-zero value in al, it is up to the
; caller to decide what action to take. The possible set of actions that
; can be taken is outlined in Section 6.7 of the USB MSC BOT Revision 1.0 
; specification.
; Output :  al = 0h  : Invalid
;           al = 1h  : bCSWStatus = 0
;           al = 2h  : bCSWStatus = 1
;           al = 4h  : bCSWStatus = 2
;           al = 8h  : bCSWStatus > 2
;           al = 10h : dCSWDataResidue = 0
;           al = 20h : dCSWDataResidue < dCBWDataTransferLength
;           al = 40h : dCSWDataResidue > dCBWDataTransferLength
;           al = 80h : Reserved
;   rax destroyed
    push rbx
    push rcx

    xor eax, eax  ;In the event that things go completely wrong
    mov bx, 8h
    mov cl, byte [msdCSW + 0Ch]

    cmp cl, 2
    cmova ax, bx
    ja .embcmcResidueCheck

    shr bx, 1       ;Shift it down to 4
    cmove ax, bx    ;If bCSWStatus = 2, move it in
    je .embcmcResidueCheck

    shr bx, 1       ;Shift down to 2
    cmp cl, 1
    cmove ax, bx    ;If bCSWStatus = 1, move bx into ax
    je .embcmcResidueCheck

    inc ax          ;Otherwise bCSWStatus = 0
.embcmcResidueCheck:
    mov ecx, dword [msdCSW + 8] ;Get dCSWDataResidue

    mov bx, 10h
    or bx, ax   
    test ecx, ecx
    cmovz ax, bx    ;If its zero, move bx with added bit from ax into ax
    jz .embcmcExit

    mov bx, 20h
    or bx, ax 
    cmp ecx, dword [ehciDataOut + 8];ehciDataOut + 8 = dCBWDataTransferLength
    cmovb ax, bx
    jb .embcmcExit

    or ax, 40h  ;Else, it must be above, fail
.embcmcExit:
    pop rcx
    pop rbx
    ret

.ehciMsdBOTCheckTransaction:
;Check successful return data here
;Output: ax = 0                                 : CSW Valid and Meaningful
;        ah = 1, al = CSW Validity bitfield     : CSW NOT valid
;        ah = 2, al = CSW Meaningful bitfield   : CSW NOT meaningful
;   rax destroyed
    xor ah, ah
    call .ehciMsdBOTCheckValidCSW
    test al, al
    jz .embhiehcswmeaningful
    mov ah, 1       ; CSW Not Valid signature
    jmp .embhiehexit
.embhiehcswmeaningful:
    call .ehciMsdBOTCheckMeaningfulCSW
    and al, 4Ch     ;Check bad bits first and bCSWStatus=02 40h|08h|04h
    jz .embhiehexit
    mov ah, 2       ; CSW Not Meaningful signature
.embhiehexit:
    ret
.ehciMsdBOTOO64I:   ;For devices with 64 byte max packet size
.ehciMsdBOTOI64I:   ;For devices with 64 byte max packet size
    mov byte [msdStatus], 0BBh   ;Undefined error
    ret
.ehciMsdBOTOOI:     ;Out Out In transfer
;Input - rsi = MSD device parameter block
;        rbx = Input buffer for Data In
;        ecx = Number of milliseconds to wait between Out and In packets
;        r8  = Number of bytes to be transferred (for the DATA phase)
;        r10 = LUN Value
;        r11 = Length of CBW command block
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push rcx
    cld

    mov r12, r8     ;Save number of bytes to transfer to MSD device
    push rcx
;Write QHead for CBW
    mov r11, ehciTDSpace ;First TD is the head of the Out buffer
    call .ehciMsdWriteOutQHead
;Write TD for CBW send
    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    movzx r10d, byte [rsi + 15]   ;Get Out EP dt bit
    xor byte [rsi + 15], 1  ;Toggle bit
    ror r10d, 1 ;Roll dt bit to upper bit of dword
    or r10d, 001F8C80h 
; Active TD, OUT EP, Error ctr = 3, 01Fh = 31 byte transfer
    mov r11, ehciDataOut ; Data out buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    pop rcx    ;Wait ecx ms for "motors to spin up"
    jc .emboexit    ;If catastrophic Host system error, exit!

    push rax
    mov ah, 86h
    int 35h
    pop rax
;Write Qhead to Send data
    mov r11, ehciSizeOfTD + ehciSizeOfTD
    call .ehciMsdWriteOutQHead
;Write TD for data send
    mov rdi, r11
    mov r8, 1
    mov r9, r8
    mov r10, r12     ;Get back number of bytes to transfer
    shl r10, 8*2    ;Shift into 3rd byte
    or r10d, 00008C80h ;Add control bits: Active TD, OUT EP, Error ctr = 3
    movzx ecx, byte [rsi + 15]  ;Get Out EP dt bit in r9d
    xor byte [rsi + 15], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, rbx    ;Get the address of Data buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    jc .emboexit    ;If catastrophic Host system error, exit!
;Write Qhead for CSW
    mov r11, ehciTDSpace + 2*ehciSizeOfTD ;Third TD
    call .ehciMsdWriteInQHead
    mov rdi, r11
    jmp .emboiicommonep
.ehciMsdBOTOII: ;Out In In transfer
;Input - rsi = MSD device parameter block
;        rbx = Input buffer for Data In
;        ecx = Number of milliseconds to wait between Out and In packets
;        r8  = Number of bytes to be transferred (for the DATA phase)
;        r10 = LUN Value
;        r11 = Length of CBW command block

    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push rcx
    cld

    mov r12, r8 ;Save the number of bytes to be transferred
    push rcx

;Write the OUT Queue Head
    mov r11, ehciTDSpace ;First TD is the head of the Out buffer
    call .ehciMsdWriteOutQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    movzx r10d, byte [rsi + 15]   ;Get Out EP dt bit
    xor byte [rsi + 15], 1  ;Toggle bit
    ror r10d, 1 ;Roll dt bit to upper bit of dword
    or r10d, 001F8C80h 
; Active TD, OUT EP, Error ctr = 3, 01Fh = 31 byte transfer
    mov r11, ehciDataOut ; Data out buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    pop rcx    ;Wait ecx ms for "motors to spin up"
    jc .emboexit    ;If catastrophic Host system error, exit!
         
    push rax
    mov ah, 86h
    int 35h
    pop rax
;Write the IN Queue Head
    mov r11, ehciTDSpace + ehciSizeOfTD ;Move to position 2 to preserve OUT TD
    call .ehciMsdWriteInQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    lea r8, qword [rdi + ehciSizeOfTD]  ;Point to next TD
    mov r9, r8
    mov r10, r12     ;Get back number of bytes to transfer from the stack
    shl r10, 8*2    ;Shift into 3rd byte
    or r10d, 00000D80h ;Add control bits: Active TD, IN EP, Error ctr = 3
    movzx ecx, byte [rsi + 14]  ;Get IN EP dt bit in r9d
    xor byte [rsi + 14], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, rbx ; Data out buffer, default ehciDataIn
    call .ehciWriteQHeadTD

    add rdi, ehciSizeOfTD     ;Go to next TD space
.emboiicommonep:
    mov r8, 1
    mov r9, r8
    mov r10d, 000D8D80h     ;Active TD, IN EP, Error ctr = 3, 0Dh = 13 byte CSW
    movzx ecx, byte [rsi + 14]  ;Get IN EP dt bit in r9d
    xor byte [rsi + 14], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, msdCSW

    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
.emboexit:
    pop rcx
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    ret
.ehciMsdBOTOI: ;Out In transfer
;Input - rsi = MSD device parameter block
;        rbx = Input buffer for Data In
;        ecx = Number of milliseconds to wait between Out and In packets
;        r8  = Number of bytes to be transferred (for the DATA phase)
;        r10 = LUN Value
;        r11 = Length of CBW command block

    push rdi
    push r8
    push r9
    push r10
    push r11
    push rcx
    cld


;Write the OUT Queue Head
    mov r11, ehciTDSpace ;First TD is the head of the Out buffer
    call .ehciMsdWriteOutQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    movzx r10d, byte [rsi + 15]   ;Get Out EP dt bit
    xor byte [rsi + 15], 1  ;Toggle bit
    ror r10d, 1 ;Roll dt bit to upper bit of dword
    or r10d, 001F8C80h 
; Active TD, OUT EP, Error ctr = 3, 01Fh = 31 byte transfer
    mov r11, ehciDataOut ; Data out buffer
    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
    jc .emboiexit    ;If catastrophic Host system error, exit!
         
;Write the IN Queue Head
    mov r11, ehciTDSpace + ehciSizeOfTD ;Move to position 2 to preserve OUT TD
    call .ehciMsdWriteInQHead

    mov rdi, r11    ;Move pointer to TD buffer head
    mov r8, 1
    mov r9, r8
    mov r10d, 000D8D80h     ;Active TD, IN EP, Error ctr = 3, 0Dh = 13 byte CSW
    movzx ecx, byte [rsi + 14]  ;Get IN EP dt bit in r9d
    xor byte [rsi + 14], 1  ;Toggle bit
    ror ecx, 1 ;Roll dt bit to upper bit of dword
    or r10d, ecx    ;Add dt bit to r10d
    mov r11, msdCSW

    call .ehciWriteQHeadTD

    mov cl, 11b    ;Lock out internal buffer
    call .ehciProcessCommand        ;Run controller
.emboiexit:
    pop rcx
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    ret
.ehciMsdWriteOutQHead:
;Input: rsi = Valid MSD device
;       r11 = Ptr to First QHTD
    call .ehciGetNewQHeadAddr
    or r8d, 2    ;Process QHs
    mov r9d, 00006000h  ;Default mask, no nak counter
    movzx ecx, word [rsi + 12]  ;wMaxPacketSizeOut
    shl ecx, 8*2
    or r9d, ecx
    movzx ecx, byte [rsi + 11]  ;EP address
    and ecx, 0Fh
    shl ecx, 8  ;Shift to second byte 
    or r9d, ecx ;Add bits
    mov al, byte [rsi]  ;Get device address
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    call .ehciWriteQHead
    ret
.ehciMsdWriteInQHead:
;Input: rsi = Valid MSD device
;       r11 = Ptr to First QHTD
    call .ehciGetNewQHeadAddr
    or r8, 2
    mov r9d, 00006000h  ;Default mask
    movzx ecx, word [rsi + 9]  ;wMaxPacketSizeIn
    shl ecx, 8*2
    or r9d, ecx
    movzx ecx, byte [rsi + 8]  ;EP address
    and ecx, 0Fh
    shl ecx, 8  ;Shift to second byte 
    or r9d, ecx ;Add bits
    mov al, byte [rsi]  ;Get device address
    and al, 7Fh    ;Force clear upper bit of al
    or r9b, al    ;Set lower 8 bits of r9 correctly
    mov r10d, 40000000h    ;1 transaction/ms
    call .ehciWriteQHead
    ret
.ehciMsdBOTRequest:
;Input: ecx = Number of miliseconds to wait between Out and In requests
;       rbx = Data in Buffer
;       r8  = Number of bytes to be returned by command
;       r11 = Length of SCSI command block
;       r14 = Pointer to EHCI(USB) transaction function
;       r15 = Pointer to SCSI command function
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rax
    push rcx
    push rdi
    push r9
    push r10
;Clear the previous CSW
    mov rdi, msdCSW
    xor al, al
    mov ecx, 13
    rep stosb
;Write the CBW
    mov rdi, ehciDataOut    ;Write the CBW at the data out point

    mov r9b, 80h            ;Recieve an IN packet
    xor r10, r10            ;LUN 0
    call .msdWriteCBW       ;Write the 15 byte CBW
;Append the Command Block to the CBW
    xor al, al              ;LUN 0 device
    call r15                ;Write the valid CBW Command block
;Enact transaction
    call r14

    pop r10
    pop r9
    pop rdi
    pop rcx
    pop rax
    ret

.ehciMsdBOTInquiry:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Inqure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8d, 024h           ;36 bytes to be returned
    mov r11, 0Ch            ;The command block is 12 bytes (As per Bootability)
    mov r15, .scsiInquiry
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

.ehciMsdBOTReadFormatCapacities:
;Input: 
; rsi = Pointer to MSD table data structure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 0FCh            ;Return 252 bytes
    mov r11, 0Ah            ;The command block is 10 bytes
    mov r15, .scsiReadFormatCapacities
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

.ehciMsdBOTReadCapacity10:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Read Capcities
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 8
    mov r11, 0Ah
    mov r15, .scsiReadCap10
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret
.ehciMsdBOTFormatUnit:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Format
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rax
    push r8
    push r11
    push r14
    push r15
    xor r8, r8  ;Request no data
    mov r11, 06h  ;Command length is 6 bytes
    mov r14, .ehciMsdBOTOI
    mov r15, .scsiFormatUnit
    call .ehciMsdBOTRequest
    jc .embfuerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .embfuerror
.embfu0:
    call .ehciMsdBOTTestReady
    jc .embfuerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jz .embfuexit
    call .ehciMsdBOTRequestSense
    jc .embfuerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .embfu0
.embfuexit:
    pop r15
    pop r14
    pop r11
    pop r8
    pop rax
    ret
.embfuerror:
    stc
    jmp short .embfuexit
.ehciMsdBOTVerify:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Verify Sectors
; edx = Starting LBA to verify
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rax
    push r8
    push r11
    push r12
    push r14
    push r15
    xor r8, r8  ;Request no data
    mov r11, 0Ah  ;Command length is 10 bytes
    mov r12d, edx
    mov r14, .ehciMsdBOTOI
    mov r15, .scsiVerify
    call .ehciMsdBOTRequest
    jc .embvbad
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .embvbad
.embvexit:
    pop r15
    pop r14
    pop r12
    pop r11
    pop r8
    pop rcx
    ret
.embvbad:
    stc
    jmp short .embvexit
.ehciMsdBOTRequestSense:
;Input: 
; rsi = Pointer to device MSD table data structure
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 12h         ;Request 18 bytes
    mov r11, 6          ;Command length is 6
    mov r15, .scsiRequestSense
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

.ehciMsdBOTTestReady:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Test Ready
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push r8
    push r11
    push r14
    push r15
    xor r8, r8  ;Request no data
    mov r11, 6  ;Command length is 6
    mov r14, .ehciMsdBOTOI
    mov r15, .scsiTestUnitReady
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    ret
.ehciMsdBOTModeSense6:
;Input: 
; rsi = Pointer to MSD table data structure that we want to Test Ready
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rbx
    push rcx
    push r8
    push r11
    push r14
    push r15
    mov rbx, ehciDataIn
    mov ecx, 0
    mov r8, 0C0h        ;Request 192 bytes
    mov r11, 6          ;Command length is 6
    mov r15, .scsiModeSense6
    mov r14, .ehciMsdBOTOII
    call .ehciMsdBOTRequest
    pop r15
    pop r14
    pop r11
    pop r8
    pop rcx
    pop rbx
    ret

;.ehciMsdBOTOutSector64:
.ehciMsdBOTOutSector512:
;Input: 
; rsi = Pointer to MSD table data structure that we want to read
; rbx = Address of the buffer to read the segment from
; edx = Starting LBA to read to
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push r9
    push r14
    push r15
    push rax
    xor r9, r9 ;Send an OUT packet
    mov r14, .ehciMsdBOTOOI
    mov r15, .scsiWrite10
    call .ehciMsdBOTSector512
    jc .emboseerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emboseerror
    call .ehciMsdBOTTestReady   ;Seems to flush data onto disk
    jc .emboseerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emboseerror
.embosexit:
    pop rax
    pop r15
    pop r14
    pop r9
    ret
.emboseerror:
    stc
    jmp short .embosexit
;.ehciMsdBOTInSector64:
.ehciMsdBOTInSector512:
;Input: 
; rsi = Pointer to MSD table data structure that we want to read
; rbx = Address of the buffer to read the segment into
; edx = Starting LBA to read from
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push r9
    push r14
    push r15
    push rax
    mov r9, 80h ;Recieve an IN packet
    mov r14, .ehciMsdBOTOII
    mov r15, .scsiRead10
    call .ehciMsdBOTSector512
    jc .emboseerror
    call .ehciMsdBOTCheckTransaction
    test ax, ax
    jnz .emboseerror
    jmp short .embosexit
.ehciMsdBOTSector512:
;Input: 
; rsi = Pointer to MSD table data structure that we want to read
; rbx = Address of the buffer to read the segment into
; edx = Starting LBA to read to/from
; r9  = CBW flag (IN or OUT transaction)
; r15 = SCSI function
;Output:
;   CF=CY: Host error, Reset host system
;   CF=NC: Transaction succeeded, check data transferred successfully
    push rdi
    push r8
    push r10
    push r11

    mov rdi, ehciDataOut    ;Write the CBW at the data out point
    mov r8d, 200h           ;512 bytes to be transferred
    xor r10, r10            ;LUN 0
    mov r11, 0Ch            ;The command block is 10 bytes long
    call .msdWriteCBW     ;Write the CBW

    push rax                ;Temp push ax
    push r8                 ;Temp save # of bytes for transfer
    xor al, al              ;LUN 0 device
    mov r8d, edx            ;Starting LBA to read from
    mov r9, 1               ;Number of LBAs to read
    call r15                ;Write the valid CBW Command block
    pop r8
    pop rax

    mov ecx, 10              ;Wait for data preparation, 10ms
    call r14

    pop r11
    pop r10
    pop r8
    pop rdi
    ret
.msdWriteCBW:
;Writes a Command Block Wrapper at the location pointed to by rdi
; without a functional command block. Must be appended by user.
; Input:  rdi=Pointer to CBW buffer
;         r8d=Command Block Wrapper Data Transfer Length
;         r9b=Command Block Wrapper Flags
;         r10b=Command Block Wrapper LUN nybble
;         r11b=Command Block Wrapper Command Block Length
; Output: rdi = Pointer to CBW's (SCSI) Command Descriptor Block buffer
    push rax
    mov eax, CBWSig
    stosd
    movzx eax, byte [cbwTag]
    inc byte [cbwTag]
    stosd
    mov eax, r8d
    stosd
    mov al, r9b
    stosb
    mov al, r10b
    stosb
    mov al, r11b
    stosb
    xor eax, eax
    push rdi
    stosq   ;16 bytes in csw command block
    stosq   ;Clear memory
    pop rdi
    pop rax
    ret

;                        --------SCSI functions---------

.scsiInquiry:
;Writes an inquiry scsi command block to the location pointed to by rdi
;al contains the LUN of the device we are accessing. (lower 3 bits considered)
;al not preserved
    mov ah, 12h        ;Move inquiry command value high
    shl al, 5        ;Shift left by five to align LUN properly
    xchg ah, al        ;swap ah and al
    stosw            ;Store command and shifted LUN together
    xor rax, rax
    stosw            ;Store two zeros (reserved fields)
    mov rax, 24h    ;Allocation length (36 bytes)
    stosq
    ret
;NOTE! Using read/write 10 means can't read beyond the first 4 Gb of Medium.
.scsiWrite10:
;Writes a scsi write 10 transfer command to the location pointed at by rdi
;al contains the LUN of the device we are accessing
;r8d contains the LBA start address
;r9w contains the Verification Length
    mov ah, 2Ah        ;Operation code for command
    jmp short .scsirw
.scsiRead10:
;Writes a scsi Read 10 command to the location pointed to by rdi
;al contains the LUN of the device we are accessing.
;r8d contains the LBA to read from
;r9w contains the number of contiguous blocks to read (should be 1 for us)
    mov ah, 28h        ;Move read(10) command value high
.scsirw:
    shl al, 5        ;Shift left by five to align LUN properly
    xchg ah, al        ;swap ah and al
    stosw            ;Store command and shifted LUN together
    bswap r8d        ;swap endianness of r8d
    mov eax, r8d
    stosd
    xor rax, rax    ;Clear for a Reserved byte
    stosb
    mov ax, r9w        ;move into ax to use xchg on upper and lower bytes
    xchg al, ah        ;MSB first, yuck yuck yuck
    stosw
    shr eax, 16        ;Bring zeros down onto lower word
    stosw            ;Store one reserved byte and two padding bytes
    stosb            
    ret
.scsiRequestSense:
;Writes a scsi Request Sense command to the location pointer to by rdi
;al contains the LUN of the device we are accessing.
    mov ah, 03h        ;Move reqsense command value high
    shl al, 5        ;Shift left by five to align LUN properly
    xchg ah, al        ;swap ah and al
    stosw            ;Store command and shifted LUN together
    xor rax, rax    
    stosw            ;Reserved word
    mov al, 12h    ;Move alloc length byte into al
    stosq
    ret
.scsiTestUnitReady:
;Writes a scsi test unit ready command to the location pointed to by rdi
;al contains the LUN of the device we are accessing.
    xor ah, ah        ;Operation code zero
    shl al, 5
    xchg ah, al
    stosw            ;Store shifted LUN and command code
    ret
.scsiReadFormatCapacities:
;al contains the LUN of the device
    mov ah, al
    mov al, 23h        ;Operation code for command
    stosw            ;Store shifted LUN and command code
    xor rax, rax
    stosd          ;Reserved dword    
    stosw           ;Reserved word
    mov al, 0FCh    ;Move alloc length byte into al
    stosb
    ret
.scsiReadCap10:
;Writes a scsi read capacity command to the location pointed to by rdi
;al contains the LUN of the device we are accessing
    mov ah, 25h        ;Operation code for command
    shl al, 5
    xchg ah, al
    stosw            ;Store shifted LUN and command code
    ret
.scsiFormatUnit:
;Writes a scsi format unit command to the location pointed to by rdi
;al contains the LUN of the device we are accessing
    mov ah, 04h        ;Operation code for format command
    shl al, 5
    or al, 17h      ;Set bits [3:0] and 5, keep bit 4 clear
    xchg ah, al
    stosw
    xor al, al
    stosw            ;Vender specific, set to 0!!
    xor rax, rax
    stosq            ;Store LSB byte and all the 0 padding
    ret
.scsiVerify:
;Writes a scsi verify transfer command to the location pointed at by rdi
;al contains the LUN of the device we are accessing
;r12d contains the LBA for the sector address
;Verifies one sector
    mov ah, 2Fh        ;Operation code for command
    shl al, 5        ;Hardcode bytecheck (byte [1]) to 0
    xchg ah, al
    stosw            ;Store shifted LUN and command code
    bswap r12d        ;swap endianness of r12d
    mov eax, r12d
    stosd
    xor rax, rax    ;Clear for a Reserved byte
    stosb
    mov ax, 0100h    ;Write the number 1 in Big endian
    stosw
    shr eax, 16        ;Bring zeros down onto lower word
    stosw            ;Store one reserved byte and two padding bytes
    stosb        
    ret
.scsiModeSense6:
;al contains the LUN of the device we are accessing
    mov ah, 1Ah     ;Operation code for Mode Sense 6
    shl al, 5       ;Move LUN
    xchg ah, al
    stosw
    mov eax, 0C0003Fh    
    ;Request all pages, reserve byte, 192 bytes and 0 end byte
    stosd
    ret
;                    -------------------------------
.ehciGetOpBase:
;Gets opbase from mmio base (aka adds caplength) into eax
;Input:
; al = offset into ehci table
;Return:
; eax = opbase (low 4Gb)
    push rbx
    xor rbx, rbx
    movzx rax, al
    mov eax, dword [eControllerList + 4 + 8*rax]    ;get mmiobase into eax
    test eax, eax             ;addrress of 0 means no controller
    jz .egob1
    movzx ebx, byte [eax]    ;get the offset to opbase into ebx
    add eax, ebx            ;add this offset to mmiobase to get opbase
.egob1:
    pop rbx
    ret

;====================================CPU Interrupts=============================
i0:
    xor rax, rax
    jmp cpu_2args
i1:
    mov rax, 1
    jmp cpu_2args
i2:
    mov rax, 2
    jmp cpu_2args
i3:
    mov rax, 3
    jmp cpu_2args
i4:
    mov rax, 4
    jmp cpu_2args
i5:
    mov rax, 5
    jmp cpu_2args
i6:
    mov rax, 6
    jmp cpu_2args
i7:
    mov rax, 7
    jmp cpu_2args
i8:
    mov rax, 8
    jmp cpu_3args
i9:
    mov rax, 9
    jmp cpu_2args
i10:
    mov rax, 0Ah
    jmp cpu_3args
i11:
    mov rax, 0Bh
    jmp cpu_3args
i12:
    mov rax, 0Ch
    jmp cpu_3args
i13:
    mov rax, 0Dh
    jmp short cpu_3args
i14:
    mov rax, 0Eh
    jmp short cpu_4args
i15:
    mov rax, 0Fh
    jmp short cpu_2args
i16:
    mov rax, 10h
    jmp short cpu_2args
i17:
    mov rax, 11h
    jmp short cpu_3args
i18:
    mov rax, 12h
    jmp short cpu_2args
i19:
    mov rax, 13h
    jmp short cpu_2args
i20:
    mov rax, 14h
    jmp short cpu_2args
i21:
    mov rax, 15h
cpu_4args:
    mov rcx, 3
    jmp short cpu_exception
cpu_3args:
    mov rcx, 2
    jmp short cpu_exception
cpu_2args:
    mov rcx, 1
cpu_exception:
    push rax
    push rcx
    mov bx, 001Fh    ;cls attribs
    call cls

    mov rax, 0200h
    xor rbx, rbx
    mov rdx, 0722h    ;7 Rows down, 24 columns across
    mov rbp, .fatalt0
    mov bx, 0071h     ;blue grey attribs, page 0
    mov ax, 1301h     ;print zero 8 chars, with bh attrib
    mov rcx, 8
    int 30h

    mov rax, 0200h
    xor bh, bh
    mov rdx, 0A04h    ;11 Rows down, 24 columns across
    int 30h
    mov rbp, .fatal1
    xor bh, bh        ;blue grey attribs, page 0
    mov ax, 1304h            ;print zero terminated string
    int 30h

    pop rcx
    pop rax                ;pop the exception number back into rax
    call .printbyte

    mov rax, 1304h
    xor bh, bh
    mov rbp, .fatal2
    int 30h

    cmp cl, 1
    ja .cpuextendederror    ;rax contains error code, or extra cr2 value
.cpurollprint:
    mov rdx, qword [rsp]    ;Get address
;Takes whats in rdx, rols left by one byte, prints al
    mov cl, 8    ;8 bytes
.cpurollprint1:
    rol rdx, 8
    mov al, dl
    push rdx
    call .printbyte
    pop rdx
    dec cl
    jnz .cpurollprint1

.cpuexendloop:
    xor ax, ax
    int 36h
    cmp al, 1Bh    ;Check for escape pressed (unlikely?)
    je .cpu_exception_appret
    cmp al, 0Dh ;Check for enter pressed
    jne .cpuexendloop

    mov bx, 0007h    ;cls attribs
    call cls
    int 38h    ;Jump to debugger
.cpu_exception_appret:
    mov bx, 0007h    ;cls attribs
    call cls
    iretq ;Return to address on stack

.cpuextendederror:
    pop rdx
    dec rcx
    push rcx
    mov cl, 2    ;CAN CHANGE TO 4 BYTES IN THE FUTURE
.pr1:
    rol edx, 8    ;Print just edx
    mov al, dl
    push rdx
    call .printbyte
    pop rdx
    dec cl
    jnz .pr1

    mov rax, 1304h
    mov rbx, 17h
    mov rbp, .fatal2
    int 30h
    pop rcx    ;Bring the comparison value back into rcx
    
    dec rcx
    jz .cpurollprint

    mov cl, 8
    mov rdx, cr2    ;Get page fault address
.pr2:
    rol rdx, 8    ;Print rdx
    mov al, dl
    push rdx
    call .printbyte
    pop rdx
    dec cl
    jnz .pr2

    mov rax, 1304h
    mov rbx, 17h
    mov rbp, .fatal2
    int 30h
    
    jmp .cpurollprint


.char:    ;Print a single character
    mov rbx, .ascii
    xlatb    ;point al to entry in ascii table, using al as offset into table
    ;xor bh, bh
    mov ah, 0Eh
    int 30h    ;print char
    ret
.printbyte:
    mov dl, al            ;save byte in dl
    and ax, 00F0h        ;Hi nybble
    and dx, 000Fh        ;Lo nybble
    shr ax, 4            ;shift one hex place value pos right
    call .char
    mov ax, dx            ;mov lo nybble, to print
    call .char
    ret    
.fatalt0:  db "SCP/BIOS"
.fatal1:   db "A potentially fatal error has occured. To continue: ",0Ah,0Ah,0Dh
db "    Press Enter to launch SYSDEBUG, or",0Ah,0Ah,0Dh 
db "    Press ESC to try and return to the application which caused the error," 
db "or", 0Ah, 0Ah,0Dh,
db "    Press CTRL+ALT+DEL to restart your system. If you do this,",0Ah,0Dh
db "    you will lose any unsaved information in all open applications.",0Ah, 
db 0Ah, 0Dh
db "    Error: ",0
.fatal2:   db " : ",0
.ascii:    db '0123456789ABCDEF'
;==========================Dummy Interrupts======================
dummy_interrupt:
.pic2:
    push rax
    mov al, EOI
    out pic2command, al    ;EOI to pic2
    jmp short .p1
.pic1:
    push rax
.p1:
    mov al, EOI
    out pic1command, al    ;EOI to pic2
    pop rax
dummy_return_64:
    iretq
;----------------------------------------------------------------
signature:    db "v0.9 SCPBIOS"    ;12 byte signature
signature2:   db "Copyright (C) Yll Buzoku"
              db "03/12/2021"

codeResidentEndPtr:
residentLength  equ $-$$