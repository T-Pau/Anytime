MAX_CLOCK_DISPLAYS = 6
MAX_CLOCKS = 16

CLOCK_FLAG_WEEKDAY = $80
CLOCK_FLAG_CENTURY = $40
CLOCK_FLAG_24_HOURS = $20
CLOCK_FLAG_SUB_SECOND = $1

CLOCK_STATUS_ERROR = $80

.section code

clocks_init {
    lda #0
    sta clocks_count
    jsr clock_backbit_detect
    jsr clock_iec_detect
    ; TODO: detect others

    lda clocks_count
    cmp #MAX_CLOCK_DISPLAYS
    bcc :+
    lda #MAX_CLOCK_DISPLAYS
:   sta clocks_active_count
    rts
}

clocks_init_display {
    ldx #0
loop:
    cpx clocks_active_count
    bne :+
    rts
:   stx clocks_current
    jsr setup_clock_display
    ldx clocks_current
    lda clocks_open_high,x
    beq no_open
    sta open + 2
    lda clocks_open_low,x
    sta open + 1
    lda clocks_parameter,x
open:
    jsr $1000
no_open:
    ldx clocks_current
    inx
    bne loop
}

clocks_update {
    ldx #0
loop:
    cpx clocks_active_count
    bne :+
    rts
:   stx clocks_current
    lda clocks_read_low,x
    sta read + 1
    lda clocks_read_high,x
    sta read + 2
    lda clocks_parameter,x
read:
    jsr $1000
    ldx clocks_current
    jsr clock_normalize
    jsr display_clock
    ldx clocks_current
    inx
    bne loop
}


; X/Y: pointer to clock info
; A: parameter
clock_register {
    stx ptr
    sty ptr + 1
    ldx clocks_count
    ldy #0
    lda (ptr),y
    iny
    sta clocks_parameter,x
    lda (ptr),y
    iny
    sta clocks_flags,x
    lda (ptr),y
    iny
    sta clocks_name_low,x
    lda (ptr),y
    iny
    sta clocks_name_high,x
    lda (ptr),y
    iny
    sta clocks_open_low,x
    lda (ptr),y
    iny
    sta clocks_open_high,x
    lda (ptr),y
    iny
    sta clocks_read_low,x
    lda (ptr),y
    iny
    sta clocks_read_high,x
    lda (ptr),y
    iny
    sta clocks_close_low,x
    lda (ptr),y
    iny
    sta clocks_close_high,x
    inx
    stx clocks_count
    rts
}

; X: clock index
; preserves X
clock_normalize {
    lda status,x
    bne end
    lda clocks_flags,x
    and #CLOCK_FLAG_CENTURY
    bne century_ok
    ldy #$20
    lda year,x
    cmp #$70
    bcc :+
    ldy #$19
:   tya
    sta century,x
century_ok:
    lda clocks_flags,x
    and #CLOCK_FLAG_24_HOURS
    bne end
    lda am_pm,x
    beq end
    lda hour,x
    clc
    sei
    sed
    adc #$12
    cld
    cli
    sta hour,x
end:
    rts
}

.section data

clock_screen_position(row, column) = screen + 40 * (row * 6 + 2) + column * 20 + 3

clocks_screen_position_low {
    .repeat row, 3 {
        .repeat column, 2 {
            .data <clock_screen_position(row, column)
        }
    }
}

clocks_screen_position_high {
    .repeat row, 3 {
        .repeat column, 2 {
            .data >clock_screen_position(row, column)
        }
    }
}

.section reserved

clocks_count .reserve 1
clocks_active_count .reserve 1
clocks_current .reserve 1
clocks_read_low .reserve MAX_CLOCKS
clocks_read_high .reserve MAX_CLOCKS
clocks_open_low .reserve MAX_CLOCKS
clocks_open_high .reserve MAX_CLOCKS
clocks_close_low .reserve MAX_CLOCKS
clocks_close_high .reserve MAX_CLOCKS
clocks_name_low .reserve MAX_CLOCKS
clocks_name_high .reserve MAX_CLOCKS
clocks_parameter .reserve MAX_CLOCKS
clocks_flags .reserve MAX_CLOCKS



weekday .reserve MAX_CLOCK_DISPLAYS
century .reserve MAX_CLOCK_DISPLAYS
year .reserve MAX_CLOCK_DISPLAYS
month .reserve MAX_CLOCK_DISPLAYS
day .reserve MAX_CLOCK_DISPLAYS
hour .reserve MAX_CLOCK_DISPLAYS
minute .reserve MAX_CLOCK_DISPLAYS
second .reserve MAX_CLOCK_DISPLAYS
sub_second .reserve MAX_CLOCK_DISPLAYS
am_pm .reserve MAX_CLOCK_DISPLAYS
status .reserve MAX_CLOCK_DISPLAYS
