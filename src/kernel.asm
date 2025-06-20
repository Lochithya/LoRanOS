; =============================================================================
; LoRanOS -- Core Kernel for 16-bit x86, 
; Author : Lochithya Hettiarachchi
; Highly commented version for advanced study and code analysis.
; Written By Assembly Language 
; Special gratitude to MIKEOS for the inspiration provided.
; =============================================================================

    BITS 16                ; Assemble for 16-bit real mode
    ORG 0000h              ; Load origin at address 0 (bootloader loads here)

; -----------------------------------------------------------------------------
; KERNEL ENTRY POINT
; -----------------------------------------------------------------------------

kernel_entry:
    mov ax, cs             ; Load current code segment into AX
    mov ds, ax             ; Set DS to match code segment for data access
    mov es, ax             ; Set ES for segment operations

    call vid_clear         ; Clear video display, reset cursor

    mov si, _boot_msg1     ; For booting messages
    call str_emit
    call emit_crlf         ; for new lines
    call emit_crlf

    mov si, _boot_msg2
    call str_emit
    call emit_crlf         ; for new lines

    mov si, _boot_dots
    call str_emit
    call emit_crlf
    call emit_crlf      ; Extra line for spacing, optional
    call emit_crlf         ; Extra line for spacing, optional

    mov si, _greet_msg     ; SI points to welcome message
    call str_emit          ; Print welcome string to screen
    call emit_crlf         ; Print newline (CR+LF) for formatting

; -----------------------------------------------------------------------------
; MAIN KERNEL LOOP: Command Interpreter
; -----------------------------------------------------------------------------
kernel_info:
    mov ax, 0              ; Clear AX for command processing
    mov di, _cmd_buf       ; DI points to command buffer
    call str_input         ; Read user input into command buffer
    cmp byte [di], 0       ; Check if input is empty

kernel_cycle:
    call emit_crlf         ; Output newline for prompt separation
    mov si, _prompt_msg    ; SI points to prompt string
    call str_emit          ; Output prompt

    mov di, _cmd_buf       ; DI points to command buffer
    call str_input         ; Read user input into buffer

    ; -------- Command Dispatch Section --------

    mov si, _cmd_buf       ; SI points to user input
    mov di, _cmd_info      ; DI points to "info"
    call str_cmp           ; Compare input to "info"
    je .info_handler       ; If equal, jump to info handler

    mov si, _cmd_buf       ; SI points to user input
    mov di, _cmd_help      ; DI points to "help"
    call str_cmp           ; Compare input to "help"
    je .help_handler       ; If equal, jump to help handler

    mov si, _cmd_buf       ; SI points to user input
    mov di, _cmd_clear     ; DI points to "clear"
    call str_cmp           ; Compare input to "clear"
    je .clear_handler      ; If equal, jump to clear handler

    mov si, _msg_unknown   ; SI points to unknown command message
    call emit_crlf         ; Output newline before error
    call str_emit          ; Output unknown command message
    jmp kernel_cycle       ; Loop for next command

.info_handler:
    call emit_crlf            ; Output newline before info 
    call sys_hardware_profile ; Show hardware/system info
    jmp kernel_cycle          ; Return to main loop

.help_handler:
    call emit_crlf            ; Output newline before help
    mov si, _help_screen      ; SI points to help message
    call str_emit             ; Output help info
    call emit_crlf            ; Output newline after help
    jmp kernel_cycle          ; Return to main loop

.clear_handler:
    call vid_clear            ; Clear the screen
    jmp kernel_cycle          ; Return to main loop

; =============================================================================
; SYSTEM HARDWARE PROFILE: Calls all hardware detection routines
; =============================================================================

sys_hardware_profile:
    pusha                     ; Save all general registers
    call emit_crlf            ; Output newline for formatting
    call mem_probe            ; Detect and display memory info
    call cpu_probe            ; Detect and display CPU vendor/brand
    call hdd_probe            ; Detect and display HDD count
    call mouse_probe          ; Detect and display mouse status
    call serial_probe         ; Detect and display serial port info
    call cpu_feat_probe       ; Detect and display CPU feature flags

    ; ---- Additional hardware info ----
    mov si, _vga_label
    call str_emit
    call emit_crlf

    mov si, _usb_label
    call str_emit
    call emit_crlf

    mov si, _virt_label
    call str_emit
    call emit_crlf

    mov si, _bios_label
    call str_emit
    call emit_crlf

    ; ---- NEW: Even more hardware info ----
    mov si, _audio_label
    call str_emit
    call emit_crlf

    mov si, _network_label
    call str_emit
    call emit_crlf

    mov si, _battery_label
    call str_emit
    call emit_crlf

    popa                      ; Restore all general registers
    ret                       ; Return to caller

