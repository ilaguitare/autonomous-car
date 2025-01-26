; Nom
; Description
; Mesfoui-Raja Hind, Kazem Ithar

; -----------------------------------------------------------------
; Declaration des symboles

; -----------------------------------------------------------------
; Implementation en mémoire programme
			org	0000h
			LJMP	debut
			org	0030h

; -----------------------------------------------------------------
; Programme principal
debut:								; debut
			MOV	SP,#2Fh        ; | Init Pile

fin:									; fin

; -----------------------------------------------------------------
; Description
; Parametres passes:
; Parametres retournes:
RT:									; debut
					
			RET						; fin

; -----------------------------------------------------------------
; Fin d assemblage
			end
