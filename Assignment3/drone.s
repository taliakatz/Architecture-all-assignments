%macro START 1
push ebp
mov ebp, esp
sub esp, %1
%endmacro

%macro END 1
add esp, %1
mov esp, ebp
pop ebp
%endmacro 

%macro PRINT 2
pushad
pushfd
push %1 ; something to print
push %2 ; format
call printf
add esp, 8
popfd
popad
%endmacro

; define sizes
    id equ 0
    x equ 4
    y equ 14
    angle equ 24
    score equ 34
    speed equ 38
section .rodata

	format: db "%s", 10, 0
	format_float_n: db "%.2lf", 10 , 0
	
section .data
	
    global function_drones
	extern LFSR
    extern seed
    extern CURR_ID
    extern resume
    extern pointer_drones_array
    extern pointer_schedular
    extern pointer_target
    extern MAXINT
	extern hundred
	extern hundred_eighty
	extern three_hundred_sixty
    extern target_coor_x
	extern target_coor_y
	extern d
	extern printf
	
	mayDestroy_flag: db 0
    hundred_twenty: dd 120
    twenty: dd 20
    ten: dd 10
    sixty: dd 60
    zero: dd 0
    
section .bss
	
	diffrence_x: rest 1
	diffrence_y: rest 1
	diffrence_x_square: rest 1
	diffrence_y_square: rest 1
	change_angle: rest 1
	change_speed: rest 1
	curr_x: rest 1
	curr_y: rest 1
	curr_angle: rest 1
	curr_speed: rest 1

section .text

function_drones:    

    mov eax, dword [CURR_ID]
    mov edx, 48
    mul edx
    mov edx, eax
    
    mov ecx , dword[pointer_drones_array]
    
	finit
	
; compute new values to update the drone later
	
    call LFSR  ; generate a random number for change angle

    fild dword [hundred_twenty]
    fidiv dword [MAXINT]
    fild dword [seed]   ; push the generated number
    fmul        ; for angle to be in [0, 120]
    fild dword [sixty]              ; for angle to be in [-60, 60]
    fsub
    fstp tword [change_angle]

    call LFSR  ; generate a random number for change speed

    fild dword[twenty]
    fidiv dword[MAXINT]
    fild dword[seed]	; push the generated number
    fmul
    fild dword[ten]   ; for angle to be in [-10, 10]     
    fsub
    fstp tword [change_speed]
    
; compute the new values of x and y
; compute x

    fld tword[ecx + edx + angle] 	; need to change the current angle to radiance, ecx pointer to drones array
    fldpi	; load pi
    fmulp
    fidiv dword [hundred_eighty]	
    fcos	; compute the difrence between x cordinate to the new one
    fld tword[ecx + edx + speed]	; diffrence_x = cos(angle) * speed
    fmul
    fld tword[ecx + edx + x]
    fadd	; compute the new position of x coordinate
    
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_x	; if 0 is greater/equal then x, need to modify x to be positive
    
    fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_x	; if 100 is less then x, need to modify x to be less then 100
    
update_x:

    fstp tword[ecx + edx + x]	; store the result in curr_x
    jmp compute_y
    
is_negative_x:

	fild dword [hundred]	; loading 100
	fadd
	
	fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_x	; if 0 is greater/equal then x, need to modify x to be positive
	
	jmp update_x	; jump to update x
		
is_more_then_100_x:

    fild dword [hundred]	; loading 100
	fsub
	
	fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_x	; if 100 is less then x, need to modify x to be less then 100
    
	jmp update_x	; jump to update x
    
compute_y:
    
    fld tword[ecx + edx + angle] 	; need to change the current angle to radiance
    fldpi	; load pi
    fmulp
    fidiv dword [hundred_eighty]	
    fsin	; compute the difrence between y cordinate to the new one
    fld tword[ecx + edx + speed]	; diffrence_y = sin(angle) * speed
    fmul
    fld tword[ecx + edx + y]
    fadd	; compute the new position of y coordinate
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_y	; if 0 is greater/equal then y, need to modify y to be positive
    
    fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_y	; if 100 is less then y, need to modify y to be less then 100
    
update_y:

    fstp tword[ecx + edx + y]	; store the result in curr_y
    jmp compute_angle
    
is_negative_y:

	fild dword [hundred]	; loading 100
	fadd
	
	fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_y	; if 0 is greater/equal then y, need to modify y to be positive
    
	jmp update_y	; jump to update x
		
is_more_then_100_y:

    fild dword [hundred]	; loading 100
	fsub
	
	fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_y	; if 100 is less then y, need to modify y to be less then 100
    
	jmp update_y	; jump to update x

; compute new angle
compute_angle:
   
    fld tword[change_angle]	; load the diffrence
    fld tword[ecx + edx + angle]	; load the cuurent angle
    fadd	; add the diffrence
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_angle	; if 0 is greater/equal then the angle, need to modify the angle to be positive
    
    fild dword [three_hundred_sixty]	; loading 360
    fcomip	; compare
    jb is_more_then_360_angle	; if 360 is less then the angle, need to modify the angle to be between 0 - 360
    update_angle:
    fstp tword[ecx + edx + angle]	; store the result in curr_angle
    jmp compute_speed

