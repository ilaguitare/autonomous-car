; Nom
; Description
; Mesfioui-Raja Hind, Kazem Ithar

; -----------------------------------------------------------------
; Declaration des symboles
LED_R		bit	P0.0
LED_V		bit	P0.1

TH1_CHRG	equ	0E6h

; -----------------------------------------------------------------
; Implementation en mémoire programme
			org	0000h
			LJMP	debut
			org	0023h
			LJMP	IT_Serie			
			org	0030h

; -----------------------------------------------------------------
; Programme principal
debut:								; debut
			MOV	SP,#2Fh        ; | Init Pile
			LCALL	Init				; | Init()

fin:									; finD

; -----------------------------------------------------------------
; Interruption Serie
; Parametres passes:
; Parametres retournes:
IT_Serie:							; debut
			PUSH	PSW				; |
			PUSH	ACC				; |
			CLR	RI					; | Remise a zero du drapeau de RX
			MOV	A,SBUF			; | (check) <= Parite donnee XOR Parite recu
			MOV	C,P				; |
			ANL	C,/RB8			; |
			MOV	F0,C				; |
			MOV	C,RB8				; |
			ANL	C,/P				; |
			ORL	C,F0				; |
			
			POP	ACC				; |
			POP	PSW				; |
			RETI						; fin

; -----------------------------------------------------------------
; Initialisation
; Parametres passes:
; Parametres retournes:
Init:									; debut
         MOV	SCON,#11010000b; | Mode 3 Serie avec RX
			MOV	TMOD,#00100000b; | Timer 1 Mode 2
			MOV	PCON,#00h		; | Pas de dedoublement SMOD=0
			MOV	TH1,#TH1_CHRG	; | Chargement de la valeur du Timer 1 
			MOV	TL1,#TH1_CHRG	; |
			MOV	TCON,#01000000b; | Demarrage Timer 1
			MOV	IE,#10010000b	; | Validation It serie + generale
			RET						; fin			
			
; -----------------------------------------------------------------
; Fin d assemblage
			end
