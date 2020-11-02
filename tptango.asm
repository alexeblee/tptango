    processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with VCS register memory mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare variables starting from address $80
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

PlayerXPos		byte	     ; Player X position
PlayerYPos		byte	     ; Player Y position
TPXPos			byte	     
TPYPos			byte	    
ShoppingCartXPos	byte
ShoppingCartYPos	byte

PlayerLeftSpritePtr	word	     ; Pointer to PlayerLeftSprite lookup table 
PlayerLeftColorPtr	word	     ; Pointer to PlayerLeftColor lookup table 
PlayerRightSpritePtr	word	     ; Pointer to PlayerRightSprite lookup table 
PlayerRightColorPtr	word	     ; Pointer to PlayerRightColor lookup table 
TPSpritePtr		word	 
TPColorPtr		word	
ShoppingCartSpritePtr	word	 
ShoppingCartColorPtr	word
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PLAYER_HEIGHT = 9
TP_HEIGHT = 9
SHOPPING_CART_HEIGHT = 9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code at memory address $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg 
    org $F000

Reset:
    CLEAN_START              ; call macro to reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize Variables in RAM and TIA Registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0
    sta PlayerXPos           	     ; start the player on the lefthand side of the screen
    lda #50
    sta PlayerYPos           	     ; start the player somewhere in the middle of the screen

    lda #100
    sta TPXPos
    lda #50
    sta TPYPos

    lda #50
    sta ShoppingCartXPos
    lda #10
    sta ShoppingCartYPos

    lda #$AE
    sta COLUBK               ; set background color to blue
    
    lda #$0F
    sta COLUPF               ; set the playfield color with white

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize Lookup Tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #<PlayerLeftSprite
    sta PlayerLeftSpritePtr          ; low byte ptr for player left sprite lookup table
    lda #>PlayerLeftSprite
    sta PlayerLeftSpritePtr+1	     ; high byte ptr for player left sprite lookup table
    
    lda #<PlayerLeftColor
    sta PlayerLeftColorPtr
    lda #>PlayerLeftColor
    sta PlayerLeftColorPtr+1

    lda #<PlayerRightSprite
    sta PlayerRightSpritePtr          ; low byte ptr for player left sprite lookup table
    lda #>PlayerRightSprite
    sta PlayerRightSpritePtr+1	     ; high byte ptr for player left sprite lookup table
    
    lda #<PlayerRightColor
    sta PlayerRightColorPtr
    lda #>PlayerRightColor
    sta PlayerRightColorPtr+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK               ; turn on VBLANK
    sta VSYNC                ; turn on VSYNC
    REPEAT 3
        sta WSYNC            ; display 3 recommended lines of VSYNC
    REPEND
    lda #0
    sta VSYNC                ; turn off VSYNC

    REPEAT 37
        sta WSYNC            ; display the 37 recommended lines of VBLANK
    REPEND
    sta VBLANK               ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 96 visible scanlines of our main game because of 2-line kernel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #%00000001 ; CTRLPF register (D0 is the reflect flag) 
    stx CTRLPF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 10 lines of border edge
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    lda #$FF
    sta PF0
    sta PF1
    sta PF2                  ; draw the top edge border of the playing field
	
    ldx #10
.BorderTopLoop:
    sta WSYNC

    dex
    bne .BorderTopLoop       ; border is 10 lines long

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the remaining 76 playing field lines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #76                  ; remaining 76 lines (96-border top (10)-border bottom(10))
.GameLineLoop:

    lda #$0
    sta PF0
    sta PF1
    sta PF2                  ; clear border. Now we just render the main background color
   
.CheckInsidePlayer
    txa 		     ; x has the current line x coordinate. Transfer to A register
    sec                      ; make sure carry flag is set before subtraction
    sbc PlayerYPos           ; subtract sprite Y-coordinate 
    cmp #PLAYER_HEIGHT       ; are we inside the sprite height bounds?
    bcc .DrawSpriteP0        ; if result < SpriteHeight, call the draw routine
    lda #0                   ; else, set lookup index to zero
.DrawSpriteP0:
    clc                      ; clear carry flag before addition
    tay                      ; load Y so we can work with the pointer
    lda (PlayerRightSpritePtr),Y     ; load player0 bitmap data from lookup table
    sta WSYNC                ; wait for scanline
    sta GRP0                 ; set graphics for player0
    lda (PlayerRightColorPtr),Y      ; load player color from lookup table
    sta COLUP0               ; set color of player 0    
    sta WSYNC

    dex
    bne .GameLineLoop
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 10 lines of border edge
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    lda #$FF
    sta PF0
    sta PF1
    sta PF2
    
    ldx #10
.BorderBottomLoop:
    sta WSYNC

    dex
    bne .BorderBottomLoop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display Overscan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK               ; turn on VBLANK again
    REPEAT 30
        sta WSYNC            ; display 30 recommended lines of VBlank Overscan
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame           ; continue to display the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare Sprite Lookups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PlayerRightSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00101000;$FE
        .byte #%00110000;$48
        .byte #%00110000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerRightWalkSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00110000;$FE
        .byte #%00110000;$48
        .byte #%00110000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerRightColor:
        .byte #$00;
        .byte #$FE;
        .byte #$FE;
        .byte #$48;
        .byte #$48;
        .byte #$FE;
        .byte #$FE;
        .byte #$F2;
        .byte #$0E;

PlayerRightWalkColor:
        .byte #$00;
        .byte #$FE;
        .byte #$FE;
        .byte #$48;
        .byte #$48;
        .byte #$FE;
        .byte #$FE;
        .byte #$F2;
        .byte #$0E;

PlayerLeftSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00101000;$FE
        .byte #%00011000;$48
        .byte #%00011000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerLeftWalkSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00110000;$FE
        .byte #%00011000;$48
        .byte #%00011000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerLeftColor:
        .byte #$00;
	.byte #$FE;
        .byte #$FE;
        .byte #$48;
        .byte #$48;
        .byte #$FE;
        .byte #$FE;
        .byte #$F2;
        .byte #$0E;

PlayerLeftTurnColor
        .byte #$00;
        .byte #$FE;
        .byte #$FE;
        .byte #$48;
        .byte #$48;
        .byte #$FE;
        .byte #$FE;
        .byte #$F2;
        .byte #$0E;

TPSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$0E
        .byte #%00000000;$0E
        .byte #%00011000;$0E
        .byte #%00011000;$0E
        .byte #%00011000;$0E
        .byte #%00000000;$0E
        .byte #%00000000;$0E
        .byte #%00000000;--

TPColor:
        .byte #$00;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;
        .byte #$0E;

ShoppingCartSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$04
        .byte #%00011000;$04
        .byte #%00100100;$04
        .byte #%00100100;$04
        .byte #%00100100;$04
        .byte #%00100100;$04
        .byte #%00111100;$42
        .byte #%00000000;--

ShoppingCartColor:
        .byte #$00;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$04;
        .byte #$42;
        .byte #$0E;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                ; move to position $FFFC
    word Reset               ; write 2 bytes with the program reset address
    word Reset               ; write 2 bytes with the interruption vector
