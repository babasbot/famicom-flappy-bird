; vim: set syntax=asm_ca65:

.include "palette.inc"
.include "addresses.inc"

; For more details on the iNES header format, see:
; - https://www.nesdev.org/wiki/NES_2.0
; - https://www.nesdev.org/wiki/INES

.segment "HEADER"
  .byte 'N', 'E', 'S', $1A             ; iNES magic number
  .byte $02                            ; 16 KB PRG-ROM
  .byte $01        	                   ; 08 KB CHR-ROM
  .byte $0                             ; Horizontal mirroring
  .byte $0                             ; NROM
  .byte $0, $0, $0, $0, $0, $0, $0, $0 ; Unused padding

.segment "CODE"

.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAM_ADDR
  LDA #$02
  STA OAM_DMA

gravity:
  LDY $0200
  CPY #$d8
  BCS end_nmi

  TYA
  ADC #3
  STA $0200
  STA $0204
  STA $0208

  LDA $020c
  ADC #3
  STA $020c
  STA $0210
  STA $0214

end_nmi:
  RTI
.endproc

.proc reset_handler
  SEI
  CLD
  LDX #$00
  STX PPU_CTRL
  STX PPU_MASK
.endproc

.proc draw_flappybird
  LDX #$00
  draw_sprites:
    LDA flappybird_sprites,X
    STA $0200,X
    INX
    CPX #$18
    BNE draw_sprites
.endproc

.proc main
preload_bg_palette:
  LDX PPU_STAT
  LDX #$3f ; BG_PALETTE_0 high nibble
  STX PPU_ADDR
  LDX #$00 ; BG_PALETTE_0 low nibble
  STX PPU_ADDR

load_bg_palette:
  LDA bg_palettes,X
  STA PPU_DATA
  INX
  CPX #$0f
  BNE load_bg_palette

preload_fg_palette:
  LDX PPU_STAT
  LDX #$3f ; FG_PALETTE_0 high nibble
  STX PPU_ADDR
  LDX #$10 ; FG_PALETTE_0 low nibble
  STX PPU_ADDR
  LDX #$00

load_fg_palette:
  LDA fg_palettes,X
  STA PPU_DATA
  INX
  CPX #$08
  BNE load_fg_palette

vblankwait:
  BIT PPU_STAT
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPU_CTRL
  LDA #%00011110  ; turn on screen
  STA PPU_MASK

forever:
  JMP forever
.endproc

.segment "VECTORS"
.word nmi_handler
.word reset_handler
.word irq_handler

.segment "RODATA"
bg_palettes:
.byte AZURE_3, BLACK_4, GRAY_3,   YELLOW_3 ; bg palette 0
.byte AZURE_3, BLACK_4, YELLOW_3, RED_1    ; bg palette 1
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; bg palette 2
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; bg palette 3

fg_palettes:
.byte AZURE_3, BLACK_4, GRAY_3,   YELLOW_3 ; fg palette 0
.byte AZURE_3, BLACK_4, YELLOW_3, RED_1    ; fg palette 1
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; fg palette 2
.byte AZURE_3, AZURE_3, AZURE_3,  AZURE_3  ; fg palette 3

flappybird_sprites:
.byte $70, $00, $00, $70
.byte $70, $01, $00, $78
.byte $70, $02, $00, $80
.byte $78, $10, $00, $70
.byte $78, $11, $00, $78
.byte $78, $12, $01, $80
;       │    │    │    └── x-coord
;       │    │    └─────── sprite attributes
;       │    └──────────── tile number
;       └───────────────── y-coord

.segment "CHR"
.incbin "graphics.chr"

