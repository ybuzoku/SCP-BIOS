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