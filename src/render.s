
; x: >bitmap, y: >charset
.public render_init {
    stx screen_ptr + 1
    ldx #0
    txa

loop:
    sta char_address_low,x
    clc
    adc #$08
    bcc :+
    iny
    sta screen_ptr
    tya
    sta char_address_high,x
    lda screen_ptr
    inx
    bne loop

    stx screen_ptr
    rts
}

.macro render_char {
    tay
    lda char_address_low,y
    sta load + 1
    lda char_address_high,y
    sta load + 2
    ldy #7
load:
    lda charset,y
    sta (screen_ptr),y
    dey
    bpl load
    clc
    lda #8
    adc screen_ptr
    sta screen_ptr
    bcc :+
    inc screen_ptr + 1
:
}

.public render_string {
    stx load + 1
    sty load + 2
    ldx #0
    ldy #0
load:
    lda $1000,x
    beq end
    render_char
    inx
    bne load
end:
    rts
}

.public render_char {
    render_char
    rts
}

.section reserved

render_tmp .reserve 1

char_address_low .reserve $100 .align $100
char_address_high .reserve $100 .align $100

.section zero_page

.public screen_ptr .reserve 2
