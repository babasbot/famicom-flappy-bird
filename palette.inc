; vim: set syntax=asm_ca65:

;
;    Palette
;
;    x0      x1      x2      x3      x4      x5      x6      x7      x8      x9      xA      xB      xC      xD
;    ------- ------- ------- ------- ------- ------- ------- ------- ------- ------- ------- ------- ------- -------
; 0x #545454 #03216F #031A8A #2A1182 #3D0E60 #540D2F #4D0D05 #381A05 #222906 #19380A #183D0C #163A0B #10313B #000000
; 1x #989698 #1B4FBD #2B3DE3 #5231DB #7C2AAA #932762 #8C2C26 #713F13 #555918 #3E6F1D #377920 #327332 #296576 #000000
; 2x #ECEEEC #5E9AE5 #777FE5 #A56BE4 #D363E5 #DB64B0 #DD7169 #CA8A3A #A2A835 #87C03A #73CB45 #68C876 #5DB2C9 #3C3C3C
; 3x #ECEEEC #AECBE9 #BCBDE8 #CEB4E8 #E2B2E8 #E2B1D2 #E4B6B2 #DFC496 #CDD083 #BDDB84 #B4DF98 #A8DFB7 #ABD5E2 #A0A2A0
;
; For further details see: https://www.nesdev.org/wiki/PPU_palettes

GRAY_0 = $00       ; #545454
GRAY_1 = $10       ; #989698
GRAY_2 = $20       ; #ECEEEC
GRAY_3 = $30       ; #ECEEEC

AZURE_0 = $01      ; #03216F
AZURE_1 = $11      ; #1B4FBD
AZURE_2 = $21      ; #5E9AE5
AZURE_3 = $31      ; #AECBE9

BLUE_0 = $02       ; #031A8A
BLUE_1 = $12       ; #2B3DE3
BLUE_2 = $22       ; #777FE5
BLUE_3 = $32       ; #BCBDE8

VIOLET_0 = $03     ; #2A1182
VIOLET_1 = $13     ; #5231DB
VIOLET_2 = $23     ; #A56BE4
VIOLET_3 = $33     ; #CEB4E8

MAGENTA_0 = $04    ; #3D0E60
MAGENTA_1 = $14    ; #7C2AAA
MAGENTA_2 = $24    ; #D363E5
MAGENTA_3 = $34    ; #E2B2E8

ROSE_0 = $05       ; #540D2F
ROSE_1 = $15       ; #932762
ROSE_2 = $25       ; #DB64B0
ROSE_3 = $35       ; #E2B1D2

RED_0 = $06        ; #4D0D05
RED_1 = $16        ; #8C2C26
RED_2 = $26        ; #DD7169
RED_3 = $36        ; #E4B6B2

ORANGE_0 = $07     ; #381A05
ORANGE_1 = $17     ; #713F13
ORANGE_2 = $27     ; #CA8A3A
ORANGE_3 = $37     ; #DFC496

YELLOW_0 = $08     ; #222906
YELLOW_1 = $18     ; #555918
YELLOW_2 = $28     ; #A2A835
YELLOW_3 = $38     ; #CDD083

CHARTREUSE_0 = $09 ; #19380A
CHARTREUSE_1 = $19 ; #3E6F1D
CHARTREUSE_2 = $29 ; #87C03A
CHARTREUSE_3 = $39 ; #BDDB84

GREEN_0 = $0A      ; #183D0C
GREEN_1 = $1A      ; #377920
GREEN_2 = $2A      ; #73CB45
GREEN_3 = $3A      ; #B4DF98

SPRING_0 = $0B     ; #163A0B
SPRING_1 = $1B     ; #327332
SPRING_2 = $2B     ; #68C876
SPRING_3 = $3B     ; #A8DFB7

CYAN_0 = $0C       ; #10313B
CYAN_1 = $1C       ; #296576
CYAN_2 = $2C       ; #5DB2C9
CYAN_3 = $3C       ; #ABD5E2

BLACK_4 = $0d      ; #000000
BLACK_5 = $1d      ; #000000
BLACK_6 = $2d      ; #3C3C3C
BLACK_7 = $3d      ; #A0A2A0

