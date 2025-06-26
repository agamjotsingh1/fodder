ORG 0 ; ORIGIN
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
    ; Making 0x7c0 as code segment
    jmp 0x7c0:step2

step2:
    cli ; Clears interrupts

    ; --- MANUAL SEGMENTATION ---
    ; 16 bit segmentation
    ; 0x7c00 is the starting of the first segment
    ; Memory Loc = (Segment Register)*16 + Offset
    mov ax, 0x7c0
    mov ds, ax ; Data Segment
    mov es, ax ; Extra Segment
    mov ax, 0x00

    mov ss, ax ; Stack Segment
    mov sp, 0x7c00 ; Stack Pointer
    ; ----------------------------

    sti ; Enable interrupts

    ; CHS reading from emulated hard drive
    mov ah, 02h ; Read sector command
    mov al, 1 ; Number of sectors to read
    mov ch, 0 ; Cylinder low eight bits
    mov cl, 2 ; Read sector two
    mov dh, 0 ; Head number
    mov bx, buffer
    int 0x13
    jc error ; Jump carry

    mov si, buffer
    call print

    ; Infinite loop so that random memory is not read
    jmp $

error:
    mov si, error_message
    call print
    jmp $

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

error_message: db 'Failed to load sector', 0

; Filling the 512 bytes of bootloader with null bytes
times 510-($ - $$) db 0 
dw 0xAA55 ; Boot Signature (Little Endian)

buffer: