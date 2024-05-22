.public SMARTMOUSE_CLOCK_SIZE = 8
.public SMARTMOUSE_RAM_SIZE = 32

SMARTMOUSE_COMMAND_RAM = $40
SMARTMOUSE_COMMAND_CLOCK = $00
SMARTMOUSE_COMMAND_ADDRESS(address) = (address & $1f) << 1
SMARTMOUSE_COMMAND_BURST = SMARTMOUSE_COMMAND_ADDRESS($1f)
SMARTMOUSE_COMMAND_READ = $01
SMARTMOUSE_COMMAND_WRITE = $00

SMARTMOUSE_RESET = $08
SMARTMOUSE_CLOCK = $02
SMARTMOUSE_DATA = $04

.section code

.macro clear_bits bits {
    and #$ff ^ bits
}

.macro set_bits bits {
    ora #bits
}

;-------------------------------------
;(application callable routines)
;-------------------------------------

; Read 8 clock bytes and 24 RAM bytes to (ptr).
; Arguments:
;   A: controller port (1, 2)
.public smartmouse_read_all {
    jsr setup
    jsr bulk_read_clock
    jsr ptr_skip_clock
    jsr bulk_read_ram
    jsr ptr_unskip_clock
    jmp exit
}


; Read 8 clock bytes to (ptr).
; Arguments:
;   A: controller port (1, 2)
.public smartmouse_read_clock {
    and #$01
    tax
    jsr setup
    jsr bulk_read_clock
    jmp exit
}


; Read one clock byte.
; Arguments:
;   A: controller port (1, 2)
;   X: byte
;   Y: address
.public smartmouse_read_clock_byte {
    stx io_byte
    and #$01
    tax
    lda io_byte
    jsr setup
    jsr read_clock_single
    jmp exit
}

; Read 24 RAM bytes to (ptr).
; Arguments:
;   A: controller port (1, 2)
.public smartmouse_read_ram {
    and #$01
    tax
    jsr setup
    jsr bulk_read_ram
    jmp exit
}


; Read one RAM byte.
; Arguments:
;   A: controller port (1, 2)
;   Y: address
; Returns:
;   A: byte
.public smartmouse_read_ram_byte {
    and #$01
    tax
    jsr setup
    jsr read_ram_single
    jmp exit
}


; Write 8 clock bytes and 24 RAM bytes from (ptr).
; Arguments:
;   A: controller port (1, 2)
.public smartmouse_write_all {
    and #$01
    tax
    jsr setup
    jsr bulk_write_clock
    jsr ptr_skip_clock
    jsr bulk_write_ram
    jsr ptr_unskip_clock
    jmp exit
}


; Write 8 clock bytes from (ptr).
; Arguments:
;   A: controller port (1, 2)
.public smartmouse_write_clock {
    and #$01
    tax
    jsr setup
    jsr bulk_write_clock
    jmp exit
}


; Write one clock byte.
; Arguments:
;   A: controller port (1, 2)
;   X: byte
;   Y: address
.public smartmouse_write_clock_byte {
    stx io_byte
    and #$01
    tax
    lda io_byte
    jsr setup
    jsr write_clock_single
    jmp exit
}


; Write 24 RAM bytes from (ptr).
; Arguments:
;   A: controller port (1, 2)
.public smartmouse_write_ram {
    and #$01
    tax
    jsr setup
    jsr bulk_write_ram
    jmp exit
}


; Write one RAM byte.
; Arguments:
;   A: controller port (1, 2)
;   X: byte
;   Y: address
.public smartmouse_write_ram_byte {
    stx io_byte
    and #$01
    tax
    lda io_byte
    jsr setup
    jsr write_ram_single
    jmp exit
}


;-------------------------------------
;(variables)
;-------------------------------------

.section reserved

port_save .reserve 1
ddr_save .reserve 1
status_save .reserve 1
a_save .reserve 1
y_save .reserve 1
io_byte .reserve 1
bytes_count .reserve 1
bytes_current .reserve 1


;-------------------------------------
;(burst read subs)
;-------------------------------------

; Bulk read 8 clock bytes to (ptr).
;   Call setup first.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X
bulk_read_clock {
    lda #$80 | SMARTMOUSE_COMMAND_CLOCK | SMARTMOUSE_COMMAND_BURST | SMARTMOUSE_COMMAND_READ
    jsr send_command_byte
    lda #SMARTMOUSE_CLOCK_SIZE
    jmp read_bytes_burst
}


