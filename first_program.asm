.global _start
.intel_syntax noprefix

#
# Секція .data (змінні)
#
.data
    # Це наш шаблон. Ми будемо змінювати 'XXXX' "на льоту".
    # Українські літери займають 2 байти кожна в UTF-8.
    # "Індикатор: " = 18 байт + 2 байти (двокрапка + пробіл) = 20 байт.
    # Отже, 'X' починаються з 20-го байта.
    msg_template: db 'Індикатор: XXXX', 0x0A
    len_template: equ $ - msg_template
    
    # Визначимо адреси 'X' для зручності
    PTR_CHAR_1: equ msg_template + 20  # Перший 'X'
    PTR_CHAR_2: equ msg_template + 21  # Другий 'X'
    PTR_CHAR_3: equ msg_template + 22  # Третій 'X'
    PTR_CHAR_4: equ msg_template + 23  # Четвертий 'X'

    # "Комірка пам'яті" для кроку 2.2.9
    memory_cell_0001h: .byte 0xAB

    # Змінна для затримки
    delay_time:
        .quad 1      # tv_sec (секунди)
        .quad 0      # tv_nsec (наносекунди)

#
# Секція .text (код)
#
.text
_start:
    # 2.2.1 Обнулити акумулятор.
    xor rax, rax            # (al = 0x00)

    # 2.2.2 Обнулити індикатор HG1.
    # Ми записуємо символи '0' (ASCII 0x30) у наш шаблон
    mov byte [PTR_CHAR_1], '0'
    mov byte [PTR_CHAR_2], '0'
    mov byte [PTR_CHAR_3], '0'
    mov byte [PTR_CHAR_4], '0'
    call print_message      # Друкуємо "Індикатор: 0000\n"

    # 2.2.3 Завантажити акумулятор числом 0Fh.
    mov al, 0x0F

    # 2.2.4 Відобразити на HG1 «OF00».
    # al = 0x0F. rsi = адреса першого 'X'
    lea rsi, [PTR_CHAR_1]
    call byte_to_hex_string # Конвертуємо 0x0F -> '0' і 'F'
                            # і пишемо їх у [PTR_CHAR_1] та [PTR_CHAR_2]
    # Залишаємо '00' наприкінці
    mov byte [PTR_CHAR_3], '0'
    mov byte [PTR_CHAR_4], '0'
    call print_message      # Друкуємо "Індикатор: 0F00\n"

    # 2.2.5 Сформувати затримку.
    call do_delay

    # 2.2.6 Перетворити вміст акумулятора з 0Fh на F0h.
    mov cl, 4
    rol al, cl              # (al тепер 0xF0)

    # 2.2.7 Відобразити ... «F000».
    # al = 0xF0. rsi = адреса першого 'X'
    lea rsi, [PTR_CHAR_1]
    call byte_to_hex_string # Конвертуємо 0xF0 -> 'F' і '0'
    # Залишаємо '00' наприкінці
    mov byte [PTR_CHAR_3], '0'
    mov byte [PTR_CHAR_4], '0'
    call print_message      # Друкуємо "Індикатор: F000\n"

    # 2.2.8 Сформувати затримку.
    call do_delay

    # 2.2.9 Зчитати ... 0001h і відобразити ... F0xx
    # al все ще 0xF0. Конвертуємо його
    lea rsi, [PTR_CHAR_1]
    call byte_to_hex_string # Пишемо 'F' і '0' у перші два 'X'
    
    # Тепер зчитуємо 0xAB з пам'яті
    mov al, [memory_cell_0001h] # al = 0xAB
    # і конвертуємо його у другі два 'X'
    lea rsi, [PTR_CHAR_3]
    call byte_to_hex_string # Пишемо 'A' і 'B' у [PTR_CHAR_3] та [PTR_CHAR_4]
    
    call print_message      # Друкуємо "Індикатор: F0AB\n"

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
    mov rax, 1              # sys_write
    mov rdi, 1              # stdout
    lea rsi, [msg_template] # Наш шаблон
    mov rdx, len_template   # Його довжина
    syscall
    ret

#
# do_delay: Викликає затримку в 1 секунду
#
do_delay:
    mov rax, 35             # nanosleep
    lea rdi, [delay_time]   # Адреса структури часу
    mov rsi, 0              # NULL
    syscall
    ret

#
# byte_to_hex_string: Конвертує 1 байт (з AL) у 2 ASCII-символи
#                     і записує їх за адресою в RSI.
#                     Наприклад: al=0xF0, rsi=адреса -> запише 'F' і '0'
#
byte_to_hex_string:
    push rax                # Зберігаємо оригінальний rax (з 0xF0)
    
    # 1. Конвертуємо старший нібл (перші 4 біти)
    shr al, 4               # al = 0xF0 -> al = 0x0F
    call nybble_to_ascii    # Конвертуємо 0x0F -> 'F'
    mov [rsi], al           # Записуємо 'F' за адресою в rsi

    pop rax                 # Відновлюємо rax (знову 0xF0)

    # 2. Конвертуємо молодший нібл (останні 4 біти)
    and al, 0x0F            # al = 0xF0 -> al = 0x00
    call nybble_to_ascii    # Конвертуємо 0x00 -> '0'
    mov [rsi+1], al         # Записуємо '0' у наступний байт

    ret                     # Повертаємось

#
# nybble_to_ascii: Конвертує 4-бітне число (0-15) в AL
#                  у ASCII-символ ('0'-'9' або 'A'-'F')
#
nybble_to_ascii:
    cmp al, 10              # Порівнюємо з 10
    jl .is_digit            # Якщо менше (<), це цифра ('0'-'9')

    # .is_letter (Це 'A'-'F')
    add al, 0x37            # Додаємо 0x37 ('A' - 10)
                            # Наприклад: 10 (0xA) + 0x37 = 0x41 ('A')
                            #            15 (0xF) + 0x37 = 0x46 ('F')
    ret

.is_digit:
    # Це '0'-'9'
    add al, 0x30            # Додаємо 0x30 ('0')
                            # Наприклад: 0 + 0x30 = 0x30 ('0')
                            #            9 + 0x30 = 0x39 ('9')
    ret
