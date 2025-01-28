; Nom
; Description
; Mesfioui-Raja Hind, Kazem Ithar

; -----------------------------------------------------------------
; Declaration des symboles
LED_R			bit	P1.0

Info_M_A    bit   P1.3
Car_M_A     bit   P1.4

Sirene      bit   P1.1
Laser       bit   P1.2

LCD_BC	   data	P2
LCD_RS	   bit	LCD_BC.7
LCD_RW	   bit	LCD_BC.6
LCD_E		   bit	LCD_BC.5
LCD_DB	   data	P0

BP_R        bit   P3.2
BP_V        bit   P3.3

BF			   bit	LCD_DB.7	

Compteur_G  data  7Fh
Compteur_C  data  7Eh
Compteur_D  data  7Dh
C_prec      data  7Ch
C_recu      data  7Bh

Flag_T0     bit   00h

LCD_L1	   equ	00h+80h
LCD_NbTr    equ   LCD_L1 + 10
LCD_L2	   equ	40h+80h
LCD_G 	   equ	LCD_L2 + 2
LCD_C 	   equ	LCD_L2 + 6
LCD_D 	   equ	LCD_L2 + 10
Nb_Tr       equ   R7

N_Rouge     equ   10

TH1_CHRG		equ	0E6h
TL0_CHRG    equ   18h
TH0_CHRG    equ   02h

; -----------------------------------------------------------------
; Implementation en mémoire programme
				org	0000h
   			LJMP	debut
   			org	0003h
				LJMP	IT_INT0
				org	000Bh
				LJMP	IT_Timer0
   			org	0013h
				LJMP	IT_INT1
				org	0023h
				LJMP	IT_Serie			
				org	0030h

Txt_L1:	   DB		'Nb tour = 0     ',00h
Txt_L2:	   DB		'G=0 C=0 D=0     ' ,00h

; -----------------------------------------------------------------
; Programme principal
debut:								   ; debut
				MOV	SP,#2Fh        ; | Init Pile
				LCALL	Init				; | Init()			   	   
fin:			SJMP  fin  				; finD

; -----------------------------------------------------------------
; Initialisation
; Parametres passes:
; Parametres retournes:
Init:									   ; debut
            MOV   C_prec,#00h    ; | Initialisation de C_prec
            MOV   C_recu,#00h    ; | Initialisation de C_recu 
            CLR   Flag_T0
            CLR   LED_R          ; | 
            CLR   Car_M_A        ; | Definir l etat initial 
            CLR   Info_M_A       ; | 
            SETB  Laser          ; | Initialisation du Laser en mode etteint
            CLR   Sirene         ; | Initialisation de la sirene en mode etteint
            MOV   Compteur_G,#30h; | Initialisation du compteur gauche '0'
            MOV   Compteur_C,#30h; | Initialisation du compteur centre '0'
            MOV   Compteur_D,#30h; | Initialisation du compteur droite '0'
            MOV   Nb_Tr,#2Fh     ; | Initialisation du nombre de tour '-1'
         	MOV	SCON,#01000000b; | Mode 1 Serie sans RX
				MOV	TMOD,#00100001b; | Timer 1 Mode 2				
				MOV	PCON,#00h		; | Pas de dedoublement SMOD=0
				MOV	TH1,#TH1_CHRG	; | Chargement de la valeur du Timer 1 
				MOV	TL1,#TH1_CHRG	; |
				MOV	TCON,#01000101b; | Demarrage Timer 1
				LCALL LCD_Init       ; | LCD_Init()
				SETB  PX0            ; | Priorite 1 a INT0
				MOV	IE,#10010111b	; | Validation It serie + INT0 + INT1 + Timer0 + generale
				RET						; fin	
				
; -----------------------------------------------------------------
; Interruption IT_Timer0
; Parametres passes:
; Parametres retournes:
IT_Timer0:	
            SETB  Laser       ; Laser OFF
            CLR   Sirene      ; Sirene OFF
            CLR   Flag_T0     ; Flag_T0 OFF
            CLR   TR0         ; Arret timer0
				RETI					; fin	

; -----------------------------------------------------------------
; Interruption INT0 BP Rouge
; Parametres passes:
; Parametres retournes:
IT_INT0:	
            PUSH  ACC         ; 
            CLR   EA          ; Desactivation de liaison série
            CLR   Info_M_A    ; Definir l etat de la voiture en arret
            SETB  Car_M_A     ; Arreter la voiture
            CLR   Car_M_A     ;
