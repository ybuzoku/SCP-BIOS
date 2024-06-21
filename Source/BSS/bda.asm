;Refer to MEMMAP.TXT for memory address reference!
;If Interrupt call is faulty, Carry will be set AND either:
;                    ah=80h => Invalid function.
;                    ah=86h => Not (yet) supported.
;------------------------------Data Area-------------------------
IDTlength       dw ? ;Maximum number of Interrupts is 256
IDTpointer:
.Limit          dw ?
.Base           dq ?

GDTlength       dw ?
GDTpointer:
.Limit          dw ?
.Base           dq ?

pageTablePtr:   dq ?
;----------------------------------------
;       Spurious Interrupt counter      :
;----------------------------------------
spurint1        db ?    ;Keep track of how many spur ints on pic1
spurint2        db ?    ;pic 2
;----------------------------------------
;            Keyboard Data Area         :
;----------------------------------------
kb_buffer       dw 10h dup (?)
kb_buf_head     dq ?    ;Pointer to Keyboard buffer head
kb_buf_tail     dq ?    ;Pointer to Keyboard buffer tail 
kb_buf_start    dq ?    ;Pointer for circular buffer start
kb_buf_end      dq ?    ;Ditto..., for end
kb_flags        db ?    ;Keyboard state flags
kb_flags_1      db ?    ;Extended flags, empty for now
kb_flags_2      db ?    ;Bit 0 = E1 present, Bit 1 = E0 present
break_flag      db ?    ;Well, its not for the Print Screen key
;----------------------------------------
;            Serial Data Area           :
;----------------------------------------
numCOM          db ?  ;Number of Serial Ports
com_addresses   dw 4 dup (?)     ;Space for 4 IO addresses

comX_buffer:
com1_buffer     db 10h dup (?)
com2_buffer     db 10h dup (?)
com3_buffer     db 10h dup (?)
com4_buffer     db 10h dup (?)

comX_buf_head:
com1_buf_head   dq ?
com2_buf_head   dq ?
com3_buf_head   dq ?
com4_buf_head   dq ?

comX_buf_tail:
com1_buf_tail   dq ?
com2_buf_tail   dq ?
com3_buf_tail   dq ?
com4_buf_tail   dq ?

comX_buf_start:
com1_buf_start  dq ?
com2_buf_start  dq ?
com3_buf_start  dq ?
com4_buf_start  dq ?

comX_buf_end:
com1_buf_end    dq ?
com2_buf_end    dq ?
com3_buf_end    dq ?
com4_buf_end    dq ?

;----------------------------------------
;            Printer Data Area          :
;----------------------------------------
prt_addresses   dw 3 dup (?)    ;Space for 3 IO addresses
;----------------------------------------
;            Timer Data Area            :
;----------------------------------------
pit_divisor     dw ?
pit_ticks       dd ?    ;Similar to IBM PC, only with default divisor
;[31]=OF cnt, [30:21]=Res [20:16]=Hi cnt, [15,0]=Lo cnt
rtc_ticks       dq ?
;----------------------------------------
;            Screen Data Area           :
;----------------------------------------
scr_curs_pos    dw 8 dup (?)    ;Cursor pos, hi byte = row / lo byte = column
scr_cols        db ?    ;80 Cols
scr_rows        db ?    ;25 Rows
scr_curs_shape  dw ?    ;Packed start/end scan line
scr_char_attr   db ?    ;Grey text on black background
scr_mode        db ?    ;80x25, 16 colours default
scr_active_page db ?    ;Mode dependent
scr_crtc_base   dw ?    ;03D4h for Graphics, 03B4h for MDA
scr_page_addr   dd ?    ;CRTC Register 12 changes base address accessed
scr_mode_params dq ?    ;Stub pointer location for future mode parameters
scr_vga_ptrs    dq 8 dup (?)  ;VGA pointers
;----------------------------------------
;       Mass storage Data Area          :
;----------------------------------------
i33Devices      db ?  ;Number of devices Int 33h is aware of
msdStatus       db ?  ;Status byte. Used by BIOS for all transfers with Int 33h.
fdiskNum        db ?  ;Number of fixed disks
ata0CmdByte     db ?  ;Contains bitfield of instructions, Bit 0 is master/slave, Bit 1 is Data Mutex
ata0Status      db ?  ;Contains the status of the last transaction
ata1CmdByte     db ?
ata1Status      db ?
diskDptPtr      dq ?
fdiskDptPtr     dq ?
;----------------------------------------
;            SysInit Data Area          :
;----------------------------------------
nextFilePtr     dq ?  ;Pointer to next file to load
numSectors      dw ?  ;Number of sectors to copy 
;----------------------------------------
;            Memory Data Area           :
;----------------------------------------
MachineWord     dw ?    ;Really Legacy Hardware Bitfield
convRAM         dw ?  ;Conventional memory word
userBase        dq ?    ;Start address of the user space
bigmapSize      db ?    ;First byte, in units of 24 bytes
srData          dw 4 dup(?)  ;4 words for memory64MB
srData1         dw ?  ;Reserve 1 word for memory16MB
sysMem          dq ?  ;Size of usable system RAM (without SCP/BIOS)
scpSize         dd ?  ;Size of SCP/BIOS allocation
;----------------------------------------
;            MCP Data Area              :
;----------------------------------------
mcpUserBase     dq ?  ;Pointer to register save space
mcpUserRip      dq ?  ;Save the custom user RIP for new jumps
mcpUserkeybf    dq ?  ;Pointer to the keyboard buffer
mcpUserRaxStore dq ?  ;Temp rax save space
mcpStackPtr     dq ?  ;Address of base of user Stack Pointer
;----------------------------------------
;            USB Data Area              :
;----------------------------------------
xControllers    db ?
eControllers    db ?    ;Number of EHCI controllers
eControllerList dq 4 dup (?)    ;Entry = PCI space addr|MMIO addrs
usbDevices      db ?    ;Max value, 10 for now!
eHCErrorHandler dq ?  ;Address of default error handler
;----------------------------------------
;            EHCI Async Area            :
;----------------------------------------
eCurrAsyncHead  dq ?      ;Point to the current head of the async list
eNewBus         db ?      ;Default to 0, if 1, a new bus was selected
eActiveCtrlr    db ?      ;Current working controller (default -1)
eActiveInt      db ?      ;Gives a copy of the usbsts intr bits
eAsyncMutex     db ?    
    ;Mutex, x1b=data NOT ready, wait. x0b=ready, data ready to access.
    ;        1xb=Internal buffer. 0xb=user provided buffer.
    ;        bits [7:2], number of interrupts to ignore (if any)
    ;            a value of 0 means dont ignore
;----------------------------------------
;            MSD Data Area              :
;----------------------------------------
cbwTag  db ?        ;cbw transaction unique id (inc post use)
numMSD  db ?        ;Number of MSD devices
;----------------------------------------
;           USB Tables                  :
;----------------------------------------
usbDevTbl   db usbDevTblSz*usbDevTblEntry_size dup (?)
hubDevTbl   db hubDevTblSz*hubDevTblEntry_size dup (?)
msdDevTbl   db msdDevTblSz*msdDevTblEntry_size dup (?)
;----------------------------------------
;           IDE Tables                  :
;----------------------------------------
;Support up to two IDE controllers
ideNumCtrlr db ?
ideCtrlrTbl db ideCtrlrTblSz*ideCtrlrTblEntry_size dup (?)
;----------------------------------------
;           ATA Tables                  :
;----------------------------------------
fdiskTbl  db fdiskTblSz*fdiskTblEntry_size dup (?) ;Max 4 fixed disks
;----------------------------------------
;            Int33h Table Area          :
;----------------------------------------
i33DevTbl   db i33DevTblSz*i33DevTblEntry_size dup (?)
;----------------------------------------------------------------