; -----------------------------------------------------------------------------
; MEMORY DETECTION: Base, Extended, and Total RAM
; -----------------------------------------------------------------------------

mem_probe:
    mov si, _mem_base         ; SI points to base memory label
    call str_emit             ; Output label for base memory
    int 12h                   ; BIOS: Get base memory in KB (AX)
    mov [mem_kb_base], ax     ; Store base memory in variable
    call dec_emit             ; Print value in AX as decimal
    call emit_k               ; Print "k" and newline

    mov si, _mem_ext          ; SI points to extended memory label
    call str_emit             ; Output label for extended memory
    mov ah, 88h               ; BIOS: Get extended memory
    int 15h                   ; Returns extended memory in KB (AX)
    mov [mem_kb_ext], ax      ; Store extended memory in variable
    call dec_emit             ; Print value in AX as decimal
    call emit_k               ; Print "k" and newline

    mov si, _mem_ext2         ; SI points to label for memory >16MB
    call str_emit             ; Output label for extended memory above 16MB
    mov ax, 0E801h            ; BIOS: Get memory above 16MB
    int 15h                   ; Returns CX/DX blocks if supported
    jc .no_e801               ; If not supported, jump to .no_e801
    mov [mem_16k], cx         ; CX = 16KB blocks
    mov [mem_64k], dx         ; DX = 64KB blocks
    mov dx, 0                 ; Clear DX for division
    mov ax, [mem_64k]         ; AX = 64KB block count
    mov cx, 16                ; Divisor for MB conversion
    div cx                    ; AX = MB above 16MB
    mov [mem_mb_ext2], ax     ; Store MB value
    call dec_emit             ; Print value in AX as decimal
    call emit_M               ; Print "M" and newline
    jmp .mem_sum              ; Continue to total memory

.no_e801:
    mov si, _msg_notsup       ; SI points to "Not Supported" string
    call str_emit             ; Output not supported message
    mov word [mem_mb_ext2], 0 ; Set MB above 16MB to zero

.mem_sum:
    mov si, _mem_total        ; SI points to total memory label
    call str_emit             ; Output total memory label

    mov eax, 0                ; Clear EAX for total KB
    movzx ebx, word [mem_kb_base] ; Zero-extend base memory
    add eax, ebx              ; Add base memory to total
    movzx ebx, word [mem_kb_ext]  ; Zero-extend extended memory
    add eax, ebx              ; Add extended memory to total
    movzx ebx, word [mem_mb_ext2] ; Zero-extend MB above 16MB
    mov ecx, 1024             ; Multiplier for MB to KB
    imul ebx, ecx             ; Convert MB to KB
    add eax, ebx              ; Add to total KB
    mov edx, 0                ; Clear EDX for division
    mov ecx, 1024             ; Divisor for KB to MB
    div ecx                   ; EAX = total MB
    call dec_emit             ; Print total MB
    call emit_M               ; Print "M" and newline
    ret                       ; Return from memory probe

; -----------------------------------------------------------------------------
; CPU VENDOR AND BRAND DETECTION
; -----------------------------------------------------------------------------

cpu_probe:
    mov si, _cpu_vendor       ; SI points to CPU vendor label
    call str_emit             ; Output CPU vendor label
    mov eax, 0                ; CPUID function 0
    cpuid                     ; Get vendor string in EBX, EDX, ECX
    mov [cpu_vendor_val+0], ebx ; Store first 4 chars
    mov [cpu_vendor_val+4], edx ; Store next 4 chars
    mov [cpu_vendor_val+8], ecx ; Store last 4 chars
    mov si, cpu_vendor_val    ; SI points to vendor string
    call str_emit             ; Output vendor string
    call emit_crlf            ; Output newline

    mov si, _cpu_desc         ; SI points to CPU brand label
    call str_emit             ; Output CPU brand label
    mov eax, 80000002h        ; CPUID function 80000002h
    cpuid                     ; Get first 16 chars of brand string
    mov [cpu_type_val+0], eax
    mov [cpu_type_val+4], ebx
    mov [cpu_type_val+8], ecx
    mov [cpu_type_val+12], edx
    mov eax, 80000003h        ; CPUID function 80000003h
    cpuid                     ; Get next 16 chars
    mov [cpu_type_val+16], eax
    mov [cpu_type_val+20], ebx
    mov [cpu_type_val+24], ecx
    mov [cpu_type_val+28], edx
    mov eax, 80000004h        ; CPUID function 80000004h
    cpuid                     ; Get final 16 chars
    mov [cpu_type_val+32], eax
    mov [cpu_type_val+36], ebx
    mov [cpu_type_val+40], ecx
    mov [cpu_type_val+44], edx
    mov si, cpu_type_val      ; SI points to brand string
    call str_emit             ; Output brand string
    call emit_crlf            ; Output newline
    ret                       ; Return from CPU probe

