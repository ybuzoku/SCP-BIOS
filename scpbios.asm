[map all scpbios.map]
;-----------------------------------SCPBIOS-----------------------------------
%include "./Include/equates.inc"
;----------------------------------------------------------------
;                 BIOS SYSTEM TABLE AREA                        :
;----------------------------------------------------------------
Segment BIOSTables nobits start=BIOSStartAddr align=1
%include "./BSS/gtables.asm"
;----------------------------------------------------------------
;                    BIOS DATA AREA STARTS HERE                 :
;----------------------------------------------------------------
Segment data nobits follows=BIOSTables align=1 
%include "./BSS/bda.asm"
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
%include "./BSS/xbda.asm"
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
%include "./Init/RealInit.asm"
BITS 64
%include "./Init/LongInit.asm"
%include "./Init/Hardware/PIC/picinit.asm"
%include "./Init/Hardware/PCI/init.asm"
%include "./Init/Hardware/Timers/pitinit.asm"
%include "./Init/Hardware/Timers/rtcinit.asm"
%include "./Init/Hardware/Timers/beepOK.asm"
%include "./Init/Hardware/Serial/rs232ini.asm"
%include "./Init/Hardware/PS2/ps2init.asm"
%include "./Sysdebug/init.asm"
;----------------------------------------------------------------
;              Drive Enum and Initialisation procedures         :
;----------------------------------------------------------------
%include "./Init/Hardware/IDE/ideinit.asm"
%include "./Init/Hardware/USB/EHCI/ehciinit.asm"
%include "./Init/Hardware/USB/MSD/msdinit.asm"
%include "./Init/Hardware/MSD/i33init.asm"
;----------------------------------------------------------------
;                         End of Enum                           :
;----------------------------------------------------------------    
%include "./Init/InitEnd.asm"
%include "./Init/IntTable.asm"
seg0len equ ($ - $$)

;----------------------------------------------------------------
;                BIOS RESIDENT CODE AREA STARTS HERE            :
;----------------------------------------------------------------
Segment codeResident follows=codeInit vfollows=data align=1 valign=1
%include "./Resident/Misc/Procs/common.asm"
;--------------------Interrupt Service routines------------------

;======================HARDWARE INTERRUPTS=======================
%include "./Resident/Hardware/Timers/pitInt.asm"
%include "./Resident/Hardware/PS2/keybInt.asm"
%include "./Resident/Hardware/Serial/serInt.asm"
%include "./Resident/Hardware/MSD/fddInt.asm"
%include "./Resident/Hardware/Timers/rtcInt.asm"
%include "./Resident/Hardware/MSD/hddInt.asm"
%include "./Resident/Hardware/USB/EHCI/ehciInt.asm"
%include "./Resident/Hardware/spurInt.asm"
;========================SOFTWARE INTERRUPTS=====================
%include "./Resident/Services/Int30h.asm"
%include "./Resident/Services/Int31h.asm"
%include "./Resident/Services/Int32h.asm"
%include "./Resident/Services/Int33h.asm"
%include "./Resident/Services/Int34h.asm"
%include "./Resident/Services/Int35h.asm"
%include "./Resident/Services/Int36h.asm"
%include "./Resident/Services/Int37h.asm"
%include "./Sysdebug/sysdeb.asm"
%include "./Resident/Services/Int39h.asm"
%include "./Resident/Services/Int3Ah.asm"
%include "./Resident/Services/Int3Bh.asm"
%include "./Resident/Services/Int3Dh.asm"
%include "./Resident/Services/Int3Eh.asm"
%include "./Resident/Services/Int3Fh.asm"
;========================RESIDENT DRIVERS=====================
%include "./Resident/Hardware/ATA/ataDrv.asm"
%include "./Resident/Hardware/USB/EHCI/ehciDriv.asm"
;====================================CPU Interrupts=============================
%include "./Resident/Hardware/CPU/xception.asm"
;==========================Dummy Interrupts======================
%include "./Resident/Hardware/dummyInt.asm"
%include "./Resident/Misc/version.asm"
codeResidentEndPtr:
residentLength  equ $-$$
