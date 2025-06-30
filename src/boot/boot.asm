ORG 0x7c00 ; ORIGIN
BITS 16 ; 16 bit ISA

CODE_SEG equ gdt_code - gdt_start ; 0x8 (Offset for code seg)
DATA_SEG equ gdt_data - gdt_start ; 0x10 (Offset for data seg)

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
    lgdt[gdt_descriptor] ; Load GDT

    ; Set the protected bit as high 
    ; in Control Register 0
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax

    jmp CODE_SEG:load32 ; Jump to load32 (protected mode)

; GDT (Global Descriptor Table)

; Reference for GDT
; https://wiki.osdev.org/Global_Descriptor_Table

gdt_start: ; Start label (for size)

; 8 bytes of NULL Data (acc to GDT Specifications)
; Offset 0x0
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

[BITS 32]
load32:
    mov eax, 1 ; Starting Sector (0 is boot sector)
    mov ecx, 100 ; Total number of sectors to load
    mov edi, 0x0100000 ; (1 MB) Where the kernel code is loaded in memory
    call ata_lba_read

; Driver for reading from disk without BIOS (not valid in protected mode)
ata_lba_read:
    mov ebx, eax ; Backup the LBA
    ; Using ATA LBA Ports we send
    ; https://wiki.osdev.org/ATA_read/write_sectors#:~:text=rax%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20popfq%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20ret-,Read%20in%20LBA%20mode,-This%20page%20or

    ; Send the bits 24-27 of the lba to hard disk controller
    ; see osdev ata read write for clarity
    shr eax, 24 ; Shift Right 24 bits
    mov dx, 0x1F6
    out dx, al
    
    ; Send the total sectors to read
    mov eax, ecx
    mov dx, 0x1F2
    out dx, al

    ; Send bits 0-7 of the LBA
    mov eax, ebx ; Get the LBA back
    mov dx, 0x1F3
    out dx, al

    ; Send bits 8-15 of the LBA
    mov eax, ebx
    shr eax, 8
    mov dx, 0x1F4
    out dx, al

    ; Send bits 16-23 of the LBA
    mov eax, ebx
    shr eax, 16
    mov dx, 0x1F5
    out dx, al

    mov dx, 0x1F7 ; Command port
    mov al, 0x20 ; Read with retry.
    out dx, al

; Reading all sectors into memory
.next_sector:
    push ecx

; Checking if we need to read
.try_again:
    mov dx, 0x1F7
    in al, dx
    test al, 8 ; the sector buffer requires servicing
    jz .try_again

; Need to Read 256 words (512 bytes for 16 BIT ATA Standard)

; Filling the 512 bytes of bootloader with null bytes
times 510-($ - $$) db 0 
dw 0xAA55 ; Boot Signature (Little Endian)