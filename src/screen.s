.section data

.public main_screen {
    ;      1234567890123456789012345678901234567890
    .repeat 3 {
        .data "                                        ":screen_inverted
        .data "  ":screen_inverted, "[              ]":screen, "    ":screen_inverted, "[              ]":screen, "  ":screen_inverted
        .data "  ":screen_inverted, "                ":screen, "    ":screen_inverted, "                ":screen, "  ":screen_inverted
        .data "  ":screen_inverted, "                ":screen, "    ":screen_inverted, "                ":screen, "  ":screen_inverted
        .data "  ":screen_inverted, "<££££££££££££££>":screen, "    ":screen_inverted, "<££££££££££££££>":screen, "  ":screen_inverted
        .data "                                        ":screen_inverted
    }
    .repeat 6 {
        .data "                                        ":screen_inverted
    }
    .data "                                   t'pau":screen_inverted
}

.public main_color {
    .repeat 3 {
        .data .fill(40, NAME_COLOR)
        .data .fill(40, FRAME_COLOR)
        .data .fill(80, CLOCK_COLOR)
        .data .fill(80, FRAME_COLOR)
    }
    .data .fill(7*40 -5, NAME_COLOR), .fill(5, TPAU_COLOR)
}