rpt_INT0:                        
            CPL   LED_R       ; (LED_R) <= /(LED_R)
            MOV   A,#N_Rouge  ; (CTR) <= N_Rouge 
tq_INT0:    JZ    ftq_INT0    ; Tant que (CTR) != 0
            DEC   A           ; | (CTR) <= (CTR - 1)
            LCALL Tempo       ; | Tempo()
            SJMP  tq_INT0
ftq_INT0:                     ; Fin Tant que 
                              
jsq_INT0:   SJMP  rpt_INT0    ; | 
            POP   ACC         ; 
				RETI					; fin	

; -----------------------------------------------------------------
; Interruption INT1 BP Vert
; Parametres passes:
; Parametres retournes:
IT_INT1:	
			   SETB  REN  			; (REN) <= 1
			   SETB  LED_R       ; (LED_R) ON
				RETI					; fin	

; -----------------------------------------------------------------
; Interruption Serie
; Parametres passes:
; Parametres retournes:
IT_Serie:							                       ; debut
				PUSH	PSW				                    ; |
				PUSH  B
				PUSH	ACC				                    ; |
				CLR	RI					                    ; | Remise a zero du drapeau de RX
      	   MOV   A,SBUF                             ; | (C_recu) <-- (RXD) 
            MOV   C,ACC.7                            ; | (P_recu) <-- (ACC.7)
            MOV   B.0,C                              ; | 
            ANL   A,#01111111b                       ; | C_recu ET 01111111  
            MOV   C_recu, A                          ; |           
            MOV   C,P                                ; | (P_calcule) <-- (P)
            MOV   B.1,C                              ; | 
            CPL   B.1                                ; | /(P_calcule)
            MOV   C,B.0                              ; | Resultat <-- (P_recu) XOR (P_calcule)
            ANL   C,/B.1                             ; |
            MOV   F0,C                               ; | 
            MOV   C,B.1                              ; | 
            ANL   C,/B.0                             ; |       
            ORL   C,F0                               ; | 
AZsi_parite:  JC   fsi_parite                          ; | Si (Resultat) = 0       
si_T0:      JNB   Flag_T0,fsi_T0                     ; | | Si (Flag_T0) = 1 alors
      	   CLR   TR0                                ; | | | Reinitialiser le timer0
				MOV	TH0,#TH0_CHRG	                    ; | | | 
				MOV	TL0,#TL0_CHRG				      	  ; | | |
				SETB  TR0                                ; | | |
fsi_T0:                                              ; | | Fin de si                                                                                   
      	   CJNE  A,C_prec,si_diff                   ; | | Si (C_prec) != (C_recu)  
      	   LJMP  fsi_diff                           ; | | | 
si_diff:		                                         ; | | | 
cas_V:		CJNE  A,#'V',cas_R                       ; | | | Cas (RXD) = 'V' 
				LCALL Vert    		                       ; | | | | Vert()
fcas_V:     LJMP	fcas                               ; | | | Fin cas 'V' 
cas_R:	   CJNE  A,#'R',cas_G	                    ; | | | Cas (RXD) = 'R'
            LCALL Rouge                              ; | | | | Rouge()
fcas_R:     LJMP	fcas                               ; | | | Fin cas 'R'
cas_G:	   CJNE  A,#'G',cas_C	                    ; | | | Cas (RXD) = 'G'
            LCALL Gauche                             ; | | | | Gauche()
fcas_G:     LJMP	fcas                               ; | | | Fin cas 'G'
cas_C:	   CJNE  A,#'C',cas_D	                    ; | | | Cas (RXD) = 'C'
            LCALL Centre                             ; | | | | Centre()
fcas_C:     LJMP	fcas                               ; | | | Fin cas 'C'
cas_D:	   CJNE  A,#'D',cas_A	                    ; | | | Cas (RXD) = 'D'
            LCALL Droite                             ; | | | | Droite()
fcas_D:     LJMP	fcas                               ; | | | Fin cas 'D' 
cas_A:	   CJNE  A,#'A',fcas                        ; | | | Cas (RXD) = 'A'
            LCALL Absent                             ; | | | | Absence()
