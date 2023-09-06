//***********************************************************
// ECE 3058 Architecture Concurrency and Energy in Computation
//
// RISCV Processor System Verilog Behavioral Model
//
// School of Electrical & Computer Engineering
// Georgia Institute of Technology
// Atlanta, GA 30332
//
//  Module:     core_tb
//  Functionality:
//      Instruction Fetch Stage for a 5 Stage RISCV Processor
//
//***********************************************************

import CORE_PKG::*;

module IF_Stage (
  // General Inputs
  input logic clock,
  input logic reset,
	input logic mem_en,
  input logic instr_gnt_ip,               // Input signal from DRAM to grant access

  // Inputs from Decode
  input pc_mux pc_mux_ip,
	input logic stall_ip,
  input logic flush_ip,										// From stall control in Decode stage

  // Inputs from ALU
  input logic [31:0] alu_result_ip,
	input logic alu_result_valid_ip,

  // Outputs to DECODE
  output logic instr_valid_op,              // Addr. signal sent is valid
  output logic [31:0] instr_data_op,      // Addr. containing the instruction in memory to fetch
	output logic [31:0] instr_pc_addr_op
);

	logic mem_instr_req_valid;
	logic [31:0] instr_mem_addr;
	logic [31:0] pc_addr;

	logic instr_valid;
	logic [31:0] instr_data;

	logic [31:0] Next_PC;

  always @(*) begin
		
	//Check the stall signal and assign the Next PC address

    if (reset == 1'b1 || flush_ip == 1'b1) 
      Next_PC = 0;
    else begin
      unique case (pc_mux_ip)
	  	NOP_PC_MUX: Next_PC = stall_ip ? pc_addr: pc_addr + 4;
        NEXTPC: Next_PC = stall_ip ? pc_addr: pc_addr + 4;
        ALU_RESULT: Next_PC = alu_result_valid_ip ? alu_result_ip: pc_addr; // If not valid, then stall until valid
        default: Next_PC = pc_addr + 4;
      endcase
    end
  end

	/*
	* IF/ID Pipeline Buffer
	*/ 
	always_ff @(posedge clock) begin
		if ((reset == 1'b1) || (flush_ip == 1'b1)) begin
			instr_valid_op <= 0;
			instr_data_op <= 0;
			instr_pc_addr_op <= 0;
		end
		else if (stall_ip == 1'b1) begin 
			instr_pc_addr_op <= instr_pc_addr_op;
			instr_valid_op <= instr_valid_op;
			instr_data_op <= instr_data_op;
		end
		else begin
			instr_pc_addr_op <= pc_addr;
			instr_valid_op <= instr_valid;
			instr_data_op <= instr_data;
		end
	end

	Fetch FetchModule (
		// General Inputs
		.clock(clock),
		.reset(reset),
		.instr_gnt_ip(mem_gnt_req),

		.Next_PC_ip(Next_PC),

		// Outputs to Instruction Memory
		.instr_req_op(mem_instr_req_valid),
		.instr_addr_op(instr_mem_addr),

		.pc_addr(pc_addr)
	);

	Instr_Mem InstructionMemory (
		.clock(clock),
		.mem_en(mem_en),

		.instr_req_ip(mem_instr_req_valid),                 
		.instr_addr_ip(instr_mem_addr), 

		.instr_valid_op(instr_valid),         
		.instr_data_op(instr_data)  
	);

endmodule