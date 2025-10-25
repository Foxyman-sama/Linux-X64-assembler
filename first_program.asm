.global _start
.intel_syntax noprefix

#
# Секція .data (змінні)
# Тут ми заздалегідь готуємо рядки, які будемо "відображати"
#
.data
    # Рядок для кроку 2.2.2
    msg_0000: .asciz "Індикатор: 0000\n"
    len_0000: .quad $ - msg_0000

    # Рядок для кроку 2.2.4
    msg_0F00: .asciz "Індикатор: 0F00\n"
    len_0F00: .quad $ - msg_0F00

    # Рядок для кроку 2.2.7
    msg_F000: .asciz "Індикатор: F000\n"
    len_F000: .quad $ - msg_F000

    # Рядок для кроку 2.2.9
    # Ми симулюємо "комірку 0001h", яка містить 0xAB
    memory_cell_0001h: .byte 0xAB 
    # Рядок, який показує F0 (з акумулятора) та AB (з пам'яті)
    msg_F0AB: .asciz "Індикатор: F0AB\n"
    len_F0AB: .quad $ - msg_F0AB

    # Змінна для затримки (1 секунда)
    delay_time:
        .quad 1     # tv_sec (секунди)
        .quad 0     # tv_nsec (наносекунди)

#
# Секція .text (код)
#
.text
_start:
    # 2.2.1 Обнулити акумулятор.
    xor rax, rax            # (Використовуємо 64-бітний RAX)

    # 2.2.2 Обнулити індикатор HG1. (Друкуємо "0000")
    mov rax, 1              # (Системний виклик sys_write = 1)
    mov rdi, 1              # (Файловий дескриптор stdout = 1)
    lea rsi, [msg_0000]
    mov rdx, [len_0000]
    syscall

    # 2.2.3 Завантажити акумулятор числом 0Fh.
    mov al, 0x0F            # (Використовуємо 8-бітний AL)

    # 2.2.4 Відобразити на HG1 «OF00». (Друкуємо "0F00")
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_0F00]
    mov rdx, [len_0F00]
    syscall

    # 2.2.5 Сформувати затримку.
    mov rax, 35             # (Системний виклик nanosleep = 35)
    lea rdi, [delay_time]
    mov rsi, 0              # (Другий аргумент = NULL)
    syscall

    # 2.2.6 Перетворити вміст акумулятора з 0Fh на F0h.
    # (AL все ще = 0x0F з кроку 2.2.3)
    mov cl, 4
    rol al, cl              # (AL тепер 0xF0)

    # 2.2.7 Відобразити ... «F000». (Друкуємо "F000")
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_F000]
    mov rdx, [len_F000]
    syscall

    # 2.2.8 Сформувати затримку.
    mov rax, 35
    lea rdi, [delay_time]
    mov rsi, 0
    syscall

    # 2.2.9 Зчитати ... 0001h і відобразити ... F0xx
    # (Ми "зчитали" 0xAB і надрукуємо "F0AB")
    mov rax, 1
    mov rdi, 1
    lea rsi, [msg_F0AB]
    mov rdx, [len_F0AB]
    syscall

    # --- Завершення програми ---
    mov rax, 60             # (Системний виклик sys_exit = 60)
    mov rdi, 0              # (Код виходу 0 = успіх)
    syscall

