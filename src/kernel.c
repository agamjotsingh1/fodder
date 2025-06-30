#include "kernel.h" 
#include <stdint.h>
#include <stddef.h>

// Text Mode Video Memory
uint16_t* video_mem = 0;
uint16_t terminal_row = 0;
uint16_t terminal_col = 0;

uint16_t terminal_make_char(char ch, char color){
    return (color << 8) | ch; // Little endian
}

void terminal_put_char(int x, int y, char ch, char color) {
    video_mem[(y * VGA_WIDTH) + x] = terminal_make_char(ch, color);
}

void terminal_write_char(char ch, char color){
    if(ch == '\n') {
        terminal_col = 0;
        terminal_row += 1;
        return;
    }

    terminal_put_char(terminal_col, terminal_row, ch, color);
    terminal_col += 1;
    if(terminal_col >= VGA_WIDTH) {
        terminal_col = 0;
        terminal_row += 1;
    }
}

void terminal_initialize(){
    video_mem = (uint16_t* )(0xB8000); // Pointer to 0xB8000 for video card output
    for(int y = 0; y < VGA_HEIGHT; y++)
        for(int x = 0; x < VGA_WIDTH; x++)
            terminal_put_char(x, y, ' ', 0);
}

size_t strlen(const char* str){
    size_t len = 0;
    while(str[len]) len++;
    return len;
}

void print(const char* str) {
    size_t len = strlen(str);
    for(int i = 0; i < len; i++) terminal_write_char(str[i], 15);
}

void kernel_main(){
    terminal_initialize();
    print("hello world\ngood morning");
}