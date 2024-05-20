PARAMETER_COLOR = COLOR_GREY_1
TPAU_COLOR = COLOR_GREY_1
FRAME_COLOR = COLOR_GREY_2
BACKGROUND_COLOR = COLOR_GREY_3
NAME_COLOR = COLOR_BLACK
CLOCK_COLOR = COLOR_GREY_1

.section code

; Set up clock display based on flags.
; Arguments:
;   X: clock index
; Returns: -
.public setup_clock_display {
    setup_clock_display_position
    ldy #6
    lda clocks_flags,x
    bmi date
    lda #$20 ; ' ':screen
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    ldy #4
date:
    lda #$2f ; "/":screen
    sta (screen_ptr),y
    iny
    iny
    iny
    lda #$2f ; '/':screen
    sta (screen_ptr),y

    lda clocks_flags,x
    and #1
    beq no_sub_second
    ldy #50
    lda #$2e ; '.':screen
    sta (screen_ptr),y
    ldy #44
    bne time
no_sub_second:
    lda #$20 ; ' ':screen
    ldy #42
    sta (screen_ptr),y
    ldy #51
    sta (screen_ptr),y
    ldy #45
time:
    lda #$3a ; ':':screen
    sta (screen_ptr),y
    iny
    iny
    iny
    lda #$3a
    sta (screen_ptr),y

    sec
    lda screen_ptr
    sbc #80
    sta screen_ptr
    sta ptr
    lda screen_ptr + 1
    sbc #$00
    sta screen_ptr + 1
    eor #$dc ; <(screen ^ color_ram)
    sta ptr + 1
    lda clocks_name_low,x
    sta ptr2
    lda clocks_name_high,x
    sta ptr2 + 1
    ldy #0
:   lda (ptr2),y
    beq :+
    ora #$80
    sta (screen_ptr),y
    lda #NAME_COLOR
    sta (ptr),y
    iny
    bne :-
:   lda #$a0 ; ' ':screen_inverted
    sta (screen_ptr),y
    iny
    lda clocks_parameter,x
    cmp #$ff
    beq no_number
    lda #$a3 ; '#':screen_inverted
    sta (screen_ptr),y
    lda #PARAMETER_COLOR
    sta (ptr),y
    iny
    ldx #0
    lda clocks_parameter,x
:   cmp #100
    bcc hundreds_done
    sec
    sbc #100
    inx
    bne :-
hundreds_done:
    cpx #0
    stx display_zeroes
    beq tens
    sta display_tmp
    txa
    ora #$b0 ; '0':screen_inverted
    sta (screen_ptr),y
    lda #PARAMETER_COLOR
    sta (ptr),y
    iny
    lda display_tmp
tens:
    ldx #0
:   cmp #10
    bcc tens_done
    sec
    sbc #10
    inx
    bne :-
tens_done:
    sta display_tmp
    cpx #0
    bne display_tens
    lda display_zeroes
    beq ones
display_tens:
    txa
    ora #$b0 ; '0':screen_inverted
    sta (screen_ptr),y
    lda #PARAMETER_COLOR
    sta (ptr),y
    iny
ones:
    lda display_tmp
    ora #$b0 ; '0':screen_inverted
    sta (screen_ptr),y
    lda #PARAMETER_COLOR
    sta (ptr),y
    iny
no_number:
    lda #$a0 ; ' ':screen
:   sta (screen_ptr),y
    iny
    cpy #14
    bcc :-
    rts
}

; Update clock based on flags.
; Arguments:
;   X: clock index
; Returns: -
; Preserves: -
.public display_clock {
    setup_clock_display_position
    lda clocks_flags,x
    bpl no_weekday
    ldy #0
    lda weekday,x
    asl
    asl
    tax
    lda weekdays,x
    sta (screen_ptr),y
    iny
    lda weekdays + 1,x
    sta (screen_ptr),y
    iny
    lda weekdays + 2,x
    sta (screen_ptr),y
    iny
    ldx clocks_current
    iny
    bne date
no_weekday:
    ldy #2
date:
    lda day,x
    jsr display_bcd
    iny
    lda month,x
    jsr display_bcd
    iny
    lda century,x
    jsr display_bcd
    lda year,x
    jsr display_bcd

    ldy #43
    lda clocks_flags,x
    and #1
    beq time
    ldy #51
    lda sub_second,x
    and #$0f
    ora #$30
    sta (screen_ptr),y
    ldy #42
time:
    lda hour,x
    jsr display_bcd
    iny
    lda minute,x
    jsr display_bcd
    iny
    lda second,x
    jmp display_bcd
}

.public display_bcd {
    sta display_tmp
    lsr
    lsr
    lsr
    lsr
    ora #$30
    sta (screen_ptr),y
    iny
    lda display_tmp
    and #$0f
    ora #$30
    sta (screen_ptr),y
    iny
    rts
}

; X: clock index
; preserves X
.macro setup_clock_display_position {
    lda clocks_screen_position_low,x
    sta screen_ptr
    lda clocks_screen_position_high,x
    sta screen_ptr + 1
}

.section data

weekdays {
    .data "sun":screen, 0
    .data "mon":screen, 0
    .data "tue":screen, 0
    .data "wed":screen, 0
    .data "thu":screen, 0
    .data "fri":screen, 0
    .data "sat":screen, 0
    .data "sun":screen, 0
}

.section zero_page

display_tmp .reserve 1
display_zeroes .reserve 1