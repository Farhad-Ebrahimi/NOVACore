	.file	"fadd_s.c"
	.option nopic
	.attribute arch, "rv32i2p1_m2p0_a2p1_f2p2_zicsr2p0_zmmul1p0_zaamo1p0_zalrsc1p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.section	.text.exception_handler,"ax",@progbits
	.align	2
	.globl	exception_handler
	.type	exception_handler, @function
exception_handler:
	li	a4,-2147483648
	addi	a4,a4,31
	li	a5,-2147483648
	and	a0,a0,a4
	addi	a5,a5,16
	beq	a0,a5,.L4
	ret
.L4:
	lw	a5,0(zero)
	ebreak
	.size	exception_handler, .-exception_handler
	.section	.text.test_fpu_logic_mul,"ax",@progbits
	.align	2
	.globl	test_fpu_logic_mul
	.type	test_fpu_logic_mul, @function
test_fpu_logic_mul:
	addi	sp,sp,-16
	li	a5,12
	sw	a5,8(sp)
	li	a5,4
	sw	a5,12(sp)
	lw	a4,8(sp)
	lw	a5,12(sp)
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	addi	sp,sp,16
	fmul.s	fa5,fa5,fa4
	fcvt.w.s a0,fa5,rtz
	jr	ra
	.size	test_fpu_logic_mul, .-test_fpu_logic_mul
	.section	.text.test_fpu_logic_add,"ax",@progbits
	.align	2
	.globl	test_fpu_logic_add
	.type	test_fpu_logic_add, @function
test_fpu_logic_add:
	addi	sp,sp,-16
	li	a5,2
	sw	a5,8(sp)
	li	a5,3
	sw	a5,12(sp)
	lw	a4,8(sp)
	lw	a5,12(sp)
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	addi	sp,sp,16
	fadd.s	fa5,fa5,fa4
	fcvt.w.s a0,fa5,rtz
	jr	ra
	.size	test_fpu_logic_add, .-test_fpu_logic_add
	.section	.text.test_fpu_logic_sub,"ax",@progbits
	.align	2
	.globl	test_fpu_logic_sub
	.type	test_fpu_logic_sub, @function
test_fpu_logic_sub:
	addi	sp,sp,-16
	li	a5,10
	sw	a5,8(sp)
	li	a5,1
	sw	a5,12(sp)
	lw	a4,8(sp)
	lw	a5,12(sp)
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	addi	sp,sp,16
	fsub.s	fa5,fa5,fa4
	fcvt.w.s a0,fa5,rtz
	jr	ra
	.size	test_fpu_logic_sub, .-test_fpu_logic_sub
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	li	a5,2
	sw	a5,40(sp)
	li	a5,3
	sw	a5,44(sp)
	lw	a4,40(sp)
	lw	a5,44(sp)
	li	a2,10
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	li	a3,1
	li	a4,12
	fadd.s	fa5,fa5,fa4
	li	a5,4
	fcvt.w.s a1,fa5,rtz
	sw	a1,12(sp)
	sw	a2,32(sp)
	sw	a3,36(sp)
	lw	a2,32(sp)
	lw	a3,36(sp)
	fcvt.s.w	fa5,a2
	fcvt.s.w	fa4,a3
	fsub.s	fa5,fa5,fa4
	fcvt.w.s a3,fa5,rtz
	sw	a3,16(sp)
	sw	a4,24(sp)
	sw	a5,28(sp)
	lw	a4,24(sp)
	lw	a5,28(sp)
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	fmul.s	fa5,fa5,fa4
	fcvt.w.s a5,fa5,rtz
	sw	a5,20(sp)
.L12:
	j	.L12
	.size	main, .-main
	.ident	"GCC: (GNU) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
