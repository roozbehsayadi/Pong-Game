
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.DATA
     
           
.CODE

    mov ax, @DATA
    mov ds, ax
    
    mov ah, 4ch ;exit status
    mov 21h
    
MAIN    PROC FAR
MAIN    ENDP
;---------------------
END MAIN

ret




