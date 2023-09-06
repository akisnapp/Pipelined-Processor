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
//      Instruction Memory for a 5 Stage RISCV Processor
//
//***********************************************************

import CORE_PKG::*;

module Instr_Mem (
  // General Inputs
  input logic clock,
  input logic mem_en,

  // Inputs from PC
  input logic instr_req_ip,                   // Validity of instr. addr sent from Fetch
  input logic [31:0] instr_addr_ip,           // Addr. in memory holding desired/speculated instruction. Multiples of 4

  // Outputs to Decode
  output logic instr_valid_op,                // Validity of the fetch instr. data output
  output logic [31:0] instr_data_op           // Read instruction sent to decode 
);

  // Static parameters to set memory during compile time
  localparam PARAM_MEM_length = 1024;

  // Declare Byte Addressed DRAM
  logic [7:0] instr_RAM [0:PARAM_MEM_length-1];

  // Big Endian variation since the MSB bit (bits 31) is stored at the lowest address
  // Not Synthesizable but for simulation, create a RAM memory system for access and writes
  initial begin
    for (int i = 0; i < PARAM_MEM_length; i++) 
      instr_RAM[i] = 0; //initialize the RAM with all zeros
  end

  always_ff @(posedge clock) begin
    case({mem_en, instr_req_ip})
      2'b11: begin
              instr_valid_op <= 1'b1;
              instr_data_op <= {
                instr_RAM[instr_addr_ip],
                instr_RAM[instr_addr_ip+1],
                instr_RAM[instr_addr_ip+2],
                instr_RAM[instr_addr_ip+3]
              };
            end
      default: begin
                instr_valid_op <= 0;
                instr_data_op <= 32'bz;
              end  
    endcase 
  end



endmodule