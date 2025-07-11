org 0x7C00
    mov si, input_prompt
    call output_string_zero_terminated
    mov di, input_buffer         ; destination index register for input buffer
    mov cx, 20                   ; defines maximum limit of input characters
capture_user_input:
    mov ah, 0                    ; BIOS INT 16h function 0: wait and read pressed key
    int 16h                      ; returns ASCII code in AL
    cmp al, 13                   ; check if it's carriage return (Enter)
    je  process_formatted_output
    stosb                        ; stores AL in [DI] and increments DI automatically
    mov ah, 0Eh                  ; BIOS INT 10h function 0Eh: character output in TTY mode
    int 10h
    loop capture_user_input
    jmp process_formatted_output
process_formatted_output:
    mov si, greeting_header
    call output_string_zero_terminated
    mov si, input_buffer         ; points to buffer containing input data
render_username:
    lodsb                        ; loads byte from [SI] into AL and increments SI
    cmp al, 0                    ; checks for null terminator
    je program_termination
    cmp al, 13                   ; filters carriage return from buffer
    je program_termination
    mov ah, 0Eh                  ; BIOS INT 10h function 0Eh for character output
    int 10h
    jmp render_username
program_termination:
    jmp $                        ; infinite loop - processor halt
; --- Output routine for zero-terminated strings
output_string_zero_terminated:
    lodsb                        ; loads next byte from string into AL
    or  al, al                   ; tests if AL is zero (terminator)
    jz   .function_return
    mov ah, 0Eh                  ; BIOS INT 10h function 0Eh: teletype mode
    int 10h
    jmp output_string_zero_terminated
.function_return:
    ret
input_prompt db 'Enter user identifier (name): ',0
greeting_header db 13, 10, 'Greetings, ',0
input_buffer times 21 db 0       ; reserved memory area (20 chars + CR + null terminator)
times 510-($-$$) db 0            ; padding until offset 510 of boot sector
dw 0xAA55                        ; magic signature of master boot record