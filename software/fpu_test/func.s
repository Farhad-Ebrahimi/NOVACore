	.file	"func.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_f2p2_zicsr2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.mul,"ax",@progbits
	.align	2
	.globl	mul
	.type	mul, @function
mul:
	fmv.w.x	fa5,a0
	fmv.w.x	fa4,a1
	fmul.s	fa5,fa5,fa4
	fmv.x.w	a0,fa5
	ret
	.size	mul, .-mul
	.section	.text.reverse,"ax",@progbits
	.align	2
	.globl	reverse
	.type	reverse, @function
reverse:
	addi	a1,a1,-1
	li	a5,0
.L3:
	blt	a5,a1,.L4
	ret
.L4:
	add	a4,a0,a1
	add	a3,a0,a5
	lbu	a6,0(a4)
	lbu	a2,0(a3)
	addi	a5,a5,1
	sb	a6,0(a3)
	sb	a2,0(a4)
	addi	a1,a1,-1
	j	.L3
	.size	reverse, .-reverse
	.globl	__umodsi3
	.globl	__modsi3
	.globl	__udivsi3
	.globl	__divsi3
	.section	.text.int_to_str,"ax",@progbits
	.align	2
	.globl	int_to_str
	.type	int_to_str, @function
int_to_str:
	addi	sp,sp,-32
	sw	s1,20(sp)
	sw	s2,16(sp)
	sw	s3,12(sp)
	sw	s4,8(sp)
	sw	ra,28(sp)
	sw	s0,24(sp)
	sw	s5,4(sp)
	mv	s1,a0
	mv	s2,a1
	mv	s3,a2
	li	s4,0
	bge	a0,zero,.L6
	neg	s1,a0
	li	s4,1
.L6:
	li	s0,0
	j	.L7
.L8:
	li	a1,10
	mv	a0,s1
	call	__modsi3
	add	s5,s2,s0
	addi	a0,a0,48
	sb	a0,0(s5)
	li	a1,10
	mv	a0,s1
	call	__divsi3
	mv	s1,a0
	addi	s0,s0,1
.L7:
	bne	s1,zero,.L8
	mv	a5,s0
	li	a4,48
.L9:
	bgt	s3,a5,.L10
	sub	a4,s3,s0
	li	s1,0
	bgt	s0,s3,.L12
	mv	s1,a4
.L12:
	add	s1,s1,s0
	beq	s4,zero,.L13
	addi	s1,s1,1
	li	a5,0
	bgt	s0,s3,.L15
	mv	a5,a4
.L15:
	add	s0,s2,s0
	add	s0,s0,a5
	li	a5,45
	sb	a5,0(s0)
.L13:
	mv	a0,s2
	mv	a1,s1
	add	s2,s2,s1
	call	reverse
	sb	zero,0(s2)
	lw	ra,28(sp)
	lw	s0,24(sp)
	lw	s2,16(sp)
	lw	s3,12(sp)
	lw	s4,8(sp)
	lw	s5,4(sp)
	mv	a0,s1
	lw	s1,20(sp)
	addi	sp,sp,32
	jr	ra
.L10:
	add	a3,s2,a5
	sb	a4,0(a3)
	addi	a5,a5,1
	j	.L9
	.size	int_to_str, .-int_to_str
	.section	.text.fp2str,"ax",@progbits
	.align	2
	.globl	fp2str
	.type	fp2str, @function
fp2str:
	fmv.w.x	fa5,a0
	addi	sp,sp,-32
	sw	s1,24(sp)
	fcvt.w.s a0,fa5,rtz
	sw	ra,28(sp)
	mv	s1,a2
	fcvt.s.w	fa4,a0
	fsub.s	fa5,fa5,fa4
	fmv.w.x	fa4,zero
	flt.s	a5,fa5,fa4
	beq	a5,zero,.L23
	fneg.s	fa5,fa5
.L23:
	li	a2,0
	fsw	fa5,12(sp)
	sw	a1,8(sp)
	call	int_to_str
	beq	s1,zero,.L22
	lw	a1,8(sp)
	li	a4,46
	flw	fa5,12(sp)
	add	a5,a1,a0
	sb	a4,0(a5)
	lui	a4,%hi(.LC0)
	flw	fa4,%lo(.LC0)(a4)
	lui	a4,%hi(.LC1)
	flw	fa3,%lo(.LC1)(a4)
	li	a5,0
.L26:
	blt	a5,s1,.L27
	fmul.s	fa5,fa5,fa4
	lui	a5,%hi(.LC2)
	flw	fa4,%lo(.LC2)(a5)
	addi	a0,a0,1
	lw	ra,28(sp)
	fadd.s	fa5,fa5,fa4
	mv	a2,s1
	add	a1,a1,a0
	lw	s1,24(sp)
	fcvt.w.s a0,fa5,rtz
	addi	sp,sp,32
	tail	int_to_str
.L27:
	fmul.s	fa4,fa4,fa3
	addi	a5,a5,1
	j	.L26
.L22:
	lw	ra,28(sp)
	lw	s1,24(sp)
	addi	sp,sp,32
	jr	ra
	.size	fp2str, .-fp2str
	.section	.srodata.cst4,"aM",@progbits,4
	.align	2
.LC0:
	.word	1065353216
	.align	2
.LC1:
	.word	1092616192
	.align	2
.LC2:
	.word	1056964608
	.ident	"GCC: (g1ea978e3066) 12.1.0"
