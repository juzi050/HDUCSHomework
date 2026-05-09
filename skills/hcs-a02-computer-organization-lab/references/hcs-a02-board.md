# HCS-A02 Board Reference

Use this reference when writing top-level ports, XDC constraints, simulations that mirror board behavior, or lab reports for HCS-A02 computer organization experiments.

## Input Devices

Switches:

- The board has 36 switches named `SW35` through `SW0`.
- Upper row, left to right: `SW31` through `SW16`.
- Lower-left row, left to right: `SW15` through `SW0`.
- Lower-right four switches, left to right: `SW35` through `SW32`.
- Switch up inputs `1`; switch down inputs `0`.

| Switch | FPGA pin | Switch | FPGA pin | Switch | FPGA pin |
| --- | --- | --- | --- | --- | --- |
| SW31 | T8 | SW19 | V16 | SW7 | U11 |
| SW30 | U1 | SW18 | V17 | SW6 | U12 |
| SW29 | U2 | SW17 | R18 | SW5 | U13 |
| SW28 | U3 | SW16 | P18 | SW4 | V14 |
| SW27 | V5 | SW15 | R8 | SW3 | U16 |
| SW26 | V6 | SW14 | T9 | SW2 | U17 |
| SW25 | V7 | SW13 | V1 | SW1 | T18 |
| SW24 | V9 | SW12 | V2 | SW0 | P17 |
| SW23 | V11 | SW11 | V4 | SW35 | T10 |
| SW22 | V12 | SW10 | U6 | SW34 | R10 |
| SW21 | U14 | SW9 | U7 | SW33 | T11 |
| SW20 | V15 | SW8 | U9 | SW32 | R11 |

Buttons:

- The board has 8 buttons named `BT7` through `BT0`.
- Upper row, left to right: `BT7` through `BT4`.
- Lower row, left to right: `BT3` through `BT0`.
- Pressed inputs `1`; released inputs `0`.
- Hardware debounce is already present.

| Button | FPGA pin | Button | FPGA pin |
| --- | --- | --- | --- |
| BT7 | N5 | BT3 | H16 |
| BT6 | P5 | BT2 | C11 |
| BT5 | G16 | BT1 | C10 |
| BT4 | C15 | BT0 | D15 |

Clock:

| Source | FPGA pin |
| --- | --- |
| 100 MHz | E3 |

## Output Devices

LEDs:

- The board has 36 LEDs named `LD35` through `LD0`.
- Output `1` turns the LED on; output `0` turns it off.

| LED | FPGA pin | LED | FPGA pin | LED | FPGA pin |
| --- | --- | --- | --- | --- | --- |
| LD31 | L3 | LD19 | R6 | LD7 | N15 |
| LD30 | L4 | LD18 | T6 | LD6 | N16 |
| LD29 | M3 | LD17 | R7 | LD5 | M16 |
| LD28 | M4 | LD16 | V10 | LD4 | R16 |
| LD27 | N4 | LD15 | U18 | LD3 | T16 |
| LD26 | P3 | LD14 | R17 | LD2 | R15 |
| LD25 | P4 | LD13 | M18 | LD1 | T15 |
| LD24 | R3 | LD12 | M17 | LD0 | T14 |
| LD23 | T3 | LD11 | N17 | LD35 | R13 |
| LD22 | T4 | LD10 | L18 | LD34 | T13 |
| LD21 | R5 | LD9 | K16 | LD33 | R12 |
| LD20 | T5 | LD8 | P15 | LD32 | P14 |

Traffic lights:

- Left group is west-east (`W<->E`): red `R1`, yellow `Y1`, green `G1`.
- Right group is south-north (`S<->N`): red `R2`, yellow `Y2`, green `G2`.
- Output `1` turns the light on; output `0` turns it off.

| Direction | Light | FPGA pin | Suggested port |
| --- | --- | --- | --- |
| West-east | R1 red | G2 | `traffic_we_r` |
| West-east | Y1 yellow | H1 | `traffic_we_y` |
| West-east | G1 green | H2 | `traffic_we_g` |
| South-north | R2 red | B7 | `traffic_sn_r` |
| South-north | Y2 yellow | B8 | `traffic_sn_y` |
| South-north | G2 green | A8 | `traffic_sn_g` |

Seven-segment display:

- The board has 8 common-anode seven-segment digits named `TB7` through `TB0`.
- `TB7` is the leftmost digit; `TB0` is the rightmost digit.
- Template convention: active-low digit select `an[7:0]`, active-low segment select `seg[6:0]`, active-low decimal point `dp`.
- Segment mapping: `seg[0] = CA`, `seg[1] = CB`, `seg[2] = CC`, `seg[3] = CD`, `seg[4] = CE`, `seg[5] = CF`, `seg[6] = CG`.

| Digit select | FPGA pin | Segment | FPGA pin |
| --- | --- | --- | --- |
| AN7 / TB7 | G1 | CA | E2 |
| AN6 / TB6 | B2 | CB | A3 |
| AN5 / TB5 | A1 | CC | B1 |
| AN4 / TB4 | B4 | CD | E1 |
| AN3 / TB3 | A4 | CE | F1 |
| AN2 / TB2 | A5 | CF | D2 |
| AN1 / TB1 | B6 | CG | B3 |
| AN0 / TB0 | A6 | DP | C1 |