si_G:       MOV   A,C_prec                           ; | | | | Si (C_prec) = 'G'
            CJNE  A,#'G',fsi_G                       ; | | | | | 
            SETB  Laser                              ; | | | | | (Laser) <-- OFF
            CLR   Sirene                             ; | | | | | 
            CLR   TR0                                 
            CLR   Flag_T0                             
fsi_G:                                               ; | | | | Fin Si                                        
fcas:			                                         ; | | | Fin cas 
            MOV   C_prec,C_recu                      ; | | (C_prec) <-- (C_recu)
fsi_diff:                                            ; | | Fin Si           
fsi_parite:                                          ; | Fin Si            
				POP	ACC			                       ; |
				POP   B                                  ; | 
				POP	PSW				                    ; |
				RETI						                    ; fin
				

; -----------------------------------------------------------------
; Vert
; Parametres passes: 
; Parametres retournes:
Vert:									   ; debut
            CLR   LED_R          ; | LED_R <= 0
            SETB  Info_M_A       ; | Definir l etat de la voiture en marche
            SETB  Car_M_A        ; | Demarer la voiture
            CLR   Car_M_A        ; |  
				RET						; fin		
; -----------------------------------------------------------------
; Rouge
; Parametres passes:
; Parametres retournes:
Rouge:									      ; debut
            PUSH  ACC                  ; | 
            SETB  LED_R                ; | LED_R <= 1
                                 
            INC   Nb_Tr                ; | Incrementer le nb de tour 
				MOV   A,#LCD_NbTr          ; |
				LCALL	LCD_Code             ; | LCD_Code(LCD_NbTr)
				MOV   A,Nb_Tr              ; |
			   LCALL	LCD_Data			      ; | LCD_Data((Nb_Tr))
si_nb_tr:   CJNE  Nb_Tr,#33h,fsi_nb_tr  ; | Si Nb tour = 3
			   CLR   ES                   ; | | Devalider l'IT_serie
fsi_nb_tr:                             ; | Fin Si
			   
            CLR   Info_M_A             ; | Definir l etat de la voiture en arret
            SETB  Car_M_A              ; | Arreter la voiture
            CLR   Car_M_A              ; | 
            
            POP   ACC                  ; | 
				RET						      ; fin
				
; -----------------------------------------------------------------
; Gauche
; Parametres passes:
; Parametres retournes:
Gauche:									; debut
            PUSH  ACC
            INC   Compteur_G     ; | Incrementer le compteur G
				MOV   A,#LCD_G       ; | 
				LCALL	LCD_Code       ; | LCD_Code(LCD_G)
				MOV   A, Compteur_G  ; | 
			   LCALL	LCD_Data			; | LCD_Data((Compteur_G))
			   POP   ACC            ; |
				RET						; fin		
				
; -----------------------------------------------------------------
; Centre
; Parametres passes:
; Parametres retournes:
Centre:									; debut
            PUSH  ACC
            INC   Compteur_C     ; | Incrementer le compteur C           
				MOV   A, #LCD_C      ; | 
				LCALL	LCD_Code       ; | LCD_Code(LCD_C)
				MOV   A, Compteur_C  ; | 
			   LCALL	LCD_Data			; | LCD_Data((Compteur_C))
			   POP   ACC			   
				RET						; fin
; -----------------------------------------------------------------
; Droite
; Parametres passes:
; Parametres retournes:
Droite:									; debut
            PUSH  ACC
            INC   Compteur_D   ; | Incrementer le compteur D          
				MOV   A, #LCD_D      ; | 
				LCALL	LCD_Code       ; | LCD_Code(LCD_D)
				MOV   A, Compteur_D  ; | 
			   LCALL	LCD_Data			; | LCD_Data((Compteur_D))
            POP   ACC
            RET						; fin
; -----------------------------------------------------------------
; Absence
; Parametres passes:
; Parametres retournes:
Absent:									; debut
            CLR  Laser           ; | Allumer le laser
            SETB  Sirene         ; | Allumer la sirene
            SETB  Flag_T0        ; | Allumer le Timer0
            CLR   TR0
            MOV	TH0,#TH0_CHRG	; | Chargement de la valeur du Timer 0 
				MOV	TL0,#TL0_CHRG	; |
            SETB  TR0
				RET						; fin		
					
				
				
				
