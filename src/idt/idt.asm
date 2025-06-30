section .asm
global idt_load

idt_load:
    ; EBP points to the caller function's stack frame's base
    push ebp
    mov ebp, esp

    ; [EBP+8]  - First Parameter
    ; [EBP+4]  - Return address
    mov ebx, [ebp+8] ; [EBP+8] is the mem address of first parameter
    lidt [ebx]

    pop ebp
    ret