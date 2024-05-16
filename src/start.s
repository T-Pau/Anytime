.section code

.public start {
    ldx #VIC_VIDEO_ADDRESS($400, $2000)
    stx VIC_VIDEO_ADDRESS

    lda #$0c
    sta VIC_BORDER_COLOR
    lda #$0f
    sta VIC_BACKGROUND_COLOR

    ldx #0
:   lda main_screen,x
    sta $0400,x
    lda main_screen + $100,x
    sta $0500,x
    lda main_screen + $200,x
    sta $0600,x
    lda main_screen + $2e8,x
    sta $06e8,x
    lda main_color,x
    sta $d800,x
    lda main_color + $100,x
    sta $d900,x
    lda main_color + $200,x
    sta $da00,x
    lda main_color + $2e8,x
    sta $dae8,x
    dex
    bne :-

    lda #$04
    sta screen_ptr + 1

    ldx #0
    lda #8
    jsr iec_open

loop:
    ldx #0
    jsr iec_read
    jsr clock_normalize
    ldy #83
    sty screen_ptr
    jsr display_clock_weekday

    jmp loop
}

.pin charset $2000
.pin charset_inverted $2400


.section zero_page

screen_ptr .reserve 2
