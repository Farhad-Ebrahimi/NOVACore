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
	.section	.text.startup.main,"ax",@progbits
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	li	a5,2
	sw	a5,0(sp)
	li	a5,3
	sw	a5,4(sp)
	lw	a5,4(sp)
	fcvt.s.w	fa5,a5
	fsw	fa5,8(sp)
	lw	a4,0(sp)
	lw	a5,4(sp)
	fcvt.s.w	fa4,a4
	fcvt.s.w	fa5,a5
	fadd.s	fa5,fa5,fa4
	fsw	fa5,12(sp)
	flw	fa4,12(sp)
	flw	fa5,8(sp)
	fgt.s	a5,fa4,fa5
	beq	a5,zero,.L12
	li	a5,10
	sw	a5,16(sp)
	lw	a5,16(sp)
	fcvt.s.w	fa5,a5
	fsw	fa5,20(sp)
	flw	fa5,20(sp)
	flw	fa4,12(sp)
	fmul.s	fa5,fa5,fa4
	fsw	fa5,24(sp)
.L13:
	j	.L13
.L12:
	flw	fa5,12(sp)
	fcvt.w.s a5,fa5,rtz
	sw	a5,28(sp)
	j	.L13
	.size	main, .-main
	.ident	"GCC: (GNU) 15.1.0"
	.section	.note.GNU-stack,"",@progbits
