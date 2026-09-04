.MODEL SMALL
 
.STACK 100H

.DATA

;---------------------------------menu data---------------------------------
CLEAR DB 25 DUP(13,10),"$"
MENU DB 13,10, "===MENU===",13,10
     DB "1. Check Balance" ,13,10
     DB "2. Take loan" ,13,10
     DB "3. Transfer Money" ,13,10
     DB "4. Mobile Recharge" ,13,10 
     DB "5. Transaction History" ,13,10 
     DB "6. Exit" ,13,10  
     DB "Select an option: $" 

PRESSED DW 0
PRESS_KEY DB 13,10, "Press Enter to return to menu $"
INVALID DB 13,10, "Invalid option! Try again. $"    

HDR_BALANCE DB 13,10,"========== CHECK BALANCE ==========",13,10,"$"
HDR_LOAN DB 13,10,"========== TAKE LOAN ==========",13,10,"$"
HDR_TRANSFER DB 13,10,"========== TRANSFER MONEY ==========",13,10,"$"
HDR_RECHARGE DB 13,10,"========== MOBILE RECHARGE ==========",13,10,"$"
HDR_HISTORY DB 13,10,"========== TRANSACTION HISTORY ==========",13,10,"$"

STUB_BALANCE DB 13,10,"[Balance feature goes here]$"
STUB_LOAN    DB 13,10,"[Loan feature goes here]$"
STUB_TRANSFER DB 13,10,"[Transfer feature goes here]$"
STUB_RECHARGE DB 13,10,"[Airtime feature goes here]$"
STUB_HISTORY DB 13,10,"[History feature goes here]$"  

;-----------------------------Feature 1: PIN Authentication data----------------
SAVED_PIN DW 1234
ATTEMPTS_LEFT DB 3
MSG_ENTER_PIN DB 13,10,"Enter 4-digit PIN: $"
MSG_PIN_WRONG DB 13,10,"Incorrect PIN! Attempts remaining: $"
MSG_PIN_BLOCKED DB 13,10,"3 Failed Attempts! System frozen for 10 seconds...",13,10,"$"
MSG_PIN_OK DB 13,10,"PIN Verified Successfully!",13,10,"$"
MSG_UNFROZEN DB 13,10,"System unlocked. Please try again.",13,10,"$"

;-----------------------------Feature 2: Balance Dashboard data----------------
MSG_CURRENT_BAL DB 13,10,"Current Available Balance: $"
MSG_CURRENCY DB " BDT",13,10,"$"

;-----------------------------micro loan feature data--------------------------------------------
M1 DB "Enter the amount: $" 
M2 DB 13,10, "Interest rate(%): $"
M3 DB 13,10, "Interest applied  : $"
M4 DB 13,10, "Total payback: $"
M5 DB 13,10, "Current balance: $"

REQUESTED DW 0
INTEREST DW 0
RATE EQU 5    

PAYBACK DW 0
BALANCE DW 5000
     


.CODE
MAIN PROC

; initialize DS

MOV AX,@DATA
MOV DS,AX

;=============================================================================
; FEATURE 1: SECURE PIN AUTHENTICATION
;=============================================================================
PIN_AUTH_START:
    LEA DX, CLEAR
    MOV AH, 09H
    INT 21H

    LEA DX, MSG_ENTER_PIN
    MOV AH, 09H
    INT 21H

    ; Read 4 digits masked with '*'
    MOV CX, 4          ; exactly 4 digits
    MOV BX, 0          ; BX will accumulate the entered PIN value