is_negative_angle:
	
	fild dword [three_hundred_sixty]	; loading 360 
	fadd
	
	fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_angle	; if 0 is greater/equal then the angle, need to modify the angle to be positive
    
	jmp update_angle	; jump to update the angle
	
is_more_then_360_angle:

	fild dword [three_hundred_sixty]	; loading 360 
	fsub
	
	fild dword [three_hundred_sixty]	; loading 360
    fcomip	; compare
    jb is_more_then_360_angle	; if 360 is less then the angle, need to modify the angle to be between 0 - 360
    
	jmp update_angle	; jump to update the angle

; compute new speed
compute_speed:

    fld tword[change_speed]
    fld tword[ecx + edx + speed]
    fadd
    fild dword[hundred]
    fcomip
    jl first_cut_to_100	; if 100 < new speed
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_speed	; if 0 is greater/equal then the speed, need to modify the speed to be 0
    fstp tword[ecx + edx + speed]	; store the result in curr_speed
    jmp first_after_cut_to_100
    
first_cut_to_100:


	fild dword [hundred]	; loading 100
	fstp tword[ecx + edx + speed]	; store the result in curr_speed

    ;mov eax , dword[hundred]
	;mov [ecx + edx + speed] , eax
	jmp first_after_cut_to_100
	
is_negative_speed:

	fild dword [zero]	; loading 0
	fstp tword[ecx + edx + speed]	; store the result in curr_speed
	;mov eax , dword[zero]
	;mov [ecx + edx + speed] , eax
	
first_after_cut_to_100:
	
	ffree
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loop_forever:	
	
	jmp mayDestroy
	
after_call_mayDestroy:

	cmp byte [mayDestroy_flag], 1
	jne after_destroyed_target
destroied:
	mov ecx , dword[pointer_drones_array]
	mov eax, dword [CURR_ID]
    mov edx, 48
    mul edx
    mov edx, eax
    
    inc dword[ecx + edx + score]
	
	mov ebx, pointer_target	; ebx = struct of co routine of the drone with the CURR_ID	
	call resume
	
after_destroyed_target:

	mov edx,0
	mov eax, dword [CURR_ID]
    mov edx, 48
    mul edx
    mov edx, eax
    
    mov ecx , dword[pointer_drones_array]
    
	finit
	
	; compute new values to update the drone later
	
    call LFSR  ; generate a random number for change angle

    fild dword [hundred_twenty]
    fidiv dword [MAXINT]
    fild dword [seed]   ; push the generated number
    fmul        ; for angle to be in [0, 120]
    fild dword [sixty]              ; for angle to be in [-60, 60]
    fsub
    fstp tword [change_angle]

    call LFSR  ; generate a random number for change speed

    fild dword[twenty]
    fidiv dword[MAXINT]
    fild dword[seed]	; push the generated number
    fmul
    fild dword[ten]   ; for angle to be in [-10, 10]     
    fsub
    fstp tword [change_speed]
    
; compute the new values of x and y
; compute x

    fld tword[ecx + edx + angle] 	; need to change the current angle to radiance, ecx pointer to drones array
    fldpi	; load pi
    fmulp
    fidiv dword [hundred_eighty]	
    fcos	; compute the difrence between x cordinate to the new one
    fld tword[ecx + edx + speed]	; diffrence_x = cos(angle) * speed
    fmul
    fld tword[ecx + edx + x]
    fadd	; compute the new position of x coordinate
    
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_x_second	; if 0 is greater/equal then x, need to modify x to be positive
    
    fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_x_second	; if 100 is less then x, need to modify x to be less then 100
    
update_x_second:

    fstp tword[ecx + edx + x]	; store the result in curr_x
    jmp compute_y_second
    
is_negative_x_second:

	fild dword [hundred]	; loading 100
	fadd
	
	fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_x_second	; if 0 is greater/equal then x, need to modify x to be positive
    
	jmp update_x_second	; jump to update x
		
is_more_then_100_x_second:

    fild dword [hundred]	; loading 100
	fsub
	
	fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_x_second	; if 100 is less then x, need to modify x to be less then 100
    
	jmp update_x_second	; jump to update x

compute_y_second:
    
    fld tword[ecx + edx + angle] 	; need to change the current angle to radiance
    fldpi	; load pi
    fmulp
    fidiv dword [hundred_eighty]	
    fsin	; compute the difrence between y cordinate to the new one
    fld tword[ecx + edx + speed]	; diffrence_y = sin(angle) * speed
    fmul
    fld tword[ecx + edx + y]
    fadd	; compute the new position of y coordinate
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_y_second	; if 0 is greater/equal then y, need to modify y to be positive
    
    fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_y_second	; if 100 is less then y, need to modify y to be less then 100
    
