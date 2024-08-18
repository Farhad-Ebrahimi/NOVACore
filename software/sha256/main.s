	.file	"main.c"
	.option nopic
	.attribute arch, "rv32i2p1_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.globl	__udivsi3
	.globl	__divsi3
	.globl	__umodsi3
	.globl	__modsi3
	.section	.rodata.exception_handler.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	" H/s\n\r"
	.align	2
.LC1:
	.string	"Bus error!\n\r"
	.section	.text.exception_handler,"ax",@progbits
	.align	2
	.globl	exception_handler
	.type	exception_handler, @function
exception_handler:
	blt	a0,zero,.L109
.L104:
	ret
.L109:
	andi	a5,a0,16
	beq	a5,zero,.L104
	andi	a0,a0,15
	li	a5,1
	beq	a0,a5,.L3
	li	a4,4
	beq	a0,a4,.L4
	bne	a0,zero,.L5
	addi	sp,sp,-32
	lui	a5,%hi(hashes_per_second)
	sw	s0,24(sp)
	lw	s0,%lo(hashes_per_second)(a5)
	sw	ra,28(sp)
	beq	s0,zero,.L110
	sw	s1,20(sp)
	addi	s1,sp,4
	bge	s0,zero,.L8
	li	a5,45
	neg	s0,s0
	sb	a5,4(sp)
	addi	s1,sp,5
.L8:
	li	a1,1000001536
	addi	a1,a1,-1536
	mv	a0,s0
	call	__divsi3
	beq	a0,zero,.L9
	addi	a0,a0,48
	li	a1,1000001536
	sb	a0,0(s1)
	addi	a1,a1,-1536
	mv	a0,s0
	call	__modsi3
	li	a1,99999744
	addi	a1,a1,256
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L10
	addi	s1,s1,1
.L11:
	addi	a0,a0,48
	li	a1,99999744
	sb	a0,0(s1)
	addi	a1,a1,256
	mv	a0,s0
	call	__modsi3
	li	a1,9998336
	addi	a1,a1,1664
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	bne	a0,zero,.L14
.L13:
	li	a1,999424
	li	a5,48
	sb	a5,0(s1)
	addi	a1,a1,576
	mv	a0,s0
	addi	s1,s1,1
	call	__divsi3
	bne	a0,zero,.L17
.L16:
	li	a1,98304
	li	a5,48
	sb	a5,0(s1)
	addi	a1,a1,1696
	mv	a0,s0
	addi	s1,s1,1
	call	__divsi3
	bne	a0,zero,.L20
.L19:
	li	a1,8192
	li	a5,48
	sb	a5,0(s1)
	addi	a1,a1,1808
	mv	a0,s0
	addi	s1,s1,1
	call	__divsi3
	bne	a0,zero,.L23
.L22:
	li	a5,48
	sb	a5,0(s1)
	li	a1,1000
	mv	a0,s0
	addi	s1,s1,1
	call	__divsi3
	bne	a0,zero,.L26
.L25:
	li	a5,48
	sb	a5,0(s1)
	li	a1,100
	mv	a0,s0
	addi	s1,s1,1
	call	__divsi3
	bne	a0,zero,.L29
.L28:
	li	a5,48
	sb	a5,0(s1)
	li	a1,10
	mv	a0,s0
	addi	s1,s1,1
	call	__divsi3
	bne	a0,zero,.L32
.L31:
	li	a5,48
	sb	a5,0(s1)
	addi	s1,s1,1
	bne	s0,zero,.L33
.L34:
	li	a4,48
	addi	a5,s1,1
	sb	a4,0(s1)
.L35:
	sb	zero,0(a5)
	lbu	a3,4(sp)
	lui	a5,%hi(uart0)
	lw	a4,%lo(uart0)(a5)
	lw	s1,20(sp)
	beq	a3,zero,.L39
.L7:
	addi	a2,sp,5
.L37:
	lw	a5,8(a4)
	andi	a5,a5,8
	bne	a5,zero,.L37
	addi	a2,a2,1
	sw	a3,0(a4)
	lbu	a3,-1(a2)
	bne	a3,zero,.L37
.L39:
	lui	a3,%hi(.LC0+1)
	addi	a3,a3,%lo(.LC0+1)
	li	a2,32
.L40:
	lw	a5,8(a4)
	andi	a5,a5,8
	bne	a5,zero,.L40
	addi	a3,a3,1
	sw	a2,0(a4)
	lbu	a2,-1(a3)
	bne	a2,zero,.L40
	lui	a5,%hi(timer0)
	lw	a4,%lo(timer0)(a5)
	li	a3,1
	lui	a5,%hi(reset_counter)
	sb	a3,%lo(reset_counter)(a5)
	lw	a5,0(a4)
	lw	ra,28(sp)
	lw	s0,24(sp)
	ori	a5,a5,2
	sw	a5,0(a4)
	addi	sp,sp,32
	jr	ra