READ_PIN_LOOP:
    MOV AH, 07H        ; Direct char input without echo
    INT 21H

    CMP AL, '0'
    JB READ_PIN_LOOP   ; ignore non-digit keys
    CMP AL, '9'
    JA READ_PIN_LOOP

    ; Valid digit: save digit value
    PUSH AX            ; save AL (character)
    
    ; Display '*'
    MOV DL, '*'
    MOV AH, 02H
    INT 21H

    ; Multiply BX by 10 and add digit
    MOV AX, BX
    MOV DX, 10
    MUL DX             ; AX = BX * 10
    MOV BX, AX

    POP AX             ; restore character
    SUB AL, '0'
    MOV AH, 0
    ADD BX, AX         ; BX = BX * 10 + digit

    LOOP READ_PIN_LOOP

    ; Compare entered PIN (BX) with SAVED_PIN
    CMP BX, SAVED_PIN
    JE PIN_SUCCESS

    ; --- PIN Incorrect ---
    DEC ATTEMPTS_LEFT
    CMP ATTEMPTS_LEFT, 0
    JE PIN_LOCKOUT

    ; Show attempts remaining and retry
    LEA DX, MSG_PIN_WRONG
    MOV AH, 09H
    INT 21H

    MOV DL, ATTEMPTS_LEFT
    ADD DL, '0'
    MOV AH, 02H
    INT 21H

    ; Wait a moment before asking again
    MOV CX, 000FH
    MOV DX, 4240H
    MOV AH, 86H
    INT 15H
    JMP PIN_AUTH_START

PIN_LOCKOUT:
    ; 3 failed attempts: freeze interface for ~10 seconds
    LEA DX, MSG_PIN_BLOCKED
    MOV AH, 09H
    INT 21H

    CALL FREEZE_SYSTEM

    ; Reset attempts and let user try again
    MOV ATTEMPTS_LEFT, 3
    LEA DX, MSG_UNFROZEN
    MOV AH, 09H
    INT 21H

    MOV CX, 000FH
    MOV DX, 4240H
    MOV AH, 86H
    INT 15H
    JMP PIN_AUTH_START

PIN_SUCCESS:
    ; Reset attempts on success
    MOV ATTEMPTS_LEFT, 3
    LEA DX, MSG_PIN_OK
    MOV AH, 09H
    INT 21H

    ; Brief pause before entering menu
    MOV CX, 0008H
    MOV DX, 0000H
    MOV AH, 86H
    INT 15H

;=============================================================================
; FEATURE 6: USSD INTERACTIVE MENU DASHBOARD
;=============================================================================
MENU_START: 

  
   LEA DX, CLEAR
   MOV AH,09
   INT 21H
   
   LEA DX, MENU
   MOV AH,09
   INT 21H

   CALL READ_NUM
   MOV PRESSED, AX
   

   MOV AX, PRESSED
   CMP AX, 1
   JE CHECK_BALANCE 
   
   MOV AX, PRESSED
   CMP AX, 2
   JE TAKE_LOAN

   MOV AX, PRESSED
   CMP AX, 3
   JE TRANSFER_MONEY

   MOV AX, PRESSED
   CMP AX, 4
   JE RECHARGE 

   MOV AX, PRESSED
   CMP AX, 5
   JE HISTORY
 
   MOV AX, PRESSED
   CMP AX, 6
   JE EXIT 
   
   LEA DX, INVALID
   MOV AH,09
   INT 21H
   JMP STARTING
   
;=============================================================================
; FEATURE 2: DYNAMIC BALANCE DASHBOARD
;=============================================================================
CHECK_BALANCE: 

   LEA DX, HDR_BALANCE
   MOV AH,09
   INT 21H
   
   LEA DX, MSG_CURRENT_BAL
   MOV AH,09
   INT 21H

   MOV AX, BALANCE
   CALL PRINT_NUM

   LEA DX, MSG_CURRENCY
   MOV AH,09
   INT 21H

   JMP STARTING
                 
RECHARGE:  

   LEA DX, HDR_RECHARGE
   MOV AH,09
   INT 21H
   
   LEA DX, STUB_RECHARGE
   MOV AH,09
   INT 21H 
   JMP STARTING
   
              
TAKE_LOAN: 

    LEA DX, HDR_LOAN
    MOV AH,09
    INT 21H  
    
    LEA DX, M1
    MOV AH,09
    INT 21H
    
    CALL READ_NUM
    
    MOV REQUESTED, AX   

;interest calculation    
    MOV AX, REQUESTED
    MOV BX, RATE
    MUL BX

    MOV BX, 100   
    mov DX,0
    DIV BX  
    MOV INTEREST, AX

