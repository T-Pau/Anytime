MAX_CLOCK_DISPLAYS = 6
MAX_CLOCKS = 16

CLOCK_WEEKDAY = $80
CLOCK_SUB_SECOND = $1

.section code

clocks_init {
    lda #0
    sta clocks_count
    jsr clock_backbit_detect
    ; TODO: detect others
    rts
}

; X/Y: pointer to clock info
; A: parameter
clock_register {
    stx ptr
    sty ptr + 1
    ldx clocks_count
    inx
    stx clocks_count
    ldy #0
    lda (ptr),y
    iny
    sta clocks_parameter,x
    lda (ptr),y
    iny
    sta clocks_flags,x
    txa
    asl
    tax
    lda (ptr),y
    iny
    sta clocks_name,x
    lda (ptr),y
    iny
    sta clocks_name + 1,x
    lda (ptr),y
    iny
    sta clocks_open,x
    lda (ptr),y
    iny
    sta clocks_open + 1,x
    lda (ptr),y
    iny
    sta clocks_read,x
    lda (ptr),y
    iny
    sta clocks_read + 1,x
    lda (ptr),y
    iny
    sta clocks_close,x
    lda (ptr),y
    iny
    sta clocks_close + 1,x
    rts
}

; X: clock index
; preserves X
clock_normalize {
    lda status,x
    bne end
    lda century,x
    bpl century_ok
    ldy #$20
    lda year,x
    cmp #$70
    bcc :+
    ldy #$19
:   tya
    sta century,x
century_ok:
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

.section reserved

clocks_count .reserve 1
clocks_read .reserve MAX_CLOCKS * 2
clocks_open .reserve MAX_CLOCKS * 2
clocks_close .reserve MAX_CLOCKS * 2
clocks_name .reserve MAX_CLOCKS * 2
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
