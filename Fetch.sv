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
//      Program Counter for a 5 Stage RISCV Processor
//
//***********************************************************

import CORE_PKG::*;

module Fetch(
  // General Inputs
  input logic clock,
  input logic reset,
  input logic instr_gnt_ip,               // Input signal from DRAM to grant access

  input logic [31:0] Next_PC_ip,


  // Outputs to MEM
  output logic instr_req_op,              // Addr. signal sent is valid
  output logic [31:0] instr_addr_op,      // Addr. containing the instruction in memory to fetch

  output logic [31:0] pc_addr
);

  // Internal Signals
  logic [31:0] PC, Next_PC;               // need 8 bits to encode 0-255 for DRAM access but for 32 bit address

  assign Instr_or_Data_op = 0;            // drive low to inform memory that request if for instruction
  assign pc_addr = PC;

  always @(*) begin
    if (reset == 1'b1) begin
      instr_addr_op = 0;
      instr_req_op = 0;
    end
    else begin
      instr_addr_op = Next_PC_ip;
      instr_req_op = 1;
    end
  end

  // Output the actual PC addr to the IF Stage Pipeline buffer
  always_ff @(posedge clock) begin
    if (reset == 1'b1)
      PC <= 0;
    else
      PC <= Next_PC_ip;
  end


endmodule