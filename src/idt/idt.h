#ifndef IDT_H
#define IDT_H

struct idt_desc {
    uint16_t offset1; // Offset bits 0-15
    uint16_t selector; // Selector (in GDT)
    uint16_t zero; // Null space, does nothing
    uint16_t type_attr; // Descriptor types and attributes
    uint16_t offset2; // Offset bits 0-15
} __attribute__((packed));

struct idtr_desc {
    uint16_t limit; // Size of idt - 1
    uint16_t base; // Base address of the start of the idt 
} __attribute__((packed));


#endif
