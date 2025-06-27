ENTRY(_start)
OUTPUT_FORMAT(binary)
SECTIONS
(
    . = 1M; /* Mem Loc 0x100000 */
    .text :
    {
        *(.text)
    }

    .rodata :
    {
        *(.rodata)
    }

    .data :
    {
        *(.data)
    }

    .bss :
    {
        *(COMMON)
        *(.bss)
    }
)