# Program for drawing an ellipse using the bresenham algorithm in BMP File by Jan Piotrowski

.data
message: .asciiz "Give the major axis and the minor axis of the ellipse\n"
message_error: .asciiz "Minor axis can't be greater then major axis!\n"
filename: .asciiz "C:/Users/janpi/OneDrive/Dokumenty/Mips/ellipse.bmp"
.align 2
header: .space 56


.text
#$s0 - width/height of image
#$s1 - width of image with excess (multiplies of 4)
#$s2 - address of the image buffer
#$s3 - address to the beginning of the file
#$s4 - the size of the entire image
#$s5 - the major axis of ellipse
#$s6 - the minor axis of ellipse


#Message display
	li $v0, 4
	la $a0, message
	syscall

#Loading the radius of the circle
	li $v0, 5 #major axis
	syscall
	move $s5, $v0
	li $v0, 5 #minor axis
	syscall
	move $s6, $v0
	blt $s5, $s6, program_ended_with_error #if major axis < minor axis


#Calculating image size 
	add $s0, $s5, $s5	#doubling major axis and write to $ s0
	addi $s0, $s0, 1	#adding 1 to diameter (middle pixel)
	
#Counting the excess - Rounding up the number of pixels to 4 (up)
	mul $s1, $s0, 3		#number of pixels in image width (3 pixels per bit)
	subi $s1, $s1, 1	#substract 1
	andi $s1, $s1, 0xfffffffc	#bitmask - an integer is formed by dividing $s1 by 4 or in other words AND (* 00) and $s1	
	addi $s1, $s1, 4	#Adding 4 to round to 4 

#Displaying with excess
	li $v0, 1
	add $a0, $s1, $zero
	syscall

#Preparing header
	la $t0, header		#getting an address to the header buffer, now in t0 is 56 bits
	li $t1, 0x42		#reparing the first character (resulting from the BMP documentation)
	sb $t1, 2($t0)		#write
	li $t1, 0x4D		#second char
	sb $t1, 3($t0)	

#Allocating memory to the image and writing the header
	mul $t1, $s0, $s1	#pixels needed for the entire image - (height) x (width with excess)
	add $s4, $t1, $zero	#remember value for later
	
	li $v0, 9		#allocate byte size (size)
	add $a0, $t1, $zero	
	syscall
	add $s2, $v0, $zero	#remember the address to the allocated memory in $ s2
	
	addi $t1, $t1, 54	#size of the entire file is the size of the image and the headline in $ t1
	sw $t1, 4($t0)		#enter the size of the entire file into the header

	li $t1, 54		#54 - data offset (header size)
	sw $t1, 12($t0)		
	li $t1, 40		#40 - length to end of header
	sw $t1, 16($t0)		
	add $t1, $s0, $zero	#copy image width / height
	sw $t1, 20($t0)		#width
	sw $t1, 24($t0)		#height
	li $t1, 1		#1 - number of layers of colors
	sw $t1, 28($t0)		
	li $t1, 24		#24 - number of bits per pixel (3 colors of 8 bits each)
	sb $t1, 30($t0)		

#Opening the file to write
	li $v0, 13		#opening a file
	la $a0, filename	#loading address into file name
	li $a1, 1		#1 - file to read
	li $a2, 0		#0 - flag
	syscall
	add $s3, $v0, $zero	#saving pointer to file in $ s3

#Saving header
	li $v0, 15		
	add $a0, $s3, $zero	#copy pointer to file
	la $a1, header+2	#start of recorded data
	li $a2, 54		#number of bits to save (header size)
	syscall

#Bresenham's algorithm for blue loop
	add $t0, $s5, $zero 	#coordinate X of ellipse center (X0) - equal to major axis
	move $t1, $t0		#coordinate Y of ellipse center (Y0) - equal to major axis
	mul $t2, $s5, $s5	#a^2
	mul $t3, $s6, $s6	#b^2
	sll $t4, $t3, 2		#4*b^2
	mul $t5, $s6, -4	#-4*b
	mul $t5, $t2, $t5	#-4*b*a^2
	add $t4, $t4, $t5	#4*b^2 - 4*b*a^2
	add $t4, $t4, $t2	#d = 4*b^2 - 4*b*a^2 + a^2

	mul $t5, $t3, 12	#deltaA = 12*b^2
	mul $t6, $t3, 3		#deltaB = 3*b^2
	mul $t7, $s6, -2	# -2b
	mul $t7, $t7, $t2	# -2b*a^2
	sll $t8, $t2, 1		# 2*a^2
	add $t6, $t6, $t7
	add $t6, $t6, $t8 	#3*b^2 - 2*b*a^2 + 2*a^2
	sll $t6, $t6, 2		#4*(3*b^2 - 2*b*a^2 + 2*a^2)

	move $s0, $t2		#change a^2 from $t2 to $s0
	move $s7, $t3		#change B^2 from $t3 to $s7
	move $t2, $t4		#change d from $t4 to $t2

	li $t3, 0		#coordinate X - actual
	move $t4, $s6		#coordinate Y - actual



loop_blue:
#Setting pixel colors:

#Set the color of 1st pixel
	sub $t7, $t0, $t3	# x0 - x
	sub $t8, $t1, $t4	# y0 - y
	mul $t7, $t7, 3		# *= 3 (3 pixels per point)
	mul $t8, $t8, $s1	# *= size_of_line (moving down)
	add $t7, $t7, $t8	#current pixel position
	add $t7, $t7, $s2	#the position of the pixel relative to the beginning of the file (Adding to the beginning of the file)
	li $v0, 0xff		#black
	sb $v0, ($t7)		#blue
	sb $v0, 1($t7)		#green
	sb $v0, 2($t7)		#red