update_y_second:

    fstp tword[ecx + edx + y]	; store the result in curr_y
    jmp compute_angle_second
    
is_negative_y_second:

	fild dword [hundred]	; loading 100
	fadd
	
	fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_y_second	; if 0 is greater/equal then y, need to modify y to be positive
    
	jmp update_y_second	; jump to update x
		
is_more_then_100_y_second:

    fild dword [hundred]	; loading 100
	fsub
	
	fild dword [hundred]	; loading 100
    fcomip	; compare
    jb is_more_then_100_y_second	; if 100 is less then y, need to modify y to be less then 100
    
	jmp update_y_second	; jump to update x

compute_angle_second:
	
    fld tword[change_angle]	; load the diffrence
    fld tword[ecx + edx + angle]	; load the cuurent angle
    fadd	; add the diffrence
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_angle2	; if 0 is greater/equal then the angle, need to modify the angle to be positive
    fild dword [three_hundred_sixty]	; loading 360
    fcomip	; compare
    jb is_more_then_360_angle2	; if 360 is less then the angle, need to modify the angle to be between 0 - 360
    
update_angle2:

    fstp tword[ecx + edx + angle]	; store the result in curr_angle
    jmp compute_speed2

is_negative_angle2:

	fild dword [three_hundred_sixty]	; loading 360 
	fadd
	
	fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_angle2	; if 0 is greater/equal then the angle, need to modify the angle to be positive
    
	jmp update_angle2	; jump to update the angle
	
is_more_then_360_angle2:

	fild dword [three_hundred_sixty]	; loading 360 
	fsub
	
	fild dword [three_hundred_sixty]	; loading 360
    fcomip	; compare
    jb is_more_then_360_angle2	; if 360 is less then the angle, need to modify the angle to be between 0 - 360
    
	jmp update_angle2	; jump to update the angle

; compute new speed
compute_speed2:

    fld tword[change_speed]
    fld tword[ecx + edx + speed]
    fadd
    fild dword[hundred]
    fcomip
    jl second_cut_to_100	; if 100 < new speed
    fild dword [zero]	; loading 0
    fcomip	; compare
    jae is_negative_speed2	; if 0 is greater/equal then the speed, need to modify the speed to be 0
    fstp tword[ecx + edx + speed]	; store the result in curr_angle
    jmp second_after_cut_to_100
    
second_cut_to_100:

	fild dword [hundred]	; loading 100
	fstp tword[ecx + edx + speed]	; store the result in curr_speed

    ;mov eax , dword[hundred]
	;mov [ecx + edx + speed] , eax
	jmp second_after_cut_to_100
	
is_negative_speed2:

	fild dword [zero]	; loading 0
	fstp tword[ecx + edx + speed]	; store the result in curr_speed

	;mov eax , dword[zero]
	;mov [ecx + edx + speed] , eax
	
second_after_cut_to_100:
	
	ffree
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; switch to the schedular co routine
	mov ebx, pointer_schedular	; ebx = struct of co routine of the drone with the CURR_ID	
	call resume

	jmp loop_forever

; mayDestroy()
mayDestroy:

	START 0
    finit
  
    mov edi, [pointer_drones_array]    ;to get to the first current drone structure
    mov ecx, [CURR_ID]             
    mov eax, 48
    mul ecx         ; eax = CURR_ID * 48
    add edi, eax       ; edi = pointer_drones_array[CURR_ID * 48] -> for the current COi
    
	fld tword [target_coor_y]
	fld tword [edi + y]
	fsub
	fstp tword [diffrence_y]   ; diffrence_y = (current drone y) - (target y)
	
	fld tword [diffrence_y]
	fld tword [diffrence_y]
	fmul
	fstp tword [diffrence_y_square]    ;diffrence_y_square = ((current drone y) - (target y))^2
	
    
	fld tword [target_coor_x]          
	fld tword [edi + x]
	fsub
	fstp tword [diffrence_x]       ; diffrence_x = (current drone x) - (target x)
	
	fld tword [diffrence_x]
	fld tword [diffrence_x]
	fmul
	fstp tword [diffrence_x_square]    ;diffrence_x_square = ((current drone x) - (target x))^2
	
	fld tword [diffrence_x_square]
	fld tword [diffrence_y_square]
	fadd                           ; ST(0) = (current drone x) - (target x))^2 + ((current drone y) - (target y))^2
	fsqrt                          ; ST(0) = SQRT ((current drone x) - (target x))^2 + ((current drone y) - (target y))^2 )

	fild dword [d]
	fcomip          
    jae cant_destroy     ; if d < current distance
    mov dword [mayDestroy_flag], 1
    jmp exit_mayDestroy
   
cant_destroy:

	mov dword [mayDestroy_flag], 0
	
exit_mayDestroy:	

	ffree
	END 0
	jmp after_call_mayDestroy
    
    
