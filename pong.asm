
; You may customize this and other start-up templates; 
; The location of this template is c:\emu8086\inc\0_com_template.txt

org 100h

.DATA                

    FRAMES_DELAY equ 41 ;24 fps
    
    current_time db ?   ;used in delay function
    initial_time db ?   ;used in delay function

    ball_start_x dw 160
    ball_start_y dw 100
    ball_radius  dw 3
           
.CODE 

MAIN    PROC FAR

    mov ax, @DATA
    mov ds, ax
                     
    call SET_GRAPHIC_MODE
    ;call CLEAR_SCREEN
    
    move_ball_loop:
        call CLEAR_BALL
        call MOVE_BALL
        call DRAW_BALL
        call DELAY
        jmp move_ball_loop
    
    mov ah, 4ch ;exit status
    int 21h
    
MAIN    ENDP
;---------------------
DRAW_BALL   PROC
    
    ;call SET_GRAPHIC_MODE
       
    mov dx, ball_start_y        ;
    sub dx, ball_radius         ;Initial row for drawing the ball
    
    draw_ball_loop1:
        mov cx, ball_start_x    ;
        sub cx, ball_radius     ;initial column for drawing the ball
        
        draw_ball_loop2:
            mov ah, 0ch         ;code for drawing pixel
            mov al, 0Fh         ;color (white)
            int 10h             ;interupt
            inc cx              ;go to next column
            mov ax, ball_start_x    ;checking if code reached end of column
            add ax, ball_radius    
            cmp cx, ax
            jnz draw_ball_loop2
            
            inc dx                  ;go to next tow
            mov ax, ball_start_y    ;checking if code reached end of row
            add ax, ball_radius
            cmp dx, ax
            jnz draw_ball_loop1
            
        
            
    RET
            
DRAW_BALL   ENDP    
;---------------------
MOVE_BALL   PROC       
    
    add ball_start_x, 2
    add ball_start_y, 2 
    
    RET
    
MOVE_BALL   ENDP    
;---------------------
DELAY PROC
           
    ;mov ah, 2ch
    ;int 21h
    ;mov initial_time, dl
    
    ;delay_loop:
        ;mov ah, 2ch
        ;int 21h
        ;mov current_time, dl
        ;mov al, current_time
        ;sub al, initial_time
        ;cmp al, FRAMES_DELAY
        ;jl delay_loop
        
    mov ah, 86h
    mov cx, 0h
    mov dx, 0a028h
    int 15h
    
    RET
    
DELAY ENDP    
;---------------------
CLEAR_BALL  PROC    ;same as draw ball, with black color
    
    mov dx, ball_start_y        ;
    sub dx, ball_radius         ;Initial row for drawing the ball
    
    clear_ball_loop1:
        mov cx, ball_start_x    ;
        sub cx, ball_radius     ;initial column for drawing the ball
        
        clear_ball_loop2:
            mov ah, 0ch         ;code for drawing pixel
            mov al, 00h         ;color (black)
            int 10h             ;interupt
            inc cx              ;go to next column
            mov ax, ball_start_x    ;checking if code reached end of column
            add ax, ball_radius    
            cmp cx, ax
            jnz clear_ball_loop2
            
            inc dx                  ;go to next tow
            mov ax, ball_start_y    ;checking if code reached end of row
            add ax, ball_radius
            cmp dx, ax
            jnz clear_ball_loop1
    
    RET
    
CLEAR_BALL  ENDP    
;---------------------
CLEAR_SCREEN    PROC
    
    mov ah, 06H     ;scroll up
    mov al, 00h     ;clear entire window
    mov bh, 00h     ;color    
    mov cx, 0000    ;start row, column
    mov dx, 184fh   ;end  row, column
    int 10h
      
    RET
    
CLEAR_SCREEN    ENDP
;---------------------
SET_GRAPHIC_MODE    PROC
       
    mov ah, 00h     ;setting video mode
    mov al, 13h     ;320x200 256 colors 
    int 10h         ;call interruption      
    
    RET
    
SET_GRAPHIC_MODE    ENDP    
;---------------------
END MAIN

ret




