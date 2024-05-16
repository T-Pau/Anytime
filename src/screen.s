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
    .repeat 7 {
        .data "                                        ":screen_inverted
    }
}

.public main_color {
    .repeat 3 {
        .data .fill(40, $c)
        .data .fill(40, $c)
        .data $c, $c, .fill(16, $b), $c, $c, $c, $c, .fill(16, $b), $c, $c
        .data $c, $c, .fill(16, $b), $c, $c, $c, $c, .fill(16, $b), $c, $c
        .data .fill(40, $c)
        .data .fill(40, $c)
    }
    .data .fill(7*40, $c)
}