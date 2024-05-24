; start.s -- main routine
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

screen = $0400
color_ram = $d800

.section code

.public start {
    jsr startup_display
    jsr clocks_init
    jsr setup_display
    jsr clocks_init_display

loop:
    jsr clocks_update
    jmp loop
}

startup_display {
    lda #VIC_VIDEO_ADDRESS($400, $2000)
    sta VIC_VIDEO_ADDRESS
    lda #FRAME_COLOR
    sta VIC_BORDER_COLOR
    sta VIC_BACKGROUND_COLOR
    ldx #0
    lda #$20
:   sta screen,x
    sta screen + $100,x
    sta screen + $200,x
    sta screen + $2e8,x
    dex
    bne :-
    lda #PARAMETER_COLOR
:   sta color_ram,x
    sta color_ram + $100,x
    sta color_ram + $200,x
    sta color_ram + $2e8,x
    dex
    bne :-
:   lda startup_message,x
    beq done
    sta screen + 10 * 40 + 12,x
    inx
    bne :-
done:
    ldx #5
:   lda main_screen + 1000 - 5,x
    and #$7f
    sta screen + 1000 - 5,x
    dex
    bpl :-
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

.section data

startup_message {
    .data "detecting clocks":screen, 0
}

.section zero_page

screen_ptr .reserve 2
