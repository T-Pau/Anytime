; screens.s -- screen layouts
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
.pin charset $2000
color_ram = $d800

source_ptr = ptr
destination_ptr = screen_ptr

.section code

; Set up VIC.
setup_display {
    lda #VIC_VIDEO_ADDRESS(screen, charset)
    sta VIC_VIDEO_ADDRESS
    .if .defined(C128) {
        sta $0a2c
    }

    lda #FRAME_COLOR
    sta VIC_BORDER_COLOR
    sta VIC_BACKGROUND_COLOR_2
    lda #BACKGROUND_COLOR
    sta VIC_BACKGROUND_COLOR
    lda VIC_CONTROL_1
    ora #VIC_EXTENDED_BACKGROUND_COLOR
    sta VIC_CONTROL_1
    rts
}

; Display detecting clocks screen.
display_detect {
    display_screen detect_screen, detect_color
    rts
}

; Display main screen.
display_main {
    display_screen main_screen, main_color
    rts
}

; Display help scren.
display_help {
    display_screen help_screen, help_color
    rts
}

; Display screen runlength encoded screen and color data.
.macro display_screen screen_rl, color_rl {
    store_word source_ptr, screen_rl
    store_word destination_ptr, screen
    jsr rl_expand
    store_word source_ptr, color_rl
    store_word destination_ptr, color_ram
    jsr rl_expand
}


.section zero_page

screen_ptr .reserve 2

.section data

.public main_color {
    .repeat 3 {
        rl_encode 40, NAME_COLOR
        rl_encode 40, FRAME_COLOR
        rl_encode 80, CLOCK_COLOR
        rl_encode 80, FRAME_COLOR
    }
    rl_encode 7*40 - 5, NAME_COLOR
    rl_encode 5, TPAU_COLOR
    rl_end
}

.public help_color {
    rl_encode 40, NAME_COLOR
    rl_encode 40, FRAME_COLOR
    rl_encode 18 * 40, CLOCK_COLOR
    rl_encode 40, FRAME_COLOR
    rl_encode 4 * 40 - 5, NAME_COLOR
    rl_encode 5, TPAU_COLOR
    rl_end
}

.public detect_color {
    rl_encode 25 * 40 - 5, PARAMETER_COLOR
    rl_encode 5, TPAU_COLOR
    rl_end
}
