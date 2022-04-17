;eXtended BDA area for data transfers

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