.L3:
	lui	a0,%hi(led_status)
	lbu	a4,%lo(led_status)(a0)
	srli	a4,a4,1
	andi	a5,a4,15
	mv	a6,a4
	beq	a5,zero,.L111
.L41:
	lui	a5,%hi(gpio0)
	lw	a3,%lo(gpio0)(a5)
	li	a2,4096
	lui	a1,%hi(timer1)
	lw	a5,0(a3)
	lw	a7,0(a3)
	lw	a1,%lo(timer1)(a1)
	srli	a5,a5,4
	and	a5,a5,a6
	or	a5,a5,a7
	slli	a5,a5,8
	addi	a2,a2,-256
	and	a5,a5,a2
	sw	a5,4(a3)
	lw	a5,0(a1)
	sb	a4,%lo(led_status)(a0)
	ori	a5,a5,2
	sw	a5,0(a1)
	ret
.L5:
	addi	a0,a0,24
	sll	a5,a5,a0
 #APP
# 90 "../../potato.h" 1
	csrc mie, a5

# 0 "" 2
 #NO_APP
	ret
.L4:
	lui	a5,%hi(uart0)
	lw	a4,%lo(uart0)(a5)
	lui	a3,%hi(.LC1+1)
	addi	a3,a3,%lo(.LC1+1)
	li	a2,66
.L42:
	lw	a5,8(a4)
	andi	a5,a5,8
	bne	a5,zero,.L42
	addi	a3,a3,1
	sw	a2,0(a4)
	lbu	a2,-1(a3)
	bne	a2,zero,.L42
	lw	a5,0(zero)
	ebreak
.L111:
	li	a4,8
	li	a6,8
	j	.L41
.L110:
	lui	a5,%hi(uart0)
	lw	a4,%lo(uart0)(a5)
	li	a5,48
	sh	a5,4(sp)
	li	a3,48
	j	.L7
.L9:
	li	a1,99999744
	addi	a1,a1,256
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L11
	li	a1,9998336
	addi	a1,a1,1664
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L14
	li	a1,999424
	addi	a1,a1,576
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L17
	li	a1,98304
	addi	a1,a1,1696
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L20
	li	a1,8192
	addi	a1,a1,1808
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L23
	li	a1,1000
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L26
	li	a1,100
	mv	a0,s0
	call	__divsi3
	bne	a0,zero,.L29
	li	a1,10
	mv	a0,s0
	call	__divsi3
	beq	a0,zero,.L33
.L32:
	addi	a0,a0,48
	sb	a0,0(s1)
	li	a1,10
	mv	a0,s0
	call	__modsi3
	addi	s1,s1,1
	mv	s0,a0
	beq	a0,zero,.L34
.L33:
	addi	s0,s0,48
	addi	a5,s1,1
	sb	s0,0(s1)
	j	.L35
.L10:
	li	a1,9998336
	li	a5,48
	sb	a5,1(s1)
	addi	a1,a1,1664
	mv	a0,s0
	addi	s1,s1,2
	call	__divsi3
	beq	a0,zero,.L13
.L14:
	addi	a0,a0,48
	li	a1,9998336
	sb	a0,0(s1)
	addi	a1,a1,1664
	mv	a0,s0
	call	__modsi3
	li	a1,999424
	addi	a1,a1,576
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L16
.L17:
	addi	a0,a0,48
	li	a1,999424
	sb	a0,0(s1)
	addi	a1,a1,576
	mv	a0,s0
	call	__modsi3
	li	a1,98304
	addi	a1,a1,1696
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L19
.L20:
	addi	a0,a0,48
	li	a1,98304
	sb	a0,0(s1)
	addi	a1,a1,1696
	mv	a0,s0
	call	__modsi3
	li	a1,8192
	addi	a1,a1,1808
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L22
.L23:
	addi	a0,a0,48
	li	a1,8192
	sb	a0,0(s1)
	addi	a1,a1,1808
	mv	a0,s0
	call	__modsi3
	li	a1,1000
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L25
.L26:
	addi	a0,a0,48
	sb	a0,0(s1)
	li	a1,1000
	mv	a0,s0
	call	__modsi3
	li	a1,100
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L28
.L29:
	addi	a0,a0,48
	sb	a0,0(s1)
	li	a1,100
	mv	a0,s0
	call	__modsi3
	li	a1,10
	addi	s1,s1,1
	mv	s0,a0
	call	__divsi3
	beq	a0,zero,.L31
	j	.L32
	.size	exception_handler, .-exception_handler
	.section	.rodata.main.str1.4,"aMS",@progbits,1
	.align	2
.LC2:
	.string	"--- SHA256 Benchmark Application ---\r\n\n"
	.align	2
