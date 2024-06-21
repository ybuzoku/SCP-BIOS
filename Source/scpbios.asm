[map all ./Source/scpbios.map]
;-----------------------------------SCPBIOS-----------------------------------
%include "./Source/Include/equates.inc"
;----------------------------------------------------------------
;                 BIOS SYSTEM TABLE AREA                        :
;----------------------------------------------------------------
Segment BIOSTables nobits start=BIOSStartAddr align=1
%include "./Source/BSS/gtables.asm"
;----------------------------------------------------------------
;                    BIOS DATA AREA STARTS HERE                 :
;----------------------------------------------------------------
Segment data nobits follows=BIOSTables align=1 
%include "./Source/BSS/bda.asm"
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
%include "./Source/BSS/xbda.asm"
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
%include "./Source/Init/RealInit.asm"
BITS 64
%include "./Source/Init/LongInit.asm"
%include "./Source/Init/Hardware/PIC/picinit.asm"
%include "./Source/Init/Hardware/PCI/init.asm"
%include "./Source/Init/Hardware/Timers/pitinit.asm"
%include "./Source/Init/Hardware/Timers/rtcinit.asm"
%include "./Source/Init/Hardware/Timers/beepOK.asm"
%include "./Source/Init/Hardware/Serial/rs232ini.asm"
%include "./Source/Init/Hardware/PS2/ps2init.asm"
%include "./Source/Sysdebug/init.asm"
;----------------------------------------------------------------
;              Drive Enum and Initialisation procedures         :
;----------------------------------------------------------------
%include "./Source/Init/Hardware/IDE/ideinit.asm"
%include "./Source/Init/Hardware/USB/xHCI/xhciinit.asm"
%include "./Source/Init/Hardware/USB/EHCI/ehciinit.asm"
%include "./Source/Init/Hardware/USB/MSD/msdinit.asm"
%include "./Source/Init/Hardware/MSD/i33init.asm"
;----------------------------------------------------------------
;                         End of Enum                           :
;----------------------------------------------------------------    
%include "./Source/Init/InitEnd.asm"
%include "./Source/Init/IntTable.asm"
seg0len equ ($ - $$)

;----------------------------------------------------------------
;                BIOS RESIDENT CODE AREA STARTS HERE            :
;----------------------------------------------------------------
Segment codeResident follows=codeInit vfollows=data align=1 valign=1
%include "./Source/Resident/Misc/Procs/common.asm"
;--------------------Interrupt Service routines------------------

;======================HARDWARE INTERRUPTS=======================
%include "./Source/Resident/Hardware/Timers/pitInt.asm"
%include "./Source/Resident/Hardware/PS2/keybInt.asm"
%include "./Source/Resident/Hardware/Serial/serInt.asm"
%include "./Source/Resident/Hardware/MSD/fddInt.asm"
%include "./Source/Resident/Hardware/Timers/rtcInt.asm"
%include "./Source/Resident/Hardware/MSD/hddInt.asm"
%include "./Source/Resident/Hardware/USB/EHCI/ehciInt.asm"
%include "./Source/Resident/Hardware/spurInt.asm"
;========================SOFTWARE INTERRUPTS=====================
%include "./Source/Resident/Services/Int30h.asm"
%include "./Source/Resident/Services/Int31h.asm"
%include "./Source/Resident/Services/Int32h.asm"
%include "./Source/Resident/Services/Int33h.asm"
%include "./Source/Resident/Services/Int34h.asm"
%include "./Source/Resident/Services/Int35h.asm"
%include "./Source/Resident/Services/Int36h.asm"
%include "./Source/Resident/Services/Int37h.asm"
%include "./Source/Sysdebug/sysdeb.asm"
%include "./Source/Resident/Services/Int39h.asm"
%include "./Source/Resident/Services/Int3Ah.asm"
%include "./Source/Resident/Services/Int3Bh.asm"
%include "./Source/Resident/Services/Int3Dh.asm"
%include "./Source/Resident/Services/Int3Eh.asm"
%include "./Source/Resident/Services/Int3Fh.asm"
;========================RESIDENT DRIVERS=====================
%include "./Source/Resident/Hardware/ATA/ataDrv.asm"
%include "./Source/Resident/Hardware/USB/EHCI/ehciDriv.asm"
%include "./Source/Resident/Hardware/USB/xHCI/xhciDriv.asm"
;====================================CPU Interrupts=============================
%include "./Source/Resident/Hardware/CPU/xception.asm"
;==========================Dummy Interrupts======================
%include "./Source/Resident/Hardware/dummyInt.asm"
%include "./Source/Resident/Misc/version.asm"
codeResidentEndPtr:
residentLength  equ $-$$
