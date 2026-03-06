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
	fcvt.w.s a5,fa5,rtz
	fcvt.s.w	fa0,a5
	jr	ra
	.size	test_fpu_logic_mul, .-test_fpu_logic_mul
	.section	.text.test_fpu_logic_add,"ax",@progbits
	.align	2
	.globl	test_fpu_logic_add
	.type	test_fpu_logic_add, @function
test_fpu_logic_add:
	fcvt.s.w	fa0,a0
	fcvt.s.w	fa5,a1
	fadd.s	fa0,fa0,fa5
	ret
	.size	test_fpu_logic_add, .-test_fpu_logic_add
	.section	.text.conv,"ax",@progbits
	.align	2
	.globl	conv
	.type	conv, @function
conv:
	fcvt.s.w	fa0,a0
	ret
	.size	conv, .-conv
	.section	.text.test_fpu_logic_add_1,"ax",@progbits
	.align	2
	.globl	test_fpu_logic_add_1
	.type	test_fpu_logic_add_1, @function
test_fpu_logic_add_1:
	addi	sp,sp,-16
	li	a5,20
	sw	a5,8(sp)
	li	a5,6
	sw	a5,12(sp)
	lw	a4,8(sp)
	lw	a5,12(sp)
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	addi	sp,sp,16
	fadd.s	fa5,fa5,fa4
	fcvt.w.s a0,fa5,rtz
	jr	ra
	.size	test_fpu_logic_add_1, .-test_fpu_logic_add_1
	.section	.text.test_fpu_logic_div,"ax",@progbits
	.align	2
	.globl	test_fpu_logic_div
	.type	test_fpu_logic_div, @function
test_fpu_logic_div:
	fcvt.s.w	fa5,a0
	fcvt.s.w	fa4,a1
	fdiv.s	fa5,fa5,fa4
	fcvt.w.s a0,fa5,rtz
	ret
	.size	test_fpu_logic_div, .-test_fpu_logic_div
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-48
	li	a5,2
	sw	a5,12(sp)
	li	a5,3
	sw	a5,16(sp)
	li	a5,20
	sw	a5,20(sp)
	li	a4,4
	sw	a4,24(sp)
	lw	a2,16(sp)
	lw	a3,12(sp)
	li	a4,6
	fcvt.s.w	fa5,a2
	fcvt.s.w	fa4,a3
	li	a0,0
	fdiv.s	fa5,fa5,fa4
	fcvt.w.s a3,fa5,rtz
	sw	a3,28(sp)
	lw	a2,20(sp)
	lw	a3,24(sp)
	fcvt.s.w	fa5,a2
	fcvt.s.w	fa4,a3
	fdiv.s	fa5,fa5,fa4
	fcvt.w.s a3,fa5,rtz
	sw	a3,32(sp)
	sw	a5,40(sp)
	sw	a4,44(sp)
	lw	a4,40(sp)
	lw	a5,44(sp)
	fcvt.s.w	fa5,a4
	fcvt.s.w	fa4,a5
	fadd.s	fa5,fa5,fa4
	fcvt.w.s a5,fa5,rtz
	sw	a5,36(sp)
	addi	sp,sp,48
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
