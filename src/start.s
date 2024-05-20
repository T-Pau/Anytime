screen = $0400
color_ram = $d800

.section code

.public start {
    jsr setup_display

    jsr clocks_init
    jsr clocks_init_display

loop:
    jsr clocks_update
    jmp loop
}

setup_display {
    lda #VIC_VIDEO_ADDRESS($400, $2000)
    sta VIC_VIDEO_ADDRESS

    lda #FRAME_COLOR
    sta VIC_BORDER_COLOR
    sta VIC_BACKGROUND_COLOR_2
    lda #BACKGROUND_COLOR
    sta VIC_BACKGROUND_COLOR
    lda VIC_CONTROL_1
    ora #VIC_EXTENDED_BACKGROUND_COLOR
    sta VIC_CONTROL_1

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
    rts
}

.pin charset $2000

.section zero_page

screen_ptr .reserve 2