; Bulk write 8 clock bytes from (ptr).
;   Call setup first.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X
bulk_write_clock {
    jsr send_write_protect_off
    lda #$80 | SMARTMOUSE_COMMAND_CLOCK | SMARTMOUSE_COMMAND_BURST | SMARTMOUSE_COMMAND_WRITE
    jsr send_command_byte
    lda #SMARTMOUSE_CLOCK_SIZE
    jsr write_bytes_burst
    jmp send_write_protect_on
}

;(read 24 ram bytes)
bulk_read_ram {
    lda #$80 | SMARTMOUSE_COMMAND_RAM | SMARTMOUSE_COMMAND_BURST | SMARTMOUSE_COMMAND_READ
    jsr send_command_byte
    lda #SMARTMOUSE_RAM_SIZE
    jmp read_bytes_burst
}

;(write 24 ram bytes)
bulk_write_ram {
    jsr send_write_protect_off
    lda #$80 | SMARTMOUSE_COMMAND_RAM | SMARTMOUSE_COMMAND_BURST | SMARTMOUSE_COMMAND_WRITE
    jsr send_command_byte
    lda #SMARTMOUSE_RAM_SIZE
    jsr write_bytes_burst
    jmp send_write_protect_on
}

;-------------------------------------
;(read single byte subs)
;-------------------------------------

read_single_common {
    jsr send_command_address
    jsr read_byte
    jsr reset_high
    lda io_byte
    rts
}

; Read one clock byte.
; Arguments:
;   X: CIA port (0, 1)
;   Y: Argument
; Returns:
;   A: byte
; Preserves: X
read_clock_single {
    lda #$80 | SMARTMOUSE_COMMAND_CLOCK | SMARTMOUSE_COMMAND_READ
    jmp read_single_common
}

; Read one RAM byte.
; Arguments:
;   X: CIA port (0, 1)
;   Y: Argument
; Returns:
;   A: byte
; Preserves: X
read_ram_single {
    lda #$80 | SMARTMOUSE_COMMAND_RAM | SMARTMOUSE_COMMAND_READ
    jmp read_single_common
}


; Write one clock byte.
; Arguments:
;   A: byte
;   X: CIA port (0, 1)
;   Y: Argument
; Returns: -
; Preserves: X
write_clock_single {
    clc
    jmp write_single_common
}

; Write one RAM byte.
; Arguments:
;   A: byte
;   X: CIA port (0, 1)
;   Y: Argument
; Returns: -
; Preserves: X
write_ram_single {
    sec
    jmp write_single_common
}

; Write one byte.
; Arguments:
;   A: byte
;   X: CIA port (0, 1)
;   Y: Argument
;   C: set: write RAM, clear: write clock
; Returns: -
; Preserves: X
write_single_common {
    sta a_save
    sty y_save
    jsr send_write_protect_off
    lda #$80 | SMARTMOUSE_COMMAND_WRITE
    bcc :+
    ora #SMARTMOUSE_COMMAND_RAM
:   ldy y_save
    jsr send_command_address
    jsr set_io_output
    lda a_save
    jsr send_byte
    jsr set_io_input
    jsr send_write_protect_off
    rts
}

; Send command with address.
; Arguments:
;   A: command
;   X: CIA port (0, 1)
;   Y: address
; Preserves: X
send_command_address {
    sta io_byte
    tya
    asl
    and #$3e
    ora io_byte
    jmp send_command_byte
}

;-------------------------------------
;(write protect routines)
;-------------------------------------

; Turn write protect off.
;   Call setup first.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X
send_write_protect_off {
    lda #$00
    jmp send_write_protect
}

; Turn write protect on.
;   Call setup first.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X
send_write_protect_on {
    lda #$80
.private send_write_protect:
    pha
    lda #$8e
    jsr send_command_byte
    jsr set_io_output
    pla
    jsr slbyt
    jmp reset_high
}

;-------------------------------------
;(low-level routines)
;-------------------------------------

; Skip ptr past clock portion.
; Arguments: -
; Returns: -
; Preserves: X, Y
ptr_skip_clock {
    lda ptr
    clc
    adc #SMARTMOUSE_CLOCK_SIZE
    sta ptr
    bcc :+
    inc ptr + 1
:   rts
}

; Unskip ptr to beginning of clock portion.
; Arguments: -
; Returns: -
; Preserves: X, Y
ptr_unskip_clock {
    lda ptr
    sec
    sbc #SMARTMOUSE_CLOCK_SIZE
    sta ptr
    bcs :+
    dec ptr + 1
:   rts
}

;(send command byte)-------------------
;call 'setup' before using this routine


