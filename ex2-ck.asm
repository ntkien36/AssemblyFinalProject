.eqv KEY_CODE 0xFFFF0004  # ASCII code to show, 1 byte 
.eqv KEY_READY 0xFFFF0000        # =1 if has a new keycode ?                                  
				# Auto clear after lw 
.eqv DISPLAY_CODE 0xFFFF000C # ASCII code to show, 1 byte 
.eqv DISPLAY_READY 0xFFFF0008  # =1 if the display has already to do                                  
				# Auto clear after sw 

.data
L :	.asciiz "a"
R : 	.asciiz "d"
U: 	.asciiz "w"
D: 	.asciiz "s"

.text	
	li $k0, KEY_CODE 	# chua ký tu nhap vao     
	li $k1, KEY_READY	# kiem tra da nhap phim nao chua  
	li $s2, DISPLAY_CODE	# hien thi ky tu  
	li $s1, DISPLAY_READY	# kiem tra xem man hinh da san sang hien thi chua

#Draw a circle in the center of the input pixel 
#a0 = x0
#a1 = y0
#a2 = color
#a3 = radius
.eqv YELLOW 0x00FFFF00
.eqv MONITOR_SCREEN 0x10010000
.text
li $v1, MONITOR_SCREEN
li $a0, 256
li $a1, 256
li $a3, 20
li $a2, YELLOW
addi	$s7, $0, 512			#store the width in s7
jal 	DrawCircle	
nop
moving:
	
	beq $t0,97,left
	beq $t0,100,right
	beq $t0,115,down
	beq $t0,119,up
	j Input
	left:
		li $a2,0x00000000
		jal DrawCircle
		addi $a0,$a0,-1
		add $a1,$a1, $0
		li $a2, YELLOW
		jal DrawCircle
		jal Pause
		bltu $a0,20,reboundRight
		j Input
	right: 
		li $a2,0x00000000
		jal DrawCircle
		addi $a0,$a0,1
		add $a1,$a1, $0
		li $a2, YELLOW
		jal DrawCircle
		jal Pause
		bgtu $a0,492,reboundLeft
		j Input
	up: 
		li $a2,0x00000000
		jal DrawCircle
		addi $a1,$a1,-1
		add $a0,$a0,$0
		li $a2, YELLOW
		jal DrawCircle
		jal Pause
		bltu $a1,20,reboundDown	
		j Input
	down: 
		li $a2,0x00000000
		jal DrawCircle
		addi $a1,$a1,1
		add $a0,$a0,$0
		li $a2, YELLOW
		jal DrawCircle
		jal Pause
		bgtu $a1,492,reboundUp	
		j Input
	reboundLeft:
		li $t3 97
		sw $t3,0($k0)
		j Input
	reboundRight:
		li $t3 100
		sw $t3,0($k0)
		j Input
	reboundDown:
		li $t3 115
		sw $t3,0($k0)
		j Input
	reboundUp:
		li $t3 119
		sw $t3,0($k0)
		j Input
endMoving:
Input:
	ReadKey: lw $t0, 0($k0) # $t0 = [$k0] = KEY_CODE
	j moving

Pause:
	addiu $sp,$sp,-4
	sw $a0, ($sp)
	la $a0,0		# speed =20ms
	li $v0, 32	 #syscall value for sleep
	syscall
	
	#addiu   $t1, $t1, 0xFE0408  # adjust background color (red -2, green +4, blue +8 + overflows (B -> G -> R)
    	#andi    $t1, $t1, 0xFFFFFF  # force "alpha" to zero
    
	lw $a0,($sp)
	addiu $sp,$sp,4
	jr $ra
	
	
