;----------------------------------------------------------------
;                    Long Mode Initialisation                   :
;----------------------------------------------------------------
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
    stosb       ;fdiskNumber
    mov cx, 4*fdiskEntry_size
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