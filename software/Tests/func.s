	.file	"func.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_zicsr2p0_zmmul1p0_zaamo1p0_zalrsc1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.conv,"ax",@progbits
	.align	2
	.globl	conv
	.type	conv, @function
conv:
	fcvt.s.w	fa5,a0
	fcvt.w.s a0,fa5,rtz
	ret
	.size	conv, .-conv
	.section	.text.reverse,"ax",@progbits
	.align	2
	.globl	reverse
	.type	reverse, @function
reverse:
	li	a5,1
	ble	a1,a5,.L3
	addi	a5,a0,-1
	add	a5,a5,a1
	li	a4,0
	addi	a1,a1,-1
.L5:
	lbu	a2,0(a5)
	lbu	a3,0(a0)
	addi	a4,a4,1
	sb	a2,0(a0)
	sb	a3,0(a5)
	sub	a3,a1,a4
	addi	a0,a0,1
	addi	a5,a5,-1
	blt	a4,a3,.L5
.L3:
	ret
	.size	reverse, .-reverse
	.section	.text.intToStr,"ax",@progbits
	.align	2
	.globl	intToStr
	.type	intToStr, @function
intToStr:
	mv	a4,a0
	beq	a0,zero,.L8
	li	t1,1717985280
	addi	t1,t1,1639
	li	a0,0
.L9:
	mulh	a5,a4,t1
	srai	a3,a4,31
	mv	a6,a0
	addi	a0,a0,1
	add	a7,a1,a0
	srai	a5,a5,2
	sub	a5,a5,a3
	slli	a3,a5,2
	add	a3,a3,a5
	slli	a3,a3,1
	sub	a4,a4,a3
	addi	a3,a4,48
	sb	a3,-1(a7)
	mv	a4,a5
	bne	a5,zero,.L9
	ble	a2,a0,.L13
.L11:
	sub	a5,a2,a0
	addi	t3,a5,-1
	slt	a6,a0,a2
	mv	t4,a0
	bge	a0,a2,.L14
	sltiu	a4,t3,6
	bne	a4,zero,.L14
	li	a4,1
	bne	a6,zero,.L42
.L16:
	neg	a3,a7
	andi	a5,a3,3
	mv	t1,a0
	beq	a5,zero,.L17
	li	t5,48
	andi	a3,a3,2
	sb	t5,0(a7)
	addi	t1,a0,1
	beq	a3,zero,.L17
	add	t1,a1,t1
	sb	t5,0(t1)
	addi	a3,a0,2
	li	a7,3
	mv	t1,a3
	bne	a5,a7,.L17
	add	a3,a1,a3
	sb	t5,0(a3)
	add	t1,a0,a5
.L17:
	sub	a7,a4,a5
	add	a5,a0,a5
	add	a5,a1,a5
	andi	a0,a7,-4
	li	a4,808464384
	add	a3,a5,a0
	addi	a4,a4,48
.L19:
	sw	a4,0(a5)
	addi	a5,a5,4
	bne	a5,a3,.L19
	beq	a7,a0,.L23
	add	a0,a0,t1
	add	a7,a1,a0
.L14:
	li	a5,48
	sb	a5,0(a7)
	addi	a4,a0,1
	bge	a4,a2,.L23
	add	a4,a1,a4
	sb	a5,0(a4)
	addi	a4,a0,2
	ble	a2,a4,.L23
	add	a4,a1,a4
	sb	a5,0(a4)
	addi	a4,a0,3
	ble	a2,a4,.L23
	add	a4,a1,a4
	sb	a5,0(a4)
	addi	a4,a0,4
	ble	a2,a4,.L23
	add	a4,a1,a4
	sb	a5,0(a4)
	addi	a0,a0,5
	ble	a2,a0,.L23
	add	a0,a1,a0
	sb	a5,0(a0)
.L23:
	neg	a6,a6
	and	a6,t3,a6
	add	a6,a6,t4
	addi	a0,a6,1
	add	a7,a1,a0
.L13:
	beq	a6,zero,.L12
	add	a4,a1,a6
	li	a5,0
.L25:
	lbu	a2,0(a4)
	lbu	a3,0(a1)
	addi	a5,a5,1
	sb	a2,0(a1)
	sb	a3,0(a4)
	sub	a3,a6,a5
	addi	a1,a1,1
	addi	a4,a4,-1
	blt	a5,a3,.L25
.L12:
	sb	zero,0(a7)
	ret
.L42:
	mv	a4,a5
	j	.L16
.L8:
	li	a0,0
	mv	a7,a1
	bgt	a2,zero,.L11
	j	.L12
	.size	intToStr, .-intToStr
	.ident	"GCC: (GNU) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