;payback calculation    
    MOV AX, REQUESTED
    ADD AX, INTEREST
    MOV PAYBACK, AX

;final balance calculation    
    MOV AX, BALANCE
    ADD AX, REQUESTED
    MOV BALANCE, AX 
    

; INTEREST RATE   
    LEA DX, M2
    MOV AH,09
    INT 21H 
    MOV AX, RATE
    CALL PRINT_NUM
    

; INTEREST    
    LEA DX, M3
    MOV AH,09
    INT 21H 
    MOV AX, INTEREST
    CALL PRINT_NUM  

    
;PAYBACK    
    LEA DX, M4
    MOV AH,09
    INT 21H 
    MOV AX, PAYBACK
    CALL PRINT_NUM
    
;BALANCE
    LEA DX, M5
    MOV AH,09
    INT 21H 
    MOV AX, BALANCE
    CALL PRINT_NUM
   
   JMP STARTING    
   

TRANSFER_MONEY: 

   LEA DX, HDR_TRANSFER
   MOV AH,09
   INT 21H
   
   LEA DX, STUB_TRANSFER
   MOV AH,09
   INT 21H
   JMP STARTING 
   

HISTORY:   

   LEA DX, HDR_HISTORY
   MOV AH,09
   INT 21H
   
   LEA DX, STUB_HISTORY
   MOV AH,09
   INT 21H
   JMP STARTING


STARTING:
   LEA DX, PRESS_KEY
   MOV AH,09
   INT 21H   
   
   MOV AH,1
   INT 21H  
   JMP MENU_START
                   
  
EXIT:
               
  MOV AX,4C00H
  INT 21H

MAIN ENDP

READ_NUM PROC
     

    MOV CX, 0
    
READ:
   MOV AH, 1
   INT 21H 
   CMP AL, 13
   JE DONE
   SUB AL,30H
   MOV AH,0
   PUSH AX 
   
   MOV AX,CX 
   MOV BX, 10
   MUL BX
   MOV CX, AX
   
   POP AX
   ADD CX,AX
   JMP READ
   
DONE:     
   MOV AX, CX
   
    RET
READ_NUM ENDP


;PRINTING THE OUTPUT
PRINT_NUM PROC 
    MOV BX , 10
    MOV CX , 0
    
PN_DIVIDE:
    MOV DX, 0
    DIV BX ; AX = AX /10 , DX = remainder
    PUSH DX
    INC CX
    CMP AX, 0
    JNZ PN_DIVIDE


PN_PRINT:
    POP DX
    ADD DL, 30H
    MOV AH , 2
    INT 21H
    LOOP PN_PRINT
    RET
PRINT_NUM ENDP

;-----------------------------------------------------------------------------
; FREEZE_SYSTEM: Freezes the system for ~10 seconds (~182 clock ticks)
; and clears any keystrokes entered during the freeze window.
;-----------------------------------------------------------------------------
FREEZE_SYSTEM PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Get current BIOS timer tick count in CX:DX
    ; BIOS timer increments approx 18.2 times per second.
    ; 10 seconds = ~182 ticks.
    MOV AH, 00H
    INT 1AH
    MOV BX, DX          ; BX = starting tick count (low word)

WAIT_TICKS:
    MOV AH, 00H
    INT 1AH             ; DX = current tick count
    MOV AX, DX
    SUB AX, BX          ; AX = elapsed ticks (handles standard forward progression)
    CMP AX, 182         ; 182 ticks ~ 10 seconds
    JB WAIT_TICKS

FLUSH_KEY_BUFFER:
    ; Drain any keyboard input buffer so keys pressed during freeze are ignored
    MOV AH, 01H         ; Check if keystroke in buffer
    INT 16H
    JZ FREEZE_DONE      ; Buffer is empty
    MOV AH, 00H         ; Remove key from buffer
    INT 16H
    JMP FLUSH_KEY_BUFFER

FREEZE_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
FREEZE_SYSTEM ENDP

    END MAIN
