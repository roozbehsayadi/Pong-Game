
org 100h

.DATA

    WINDOW_WIDTH equ 320
    WINDOW_HEIGHT equ 200                

    FRAMES_DELAY equ 1 ;24 fps
    
    current_time db ?   ;used in delay function
    initial_time db ?   ;used in delay function

    ball_center_x dw 160
    ball_center_y dw 100
    ball_radius dw 5
    ball_radius_square dw ? ;will be calculated in main
    
    ball_velocity_x dw -5
    ball_velocity_y dw 2
    
    ball_color_random db 0Fh
    
    right_margin dw 35
    top_margin dw 25
    bottom_margin dw 10
    left_margin dw 10
    border_width dw 1
    
    racket_margin dw 30
    racket_start_x dw ?     ;will set to window_width - racket_margin - racket_width later
    racket_start_y dw 150
    racket_width dw 7
    racket_height dw 25
    racket_move_velocity dw 10
    
    lost dw 0
    win dw 0
    point dw 0
           
.CODE 

MAIN    PROC FAR

    mov ax, @DATA
    mov ds, ax
    
    mov ax, ball_radius
    mul ball_radius
    mov ball_radius_square, ax  ;initializing ball_radius_square
    
    mov ax, WINDOW_WIDTH
    sub ax, racket_margin
    sub ax, racket_width
    mov racket_start_x, ax      ;initializing racket_start_x based on window width, racket margin and racket width    
                     
    call SET_GRAPHIC_MODE
    
    call DRAW_BORDERS
    
    move_ball_loop:
    
        call CLEAR_BALL
        call MOVE_BALL
        
        call CLEAR_RACKET
        
        call CHECK_KEYBOARD_EVENTS 
        
        call CHECK_BALL_COLLISION
        
        call WRITE_POINT_ON_SCREEN
        call WRITE_POINT_ON_LED 
        
        call DRAW_RACKET
        call DRAW_BALL
        
        call HANDLE_LOSS
        
        cmp lost, 1
        je end_program
        
        call CHECK_WIN
        
        cmp win, 1
        je end_program 
        
        call DELAY        
        
        jmp move_ball_loop
    
    end_program:
        mov ah, 4ch ;exit status
        int 21h
    
MAIN    ENDP
;---------------------
DRAW_BALL   PROC
    
    ;call SET_GRAPHIC_MODE
       
    mov dx, ball_center_y       ;
    sub dx, ball_radius         ;Initial row for drawing the ball
    
    draw_ball_loop1:
        mov cx, ball_center_x   ;
        sub cx, ball_radius     ;initial column for drawing the ball
        
        draw_ball_loop2:
            call CHECK_INSIDE_BALL
            cmp bx, 0000h
            je pass_this_pixel            
            mov al, ball_color_random   ;color (random)
            mov ah, 0ch         ;code for drawing pixel
            int 10h             ;interupt
            pass_this_pixel:
                inc cx              ;go to next column
                mov ax, ball_center_x    ;checking if code reached end of column
                add ax, ball_radius    
                cmp cx, ax
                jne draw_ball_loop2
                
                inc dx                  ;go to next row
                mov ax, ball_center_y   ;checking if code reached end of row
                add ax, ball_radius
                cmp dx, ax
                jne draw_ball_loop1
            
        
            
    RET
            
DRAW_BALL   ENDP    
;---------------------
GET_RANDOM_COLOR    PROC
    
    push cx
    push dx 
    
    mov ah, 2ch
    int 21h         ;get current time miliseconds in al
    mov al, dl
    mov ah, 0
    mov cl, 15
    div cl          ;we have our random number inside ah (modulus)          
    inc ah          ;to avoid black color for ball!
    
    mov ball_color_random, ah
    pop dx
    pop cx  
    
    RET
    