; Send command byte.
;   Call setup first.
; Arguments:
;   A: byte
;   X: CIA port (0, 1)
; Preserves: X
send_command_byte {
    sta io_byte
    ; prepare DS-1202 to receive command
    jsr set_io_output
    lda CIA1_PRA,x
    set_bits(SMARTMOUSE_RESET)
    sta CIA1_PRA,x
    clear_bits(SMARTMOUSE_RESET | SMARTMOUSE_CLOCK | SMARTMOUSE_DATA)
    sta CIA1_PRA,x
    lda io_byte
.private slbyt:
    jsr send_byte
    jmp set_io_input
}


; Read bytes in burst mode to (ptr).
;   Call send_command_byte first.
; Arguments:
;   A: number of bytes to read
;   X: CIA port (0, 1)
; Preserves: X
read_bytes_burst {
    sta bytes_count
    ldy #0
:   sty bytes_current
    jsr read_byte
    ldy bytes_current
    sta (ptr),y
    iny
    cpy bytes_count
    bcc :-
    jmp reset_high
}


; Write bytes in burst mode from (ptr).
;   Call send_command_byte first.
; Arguments:
;   A: number of bytes to read
;   X: CIA port (0, 1)
; Preserves: X
write_bytes_burst {
    sta bytes_count
    jsr set_io_output
    ldy #0
:   sty bytes_current
    lda (ptr),y
    jsr send_byte
    ldy bytes_current
    iny
    cpy bytes_count
    bcc :-
    jsr reset_high
    jmp set_io_input
}


; Read single byte.
;   Call send_command_byte first.
; Arguments:
;   X: CIA port (0, 1)
; Returns:
;   A: byte read
; Preserves: X
read_byte {
    ldy #8
    lda CIA1_PRA,x
:   and #$ff ^ SMARTMOUSE_CLOCK |SMARTMOUSE_DATA
    sta CIA1_PRA,x
    lda CIA1_PRA,x
    lsr a
    lsr a
    lsr a
    ror io_byte
    lda CIA1_PRA,x
    ora #SMARTMOUSE_CLOCK
    sta CIA1_PRA,x
    dey
    bne :-

    lda io_byte
    rts
}

; Write single byte.
;   Call send_command_byte first.
; Arguments:
;   A: byte
;   X: CIA port (0, 1)
; Returns:
; Preserves: X
send_byte {
    sta io_byte
    ldy #8
    lda CIA1_PRA,x
loop:
    clear_bits(SMARTMOUSE_CLOCK)
    sta CIA1_PRA,x
    ror io_byte
    bcc :+
    set_bits(SMARTMOUSE_DATA)
    bne send_bit
:   clear_bits(SMARTMOUSE_DATA)
send_bit:
    sta CIA1_PRA,x
    set_bits(SMARTMOUSE_CLOCK)
    sta CIA1_PRA,x
    dey
    bne loop
    rts
}

; Set reset to low.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X, Y
reset_low {
    lda CIA1_PRA,x
    clear_bits(SMARTMOUSE_RESET)
    sta CIA1_PRA,x
    rts
}
    

; Set reset to high.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X, Y
reset_high {
    lda CIA1_PRA,x
    set_bits(SMARTMOUSE_RESET)
    sta CIA1_PRA,x
    rts
}


; Set I/O direction for data to output.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X, Y
set_io_output {
    lda #SMARTMOUSE_RESET | SMARTMOUSE_CLOCK | SMARTMOUSE_DATA
    sta CIA1_DDRA,x
    rts
}

; Set I/O direction for data to input.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: X, Y
set_io_input {
    lda #SMARTMOUSE_RESET | SMARTMOUSE_CLOCK
    sta CIA1_DDRA,x
    rts
}


; Set up ports for DS-1202 I/O.
;   Call as first step to any DS-1202 access.
; Arguments:
;   X: CIA port (0, 1)
; Returns: -
; Preserves: A, X, Y
setup {
    php
    sei
    sta io_byte
    pla
    sta status_save
    lda CIA1_PRA,x
    sta port_save
    lda CIA1_DDRA,x
    sta ddr_save
    lda #$ff
    sta CIA1_PRA,x
    lda #SMARTMOUSE_RESET | SMARTMOUSE_CLOCK
    sta CIA1_DDRA,x
    lda io_byte
    rts
}


;(exit routine)-----------------------
;jmp here to return to calling program

; Restore state.
;   Call this routine after DS-1202 access before returning to caller.
; Arguments:
;   X: CIA port (0, 1)
; Preserves: A, X, Y
exit {
    sta io_byte
    lda port_save
    sta CIA1_PRA,x
    lda ddr_save
    sta CIA1_DDRA,x
    lda status_save
    pha
    lda io_byte
    plp
    rts
}
