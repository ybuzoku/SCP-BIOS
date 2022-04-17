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