DrawCircle:#Using Midpoint Circle Algorithm
    	#MAKE ROOM ON STACK
    	addi        $sp, $sp, -20       #Make room on stack for 1 words
   	sw      $ra, 0($sp)     #Store $ra on element 0 of stack
    	sw      $a0, 4($sp)     #Store $a0 on element 1 of stack
    	sw      $a1, 8($sp)     #Store $a1 on element 2 of stack
    	sw      $a2, 12($sp)        #Store $a2 on element 3 of stack
    	sw      $a3, 16($sp)        #Store $a3 on element 4 of stack

    	#VARIABLES
    	move        $t0, $a0            #x0
    	move        $t1, $a1            #y0
    	move        $t2, $a3            #radius
    	addi        $t3, $t2, 0 #-1            #x
    	li      $t4, 0              #y
    	li      $t5, 1              #dx
    	li      $t6, 1              #dy
    	li      $t7, 0              #Err

    	#CALCULATE ERR (dx - (radius << 1))
    	sll         $t8, $t2, 1         #Bitshift radius left 1 
    	subu        $t7, $t5, $t8           #Subtract dx - shifted radius 

    	#While(x >= y)
circleLoop:
    	blt         $t3, $t4, skipCircleLoop    #If x < y, skip circleLoop

	#s5 = a0, s6 = a1
    	#Draw Dot (x0 + x, y0 + y)
    	addu        $s5, $t0, $t3
    	addu        $s6, $t1, $t4
    	lw          $a2, 12($sp)
    	jal         drawDot             #Jump to drawDot

        #Draw Dot (x0 + y, y0 + x)
        addu        $s5, $t0, $t4
        addu        $s6, $t1, $t3
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

        #Draw Dot (x0 - y, y0 + x)
        subu        $s5, $t0, $t4
        addu        $s6, $t1, $t3
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

        #Draw Dot (x0 - x, y0 + y)
        subu        $s5, $t0, $t3
        addu        $s6, $t1, $t4
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

        #Draw Dot (x0 - x, y0 - y)
        subu        $s5, $t0, $t3
        subu        $s6, $t1, $t4
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

        #Draw Dot (x0 - y, y0 - x)
        subu        $s5, $t0, $t4
        subu        $s6, $t1, $t3
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

        #Draw Dot (x0 + y, y0 - x)
        addu        $s5, $t0, $t4
        subu        $s6, $t1, $t3
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

        #Draw Dot (x0 + x, y0 - y)
        addu        $s5, $t0, $t3
        subu        $s6, $t1, $t4
        lw      $a2, 12($sp)
        jal     drawDot             #Jump to drawDot

    	#If (err <= 0)
    	bgtz        $t7, doElse
    	addi        $t4, $t4, 1     #y++
    	addu        $t7, $t7, $t6       #err += dy
    	addi        $t6, $t6, 2     #dy += 2
    	j       circleContinue      #Skip else stmt

    	#Else If (err > 0)
    	doElse:
    	addi        $t3, $t3, -1        #x--
    	addi        $t5, $t5, 2     #dx += 2
    	sll     $t8, $t2, 1     #Bitshift radius left 1 
    	subu        $t9, $t5, $t8       #Subtract dx - shifted radius 
    	addu        $t7, $t7, $t9       #err += $t9
	j circleContinue
circleContinue:
    	#LOOP
    	j       circleLoop

    	#CONTINUE
    	skipCircleLoop:     

    	#RESTORE $RA
    	lw      $ra, 0($sp)     #Restore $ra from stack
    	addiu        $sp, $sp, 20        #Readjust stack
    	jr $ra
    	nop
drawDot:
    	#li $a2, YELLOW
    	add $at, $s6, $0
    	sll     $at, $at, 9        # calculate offset in $at: at = y_pos * 512
    	add     $at, $at, $s5       # at = y_pos * 512 + x_pos = "index"
    	sll     $at, $at, 2         # at = (y_pos * 512 + x_pos)*4 = "offset"
    	add     $at, $at, $v1       # at = v1 + offset
    	sw      $a2, ($at)          # draw it!
    	jr $ra