; -----------------------------------------------------------------
; Initialisation l'écran LCD
; Parametres passes:
; Parametres retournes:
LCD_Init:								; debut
			   LCALL	LCD_Config		; | LCD_Config()
			   MOV	A,#LCD_L1		; | LCD_Code(LCD_L1) 
			   LCALL	LCD_Code			; |
			   MOV	DPTR,#Txt_L1	; | LCD_Msg(Txt_L1)
			   LCALL	LCD_Msg			; |
			   MOV	A,#LCD_L2		; | LCD_Code(LCD_L2)
			   LCALL	LCD_Code			; |
			   MOV	DPTR,#Txt_L2	; | LCD_Msg(Txt_L2)
			   LCALL	LCD_Msg			; |	
				RET						; fin	
				
; -----------------------------------------------------------------
; Attente Busy Flag
; Parametres passes:
; Parametres retournes:
LCD_BF:								; debut
			PUSH	ACC				; |
			MOV	LCD_DB,#0FFh	; | Port DB en entree
			CLR	LCD_RS			; | Lecture registre instruction
			SETB	LCD_RW			; | 
rpt_bf:								; | repeter
         CLR	LCD_E				; | | Attendre 80us avec E bas
			MOV	A,#40				; | | 
att_80:	DJNZ	ACC,att_80		; | | 
			SETB	LCD_E				; | | Front montant E
			NOP						; | | Attente de 1us
jsq_bf:	JB		BF,rpt_bf		; | jusqu'a (BF) = 0
			CLR	LCD_E				; |
			POP	ACC				; |
			RET						; fin
			
; -----------------------------------------------------------------
; Configuration LCD
; Parametres passes:
; Parametres retournes:
LCD_Config:							; debut
			PUSH	ACC				; |
			MOV	LCD_DB,00h		; | Ports LCD bas
			MOV	LCD_BC,00h		; | 
			LCALL Tempo          ; | Tempo()
			MOV	A,#00111000b	; | 8bits, 2lignes, 5x8
			LCALL LCD_Code       ; | LCD_Code()
			MOV	A,#00001100b	; | Display On, Cursor Off, Blinking Off
			LCALL LCD_Code       ; | LCD_Code()
			POP	ACC				; |
			RET						; fin

; -----------------------------------------------------------------
; Ecriture message
; Parametres passes:DPTR=@Txt
; Parametres retournes:
LCD_Msg:								; debut
			PUSH	ACC				; |
tq_msg:	CLR	A					; | tant que ((Txt)) != 0
			MOVC	A,@A+DPTR		; | |
			JZ		ftq_msg			; | |
         LCALL	LCD_Data       ; | | LCD_Data( ((Txt)) )
         INC	DPTR           ; | | (Txt) = (Txt) + 1
			SJMP	tq_msg			; | |
ftq_msg:	                     ; | fin tant que
			POP	ACC				; |
			RET						; fin
						
; -----------------------------------------------------------------
; Envoie data LCD
; Parametres passes:DATA=A
; Parametres retournes:
LCD_Data:							; debut
			LCALL	LCD_BF			; | LCD_BF()
			SETB	LCD_RS			; | Ecriture registre donnee
			CLR	LCD_RW			; | 
			MOV	LCD_DB,A			; | Ecriture donnee sur le bus
			SETB	LCD_E				; | Front descendant E
			CLR	LCD_E				; |			
			RET						; fin		
				
; -----------------------------------------------------------------
; Envoie instruction LCD
; Parametres passes:INST=A
; Parametres retournes:
LCD_Code:							; debut
			LCALL LCD_BF  			; | LCD_BF()
			CLR	LCD_RS			; | Ecriture registre instruction
			CLR	LCD_RW			; | 
			MOV	LCD_DB,A			; | Ecriture donnee sur le bus
			SETB	LCD_E				; | Front descendant E
			CLR	LCD_E				; |			
			RET						; fin
						
; -----------------------------------------------------------------
; Temporisation de 50ms
; Parametres passes:
; Parametres retournes:
Tempo:								; debut
			MOV	R0,#100			; | (R0) <= 100
Rpt_t0:	                     ; | repeter
			MOV	R1,#0FFh	      ; | | (R1) <= FFh
Rpt_t1:                       ; | | repeter
			DJNZ	R1,Rpt_t1		; | | | (R1) <= (R1) - 1
										; | | jusqu'a (R1) = 0
			DJNZ	R0,Rpt_t0		; | | (R0) <= (R0) - 1
										; | jusqu'a (R0) = 0
			RET						; fin
			
; -----------------------------------------------------------------
; Fin d assemblage
				end



