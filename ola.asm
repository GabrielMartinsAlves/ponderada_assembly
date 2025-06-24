org 0x7C00
    mov si, prompt_entrada
    call output_string_zero_terminated
    mov di, input_buffer         ; registrador de índice destino para buffer de entrada
    mov cx, 20                   ; define limite máximo de caracteres de entrada
captura_entrada_usuario:
    mov ah, 0                    ; BIOS INT 16h função 0: aguarda e lê tecla pressionada
    int 16h                      ; retorna código ASCII em AL
    cmp al, 13                   ; verifica se é carriage return (Enter)
    je  processa_saida_formatada
    stosb                        ; armazena AL em [DI] e incrementa DI automaticamente
    mov ah, 0Eh                  ; BIOS INT 10h função 0Eh: output de caractere em modo TTY
    int 10h
    loop captura_entrada_usuario
    jmp processa_saida_formatada
processa_saida_formatada:
    mov si, cabecalho_saudacao
    call output_string_zero_terminated
    mov si, input_buffer         ; aponta para buffer contendo dados de entrada
renderiza_nome_usuario:
    lodsb                        ; carrega byte de [SI] em AL e incrementa SI
    cmp al, 0                    ; verifica terminador nulo
    je terminacao_programa
    cmp al, 13                   ; filtra carriage return do buffer
    je terminacao_programa
    mov ah, 0Eh                  ; BIOS INT 10h função 0Eh para output de caractere
    int 10h
    jmp renderiza_nome_usuario
terminacao_programa:
    jmp $                        ; loop infinito - halt do processador
; --- Rotina de output para strings terminadas em zero
output_string_zero_terminated:
    lodsb                        ; carrega próximo byte da string em AL
    or  al, al                   ; testa se AL é zero (terminador)
    jz   .retorno_funcao
    mov ah, 0Eh                  ; BIOS INT 10h função 0Eh: modo teletype
    int 10h
    jmp output_string_zero_terminated
.retorno_funcao:
    ret
prompt_entrada db 'Insira identificador (nome) de usuario: ',0
cabecalho_saudacao db 13, 10, 'Saudacoes, ',0
input_buffer times 21 db 0       ; área de memória reservada (20 chars + CR + null terminator)
times 510-($-$$) db 0            ; preenchimento até offset 510 do setor de boot
dw 0xAA55                        ; assinatura mágica do master boot record