; -----------------------------------------------------------------------------
; HDD DETECTION: Count number of hard drives
; -----------------------------------------------------------------------------

hdd_probe:
    mov si, _hdd_label        ; SI points to HDD label
    call str_emit             ; Output HDD label
    push es                   ; Save ES
    mov ax, 40h               ; BIOS Data Area segment
    mov es, ax                ; Set ES to BIOS Data Area
    mov al, [es:75h]          ; Number of HDDs at 0040:0075
    mov ah, 0                 ; Clear upper byte for AX
    pop es                    ; Restore ES
    call dec_emit             ; Print HDD count
    call emit_crlf            ; Output newline
    ret                       ; Return from HDD probe

; -----------------------------------------------------------------------------
; MOUSE DETECTION: Check for mouse presence
; -----------------------------------------------------------------------------

mouse_probe:
    mov si, _mouse_label      ; SI points to mouse label
    call str_emit             ; Output mouse label
    mov ax, 0                 ; AX=0: Mouse init/detect
    int 33h                   ; BIOS mouse interrupt
    cmp ax, 0                 ; AX=0 means no mouse
    je .no_mouse              ; Jump if no mouse found
    mov si, _msg_mousefound   ; SI points to mouse found string
    call str_emit             ; Output mouse found
    jmp .mouse_done           ; Skip to done

.no_mouse:
    mov si, _msg_mousenot     ; SI points to mouse not found string
    call str_emit             ; Output not found

.mouse_done:
    call emit_crlf            ; Output newline
    ret                       ; Return from mouse probe

; -----------------------------------------------------------------------------
; SERIAL PORT DETECTION: Count and display serial ports
; -----------------------------------------------------------------------------

serial_probe:
    mov si, _serial_count     ; SI points to serial count label
    call str_emit             ; Output serial port count label
    push es                   ; Save ES
    mov ax, 40h               ; BIOS Data Area segment
    mov es, ax                ; Set ES to BIOS Data Area
    mov cx, 0                 ; CX = serial port count
    mov si, 0                 ; SI = offset for port addresses
.serial_loop:
    mov dx, [es:si]           ; Read port address
    cmp dx, 0                 ; If zero, no port
    je .serial_next           ; Skip if not present
    inc cx                    ; Increment count if present
.serial_next:
    add si, 2                 ; Next port address
    cmp si, 8                 ; Only 4 ports (8 bytes)
    jne .serial_loop          ; Loop through all ports
    mov ax, cx                ; AX = count
    call dec_emit             ; Print serial port count
    call emit_crlf            ; Output newline
    mov si, _serial_addr      ; SI points to address label
    call str_emit             ; Output address label
    mov ax, [es:0]            ; First serial port address
    pop es                    ; Restore ES
    call dec_emit             ; Print port address
    call emit_crlf            ; Output newline
    ret                       ; Return from serial probe

; -----------------------------------------------------------------------------
; CPU FEATURE DETECTION: FPU, MMX, SSE, SSE2
; -----------------------------------------------------------------------------

cpu_feat_probe:
    mov si, _cpu_features     ; SI points to features label
    call str_emit             ; Output features label
    mov eax, 1                ; CPUID function 1
    cpuid                     ; Get feature flags in EDX
    mov [feat_flags], edx     ; Store EDX for reference
    test edx, 1 << 0          ; FPU present?
    jz .no_fpu                ; Skip if not present
    mov si, _fpu              ; SI points to FPU string
    call str_emit             ; Output FPU
.no_fpu:
    test edx, 1 << 23         ; MMX present?
    jz .no_mmx                ; Skip if not present
    mov si, _mmx              ; SI points to MMX string
    call str_emit             ; Output MMX
