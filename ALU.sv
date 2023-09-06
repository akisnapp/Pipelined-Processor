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
//      ALU Unit for the 5 Stage RISVC Processor
//
//***********************************************************

import CORE_PKG::*;

module ALU (
  // General Inputs
  input logic reset,

  // Inputs from decode
  input logic alu_enable_ip,                // ALU Enable signal
  input alu_opcode_e alu_operator_ip,       // ALU Operation
  input logic [31:0] alu_operand_a_ip,      // Src register 1 value
  input logic [31:0] alu_operand_b_ip,      // Src register 2 value

  // Outputs to LSU, MEM, and Fetch
  output logic [31:0] alu_result_op,        // ALU execution result
  output logic alu_valid_op                 // ALU execution result validity
);

  always_comb begin
    case(alu_operator_ip) 
      ALU_ADD: begin
        alu_result_op = alu_operand_a_ip + alu_operand_b_ip;
        alu_valid_op = 1;
      end
      ALU_SUB: begin
        alu_result_op = alu_operand_a_ip - alu_operand_b_ip;
        alu_valid_op = 1;
      end
      ALU_SLTS: begin
        alu_result_op = ($signed(alu_operand_a_ip) < $signed(alu_operand_b_ip)) ? 1 : 0;
        alu_valid_op = 1;
      end

      default: begin
        alu_result_op = 0;
        alu_valid_op = 0;
      end
    endcase
  end


endmodule
