; Load protected mode
[BITS 32]
CODE_SEG equ 0x08
DATA_SEG equ 0x10
load32:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000 ; Base pointer
    mov esp, ebp ; Stack pointer

    ; Enabling the A20 Line
    ; Fast A20 Gate
    in al, 0x92 ; Reading port 0x92 from processor bus
    or al, 0x2 ; 10 in binary => second bit (a20 line bit)
    out 0x92, al
    jmp $