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

id equ 0
x equ 4
y equ 14
angle equ 24
score equ 34
speed equ 38

section .data
    global printer_function
	global pointer_printer
	
    extern CURR_ID
    extern pointer_drones_array
    extern CURR_ID
    extern pointer_schedular
    extern pointer_target
    extern pointer_printer
    extern target_coor_x
	extern target_coor_y
	extern N
	extern resume
	extern printf
section .rodata
	format_d_coma: db "%d ,",0 
	format_d: db "%d",0
    format_d_n: db "%d",10 ,0
	format_float_coma: db "%.2lf ," , 0
    format_float_n: db "%.2lf", 10 , 0
    format_s_n_n: db "%s" ,0
    str_n: db 0xa
    
    

section .text

	
printer_function:   
 
;prints targer coordinates
    finit
; printing x coordinate
    pushad
    fld tword[target_coor_x]
    sub esp,8
    fstp qword[esp]
    push format_float_coma
    call printf
    add esp,12
    popad

; printing y coordinate
    pushad
    fld tword[target_coor_y]
    sub esp,8
    fstp qword[esp]
    push format_float_n
    call printf
    add esp,12
    popad
    
    mov ecx, 0      ; counter
    mov edx, dword[pointer_drones_array]
    
print_drones_loop:

    cmp ecx, dword[N]
    je end_print
    
    push edx	; save edx not to be ruined by the mul
    mov eax, 48
    mul ecx     ; eax = counter * 48
    pop edx
    
    test1:	; check if the id is not -1
    cmp dword[edx + eax + id], -1
    je next_drone
    
; printing id
    pushad                
    push dword[edx + eax + id]
    push format_d_coma
    call printf
    add esp, 8
    popad

; printing x
    pushad      
    fld tword[edx + eax + x]
    sub esp,8
    fstp qword[esp]
    push format_float_coma
    call printf
    add esp, 12
    popad

; printing y
    pushad      
    fld tword[edx + eax + y]
    sub esp,8
    fstp qword[esp]
    push format_float_coma
    call printf
    add esp, 12
    popad

; printing angle
    pushad      
    fld tword[edx + eax + angle]
    sub esp,8
    fstp qword[esp]
    push format_float_coma
    call printf
    add esp, 12
    popad

; printing speed
    pushad      
    fld tword[edx + eax + speed]
    sub esp,8
    fstp qword[esp]
    push format_float_coma
    call printf
    add esp, 12
    popad

; printing score
    pushad                
    push dword dword[edx + eax + score]
    push format_d_n
    call printf
    add esp, 8
    popad
    
next_drone:
    inc ecx
    jmp print_drones_loop
      
end_print:
    ffree
    PRINT str_n, format_s_n_n
    
; switch to the schedular function
    mov ebx, pointer_schedular
    call resume
    jmp printer_function
