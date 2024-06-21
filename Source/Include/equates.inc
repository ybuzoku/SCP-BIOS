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
;                ------xHCI equates------
struc xhciCapRegs
;xHCI Host Controller Capability Registers. All entries are RO.
;The ptr to these regs is obtained from the PCI entry for this controller
    .bCAPLENGHT     db ?
    .bResvd         db ?
    .wHCIVERSION    dw ?    ;Interface Version Number
    .dHCSPARAMS1    dd ?    ;Structural Parameters 1
    .dHCSPARAMS2    dd ?    ;Structural Parameters 2
    .dHCSPARAMS3    dd ?    ;Structural Parameters 3
    .dHCCPARAMS1    dd ?    ;Capability Parameters 1
    .dDBOFF         dd ?    ;Doorbell Offset
    .dRTSOFF        dd ?    ;Runtime Register Space Offset
    .dHCCPARAMS2    dd ?    ;Capability Parameters 2
    ;CAPLENGTH - 20h are all reserved
endstruc

struc xhciOpRegs
;xHCI Operational Registers. These registers are found past the end of the 
; capability registers.
    .dUSBCMD    dd ?    ;USB Command reg
    .dUSBSTS    dd ?    ;USB Status reg
    .dPAGESIZE  dd ?    ;Page size
    .res1       dd 2 dup (?)
    .dDNCTRL    dd ?    ;Device Notification Control
    .dCRCR      dd ?    ;Command Ring Control
    .res2       dd 4 dup (?)
    .dDCBAAP    dd ?    ;Device Context Base Address Array Pointer
    .dCONFIG    dd ?    ;Configuration register
    .res3       dd 241 dup (?)  ;Align to 400h, where the port regs start
endstruc

struc xhciPortReg
    .dPORTSC    dd ?
    .dPORTPMSC  dd ?
    .dPORTLI    dd ?
    .dPORTHLPMC dd ?
endstruc

;                ------------------------
;                -------MSD equates------
setupReset       equ 0FFh
setupGetMaxLUN   equ 0FEh
;                ------------------------
;                ------Bulk Storage equates------
CBWSig           equ    043425355h
CSWSig           equ    053425355h
CBWFlagOut       equ    00h    ;Switch to send to device
CBWFlagIn        equ    80h    ;Switch to recieve from
bCSWPassed       equ    00h
bCSWFailed       equ    01h
bCSWPhase        equ    02h
;                ------------------------
;------------------USB Table equates------------------
usbMaxDevices   equ 10
usbDevTblSz     equ usbMaxDevices  ;Number of Entries in the usb device table!
struc usbDevTblEntry
    .bAddr      db ?    ;Dev Addr
    .bBus       db ?    ;Root hub
    .bClassCde  db ?    ;A usbDevClass_* value
endstruc
;USB device Class codes
usbDevClass_MSD equ 8
usbDevClass_Hub equ 9

;------------------Hub Table equates------------------
hubDevTblSz     equ 10  ;Number of Entries in the hub device table!
struc hubDevTblEntry
    .bAddr      db ?    ;The assigned device address
    .bBus       db ?    ;Host Bus [Root hub]
    .bHostHub   db ?    ;Address of Hub we are attached to or 0 for Root
    .bHubPort   db ?    ;Port number we are inserted in
    .bMaxPacketSize0    db ?    ;Max packet size to endpoint 0
    .bNumPorts  db ?    ;Number of downstream ports on hub
    .bPowerOn2PowerGood db ?  ;Time in units of 2ms for dev on port to turn on
    .bRes       db ?    ;Endpoint address, for when we add interrupt eps
;   If bNumPorts=0 => Hub needs to undergo Hub Config
endstruc

;------------------MSD Table equates------------------
msdDevTblSz     equ 10  ;Number of Entries in the msd device table :)
struc msdDevTblEntry 
    .bAddr      db ?    ;The assigned device address
    .bBus       db ?    ;Host Bus [Root hub]
    .bHostHub   db ?    ;Address of Hub we are attached to or 0 for Root
    .bHubPort   db ?    ;Port number we are inserted in
    .bIFNum     db ?    ;Interface number being used
    .bIFSClass  db ?    ;A msdIFSC_* value
    .bIFProt    db ?    ;A <sdIFProt_* value
    .bMaxPacketSize0    db ?    ; Max packet size to endpoint 0
    .bEPInAddr  db ?    ;4 bit address of IN EP
    .wMaxPacketSizeIn   dw ?    ;Max packet size to chosen In endpoint
    .bEPOutAddr db ?    ;4 bit address of OUT EP
    .wMaxPacketSizeOut  dw ?    ;Max packet size to OUT endpoint