GET_RANDOM_COLOR    ENDP
;---------------------
CHECK_INSIDE_BALL   PROC ;checks if coordinate inside cx and dx is inside the ball's circle. bx=1 for yes, bx=0 for no
    
    push cx     
    push dx     ;keep row and column inside stack
    
    cmp cx, ball_center_x   ;check if current point is left or right of center
    jge cx_is_positive
    
    mov ax, ball_center_x
    sub ax, cx
    xchg ax, cx                 ;now center_x - current_x is in cx
    jmp delta_x_is_calculated
        
    cx_is_positive: 
        sub cx, ball_center_x   ;now current_x - center_x is in cx
        jmp delta_x_is_calculated
    
    delta_x_is_calculated:
        mov al, cl
        mul cl          ;delta_x^2 inside ax
        push ax         ;push ax to stack
        
    cmp dx, ball_center_y   ;check if current point is up or down of center
    jge dx_is_positive
    
    mov ax, ball_center_y
    sub ax, dx
    xchg ax, dx                 ;now center_y - current_y is in cx
    jmp delta_y_is_calculated
    
    dx_is_positive:
        sub dx, ball_center_y   ;now current_y - center_y is in cx
        jmp delta_y_is_calculated
    
    delta_y_is_calculated:
        mov al, dl
        mul dl          ;delta_y^2 is inside ax
        push ax         ;push ax to stack
        
    calculate_distance_squared:
        pop bx                          
        pop ax
        add bx, ax                      ;calculate delta_x^2 + delta_y^2
        cmp bx, ball_radius_square
        jle point_is_inside_circle
        jg point_is_outside_circle
        
    point_is_inside_circle:
        mov bx, 1
        jmp check_inside_ball_exit
    
    point_is_outside_circle:
        mov bx, 0
        jmp check_inside_ball_exit         

    check_inside_ball_exit:
        pop dx
        pop cx    
        RET
    
CHECK_INSIDE_BALL   ENDP    
;---------------------
MOVE_BALL   PROC       
    
    mov ax, ball_velocity_x
    add ball_center_x, ax
    mov ax, ball_velocity_y
    add ball_center_y, ax
    
    RET
    
MOVE_BALL   ENDP
;---------------------
WRITE_POINT_ON_SCREEN   PROC
    
    mov dh, 1
    mov dl, 59
    mov bh, 0
    mov ah, 2
    int 10h     ;set cursor position
    
    mov ax, point   ;point is stored in ax (in al to be specific)
    mov di, 0
    mov dx, 0 
     
    print_label1:
    
        cmp ax, 0
        je print_label2
        
        mov bx, 10
        div bx
        push dx
        inc di
        
        xor dx, dx
        jmp print_label1
        
    print_label2:
    
        cmp di, 0
        je print_exit
        
        pop dx 
        mov ax, dx
        add ax, 48
        mov bh, 0
        mov bl, 046h
        mov cx, 1
        mov ah, 09h
        int 10h     ;write it
        
        mov dh, 1
        mov dl, 60
        mov bh, 0
        mov ah, 2
        int 10h     ;move cursor forward (DIRTY CODE ALERT)
        
        dec di
        jmp print_label2
        
    print_exit:
        RET
    
WRITE_POINT_ON_SCREEN   ENDP
;---------------------
WRITE_POINT_ON_LED  PROC
    
    mov ax, point
    out 199, ax
    
    RET
    
WRITE_POINT_ON_LED  ENDP
;---------------------
HANDLE_LOSS PROC
    
    ;if ball_center_x + ball_radius >= WINDOW_WIDTH, lost. 
    mov ax, ball_center_x
    add ax, ball_radius
    cmp ax, WINDOW_WIDTH
    jge handle_loss_lost                                                       
          
    jmp handle_loss_didnt_loose
    handle_loss_lost:
        mov lost, 1
        jmp handle_loss_end
        
    handle_loss_didnt_loose:
        mov lost, 0
        jmp handle_loss_end
        
    handle_loss_end:
        RET
    
HANDLE_LOSS ENDP    
;---------------------
CHECK_WIN   PROC
    
    cmp point, 30
    jge check_win_won
    jl check_win_end
    
    check_win_won:
        mov win, 1
        jmp check_win_end
        
    check_win_end:
        RET
    
CHECK_WIN   ENDP    
;---------------------
CHECK_KEYBOARD_EVENTS   PROC
    
    mov ah, 01h
    int 16h
    jz racket_movement_end
    
    mov ah, 00h
    int 16h
    
    cmp al, 'w'
    je racket_move_up

    cmp al, 's'
    je racket_move_down
    
    cmp al, 'q'
    je end_program
    
    racket_move_up:                       
        mov ax, racket_move_velocity
        sub racket_start_y, ax
        mov ax, top_margin
        cmp racket_start_y, ax
        jge racket_movement_end
        mov ax, top_margin
        mov racket_start_y, ax
        jmp racket_movement_end
    
    racket_move_down:
        mov ax, racket_move_velocity
        add racket_start_y, ax
        mov ax, WINDOW_HEIGHT
        sub ax, bottom_margin
        sub ax, racket_height
        cmp racket_start_y, ax
        jle racket_movement_end
        mov ax, WINDOW_HEIGHT
        sub ax, bottom_margin
        sub ax, racket_height
        mov racket_start_y, ax
        jmp racket_movement_end
    
    racket_movement_end:
        RET
    
CHECK_KEYBOARD_EVENTS   ENDP    
;---------------------
CHECK_BALL_COLLISION PROC
    
    call CHECK_BALL_LEFT_COLLISION
    call CHECK_BALL_TOP_COLLISION
    call CHECK_BALL_BOTTOM_COLLISION
    call CHECK_BALL_RACKET_COLLISION
    
    RET
    
