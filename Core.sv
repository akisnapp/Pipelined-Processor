//***********************************************************
// ECE 3058 Architecture Concurrency and Energy in Computation
//
// RISCV Processor System Verilog Behavioral Model
//
// School of Electrical & Computer Engineering
// Georgia Institute of Technology
// Atlanta, GA 30332
//
//  Functionality:
//      Core Unit for the 5 Stage RISVC Processor
//
//***********************************************************

import CORE_PKG::*;

module Core (
	// Input signals
	input logic clock,
	input logic reset,
	input logic mem_en
);

	localparam INSTR_START_PC = 0;
	localparam DATA_START_PC = 127; 										// address that separates instruction from data

	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	// Signals and outputs
	//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	logic mem_gnt_req;																	// Memory is ready to inputs. Sent to inputs of Fetch and LSU 	

	// Fetch Instruction Signals
	logic [31:0] next_instr_addr; 											// PC + 4
	logic [31:0] instr_mem_data;												// instruction that memory loads out
	logic instr_mem_valid;															// validity of instruction loaded out

	// Decode signals 
	pc_mux pc_mux_select;
	logic [31:0] pc_branch_offset;

	// Load/Store Mem Signals
	logic [31:0] DRAM_wdata;
	logic [31:0] DRAM_load_mem_data;										// data from DRAM after a load to sent to LSU for sign extensions and such
	logic [31:0] load_mem_data; 												// data from LSU to Decode after a load instr.
	logic mem_data_req_valid;														// Validity of request sent to mem for store/load

	// ALU Signals 
	alu_opcode_e alu_operator;													// operation that ALU should perform
	logic [31:0] alu_operand_a;													// alu src register 1
	logic [31:0] alu_operand_b;													// alu src register 2
	logic [31:0] alu_result;														// result of the ALU operation
	logic [31:0] alu_next_pc_addr;											// result of the ALU but forwarded immediately to Fetch so skip CLK
	logic alu_next_pc_addr_valid;
	logic alu_valid;																		// if the result of the ALU operation is valid
	logic alu_en;																				// enable the ALU
	logic [31:0] wb_alu_result;													// Pass through signal of ALU result through the Mem Stage

	// Forwarded Signal from ID to EX
	load_store_func_code id_lsu_operator_pt;
	logic id_lsu_en_pt;

	logic ex_lsu_en;
	load_store_func_code ex_lsu_operator;
	logic [31:0] ex_DRAM_wdata;

	// Writeback Mux Pass Through Signals
	write_back_mux_selector id_wb_mux_op;
	write_back_mux_selector ex_wb_mux_pt;
	write_back_mux_selector lsu_wb_mux_pt;

	// ALU Result pass through
	logic [31:0] ex_alu_result_pt;
	logic ex_alu_result_valid_pt;
	logic [31:0] lsu_alu_result_pt;
	logic lsu_alu_result_valid_pt;

	// Valid Data Addr to fetch from Memory from LSU to DRAM
	logic valid_mem_data_addr;

	// Write Reg Address Passthrough Signals
	logic [4:0] id_write_addr_reg_op;
	logic [4:0] ex_write_addr_reg_op;
	logic [4:0] lsu_write_addr_reg_op;

	logic [6:0] fwd_instr_opcode;
	logic [4:0] fwd_src1_reg_addr;
	logic [4:0] fwd_src2_reg_addr;

	logic [31:0] if_instr_pc_addr;
	logic [31:0] id_instr_pc_addr_pt;
	logic [31:0] ex_instr_pc_addr_pt;
	logic [31:0] lsu_instr_pc_addr_pt;

	logic [31:0] id_uimmd_pt;
	logic [31:0] ex_uimmd_pt;
	logic [31:0] lsu_uimmd_pt;

	logic [31:0] writeback_data;
	logic writeback_data_valid;

	// Foward Mux Signals
	forward_mux_code FA;
	forward_mux_code FB;

	// Stall signal propogated to relevant modules
	logic stall;
	logic flush;  // I ADDED THIS

	IF_Stage InstructionFetch_Module (
		// General Inputs
		.clock(clock),
		.reset(reset),
		.mem_en(mem_en),
		.instr_gnt_ip(mem_gnt_req),

		// Inputs from Decode
		.pc_mux_ip(pc_mux_select),
		.stall_ip(stall),
		.flush_ip(flush),

		// Inputs from EX of possible new PC 
		.alu_result_ip(alu_next_pc_addr),
		.alu_result_valid_ip(alu_next_pc_addr_valid),

		// Outputs to Decode
		.instr_valid_op(instr_mem_valid),
		.instr_data_op(instr_mem_data),
		.instr_pc_addr_op(if_instr_pc_addr)
	);

	ID_Stage InstructionDecode_Module (

		// General Inputs
		.clock(clock),
		.reset(reset),
		.pc(if_instr_pc_addr),
		.pc4(next_instr_addr),

		// Inputs from MEM
		.instr_data_valid_ip(instr_mem_valid),
		.instr_data_ip(instr_mem_data),
		.mem_dest_reg_ip(ex_write_addr_reg_op),

		.write_reg_addr_ip(lsu_write_addr_reg_op),
		.wb_data_ip(writeback_data),
  	.wb_data_valid_ip(writeback_data_valid),

		// Outputs to ALU and Comparator
		.alu_operator_op(alu_operator),
		.alu_en_op(alu_en),
		.alu_operand_a_ex_op(alu_operand_a),
		.alu_operand_b_ex_op(alu_operand_b),

		// Pass through writeback signal
		.write_reg_addr_op(id_write_addr_reg_op),
		.wb_mux_op(id_wb_mux_op),
		.id_pc_addr_pt_op(id_instr_pc_addr_pt),
		.id_uimmd_pt_op(id_uimmd_pt),

		// Outputs to LSU
		.en_lsu_op(id_lsu_en_pt),
		.lsu_operator_op(id_lsu_operator_pt),

		// Outputs to MEM	
		.mem_wdata_op(DRAM_wdata),

		.EX_instruction_opcode(fwd_instr_opcode),
		.ID_src1_reg_addr(fwd_src1_reg_addr),
		.ID_src2_reg_addr(fwd_src2_reg_addr),

		// Outputs to Fetch
		.pc_branch_offset_op(pc_branch_offset),
		.pc_mux_op(pc_mux_select),

		.stall_op(stall),
		.flush_op(flush)
	);

	FWD_Control ForwardController_Module (
		.reset(reset), 

		// Input from decode stage
		.id_instr_opcode_ip(fwd_instr_opcode),

		.EX_MEM_wb_mux_ip(ex_wb_mux_pt),
		.MEM_WB_wb_mux_ip(lsu_wb_mux_pt),

		.EX_MEM_dest_ip(ex_write_addr_reg_op), // EX/MEM Dest Register
		.MEM_WB_dest_ip(lsu_write_addr_reg_op), // MEM/WB Dest Register
		.ID_dest_rs1_ip(fwd_src1_reg_addr), // Rs from decode stage
		.ID_dest_rs2_ip(fwd_src2_reg_addr), // Rt from decode stage

		// Outputs to Execute Unit
		.fa_mux_op(FA), //select lines for forwarding muxes (Rs)
		.fb_mux_op(FB)  //select lines for forwarding muxes (Rt)
	);

	EX_Stage InstructionExecute_Module (
		.clock(clock), 
		.reset(reset), 

		// Inputs from Decode for ALU
		.alu_enable_ip(alu_en),
		.alu_operator_ip(alu_operator),
		.alu_operand_a_ip(alu_operand_a),
		.alu_operand_b_ip(alu_operand_b),

		// Signals from Forw Controller
		.fa_mux_ip(FA),
		.fb_mux_ip(FB),
		.fw_wb_data(writeback_data),

		// Pass-Through Signals to Memory
		.lsu_enable_pt_ip(id_lsu_en_pt),
		.ex_lsu_operator_pt_ip(id_lsu_operator_pt), 
		.mem_wdata_pt_ip(DRAM_wdata),
		.ex_wb_mux_ip(id_wb_mux_op),
		.ex_write_reg_addr_pt_ip(id_write_addr_reg_op),
		.ex_pc_addr_pt_ip(id_instr_pc_addr_pt),
		.ex_uimmd_pt_ip(id_uimmd_pt),

		// Pass-Through to Fetch based on Flush Controller and Writeback
		.pc_mux_ip(pc_mux_select),
		// pc_branch offset to calculate branch address if 
		.pc_branch_offset_ip(pc_branch_offset),

		// Outputs of Pass-Through Signals to Memory
		.lsu_enable_pt_op(ex_lsu_en),
		.ex_lsu_operator_pt_op(ex_lsu_operator),
		.mem_wdata_pt_op(ex_DRAM_wdata),
		.ex_write_reg_addr_pt_op(ex_write_addr_reg_op),

		// Outputs to LSU, MEM, and Fetch
		.alu_result_op(ex_alu_result_pt),
		.alu_valid_op(ex_alu_result_valid_pt),

		// Outputs to forward to Fetch for Flush Control
		.next_PC_addr_op(alu_next_pc_addr),
		.next_PC_addr_valid_op(alu_next_pc_addr_valid),

		.ex_wb_mux_op(ex_wb_mux_pt),
		.ex_pc_addr_pt_op(ex_instr_pc_addr_pt),
		.ex_uimmd_pt_op(ex_uimmd_pt),
		.mem_addrIPLSU(ex_alu_result_pt) // I ADDED THIS ??????? NEED HELP WITH THIS
	);


	Mem_Stage LoadStoreUnit (
		// General Inputs
		.clock(clock),
		.reset(reset),
		.data_gnt_i(mem_gnt_req),

		// Inputs from Decode
		.lsu_en_ip(ex_lsu_en),
		.lsu_operator_ip(ex_lsu_operator),

		// Inputs from ALU
		.alu_valid_ip(ex_alu_result_valid_pt),
		.mem_addr_ip(ex_alu_result_pt),

		// Inputs from DRAM
		.mem_data_ip(DRAM_load_mem_data),

		// pass through ALU result and valid signal to writeback 
		.wb_alu_result_pt_ip(ex_alu_result_pt),
		.wb_alu_result_valid_pt_ip(ex_alu_result_valid_pt),
		.lsu_wb_mux_pt_ip(ex_wb_mux_pt),
		.lsu_write_reg_addr_pt_ip(ex_write_addr_reg_op),
		.lsu_pc_addr_pt_ip(ex_instr_pc_addr_pt),
		.lsu_uimmd_pt_ip(ex_uimmd_pt),

		.wb_alu_result_pt_op(lsu_alu_result_pt),
		.wb_alu_result_valid_pt_op(lsu_alu_result_valid_pt),
		.lsu_wb_mux_pt_op(lsu_wb_mux_pt),
		.lsu_write_reg_addr_pt_op(lsu_write_addr_reg_op),
		.lsu_pc_addr_pt_op(lsu_instr_pc_addr_pt),
		.lsu_uimmd_pt_op(lsu_uimmd_pt),

		// Output to Decode
		.data_req_op(mem_data_req_valid),
		.load_mem_data_op(load_mem_data),

		// Output to Main Memory
		.data_addr_valid_op(valid_mem_data_addr)
	);

	DRAM MainMemory (
		// General Inputs
		.mem_en(mem_en),
		.clock(clock),
		
		// Inputs from LSU
		.data_req_ip(valid_mem_data_addr),

		// Passthrough Inputs from Decode
		.lsu_operator(ex_lsu_operator),
		.wdata_ip(ex_DRAM_wdata),

		// Passthrough Inputs from ALU. Get Wire that goes to 
		// the buffer of the LSU stage
		.data_addr_ip(ex_alu_result_pt),

		//Outputs 
		.mem_gnt_op(mem_gnt_req),

		// Outputs to Decode
		.load_data_op(DRAM_load_mem_data)
	);

	WB_Stage WriteBack_Module(
		.reset(reset), 

		// Forwarded execution results from ALU and mem stages
  	.WB_wb_mux_ip(lsu_wb_mux_pt),

 		.WB_alu_result_ip(lsu_alu_result_pt),
  	.WB_alu_result_valid_ip(lsu_alu_result_valid_pt),

  	.WB_mem_result_ip(load_mem_data),
  	.WB_mem_result_valid_ip(mem_data_req_valid),

  	.WB_immediate_ip(lsu_uimmd_pt),
  	.WB_pc_ip(lsu_instr_pc_addr_pt),

		// Outputs to FWD and Decode Module
  	.WB_regfile_write_valid(writeback_data_valid),
  	.WB_regfile_write_data(writeback_data)
	);

endmodule