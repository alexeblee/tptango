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

PlayerXPos		    byte	         ; Player X position
PlayerYPos		    byte	         ; Player Y position
TPXPos			    byte	     
TPYPos			    byte	    
ShoppingCartXPos	byte
ShoppingCartYPos	byte

Random                  byte         ; Random X starting position of shopping cart 1

renderOffset            byte

PlayerLeftSpritePtr	word	         ; Pointer to PlayerLeftSprite lookup table 
PlayerLeftColorPtr	word	         ; Pointer to PlayerLeftColor lookup table 
PlayerRightSpritePtr	word	     ; Pointer to PlayerRightSprite lookup table 
PlayerRightColorPtr	word	         ; Pointer to PlayerRightColor lookup table 
TPSpritePtr		word	 
TPColorPtr		word	
ShoppingCartSpritePtr	word	 
ShoppingCartColorPtr	word
PF0Ptr			word		         ; pointer to the PF0 lookup table
PF1Ptr			word	             ; pointer to the PF0 lookup table
PF2Ptr			word	             ; pointer to the PF0 lookup table
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Define Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PLAYER_HEIGHT = 9
PLAYER_RIGHT_OFFSET = 9
PLAYER_LEFT_OFFSET = 27
PLAYER_UP_DOWN_OFFSET = 36
TP_HEIGHT = 3
CART_HEIGHT = 9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code at memory address $F000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg 
    org $F000

Reset:
    CLEAN_START                      ; call macro to reset memory and registers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize Variables in RAM and TIA Registers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #0
    sta PlayerXPos                   ; start the player on the lefthand side of the screen
    lda #50
    sta PlayerYPos                   ; start the player somewhere in the middle of the screen

    lda #120
    sta TPXPos
    lda #65
    sta TPYPos

    lda #50
    sta ShoppingCartXPos
    lda #10
    sta ShoppingCartYPos
    lda #%11010100
    sta Random                       ; Random = $D4
 
    lda #$AE
    sta COLUBK                       ; set background color to blue
    
    lda #$0F
    sta COLUPF                       ; set the playfield color with white

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
    sta PlayerRightSpritePtr         ; low byte ptr for player left sprite lookup table
    lda #>PlayerRightSprite
    sta PlayerRightSpritePtr+1	     ; high byte ptr for player left sprite lookup table
    
    lda #<PlayerRightColor
    sta PlayerRightColorPtr
    lda #>PlayerRightColor
    sta PlayerRightColorPtr+1

    lda #<ShoppingCartSprite
    sta ShoppingCartSpritePtr        ; low byte ptr for shopping cart sprite lookup table
    lda #>ShoppingCartSprite
    sta ShoppingCartSpritePtr+1	     ; high byte ptr for shopping cart sprite lookup table
    
    lda #<ShoppingCartColor
    sta ShoppingCartColorPtr
    lda #>ShoppingCartColor
    sta ShoppingCartColorPtr+1
    
    lda #<TPSprite
    sta TPSpritePtr                  ; low byte ptr for TP sprite lookup table
    lda #>TPSprite
    sta TPSpritePtr+1	             ; high byte ptr for TP sprite lookup table
    
    lda #<TPColor
    sta TPColorPtr
    lda #>TPColor
    sta TPColorPtr+1

	lda #<BackgroundPF0
	sta PF0Ptr
	lda #>BackgroundPF0
	sta PF0Ptr+1

	lda #<BackgroundPF1
	sta PF1Ptr
	lda #>BackgroundPF1
	sta PF1Ptr+1

	lda #<BackgroundPF2
	sta PF2Ptr
	lda #>BackgroundPF2
	sta PF2Ptr+1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start the main display loop and frame rendering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display VSYNC and VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK                       ; turn on VBLANK
    sta VSYNC                        ; turn on VSYNC
    REPEAT 3
        sta WSYNC                    ; display 3 recommended lines of VSYNC
    REPEND
    lda #0
    sta VSYNC                        ; turn off VSYNC

    REPEAT 33
        sta WSYNC                    ; display the (37-calculations)  recommended lines of VBLANK
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations and tasks performed during the VBLANK section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda PlayerXPos
    ldy #0                           ; 0: player 0
    jsr SetObjectXPos                ; set player horizontal position

    lda TPXPos
    ldy #4                           ; 4: ball RESBL
    jsr SetObjectXPos                ; set TP horizontal position

    lda ShoppingCartXPos
    ldy #1                           ; 1: player 1
    jsr SetObjectXPos                ; set cart horizontal position

    sta WSYNC
    sta HMOVE                        ; apply the horizontal offsets previously set

    ldx #%00000001 ; CTRLPF register (D0 is the reflect flag) 
    stx CTRLPF

    sta WSYNC                        ; WSYNC to start fresh after HMOVE
    lda #0
    sta VBLANK                       ; turn off VBLANK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display the 96 visible scanlines of our main game because of 2-line kernel
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ldx #96		; X counts the number of remaining scanlines

