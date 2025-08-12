PDK_ROOT ?= ../../PDKs/IHP-Open-PDK/
PDK:=ihp-sg13g2
STDCELLS:=${PDK_ROOT}/${PDK}/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v
BLACKBOX_STDCELLS:=build/blackbox_stdcells.v
STDCELL_LEF:=${PDK_ROOT}/${PDK}/libs.ref/sg13g2_stdcell/lef/sg13g2_stdcell.lef
TECH_LEF:=${PDK_ROOT}/${PDK}/libs.ref/sg13g2_stdcell/lef/sg13g2_tech.lef
LYT_FILE:=${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/sg13g2.lyt
LYP_FILE:=${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/sg13g2.lyp
LYM_FILE:=${PDK_ROOT}/${PDK}/libs.tech/klayout/tech/sg13g2.map
STDCELL_GDS:=${PDK_ROOT}/${PDK}/libs.ref/sg13g2_stdcell/gds/sg13g2_stdcell.gds
STDCELL_CDL:=${PDK_ROOT}/${PDK}/libs.ref/sg13g2_stdcell/cdl/sg13g2_stdcell.cdl
MAGIC_RC:=${PDK_ROOT}/${PDK}/libs.tech/magic/ihp-sg13g2.magicrc
RCX_RULES:=./07-misc/IHP_rcx_patterns.rules

#GHDL:=ghdl
GHDL:=../../../ghdl/ghdl_mcode

VHDL_DESIGN_FILES:= ../src/aee_rom.vhd ../src/bpu.vhd ../src/Bin2Ter.vhd ../src/mul_stg3.vhd ../src/CSD_Adder.vhd ../src/CSD_Sub.vhd ../src/mul_stg2.vhd ../src/pp_types.vhd ../src/pp_constants.vhd ../src/pp_utilities.vhd ../src/pp_alu_control_unit.vhd ../src/pp_alu_mux.vhd ../src/pp_comparator.vhd ../src/pp_csr.vhd ../src/pp_control_unit.vhd ../src/pp_counter.vhd ../src/pp_csr_unit.vhd ../src/pp_register_file.vhd ../src/pp_fetch.vhd ../src/pp_imm_decoder.vhd ../src/pp_decode.vhd ../src/pp_csr_alu.vhd ../src/pp_execute.vhd ../src/pp_memory.vhd ../src/pp_writeback.vhd ../src/pp_core.vhd ../src/pp_icache.vhd ../src/pp_wb_adapter.vhd ../src/pp_wb_arbiter.vhd ../src/pp_novacore.vhd ../src/bw_alu.vhd ../src/csd_alu.vhd ../src/execution_stg1.vhd ../src/execution_stg2.vhd ../src/execution_stg3.vhd

IVERILOG?=iverilog
VVP?=vvp

define designname
$(shell echo $(1) | sed 's/^.*\///;s/\..*$$//')
endef

define tail
$(shell echo $(1) )
endef

export PDK_ROOT
export PDK
export RCX_RULES
export BLACKBOX_STDCELLS

.PHONY: clean sdf_sim

build/blackbox_stdcells.v: src/filter_stdcells.py
	@mkdir -p build
	./src/filter_stdcells.py < ${STDCELLS} > $@

build/01-synth/%.v: 01-synth/yosys-synth.tcl ${VDHL_DESIGN_FILES}
	@mkdir -p build/01-synth
	env DESIGN=$(call designname,$@) yosys -c $<

# Don't use sta since we have combinatorical loops here
build/02-sta/%.nl.v: 02-sta/sta.tcl build/01-synth/%.v
	@mkdir -p build/02-sta/sdf
	@mkdir -p build/02-sta/lib
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=1 sta -no_splash -exit $<

build/03-fp/%.odb build/03-fp/%.cdl build/03-fp/%.sdc build/03-fp/%.pnl.v build/03-fp/%.nl.v build/03-fp/%.def &: 03-fp/fp.tcl utils/base.sdc build/02-sta/%.nl.v utils/utils.tcl
	@mkdir -p build/03-fp
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=1 openroad -no_splash -exit $<

build/04-plc/%.odb build/04-plc/%.cdl build/04-plc/%.sdc build/04-plc/%.pnl.v build/04-plc/%.nl.v build/04-plc/%.def &: 04-plc/plc.tcl utils/base.sdc build/03-fp/%.odb utils/utils.tcl
	@mkdir -p build/04-plc
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=1 openroad -no_splash -exit $<

build/05-cts/%.odb build/05-cts/%.cdl build/05-cts/%.sdc build/05-cts/%.pnl.v build/05-cts/%.nl.v build/05-cts/%.def &: 05-cts/cts.tcl utils/base.sdc utils/utils.tcl build/04-plc/%.odb
	@mkdir -p build/05-cts
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=1 openroad -no_splash -exit $<

build/06-rt/%.odb build/06-rt/%.cdl build/06-rt/%.sdc build/06-rt/%.pnl.v build/06-rt/%.nl.v build/06-rt/%.def &: 06-rt/rt.tcl utils/base.sdc utils/utils.tcl build/05-cts/%.odb
	@mkdir -p build/06-rt
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=0 openroad -no_splash -exit $<

build/07-misc/%.gds: build/06-rt/%.def 07-misc/stream_out.py
	@mkdir -p build/07-misc
	./07-misc/stream_out.py $< \
		-o $@ \
		--input-lef ${STDCELL_LEF} \
		--input-lef ${TECH_LEF} \
		--lyt ${LYT_FILE} \
		--lyp ${LYP_FILE} \
		--lym ${LYM_FILE} \
		--with-gds-file ${STDCELL_GDS} \
		-t $(call designname,$@)

build/07-misc/%.cdl: build/06-rt/%.cdl ${STDCELL_CDL}
	@mkdir -p build/07-misc
	cat $^ > $@

build/07-misc/%.lvsdb: build/07-misc/%.gds build/07-misc/%.cdl
	@mkdir -p build/07-misc/lvs
	./07-misc/run_lvs.py --layout=$< --run_dir=build/07-lvs/ --netlist=$(filter-out $<,$^)

build/07-misc/%.spef: 07-misc/rcx.tcl
	@mkdir -p build/07-misc
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=0 openroad -no_splash -exit $<

build/%.spice: spcxtr/spcxtr.tcl build/%.gds
	@mkdir -p build/ext2spice
	env DESIGN=$(basename $(notdir $@)) magic -dnull -rcfile $(PDK_ROOT)/$(PDK)/libs.tech/magic/ihp-sg13g2.magicrc -noconsole -nowindow $<
	@cp build/ext2spice/$(basename $(notdir $@)).spice build

build/08-poststa/%.nl.v: 08-poststa/sta.tcl build/06-rt/%.nl.v
	@mkdir -p build/08-poststa/sdf
	@mkdir -p build/08-poststa/lib
	env DESIGN=$(call designname,$@) IDEAL_CLOCK=0 sta -no_splash -exit $<

clean:
	@rm -rf build

.SECONDARY:
