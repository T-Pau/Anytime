; display-clock.s -- routines to display clocks
;
; Copyright (C) Dieter Baron
;
; This file is part of Anytime, a program to manage real time clocks for C64.
; The authors can be contacted at <anytime@tpau.group>.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions
; are met:
; 1. Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
; 2. The names of the authors may not be used to endorse or promote
;    products derived from this software without specific prior
;    written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS
; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
; IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
; OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
; IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

PARAMETER_COLOR = COLOR_GREY_1
TPAU_COLOR = COLOR_GREY_1
FRAME_COLOR = COLOR_GREY_2
BACKGROUND_COLOR = COLOR_GREY_3
NAME_COLOR = COLOR_BLACK
CLOCK_COLOR = COLOR_GREY_1
CLOCK_COLOR_SYNTHETIC = COLOR_GREY_2

SCANNING_OFFSET = 13 * 40

.section code

; Set up clock display based on flags.
; Arguments:
;   X: clock index
; Returns: -
.public setup_clock_display {
    setup_clock_display_position -41
:   store_word ptr, clock_frame
    jsr rl_expand

    ldx clocks_current
    setup_clock_display_position 0, .true
    ldy #CLOCK_COLOR
    lda clocks_flags,x
    and #CLOCK_FLAG_WEEKDAY
    bne :+
    ldy #CLOCK_COLOR_SYNTHETIC
    tya
    ldy #0
:   sta (screen_ptr),y
    iny
    cpy #3
    bcc :-

    ldy #CLOCK_COLOR
    lda clocks_flags,x
    and #CLOCK_CENTURY
    bne :+
    ldy #CLOCK_COLOR_SYNTHETIC
    tya
    ldy #10
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny

    setup_clock_display_position -80
    lda screen_ptr
    sta ptr
    lda screen_ptr + 1
    eor #$dc ; >(screen ^ color_ram)
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
    lda clocks_parameter,x
    ldx #0
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
    lda clock_status
    beq :+
    jmp display_clock_invalid
:   ldy #0

    lda clock_weekday
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

    lda clock_day
    jsr display_bcd
    iny
    lda clock_month
    jsr display_bcd
    iny
    lda clock_century
    jsr display_bcd
    lda clock_year
    jsr display_bcd

    ldy #43
    lda clock_hour
    jsr display_bcd
    iny
    lda clock_minute
    jsr display_bcd
    iny
    lda clock_second
    jmp display_bcd
}

; Display invalid clock.
; Arguments:
;   X: clock index
; Returns: -
; Preserves: -
display_clock_invalid {
    lda #$2d ; '-':screen
    ldy clocks_flags,x
    ldy #0
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    iny

    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y

    ldy #43
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    iny
    iny
    sta (screen_ptr),y
    iny
    sta (screen_ptr),y
    rts
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


; Display scanning message for clock
; Arguments:
;   X/Y: pointer to name
;   A: parameter
display_scanning {
    ; save parameters
    stx ptr
    sty ptr + 1
    sta display_parameter

    store_word screen_ptr, display_line
    lda #$0
    jsr display_string
    lda display_parameter
    cmp #CLOCK_PARAMETER_NONE
    beq line_done
    lda #$20 ; ' ':screen
    sta (screen_ptr),y
    iny
    lda #$23 ; '#':screen
    sta (screen_ptr),y
    iny
    ldx #0
    lda display_parameter
    jsr display_number
line_done:
    lda #0
    sta (screen_ptr),y

    store_word ptr, display_line
    store_word screen_ptr, screen + SCANNING_OFFSET

    lda #$80
    jmp display_line_centered
}

; Display line at ptr centered.
; Parameters:
;   A: color
display_line_centered {
    sta display_color

    ; clear line
    ; TODO: only clear parts not used by string
    ldy #39
    ora #$20 ; ' ':screen
:   sta (screen_ptr),y
    dey
    bpl :-

    ; calculate length
    ldy #0
:   lda (ptr),y
    beq length_done
    iny
    bne :-
length_done:
    tya
    lsr
    sta display_tmp
    lda #20
    sec
    sbc display_tmp
    clc
    adc screen_ptr
    sta screen_ptr
    lda #0
    adc screen_ptr + 1
    sta screen_ptr + 1

    ; display name
    lda #$80
    jmp display_string
}

; Increase screen pointer by Y.
; Arguments:
;   Y: amount to increase
; Preserves: X
update_screen_ptr {
    tya
    clc
    adc screen_ptr
    sta screen_ptr
    bcc :+
    inc screen_ptr + 1
:   rts
}


; Display A as decimal number.
; Arguments:
;   A: number
;   X: color
; Returns:
;   Y: increased by length of number
display_number {
    stx display_color
    ldx #0
:   cmp #100
    bcc hundreds_done
    sec
    sbc #100
    inx
    bne :-
hundreds_done:
    stx display_zeroes
    cpx #0
    beq tens
    sta display_tmp
    txa
    ora #$30 ; '0':screen
    ora display_color
    sta (screen_ptr),y
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
    ora #$30 ; '0':screen
    ora display_color
    sta (screen_ptr),y
    iny
ones:
    lda display_tmp
    ora #$30 ; '0':screen
    ora display_color
    sta (screen_ptr),y
    iny
    rts
}

; Display string at ptr.
; Arguments:
;   A: color
; Returns: -
; Preserves: X
display_string {
    sta display_color
    ldy #0
:   lda (ptr),y
    beq done
    ora display_color
    sta (screen_ptr),y
    iny
    bne :-
done:
    rts
}

; X: clock index
; preserves X
.macro setup_clock_display_position offset = 0, for_color = .false {
    lda clocks_screen_position_low,x
    .if offset > 0 {
        clc
        adc #<offset
    }
    .else_if offset < 0 {
        sec
        sbc #<-offset
    }
    sta screen_ptr
    lda clocks_screen_position_high,x
    .if offset > 0 {
        adc #>offset
    }
    .else_if offset < 0 {
        sbc #>-offset
    }
    .if for_color {
        eor #$dc ; >(screen ^ color_ram)
    }
    sta screen_ptr + 1
}

.section data

CLOCK_FRAME_WIDTH = 16
CLOCK_FRAME_HEIGHT = 4

clock_frame {
    .data "[":screen
    rl_encode CLOCK_FRAME_WIDTH - 2, $20 ; ' ':screen
    .data "]":screen
    rl_skip 40 - CLOCK_FRAME_WIDTH
    rl_encode 7, $20 ; ' ':screen
    .data "/  /":screen
    rl_encode 5, $20 ; ' ':screen
    rl_skip 40 - CLOCK_FRAME_WIDTH
    rl_encode 6, $20 ; ' ':screen
    .data ":  :":screen
    rl_encode 6, $20 ; ' ':screen
    rl_skip 40 - CLOCK_FRAME_WIDTH
    .data "<":screen
    rl_encode CLOCK_FRAME_WIDTH - 2, $1c ; '£':screen
    .data ">":screen
    rl_end
}

weekdays {
    .data "sun":screen, 0
    .data "mon":screen, 0
    .data "tue":screen, 0
    .data "wed":screen, 0
    .data "thu":screen, 0
    .data "fri":screen, 0
    .data "sat":screen, 0
    .data "sun":screen, 0
    .data "---":screen, 0
}

.section reserved

display_tmp .reserve 1
display_zeroes .reserve 1
display_color .reserve 1
display_parameter .reserve 1

display_line .reserve 41
