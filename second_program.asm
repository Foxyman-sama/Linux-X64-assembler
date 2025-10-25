.global _start
.intel_syntax noprefix

#
# Секція .data (змінні)
#
.data
    # "Комірка пам'яті" за адресою 038h
    memory_cell_038h: .byte 0xAB 

    # Наш шаблон для виводу. 'XXXX' - це місце, куди ми будемо
    # динамічно вписувати 16-кові значення.
    # "Індикатор: " (20 байт) + "XXXX" (4 байти) + "\n" (1 байт)
    msg_template: .ascii "Індикатор: XXXX\n"
    len_template: .quad  . - msg_template
    
    # Константа, що вказує на адресу першого 'X' у шаблоні
    # (20 байт - це довжина рядка "Індикатор: " в UTF-8)
    .equ PTR_CHARS, msg_template + 20

    # Змінна для затримки (1 секунда)
    delay_time:
        .quad 1      # tv_sec (секунди)
        .quad 0      # tv_nsec (наносекунди)

#
# Секція .text (код)
#
.text
_start:
    # 2.2.10 Завантажити регістр R1 десятичними даними 37.
    # rbx буде R1. 37 (dec) = 0x25 (hex)
    mov rbx, 37           
    
    # 2.2.11 Завантажити R2 байтом... з адреси 038h.
    # cl буде R2.
    mov cl, [memory_cell_038h] # cl = 0xAB

    #
    # 2.2.12 Вивести R1 (старші 00) і R2 (молодші AB)
    #
    
    # 1. Беремо старший байт 0x00 з rbx (який є в bh)
    mov al, bh              # al = 0x00
    # Вказуємо, куди писати ASCII ('XX__')
    lea rsi, [PTR_CHARS]    # rsi = адреса першого 'X'
    call byte_to_hex_string # Конвертуємо 0x00 -> '0', '0'
    
    # 2. Беремо байт 0xAB з cl
    mov al, cl              # al = 0xAB
    # Вказуємо, куди писати ASCII ('__XX')
    lea rsi, [PTR_CHARS + 2] # rsi = адреса третього 'X'
    call byte_to_hex_string # Конвертуємо 0xAB -> 'A', 'B'

    # 3. Шаблон тепер "Індикатор: 00AB\n", друкуємо його
    call print_message

    # 2.2.13 Сформувати затримку.
    call do_delay

    #
    # 2.2.14 Переставити... R2 (AB) і R1 (00)
    #

    # 1. Беремо байт 0xAB з cl
    mov al, cl              # al = 0xAB
    # Вказуємо, куди писати ASCII ('XX__')
    lea rsi, [PTR_CHARS]
    call byte_to_hex_string # Конвертуємо 0xAB -> 'A', 'B'

    # 2. Беремо старший байт 0x00 з rbx (bh)
    mov al, bh              # al = 0x00
    # Вказуємо, куди писати ASCII ('__XX')
    lea rsi, [PTR_CHARS + 2]
    call byte_to_hex_string # Конвертуємо 0x00 -> '0', '0'
    
    # 3. Шаблон тепер "Індикатор: AB00\n", друкуємо його
    call print_message
    
    # --- Завершення програми ---
    mov rax, 60             
    mov rdi, 0              
    syscall

# -------------------------------------------------
# ДОПОМІЖНІ ФУНКЦІЇ (ПРОЦЕДУРИ)
# -------------------------------------------------

#
# print_message: Друкує наш msg_template на екран
#
print_message:
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_template]
    mov rdx, [len_template]
    syscall
    ret

#
# do_delay: Викликає затримку в 1 секунду
#
do_delay:
    mov rax, 35
    lea rdi, [delay_time]
    mov rsi, 0
    syscall
    ret

#
# byte_to_hex_string: Конвертує 1 байт в AL (e.g., 0xAB)
#                     у 2-символьний ASCII-рядок за адресою в RSI.
#                     (e.g., запише 'A' в [rsi] і 'B' в [rsi+1])
#
byte_to_hex_string:
    push rax                # Зберігаємо rax
    push rcx                # Зберігаємо rcx
    
    # 1. Конвертуємо старшу половину (e.g., 0xAB -> 0x0A)
    mov cl, al              # Копіюємо 0xAB в cl
    shr al, 4               # al тепер 0x0A
    call nibble_to_hex_char # al тепер ASCII 'A'
    mov [rsi], al           # Записуємо 'A'
    
    # 2. Конвертуємо молодшу половину (e.g., 0xAB -> 0x0B)
    mov al, cl              # Відновлюємо 0xAB з cl
    and al, 0x0F            # al тепер 0x0B
    call nibble_to_hex_char # al тепер ASCII 'B'
    mov [rsi+1], al         # Записуємо 'B'
    
    pop rcx                 # Відновлюємо rcx
    pop rax                 # Відновлюємо rax
    ret

#
# nibble_to_hex_char: Конвертує 4-бітне число в AL (0-15)
#                     в один ASCII символ ('0'-'9', 'A'-'F')
#
nibble_to_hex_char:
    cmp al, 9               # Порівнюємо з 9
    jle .is_digit           # Якщо <= 9, це цифра
    
    # Це буква (10-15)
    .is_letter:
        add al, 55          # Конвертуємо 10 -> 65 (ASCII 'A')
        ret
    
    # Це цифра (0-9)
    .is_digit:
        add al, 48          # Конвертуємо 0 -> 48 (ASCII '0')
        ret
