;----------------------------------------------------------------
;              Debugger Initialisation procedures               :
;----------------------------------------------------------------
debuggerInit:
;Int 40h can be used by the Debugger to return to it or if a DOS present, 
; to return to DOS.
    mov rax, MCP_int ;The application return point
    mov rsi, 40h
    mov dx, 8F00h    ;Attribs
    mov ebx, codedescriptor
    call idtWriteEntry    