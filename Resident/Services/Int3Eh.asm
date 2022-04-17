;-----------------Disk Params Interrupt Int 3Eh------------------
disk_params_io:
    mov r8, qword [diskDptPtr]    
    mov r9, qword [fdiskDptPtr]
    iretq
;------------------------End of Interrupt------------------------