.GameLineLoop:

.DrawBackground
	txa
	tay
	lda (PF0Ptr),Y
	sta PF0
	lda (PF1Ptr),Y
	sta PF1
	lda (PF2Ptr),Y
	sta PF2

.CheckInsidePlayer
    txa 		             ; x has the current line x coordinate. Transfer to A register
    sec                              ; make sure carry flag is set before subtraction
    sbc PlayerYPos                   ; subtract sprite Y-coordinate 
    cmp #PLAYER_HEIGHT               ; are we inside the sprite height bounds?
    bcc .DrawSpriteP0                ; if result < SpriteHeight, call the draw routine
    lda #0                           ; else, set lookup index to zero

.DrawSpriteP0:
    clc                              ; clear carry flag before addition
    adc renderOffset                 ; jump to correct sprite frame address in memory
    tay                              ; load Y so we can work with the pointer
    lda (PlayerRightSpritePtr),Y     ; load player0 bitmap data from lookup table
    sta WSYNC                        ; wait for scanline
    sta GRP0                         ; set graphics for player0
    lda (PlayerRightColorPtr),Y      ; load player color from lookup table
    sta COLUP0                       ; set color of player 0    

.CheckInsideTP
    txa 		             ; x has the current line y coordinate. Transfer to A register
    sec                              ; make sure carry flag is set before subtraction
    sbc TPYPos                       ; subtract sprite Y-coordinate 
    cmp #TP_HEIGHT                   ; are we inside the TP sprite height bounds?
    bcs .DontDrawTP                  ; if result > TPHeight, skip the draw routine

.DrawTP:
    lda #%00000010
    sta ENABL                        ; set graphics for TP
    jmp .CheckInsideShoppingCart     ; skip to the next graphic
.DontDrawTP
    lda #%00000000
    sta ENABL                        ; unset graphics for TP

.CheckInsideShoppingCart
    txa 		             ; x has the current line x coordinate. Transfer to A register
    sec                              ; make sure carry flag is set before subtraction
    sbc ShoppingCartYPos             ; subtract sprite Y-coordinate 
    cmp #CART_HEIGHT                 ; are we inside the cart sprite height bounds?
    bcc .DrawShoppingCart            ; if result < CartHeight, call the draw routine
    lda #0                           ; else, set lookup index to zero
    
.DrawShoppingCart:
    tay                              ; load Y so we can work with the pointer
    lda (ShoppingCartSpritePtr),Y    ; load cart bitmap data from lookup table
    sta WSYNC                        ; wait for scanline
    sta GRP1                         ; set graphics for cart
    lda (ShoppingCartColorPtr),Y     ; load cart color from lookup table
    sta COLUP1                       ; set color of cart
    
    dex
    bne .GameLineLoop

    lda #0
    sta renderOffset                 ; reset animation frame to zero each frame	
     
    sta WSYNC                        ; wait for a scanline before drawing vblank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display Overscan
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2
    sta VBLANK                       ; turn on VBLANK again
    REPEAT 30
        sta WSYNC                    ; display 30 recommended lines of VBlank Overscan
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Process joystick input for player0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckP0Up:
    lda #%00010000                   ; player0 joystick up
    bit SWCHA
    bne CheckP0Down                  ; if bit pattern doesnt match, bypass Up block
    inc PlayerYPos
    lda PLAYER_UP_DOWN_OFFSET        ; 36
    sta renderOffset                 ; 

