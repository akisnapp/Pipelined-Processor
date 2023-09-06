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
//      Stall Controller for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module Stall_Control (
  input logic reset, 

  input logic [6:0] ID_instr_opcode_ip,
  input logic [4:0] ID_src1_addr_ip,
  input logic [4:0] ID_src2_addr_ip,

  //The destination register from the different stages
  input logic [4:0] EX_reg_dest_ip,  // destination register from EX pipe
  input logic [4:0] LSU_reg_dest_ip,
  input logic [4:0] WB_reg_dest_ip,
  input logic WB_write_reg_en_ip,

  // The opcode of the current instr. in ID/EX
  input [6:0] EX_instr_opcode_ip,

  output logic stall_op,
  output logic flush_op // I ADDED THIS
);

  always_comb begin
    stall_op = 1'b0;
    flush_op = 1'b0; // Set default of flush output equal to 0
    case(ID_instr_opcode_ip) 

      OPCODE_JAL: begin// I ADDED THIS
        flush_op = 1'b1;
      end
      OPCODE_OP: begin
        
        /**
        * Decide when to pull the stall control logic high. 
        * 
        * 1. Load to use stalls
        * 2. Stalls when reading and writing from Register File
        * For Register Register instructions, only check relevant registers
        */
        if ((ID_src1_addr_ip == EX_reg_dest_ip) && (EX_instr_opcode_ip == OPCODE_LOAD)) begin
          stall_op = 1'b1;
        end
        else if ((ID_src2_addr_ip == EX_reg_dest_ip) && (EX_instr_opcode_ip == OPCODE_LOAD)) begin// && (EX_instr_opcode_ip[2:0] == 3'b011))
          stall_op = 1'b1;
        end
        else if ((ID_src1_addr_ip == WB_reg_dest_ip) && (EX_reg_dest_ip != ID_src1_addr_ip) && (LSU_reg_dest_ip !== ID_src1_addr_ip)) begin//&& WB_write_reg_en_ip) begin
          stall_op = 1'b1;
        end
        else if ((ID_src2_addr_ip == WB_reg_dest_ip) && (EX_reg_dest_ip != ID_src2_addr_ip) && (LSU_reg_dest_ip !== ID_src2_addr_ip)) begin//&& WB_write_reg_en_ip) begin
          stall_op = 1'b1;
        end
      end

      OPCODE_OPIMM: begin

        /**
        * Here you will need to decide when to pull the stall control logic high. 
        * 
        * 1. Load to use stalls
        * 2. Stalls when reading and writing from Register File
        * For Register Register instructions, only check relevant registers
        */
        if (ID_src1_addr_ip == EX_reg_dest_ip && EX_instr_opcode_ip == OPCODE_LOAD) begin
          stall_op = 1'b1;
        end
        else if ((ID_src1_addr_ip === WB_reg_dest_ip) && WB_write_reg_en_ip && (LSU_reg_dest_ip !== ID_src1_addr_ip) && (EX_reg_dest_ip !== ID_src1_addr_ip)) begin // && (EX_instr_opcode_ip[2:0] == 3'b011))
          stall_op = 1'b1;
        end

      end

      default: begin
        stall_op = 1'b0;
        flush_op = 1'b0; // Set flush output to 0 on default
      end
    endcase
  end

endmodule
