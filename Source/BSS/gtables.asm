;Global Data BIOS tables
BIOSIDTable     resq 2*256  ;256 paragraph entries reserved for IDT
BIOSPageTbl     resq 0C00h  ;6000 bytes for page tables
BIOSGDTable     resq 3      ;3 entries in basic GDT
                resq 1      ;Alignment qword