CheckP0Down:
    lda #%00100000                   ; player0 joystick down
    bit SWCHA
    bne CheckP0Left                  ; if bit pattern doesnt match, bypass Down block
    dec PlayerYPos
    lda PLAYER_UP_DOWN_OFFSET        ; 36
    sta renderOffset                 ;

CheckP0Left:
    lda #%01000000		             ; player0 joystick left
    bit SWCHA
    bne CheckP0Right 		         ; if bit pattern doesnt match, bypass Left block
    dec PlayerXPos
    lda PLAYER_LEFT_OFFSET   		 ; 27
    sta renderOffset        		 ; set animation offset to the second frame

CheckP0Right:
    lda #%10000000           		 ; player0 joystick right
    bit SWCHA
    bne EndInputCheck   		     ; if bit pattern doesnt match, bypass Right block
    inc PlayerXPos
    lda PLAYER_RIGHT_OFFSET  		 ; 9
    sta renderOffset         		 ; 

EndInputCheck:              		 ; fallback when no input was performed

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculations to update position for next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
UpdatePlayerYPosition:
    lda PlayerYPos
    clc
    cmp #0                       	 ; compare player y-position with 0 (top of border)
    bmi .ResetPlayerLowPosition  	 ; if it is < 0, then reset y-position to 0
    lda PlayerYPos
    clc
    cmp #69
    bcs .ResetPlayerHighPosition 	 ; if it is at the top of the screen, reset
    jmp EndPositionYUpdate
.ResetPlayerLowPosition
    lda #0
    sta PlayerYPos
    jmp EndPositionYUpdate
.ResetPlayerHighPosition
    lda #69
    sta PlayerYPos

EndPositionYUpdate:           		 ; fallback for the position update code
    
UpdatePlayerXPosition:
    lda PlayerXPos
    clc
    cmp #0
    bmi .ResetPlayerLeftPosition 	 ; if it is on the left side of the screen, reset
    lda PlayerXPos
    clc
    cmp #120
    bcs .ResetPlayerRightPosition 	 ; if it is on the right side of the screen, reset
    jmp EndPositionXUpdate
.ResetPlayerLeftPosition
    lda #0
    sta PlayerXPos
    jmp EndPositionXUpdate
.ResetPlayerRightPosition
    lda #120
    sta PlayerXPos

EndPositionXUpdate:          		 ; fallback for the position X update code

UpdateCartYPosition:
    lda ShoppingCartYPos
    clc
    cmp #1                           ; compare cart y-position with 1 (bottom border)
    bmi .ResetCartRandomPosition     ; if it is < 1, then reset y-position to 69
    dec ShoppingCartYPos
    jmp EndShoppingCartPositionUpdate 
.ResetCartRandomPosition             ; if it is at the bottom of the screen, reset
    jsr GetRandomShoppingCartPos

EndShoppingCartPositionUpdate:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check for object collision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CheckCollisionP0BL:          ; Check collision between player and TP
    lda #%01000000           ; CXPPMM bit 6 detects P0 and BL collision
    bit CXP0FB               ; check CXPPMM bit 6 with the above pattern
    bne .CollisionP0BL       ; if collision between P0 and BL happened, branch
    jmp CheckCollisionP0P1   ; else, skip to next check
.CollisionP0BL:
    jsr GameOver             ; call GameOver subroutine