CHECK_BALL_COLLISION ENDP
;---------------------
CHECK_BALL_RACKET_COLLISION PROC    ; storing result in stack. 1 for collision and 0 for not collision.
    
    ;ball_x - ball_radius < racket_x + racket_width
    mov ax, ball_center_x
    sub ax, ball_radius     ;ax: ball_x - ball_radius
    mov bx, racket_start_x
    add bx, racket_width    ;bx: racket_x + racket_width
    cmp ax, bx
    jge ball_racket_didnt_collide
    
    ;ball_x + ball_radius > racket_x
    mov ax, ball_center_x
    add ax, ball_radius     ;ax: ball_x + ball_radius
    mov bx, racket_start_x        ;bx: racket_x + racket_width
    cmp ax, bx
    jle ball_racket_didnt_collide
    
    ;ball_y - ball_radius < racket_y + racket_height
    mov ax, ball_center_y
    sub ax, ball_radius     ;ax: ball_y - ball_radius
    mov bx, racket_start_y
    add bx, racket_height   ;bx: racket_y + racket_height
    cmp ax, bx
    jge ball_racket_didnt_collide
    
    ;ball_y + ball_radius > racket_y 
    mov ax, ball_center_y
    add ax, ball_radius     ;ax: ball_y + ball_radius
    mov bx, racket_start_y  ;bx: racket_y
    cmp ax, bx
    jle ball_racket_didnt_collide
    
    jmp ball_racket_did_collide     
    
    ball_racket_didnt_collide:
        jmp ball_racket_collision_end
    
    ball_racket_did_collide:
        cmp ball_velocity_x, 0          ;if ball was going left, collision is not important
        jl ball_racket_collision_end
        not ball_velocity_x             
        inc ball_velocity_x             ;negate ball_velocity_x
        inc point                       ;increase point by 1
        call GET_RANDOM_COLOR
        jmp ball_racket_collision_end
        
    ball_racket_collision_end:         
        RET
    
CHECK_BALL_RACKET_COLLISION ENDP    
;---------------------
CHECK_BALL_LEFT_COLLISION PROC
    
    mov bx, ball_center_x
    sub bx, ball_radius
    cmp bx, left_margin     ;did the ball touch the left border?
    jle left_collided
    jg left_collision_end
    
    left_collided:
        mov ax, left_margin
        mov ball_center_x, ax
        mov ax, ball_radius
        add ball_center_x, ax   ;putting ball on the left border (in case it passed it)
        
        not ball_velocity_x
        add ball_velocity_x, 1  ;multiplied the x velocity by -1, so the direction of it changes.        
    
    left_collision_end:    
        RET
    
CHECK_BALL_LEFT_COLLISION ENDP
;---------------------
CHECK_BALL_TOP_COLLISION PROC
    
    mov bx, ball_center_y
    sub bx, ball_radius
    cmp bx, top_margin      ;did the ball touch the top border?
    jle top_collided
    jg top_collision_end
    
    top_collided:
        mov ax, top_margin
        mov ball_center_y, ax
        mov ax, ball_radius
        add ball_center_y, ax   ;putting ball on the top border (in case it passed it)
        
        not ball_velocity_y
        add ball_velocity_y, 1  ;multiplied the y velocity by -1, so the direction of it changes.
        
    top_collision_end:     
        RET
    
CHECK_BALL_TOP_COLLISION ENDP
;---------------------       
CHECK_BALL_BOTTOM_COLLISION PROC
    
    mov bx, ball_center_y
    add bx, ball_radius
    mov cx, WINDOW_HEIGHT
    sub cx, bottom_margin
    cmp bx, cx   ;did the ball touch the bottom border?
    jge bottom_collided
    jl bottom_collision_end
    
    bottom_collided:
        mov ax, WINDOW_HEIGHT
        sub ax, bottom_margin
        mov ball_center_y, ax
        mov ax, ball_radius
        sub ball_center_y, ax   ;putting ball on the bottom border (in case it passed it)
        
        not ball_velocity_y
        add ball_velocity_y, 1  ;multiplied the y velocity by -1, so the direction of it changes.
        
    bottom_collision_end:
        RET
    
CHECK_BALL_BOTTOM_COLLISION ENDP    
;---------------------
DELAY PROC       
        
    mov ah, 86h
    mov cx, 0h
    mov dx, 0a028h  ;wait for 41 miliseconds (for 24 fps)
    int 15h
    
    RET
    
