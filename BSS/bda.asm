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
ata0CmdByte     resb 1  ;Contains bitfield of instructions
ata0Status      resb 1  ;Contains the status of the last transaction
ata1CmdByte     resb 1
ata1Status      resb 1
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
fdiskTable:     resb 4*fdiskEntry_size  ;Max 4 fixed disks
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