#Set the color of 2nd pixel
	sub $t7, $t0, $t3	#x0 - x
	add $t8, $t1, $t4	#y0 + y
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
#Set the color of 3rd pixel
	add $t7, $t0, $t3	#x0 + x
	sub $t8, $t1, $t4 	#y0 - y
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
#Set the color of 4th pixel
	add $t7, $t0, $t3 	#x0 + x
	add $t8, $t1, $t4 	#y0 + y
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)

	#Break
	mul $t8, $s0, $s0	#a^2*a^2
	add $t7, $s0, $s7	#a^2 + b^2
	divu  $t8, $t8, $t7	#limit = (a2*a2)/(a2+b2)
	mul $t9, $t3, $t3
	blt $t8, $t9, red

	bgtz $t2, d0_blue	# d > 0
	# d <= 0
	add $t2, $t2, $t5	# d += deltaA
	addi $t3, $t3, 1	# x += 1
	sll $t9, $s7, 3		#4*2*b^2
	add $t5, $t5, $t9	# deltaA += 2*4*b^2
	add $t6, $t6, $t9	# deltaB += 2*4*b^2
	b move_blue

d0_blue:
# d > 0
	add $t2, $t2, $t6	#d += deltaB
	subi $t4, $t4, 1	#y -= 1
	addi $t3, $t3, 1	#x += 1
	
	sll $t9, $s7, 3		#4*2*b^2
	add $t5, $t5, $t9	#deltaA += 4*2*b^2
	sll $t8, $s0, 3		#4*2*a^2
	add $t8, $t8, $t9
	add $t6, $t6, $t8	#delta_B += 4*(2*b^2 + 2*a^2)
		
move_blue:
	b loop_blue			#jump to the next step
	
red:

	move $t9, $s5
	move $s5, $s6
	move $s6, $t9		#a:= b and b:= a

	mul $t2, $s5, $s5	#a^2
	mul $t3, $s6, $s6	#b^2
	sll $t4, $t3, 2		#4*b^2
	mul $t5, $s6, -4	#-4*b
	mul $t5, $t2, $t5	#-4*b*a^2
	add $t4, $t4, $t5	#4*b^2 - 4*b*a^2
	add $t4, $t4, $t2	#d = 4*b^2 - 4*b*a^2 + a^2

	mul $t5, $t3, 12	#deltaA = 12*b^2
	mul $t6, $t3, 3		#deltaB = 3*b^2
	mul $t7, $s6, -2	# -2b
	mul $t7, $t7, $t2	# -2b*a^2
	sll $t8, $t2, 1		# 2*a^2
	add $t6, $t6, $t7
	add $t6, $t6, $t8 	#3*b^2 - 2*b*a^2 + 2*a^2
	sll $t6, $t6, 2		#4*(3*b^2 - 2*b*a^2 + 2*a^2)

	move $s0, $t2		#change a^2 from $t2 to $s0
	move $s7, $t3		#change B^2 from $t3 to $s7
	move $t2, $t4		#change d from $t4 to $t2

	li $t3, 0		#coordinate X - actual
	move $t4, $s6		#coordinate Y - actual
	
loop_red:
#Setting pixel colors:

	#Set the color of 5th pixel
	sub $t7, $t0, $t4 	#x0 - y
	sub $t8, $t1, $t3 	#y0 - x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 6th pixel
	sub $t7, $t0, $t4 	#x0 - y
	add $t8, $t1, $t3 	#y0 + x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 7th pixel
	add $t7, $t0, $t4 	#x0 + y
	sub $t8, $t1, $t3 	#y0 - x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)
	#Set the color of 8th pixel
	add $t7, $t0, $t4 	#x0 + y
	add $t8, $t1, $t3 	#y0 + x
	mul $t7, $t7, 3 	# *= 3
	mul $t8, $t8, $s1 	# *= size_of_the_line
	add $t7, $t7, $t8
	add $t7, $t7, $s2
	li $v0, 0xff
	sb $v0, ($t7)
	sb $v0, 1($t7)
	sb $v0, 2($t7)

	#Break
	mul $t8, $s0, $s0	#a^2*a^2
	add $t7, $s0, $s7	#a^2 + b^2
	divu  $t8, $t8, $t7	#limit = (a2*a2)/(a2+b2)
	mul $t9, $t3, $t3
	blt $t8, $t9, end

	bgtz $t2, d0_red	# d > 0
	# d <= 0
	add $t2, $t2, $t5	# d += deltaA
	addi $t3, $t3, 1	# x += 1
	sll $t9, $s7, 3		#4*2*b^2
	add $t5, $t5, $t9	# deltaA += 2*4*b^2
	add $t6, $t6, $t9	# deltaB += 2*4*b^2
	b move_red

d0_red:
# d > 0
	add $t2, $t2, $t6	#d += deltaB
	subi $t4, $t4, 1	#y -= 1
	addi $t3, $t3, 1	#x += 1
	
	sll $t9, $s7, 3		#4*2*b^2
	add $t5, $t5, $t9	#deltaA += 4*2*b^2
	sll $t8, $s0, 3		#4*2*a^2
	add $t8, $t8, $t9
	add $t6, $t6, $t8	#delta_B += 4*(2*b^2 + 2*a^2)
		
move_red:
	b loop_red			#jump to the next step
end:
#Saving the rest of the file
	li $v0, 15		#save
	add $a0, $s3, $zero	#copy pointer to file
	add $a1, $s2, $zero	#copy address of buffer
	add $a2, $s4, $zero	#copy number of image pixels
	syscall
#Closing
	li $v0, 16		
	add $a0, $s3, $zero	#copy pointer to file
	syscall
#Finish the program
	li $v0, 10		
	syscall


program_ended_with_error:
	li $v0, 4
	la $a0, message_error
	syscall
	
li $v0, 10
syscall