.no_mmx:
    test edx, 1 << 25         ; SSE present?
    jz .no_sse                ; Skip if not present
    mov si, _sse              ; SI points to SSE string
    call str_emit             ; Output SSE
.no_sse:
    test edx, 1 << 26         ; SSE2 present?
    jz .no_sse2               ; Skip if not present
    mov si, _sse2             ; SI points to SSE2 string
    call str_emit             ; Output SSE2
.no_sse2:
    call emit_crlf            ; Output newline
    ret                       ; Return from feature probe

; =============================================================================
; KERNEL UTILITY SUBROUTINES
; =============================================================================

; -----------------------------------------------------------------------------
; STRING EMIT: Print null-terminated string at DS:SI
; -----------------------------------------------------------------------------

str_emit:
    mov ah, 0Eh               ; BIOS teletype output
.str_loop:
    lodsb                     ; Load byte at DS:SI into AL
    cmp al, 0                 ; Null terminator?
    je .str_done              ; End of string
    int 10h                   ; Print character
    jmp .str_loop             ; Continue
.str_done:
    ret                       ; Return from string emit

; -----------------------------------------------------------------------------
; EMIT CRLF: Print carriage return and line feed
; -----------------------------------------------------------------------------

emit_crlf:
    push ax                   ; Save AX
    mov ah, 0Eh               ; BIOS teletype output
    mov al, 0Dh               ; Carriage return
    int 10h                   ; Print CR
    mov al, 0Ah               ; Line feed
    int 10h                   ; Print LF
    pop ax                    ; Restore AX
    ret                       ; Return from emit_crlf

; -----------------------------------------------------------------------------
; EMIT K: Print 'k' and newline for KB
; -----------------------------------------------------------------------------

emit_k:
    pusha                     ; Save all registers
    mov si, _k                ; SI points to 'k'
    call str_emit             ; Print 'k'
    call emit_crlf            ; Print newline
    popa                      ; Restore all registers
    ret                       ; Return from emit_k

; -----------------------------------------------------------------------------
; EMIT M: Print 'M' and newline for MB
; -----------------------------------------------------------------------------

emit_M:
    pusha                     ; Save all registers
    mov si, _M                ; SI points to 'M'
    call str_emit             ; Print 'M'
    call emit_crlf            ; Print newline
    popa                      ; Restore all registers
    ret                       ; Return from emit_M

; -----------------------------------------------------------------------------
; STRING INPUT: Read user input into buffer at ES:DI
; -----------------------------------------------------------------------------

str_input:
    pusha                     ; Save all registers
    mov bx, di                ; BX = start of buffer
.input_loop:
    mov ah, 00h               ; BIOS: Read char from keyboard
    int 16h                   ; AL = char, AH = scan code
    cmp al, 0Dh               ; Enter key?
    je .input_done            ; Done if Enter
    cmp al, 08h               ; Backspace?
    je .handle_bksp           ; Handle backspace
    mov [di], al              ; Store character in buffer
    mov ah, 0Eh               ; BIOS teletype output
    int 10h                   ; Print character
    inc di                    ; Next buffer position
    jmp .input_loop           ; Continue reading

.handle_bksp:
    cmp di, bx                ; At buffer start?
    je .input_loop            ; Ignore if at start
    dec di                    ; Move back in buffer
    mov byte [di], 0          ; Clear character
    mov ah, 0Eh               ; BIOS teletype output
    mov al, 08h               ; Backspace
    int 10h
    mov al, ' '               ; Print space to erase
    int 10h
    mov al, 08h               ; Backspace again
    int 10h
    jmp .input_loop           ; Continue reading

.input_done:
    mov byte [di], 0          ; Null-terminate buffer
    popa                      ; Restore all registers
    ret                       ; Return from string input

; -----------------------------------------------------------------------------
; STRING COMPARE: Compare two null-terminated strings at DS:SI and ES:DI
; -----------------------------------------------------------------------------

str_cmp:
    pusha                     ; Save all registers
.cmp_loop:
    mov al, [si]              ; Load char from SI
    mov ah, [di]              ; Load char from DI
    cmp al, ah                ; Compare chars
    jne .not_eq               ; Not equal if mismatch
    cmp al, 0                 ; End of both strings?
    je .eq                    ; Equal if both ended
    inc si                    ; Next char SI
    inc di                    ; Next char DI
    jmp .cmp_loop             ; Continue compare
