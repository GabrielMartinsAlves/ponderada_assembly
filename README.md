# Implementação de Bootloader x86 com Interface de Entrada Interativa

## Visão Geral Arquitetural

Esta implementação constitui um bootloader de 16 bits desenvolvido em linguagem Assembly x86, projetado para execução em modo real (real mode) em arquiteturas compatíveis com o conjunto de instruções Intel 8086. O programa implementa funcionalidades básicas de entrada/saída através de interrupções BIOS, proporcionando uma interface rudimentar de interação com o usuário durante o processo de inicialização do sistema.

## Especificações Técnicas

### Arquitetura de Destino
- **Plataforma**: x86 (16-bit real mode)
- **Conjunto de Instruções**: Intel 8086/8088 compatível
- **Modelo de Memória**: Segmentado (16-bit)
- **Endereçamento**: Linear de 20 bits (1MB de espaço endereçável)

### Requisitos de Sistema
- Processador x86 compatível (8086 ou superior)
- BIOS compatível com interrupções padrão (INT 10h, INT 16h)
- Mídia de boot de 512 bytes (setor de boot padrão)
- Suporte a modo real do processador

## Análise Detalhada da Implementação

### Configuração Inicial e Organização de Memória

```assembly
org 0x7C00
```

A diretiva `org 0x7C00` estabelece o ponto de origem do código na posição de memória 0x7C00 (31744 em decimal), que constitui o endereço padrão onde o BIOS carrega o primeiro setor (512 bytes) de dispositivos de boot. Esta convenção é fundamental para a compatibilidade com o processo de inicialização padrão x86.

### Rotina de Output para Strings Zero-Terminadas

A função `output_string_zero_terminated` implementa um mecanismo eficiente de renderização de strings null-terminated utilizando a interrupção BIOS INT 10h:

```assembly
output_string_zero_terminated:
    lodsb                        ; carrega próximo byte da string em AL
    or  al, al                   ; testa se AL é zero (terminador)
    jz   .retorno_funcao
    mov ah, 0Eh                  ; BIOS INT 10h função 0Eh: modo teletype
    int 10h
    jmp output_string_zero_terminated
```

**Análise Técnica:**
- Utiliza a instrução `lodsb` para carregamento automático e incremento do registrador SI
- Implementa teste de terminação através da operação lógica `or al, al`
- Emprega a função 0Eh da INT 10h para output em modo teletype
- Mantém compatibilidade com convenções de strings C-style

### Sistema de Captura de Entrada de Teclado

O mecanismo de captura de entrada implementa um buffer circular com limitação de caracteres:

```assembly
captura_entrada_usuario:
    mov ah, 0                    ; BIOS INT 16h função 0: aguarda e lê tecla pressionada
    int 16h                      ; retorna código ASCII em AL
    cmp al, 13                   ; verifica se é carriage return (Enter)
    je  processa_saida_formatada
    stosb                        ; armazena AL em [DI] e incrementa DI automaticamente
    mov ah, 0Eh                  ; BIOS INT 10h função 0Eh: output de caractere em modo TTY
    int 10h
    loop captura_entrada_usuario
```

**Características Implementadas:**
- Blocking input através da função 0 da INT 16h
- Echo automático de caracteres digitados
- Detecção de carriage return (ASCII 13) como terminador de entrada
- Proteção contra buffer overflow através do registrador CX
- Utilização da instrução `stosb` para armazenamento otimizado

### Gerenciamento de Buffer e Validação de Dados

O sistema implementa um buffer estático de 21 bytes para armazenamento da entrada do usuário:

```assembly
input_buffer times 21 db 0       ; área de memória reservada (20 chars + CR + null terminator)
```

Esta configuração permite:
- 20 caracteres imprimíveis
- 1 byte para carriage return
- 1 byte para null terminator (compatibilidade com strings C-style)

### Processamento e Renderização de Saída

A rotina `renderiza_nome_usuario` implementa um parser para filtragem de caracteres de controle:

```assembly
renderiza_nome_usuario:
    lodsb                        ; carrega byte de [SI] em AL e incrementa SI
    cmp al, 0                    ; verifica terminador nulo
    je terminacao_programa
    cmp al, 13                   ; filtra carriage return do buffer
    je terminacao_programa
    mov ah, 0Eh                  ; BIOS INT 10h função 0Eh para output de caractere
    int 10h
    jmp renderiza_nome_usuario
```