CheckCollisionP0P1:          ; Check collision between player and shopping cart
    lda #%10000000           ; CXPPMM bit 7 detects P0 and P1 collision
    bit CXPPMM               ; check CXPPMM bit 7 with the above pattern
    bne .CollisionP0P1       ; if collision P0 and P1 happened, branch
    jmp EndCollisionCheck    ; else, skip to next check
.CollisionP0P1:
    jsr GameOver             ; call GameOver subroutine

EndCollisionCheck:           ; fallback
    sta CXCLR                ; clear all collision flags before the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop back to start a brand new frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame           ; continue to display the next frame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to handle object horizontal position with fine offset
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; A is the target x-coordinate position in pixels of our object
;; Y is the object type (0:player0, 1:player1, 2:missile0, 3:missile1, 4:ball)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SetObjectXPos subroutine
    sta WSYNC                ; start a fresh new scanline
    sec                      ; make sure carry-flag is set before subtracion
.Div15Loop
    sbc #15                  ; subtract 15 from accumulator
    bcs .Div15Loop           ; loop until carry-flag is clear
    eor #7                   ; handle offset range from -8 to 7
    asl
    asl
    asl
    asl                      ; four shift lefts to get only the top 4 bits
    sta HMP0,Y               ; store the fine offset to the correct HMxx
    sta RESP0,Y              ; fix object position in 15-step increment
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Game Over subroutine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GameOver subroutine
    lda #$30
    sta COLUBK
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutine to generate a Linear-Feedback Shift Register random number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate a LFSR random number for the X-position of the shopping cart.
;; Divide the random value by 4 to limit the size of the result to match river.
;; Add 20 to compensate for the left of the playfield
;; The routine also sets the Y-position of the cart to the top of the screen.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GetRandomShoppingCartPos subroutine
    lda Random
    asl 
    eor Random
    asl 
    eor Random
    asl 
    asl 
    eor Random
    asl 
    rol Random               ; performs a series of shifts and bit operations

    lsr 
    lsr                      ; divide the value by 4 with 2 right shifts
    sta ShoppingCartXPos     ; save it to the variable ShoppingCartXPos
    lda #20 
    adc ShoppingCartXPos     ; adds 20 + ShoppingCartXPos to compensate for left side of screen.
                             ; We don't want to start it on top of the player immediately.
    sta ShoppingCartXPos     ; and sets the new value to the bomber x-position

    lda #69 
    sta ShoppingCartYPos     ; set the y-position to the top of the screen

    rts 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Declare Sprite Lookups
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PlayerRightSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00110000;$FE
        .byte #%00110000;$48
        .byte #%00110000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerRightWalkSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00101000;$FE
        .byte #%00110000;$48
        .byte #%00110000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerLeftSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00110000;$FE
        .byte #%00011000;$48
        .byte #%00011000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerLeftWalkSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00101000;$FE
        .byte #%00011000;$48
        .byte #%00011000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;--

PlayerUpDownWalkSprite:
        .byte #%00000000;$0E
        .byte #%00000000;$FE
        .byte #%00101000;$FE
        .byte #%00111000;$48
        .byte #%00111000;$48
        .byte #%00111000;$FE
        .byte #%00111000;$FE
        .byte #%00111000;$F2
        .byte #%00000000;$0E

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

PlayerLeftWalkColor
        .byte #$00;
	.byte #$FE;
        .byte #$FE;
        .byte #$48;
        .byte #$48;
        .byte #$FE;
        .byte #$FE;
        .byte #$F2;
        .byte #$0E;

PlayerUpDownWalkColor:
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

BackgroundPF0:
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$10;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$F0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;

BackgroundPF1:
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$20;
        .byte #$20;
        .byte #$20;
        .byte #$20;
        .byte #$20;
        .byte #$20;
        .byte #$22;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$2;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;

BackgroundPF2:
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$4;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$FF;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;
        .byte #$0;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size with exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC                ; move to position $FFFC
    word Reset               ; write 2 bytes with the program reset address
    word Reset               ; write 2 bytes with the interruption vector