.not_eq:
    popa                      ; Restore registers
    cmp ax, bx                ; Set ZF=0 for not equal
    ret                       ; Return
.eq:
    popa                      ; Restore registers
    cmp ax, ax                ; Set ZF=1 for equal
    ret                       ; Return

; -----------------------------------------------------------------------------
; DECIMAL EMIT: Print unsigned integer in AX/EAX as decimal
; -----------------------------------------------------------------------------

dec_emit:
    pusha                     ; Save all registers
    mov cx, 0                 ; Digit counter
    mov ebx, 10               ; Divisor for decimal
.div_loop:
    mov edx, 0                ; Clear upper 32 bits
    div ebx                   ; Divide EAX by 10
    push edx                  ; Push remainder (digit)
    inc cx                    ; Increment digit count
    cmp eax, 0                ; Done dividing?
    jne .div_loop             ; Continue if not zero
.print_loop:
    pop eax                   ; Pop digit
    add al, '0'               ; Convert to ASCII
    mov ah, 0Eh               ; BIOS teletype output
    int 10h                   ; Print digit
    loop .print_loop          ; Loop for all digits
    popa                      ; Restore all registers
    ret                       ; Return

; -----------------------------------------------------------------------------
; VIDEO CLEAR: Set video mode to clear screen and reset cursor
; -----------------------------------------------------------------------------

vid_clear:
    pusha                     ; Save all registers
    mov ah, 00h               ; BIOS: Set video mode
    mov al, 03h               ; 80x25 text mode
    int 10h                   ; Set mode
    popa                      ; Restore all registers
    ret                       ; Return

; =============================================================================
; KERNEL DATA SEGMENT: Strings, buffers, and variables
; =============================================================================

_boot_msg1      db 'Booting from Floppy...', 0
_boot_msg2      db 'Loading Boot Image', 0
_boot_dots      db '.................', 0

_greet_msg         db 'Welcome to the paradise LoRanOS by Lochithya Hettiarachchi!', 0
_prompt_msg        db 'LoRanOS $ >> ', 0
_msg_unknown       db 'Command not recognized', 0
_cmd_info          db 'info', 0
_cmd_help          db 'help', 0
_cmd_clear         db 'clear', 0
_help_screen       db 'info - System Profile', 0Dh, 0Ah, 'clear - Wipe Display', 0Dh, 0Ah, 0

_mem_base          db 'Base Memory: ', 0
_mem_ext           db 'Extended Memory Between(1M-16M): ', 0
_mem_ext2          db 'Extended Memory Above(>16M): ', 0
_mem_total         db 'Aggregate RAM: ', 0

_cpu_vendor        db 'CPU Vendor: ', 0
_cpu_desc          db 'CPU Descriptor: ', 0
_hdd_label         db 'Hard disc drive Count: ', 0
_mouse_label       db 'Availability of Mouse: ', 0
_serial_count      db 'Serial Ports: ', 0
_serial_addr       db 'Base I/O Address for Serial Port 1: ', 0
_cpu_features      db 'CPU Flags: ', 0

_vga_label         db 'Graphics Adapter: VGA Compatible', 0
_usb_label         db 'USB Controller: Emulated', 0
_virt_label        db 'Virtualization: Oracle VirtualBox', 0
_bios_label        db 'BIOS Version: Not Detected', 0
_audio_label       db 'Audio Device: Sound Blaster Emulated', 0
_network_label     db 'Network Adapter: PCnet-FAST III (Am79C973) Emulated', 0
_battery_label     db 'Battery Status: Not Present', 0

_msg_mousefound    db 'Mouse Detected', 0
_msg_mousenot      db 'Mouse not present', 0
_msg_notsup        db 'Unsupported', 0

_k                 db 'k', 0
_M                 db 'M', 0
_fpu               db 'FPU ', 0
_mmx               db 'MMX ', 0
_sse               db 'SSE ', 0
_sse2              db 'SSE2 ', 0


_cmd_buf           times 64 db 0
cpu_vendor_val     times 13 db 0
cpu_type_val       times 49 db 0

mem_kb_base        dw 0
mem_kb_ext         dw 0
mem_16k            dw 0
mem_64k            dw 0
mem_mb_ext2        dw 0
feat_flags         dd 0

; =============================================================================
; END OF KERNEL
; =============================================================================