.LC3:
	.string	"Beginning...\n\r"
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-160
	li	a5,-1073725440
	lui	a3,%hi(gpio0)
	li	a4,4096
	sw	a5,%lo(gpio0)(a3)
	sw	s0,152(sp)
	sw	ra,156(sp)
	sw	s1,148(sp)
	sw	s2,144(sp)
	sw	s3,140(sp)
	addi	a4,a4,-256
	sw	a4,8(a5)
	li	a4,256
	sw	a4,4(a5)
	lui	s0,%hi(uart0)
	li	a5,-1073733632
	li	a4,50
	sw	a5,%lo(uart0)(s0)
	lui	a3,%hi(.LC2+1)
	sw	a4,12(a5)
	addi	a3,a3,%lo(.LC2+1)
	li	a2,45
	li	a4,-1073733632
.L113:
	lw	a5,8(a4)
	andi	a5,a5,8
	bne	a5,zero,.L113
	sw	a2,0(a4)
	lbu	a2,0(a3)
	addi	a3,a3,1
	bne	a2,zero,.L113
	li	a5,-1073741824
	lui	a4,%hi(timer0)
	sw	a5,%lo(timer0)(a4)
	li	a2,2
	li	a4,95498240
	sw	a2,0(a5)
	addi	a4,a4,1760
	sw	a4,4(a5)
	li	a3,3
	sw	a3,0(a5)
	lui	a4,%hi(timer1)
	li	a5,-1073737728
	sw	a5,%lo(timer1)(a4)
	li	a4,23875584
	sw	a2,0(a5)
	addi	a4,a4,-584
	sw	a4,4(a5)
	sw	a3,0(a5)
	li	a5,16777216
 #APP
# 78 "../../potato.h" 1
	csrs mie, a5

# 0 "" 2
 #NO_APP
	li	a5,33554432
 #APP
# 78 "../../potato.h" 1
	csrs mie, a5

# 0 "" 2
 #NO_APP
	li	a5,268435456
 #APP
# 78 "../../potato.h" 1
	csrs mie, a5

# 0 "" 2
# 149 "main.c" 1
	csrsi mstatus, 1 << 3

# 0 "" 2
 #NO_APP
	li	a5,24576
	addi	a5,a5,609
	li	a2,3
	li	a3,0
	sh	a5,64(sp)
	li	a1,3
	li	a5,99
	addi	a0,sp,64
	sb	a5,66(sp)
	call	sha256_pad_le_block
	lw	a4,%lo(uart0)(s0)
	lui	a3,%hi(.LC3+1)
	addi	a3,a3,%lo(.LC3+1)
	li	a2,66
.L115:
	lw	a5,8(a4)
	andi	a5,a5,8
	bne	a5,zero,.L115
	addi	a3,a3,1
	sw	a2,0(a4)
	lbu	a2,-1(a3)
	bne	a2,zero,.L115
	lui	s1,%hi(reset_counter)
	lui	s0,%hi(hashes_per_second)
	li	s2,136
	li	s3,1
	j	.L119
.L125:
	sw	s3,%lo(hashes_per_second)(s0)
	sb	zero,%lo(reset_counter)(s1)
.L118:
 #APP
# 176 "main.c" 1
	csrsi mstatus, 1 << 3

# 0 "" 2
 #NO_APP
.L119:
	mv	a0,sp
	call	sha256_reset
	addi	a1,sp,64
	mv	a0,sp
	call	sha256_hash_block
	addi	a1,sp,32
	mv	a0,sp
	call	sha256_get_hash
 #APP
# 169 "main.c" 1
	csrc mstatus, s2

# 0 "" 2
 #NO_APP
	lbu	a5,%lo(reset_counter)(s1)
	bne	a5,zero,.L125
	lw	a5,%lo(hashes_per_second)(s0)
	addi	a5,a5,1
	sw	a5,%lo(hashes_per_second)(s0)
	j	.L118
	.size	main, .-main
	.section	.sdata.reset_counter,"aw"
	.type	reset_counter, @object
	.size	reset_counter, 1
reset_counter:
	.byte	1
	.section	.sbss.hashes_per_second,"aw",@nobits
	.align	2
	.type	hashes_per_second, @object
	.size	hashes_per_second, 4
hashes_per_second:
	.zero	4
	.section	.sdata.led_status,"aw"
	.type	led_status, @object
	.size	led_status, 1
led_status:
	.byte	1
	.section	.sbss.timer1,"aw",@nobits
	.align	2
	.type	timer1, @object
	.size	timer1, 4
timer1:
	.zero	4
	.section	.sbss.timer0,"aw",@nobits
	.align	2
	.type	timer0, @object
	.size	timer0, 4
timer0:
	.zero	4
	.section	.sbss.uart0,"aw",@nobits
	.align	2
	.type	uart0, @object
	.size	uart0, 4
uart0:
	.zero	4
	.section	.sbss.gpio0,"aw",@nobits
	.align	2
	.type	gpio0, @object
	.size	gpio0, 4
gpio0:
	.zero	4
	.ident	"GCC: (gc891d8dc23e) 13.2.0"