;These past two bytes are temporarily kept separate! Will bitstuff later
;These two are EHCI data only.
    .bInEPdt    db ?    ;In Endpoints' dt bit
    .bOutEPdt   db ?    ;Out Endpoints' dt bit
endstruc
;Interface Subclass types for MSD 
msdIFSC_Dflt    equ 0   ;Default = SCSI Interface Subclass
msdIFSC_SCSI    equ 6   ;SCSI Interface Subclass 
msdIFSC_UFI     equ 4   ;UFI Interface Subclass (Not yet supported...)
;Interface Protocol types for MSD
msdIFProt_BBB   equ 50h ;BBB protocol
msdIFProt_iCBI  equ 0   ;CBI (not supported)
msdIFProt_CBI   equ 1   ;CBI without interrupt (not supported)
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
ideCtrlrTblSz   equ     2   ;Max 2 controllers
struc ideCtrlrTblEntry
    .dPCIAddress    dd ?    ;PCI IO address of controller
    .dPCIBAR4       dd ?    ;PCI BAR4, the Bus Mastery address
; Note that this address is given with the bottom nybble indicating
; if the address is IO or MMIO. Bit set => IO
endstruc
;----------------------FDD equates---------------------------
fdd_base        equ    3F0h
;----------------------ATA equates---------------------------
fdiskTblSz  equ 4   ;Max 4 ATA disks on a system
struc fdiskTblEntry
    .signature  db ? 
    ;CHS really shouldnt be used
    .wHeads     dw ?  ;Number of CHS Heads
    .wCylinder  dw ?  ;Number of CHS Cylinders
    .wSecTrc    dw ?  ;Number of CHS Sectors per Track
    .lbaMax     dd ?  ;Number of maximum sector accessible by LBA28
    .lbaMax48   dq ?  ;Number of maximum sector accessible by LBA48
    .ioBase     dw ?  ;IO Base address
    .msBit      db ?  ;Master Slave bit in 0A0h/0B0h format
endstruc
;.signature is as follows:
;.signature[0] set = Device present and OK to use.
;.signature[1] set = LBA 28 supported, detected by non-zero LBA28 field
;.signature[2] set = LBA 48 supported, detected by bit set AND non-zero 
;                       LBA 48 sectors field
;.signature[7:3] = Reserved
;Bitfield equates
    fdePresent  equ 1
    fdeLBA28    equ 2
    fdeLBA48    equ 4

;Equates for the ATA identify command
    idCurrCyl   equ 2*54    ;54th word
    idCurrHed   equ 2*55    ;55th word
    idCurrSecTk equ 2*56    ;56th word
    idLBASectrs equ 2*60    ;60th word
    idLBA48Sec  equ 2*100   ;100th word
;----------------------Int 33h Equates-----------------------
i33DevTblSz     equ 10h   ;10 i33 devices.

struc i33DevTblEntry
    .bDevType   db ?    ;A ddDevType_* type value
    .wDevAddr   dw ?    ;USB Address/Bus pair OR local device table address
    .dBlockSize dd ?    ;Dword size of LBA block (should be 512 for remdev)
    .qLastLBA   dq ?    ;Last LBA address (OS WILL subtract 1)
    .bEPSize    db ?    ;EP size for sector xfr. ddDevEPSize_* value.
endstruc
;REMEMBER: LBA SECTOR 0 IS CHS SECTOR 0,0,1 !!

;Disk device Max IO to EP size
ddDevEPSize_low equ 1   ;64 byte max IO size to EP. Unsupported and not used.
ddDevEPSize_reg equ 2   ;512 byte IO size to EP.
ddDevEPSize_big equ 3   ;4096 byte IO size to EP. Not yet supported

;Disk device types 
ddDevType_free  equ 0   ;Free table entry
ddDevType_eMSD  equ 1   ;MSD on an EHCI bus
ddDevType_xMSD  equ 2   ;MSD on an xHCI bus
ddDevType_fdd   equ 3   ;Physical FDD (unsupported)
ddDevType_ata   equ 4   ;Physical ATA device 
ddDevType_atapi equ 5   ;Physical ATAPI device (partially supported)

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