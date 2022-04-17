dummy_interrupt:
.pic2:
    push rax
    mov al, EOI
    out pic2command, al    ;EOI to pic2
    jmp short .p1
.pic1:
    push rax
.p1:
    mov al, EOI
    out pic1command, al    ;EOI to pic2
    pop rax
dummy_return_64:
    iretq