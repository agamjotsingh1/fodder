ORG 0x7c00 ; ORIGIN
BITS 16 ; 16 bit ISA

; Proxy (Fake) BIOS Parameter Block (BPB)
; Preventing BIOS from overriding code
; Total 33 bytes of fake data
_start:
    ; First 3 bytes are NOP according to BPB
    jmp short start ; 2 bytes
    nop ; 1 byte

    times 33 db 0 ; 33 bytes fake data

start:
    ; Making 0 as code segment
    jmp 0:step2

step2:
    cli ; Clears interrupts

    ; --- MANUAL SEGMENTATION ---
    ; 16 bit segmentation
    ; 0x7c00 is the starting of the first segment
    ; Memory Loc = (Segment Register)*16 + Offset
    mov ax, 0x00
    mov ds, ax ; Data Segment
    mov es, ax ; Extra Segment
    mov ss, ax ; Stack Segment
    mov sp, 0x7c00 ; Stack Pointer
    ; ----------------------------

    sti ; Enable interrupts
.load_protected:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

; GDT (Global Descriptor Table)

; Reference for GDT
; https://wiki.osdev.org/Global_Descriptor_Table

gdt_start: ; Start label (for size)

; 8 bytes of NULL Data (acc to GDT Specifications)
gdt_null:
    dd 0x0
    dd 0x0

; Offset 0x8
gdt_code: ; CS SHOULD POINT TO THIS
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0 ; Base first 0-15 bits
    db 0 ; Base 16-23 bits
    db 0x9a ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0 ; Base 24-31 Bits

; Offset 0x10
gdt_data: ; Data segment registers
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0 ; Base first 0-15 bits
    db 0 ; Base 16-23 bits
    db 0x92 ; Access byte
    db 11001111b ; High 4 bit flags and the low 4 bit flags
    db 0 ; Base 24-31 Bits

gdt_end: ; End label (for size)

gdt_descriptor: ; Loading the Segment Descriptor
    dw gdt_end - gdt_start - 1 ; size of the Segment Descriptor
    dd gdt_start

print:
    mov bx, 0
.loop:
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0eh
    int 0x10
    ret

; Filling the 512 bytes of bootloader with null bytes
times 510-($ - $$) db 0 
dw 0xAA55 ; Boot Signature (Little Endian)