DELAY ENDP
;---------------------
DRAW_BORDERS PROC       
                                  
    call DRAW_TOP_BORDER
    call DRAW_BOTTOM_BORDER           
    call DRAW_LEFT_BORDER
       
    RET                    
    
DRAW_BORDERS ENDP    
;---------------------
DRAW_LEFT_BORDER PROC
    
    mov dx, top_margin
    sub dx, border_width
    
    left_border_loop1:
    
        mov cx, left_margin
        sub cx, border_width
        
        left_border_loop2:
        
            mov ah, 0ch
            mov al, 0Fh
            int 10h
            
            inc cx
            mov ax, left_margin
            cmp cx, ax
            jne left_border_loop2
            
            inc dx
            mov ax, WINDOW_HEIGHT
            sub ax, bottom_margin
            cmp dx, ax
            jne left_border_loop1
    
    RET
    
DRAW_LEFT_BORDER ENDP
;---------------------
DRAW_TOP_BORDER PROC
    
    mov dx, top_margin
    sub dx, border_width
    
    top_border_loop1:
    
        mov cx, left_margin
        sub cx, border_width
        
        top_border_loop2:
        
            mov ah, 0ch
            mov al, 0Fh
            int 10h
            
            inc cx
            mov ax, WINDOW_WIDTH
            sub ax, right_margin
            add ax, border_width
            cmp cx, ax
            jne top_border_loop2
            
            inc dx
            mov ax, top_margin
            cmp dx, ax
            jne top_border_loop1
    
    RET
    
DRAW_TOP_BORDER ENDP
;---------------------
DRAW_BOTTOM_BORDER PROC
    
    mov dx, WINDOW_HEIGHT
    sub dx, bottom_margin
    
    bottom_border_loop1:
        
        mov cx, left_margin
        sub cx, border_width
        
        bottom_border_loop2:
        
            mov ah, 0ch
            mov al, 0Fh
            int 10h
            
            inc cx
            mov ax, WINDOW_WIDTH
            sub ax, right_margin
            add ax, border_width
            cmp cx, ax
            jne bottom_border_loop2
            
            inc dx
            mov ax, WINDOW_HEIGHT
            sub ax, bottom_margin
            add ax, border_width
            cmp ax, dx
            jne bottom_border_loop1
    
    RET
    
DRAW_BOTTOM_BORDER ENDP
;---------------------
CLEAR_BALL  PROC    ;same as draw ball, with black color
    
    mov dx, ball_center_y        ;
    sub dx, ball_radius         ;Initial row for drawing the ball
    
    clear_ball_loop1:
        mov cx, ball_center_x    ;
        sub cx, ball_radius     ;initial column for drawing the ball
        
        clear_ball_loop2:
            mov ah, 0ch         ;code for drawing pixel
            mov al, 00h         ;color (black)
            int 10h             ;interupt
            inc cx              ;go to next column
            mov ax, ball_center_x    ;checking if code reached end of column
            add ax, ball_radius    
            cmp cx, ax
            jnz clear_ball_loop2
            
            inc dx                  ;go to next tow
            mov ax, ball_center_y    ;checking if code reached end of row
            add ax, ball_radius
            cmp dx, ax
            jnz clear_ball_loop1
    
    RET
    
CLEAR_BALL  ENDP    
;---------------------
CLEAR_RACKET    PROC
    
    mov dx, racket_start_y  ;initial row for drawing the racket
    
    clear_racket_loop1:
        mov cx, racket_start_x  ;initial column for drawing the ball
        
        clear_racket_loop2:
            mov ah, 0ch
            mov al, 00h
            int 10h
            inc cx
            mov ax, racket_start_x
            add ax, racket_width
            cmp cx, ax
            jnz clear_racket_loop2
            
            inc dx
            mov ax, racket_start_y
            add ax, racket_height
            cmp dx, ax
            jnz clear_racket_loop1 
    
    RET
    
CLEAR_RACKET    ENDP
;---------------------
DRAW_RACKET PROC
    
    mov dx, racket_start_y
    
    draw_racket_loop1:
        mov cx, racket_start_x
        
        draw_racket_loop2:
            mov ah, 0ch
            mov al, 0Fh
            int 10h
            
            inc cx
            mov ax, racket_start_x
            add ax, racket_width
            cmp cx, ax
            jnz draw_racket_loop2
            
            inc dx
            mov ax, racket_start_y
            add ax, racket_height
            cmp dx, ax
            jnz draw_racket_loop1
    
    RET
    
DRAW_RACKET ENDP    
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
    
    mov ax, 1003h
    mov bl, 00h
    mov bh, 00h
    int 10h         ;disable blinking for background      
    
    RET
    
SET_GRAPHIC_MODE    ENDP    
;---------------------
END MAIN

ret