**Funcionalidades de Filtragem:**
- Detecção e tratamento de null terminator
- Filtragem de carriage return para limpeza de output
- Renderização caractere por caractere com validação

### Estrutura de Boot Sector

A implementação segue rigorosamente as especificações do Master Boot Record:

```assembly
times 510-($-$$) db 0            ; preenchimento até offset 510 do setor de boot
dw 0xAA55                        ; assinatura mágica do master boot record
```

**Conformidade com Especificações:**
- Tamanho exato de 512 bytes
- Assinatura mágica 0xAA55 nos últimos 2 bytes
- Preenchimento com zeros para compatibilidade

## Fluxo de Execução Detalhado

### Fase 1: Inicialização
1. BIOS carrega 512 bytes do dispositivo de boot para 0x7C00
2. Transfere controle para o código carregado
3. Registradores são inicializados com valores padrão do BIOS

### Fase 2: Prompt de Entrada
1. Carregamento do endereço da string prompt em SI
2. Chamada da rotina de output zero-terminated
3. Configuração do buffer de destino (DI) e contador (CX)

### Fase 3: Captura de Dados
1. Loop de captura com blocking input via INT 16h
2. Validação de terminadores (Enter)
3. Armazenamento no buffer com proteção contra overflow
4. Echo simultâneo para feedback visual

### Fase 4: Processamento e Saída
1. Renderização do cabeçalho de saudação
2. Filtragem e validação dos dados capturados
3. Output final com formatação adequada

### Fase 5: Terminação
1. Implementação de halt infinito (`jmp $`)
2. Prevenção de execução de código inválido
3. Manutenção do estado do sistema

## Considerações de Performance e Otimização

### Eficiência de Instruções
- Utilização de instruções string (`lodsb`, `stosb`) para operações otimizadas
- Aproveitamento de auto-incremento de registradores
- Minimização de saltos condicionais desnecessários

### Gerenciamento de Recursos
- Uso eficiente de registradores de propósito geral
- Implementação de stack frame mínimo
- Otimização de uso de memória (512 bytes totais)

### Compatibilidade e Portabilidade
- Aderência rigorosa aos padrões BIOS
- Compatibilidade retroativa com processadores 8086
- Implementação defensiva contra variações de hardware

## Limitações e Restrições Conhecidas

### Limitações Funcionais
- Buffer de entrada limitado a 20 caracteres
- Ausência de edição de linha (backspace, delete)
- Suporte apenas a caracteres ASCII básicos
- Sem validação de entrada de dados

### Restrições Arquiteturais
- Execução restrita ao modo real 16-bit
- Dependência de serviços BIOS específicos
- Limitação de tamanho total (512 bytes)
- Ausência de tratamento de exceções

### Considerações de Segurança
- Vulnerabilidade a buffer overflow em implementações modificadas
- Ausência de validação de entrada maliciosa
- Execução em nível de privilégio máximo (ring 0)

## Casos de Uso e Aplicações

### Ambientes de Desenvolvimento
- Plataforma educacional para aprendizado de Assembly x86
- Base para desenvolvimento de bootloaders mais complexos
- Ferramenta de debugging de baixo nível

### Aplicações Práticas
- Sistema de diagnóstico básico
- Interface de configuração pré-sistema operacional
- Demonstração de conceitos de programação em modo real

## Compilação e Deployment

### Ferramentas Requeridas
- Assembler compatível (NASM, MASM, ou similar)
- Ferramenta de criação de imagem de disco
- Emulador x86 para testes (QEMU, VirtualBox, etc.)

### Processo de Build
```bash
nasm -f bin bootloader.asm -o bootloader.bin
dd if=bootloader.bin of=disk.img bs=512 count=1
```

### Verificação de Integridade
- Confirmação de tamanho exato (512 bytes)
- Validação da assinatura magic number (0xAA55)
- Teste em ambiente controlado antes de deployment

## Extensibilidade e Melhorias Futuras

### Funcionalidades Propostas
- Implementação de edição de linha com backspace
- Suporte a caracteres especiais e acentuação
- Sistema de validação de entrada robusta
- Interface de menu interativa

### Otimizações Arquiteturais
- Migração para modo protegido 32-bit
- Implementação de tratamento de interrupções customizado
- Sistema de gerenciamento de memória expandida
- Suporte a dispositivos de armazenamento modernos

Este bootloader representa uma implementação dos conceitos básicos de programação em Assembly x86, fornecendo uma base para a compreensão dos mecanismos de baixo nível envolvidos no processo de inicialização de sistemas computacionais.