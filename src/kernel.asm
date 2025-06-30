[BITS 32]
global _start
extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
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

    call kernel_main
    jmp $

; Alignment to make this asm file 16 byte aligned
; Calling C functions from assembly requires
; the stack to be 16-byte aligned according to
; the System V ABI (Application Binary Interface) specification
; This is a mandatory requirement, not just a performance optimization.
times 510-($ - $$) db 0 
