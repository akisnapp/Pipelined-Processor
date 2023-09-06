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
//      Writeback Stage for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module WB_Stage (
  input logic reset, 

  input write_back_mux_selector WB_wb_mux_ip,

  input logic [31:0] WB_alu_result_ip,
  input logic WB_alu_result_valid_ip,

  input logic [31:0] WB_mem_result_ip,
  input logic WB_mem_result_valid_ip,

  input logic [31:0] WB_immediate_ip,
  input logic [31:0] WB_pc_ip,

  output logic WB_regfile_write_valid,
  output logic [31:0] WB_regfile_write_data
);

  // Mux which data result to write back to memory if appropriate
  always_comb begin
    case (WB_wb_mux_ip)
      READ_ALU_RESULT: begin
        WB_regfile_write_valid = WB_alu_result_valid_ip;
        WB_regfile_write_data = WB_alu_result_ip;
      end
      READ_MEM_RESULT: begin
        WB_regfile_write_valid = WB_mem_result_valid_ip;
        WB_regfile_write_data = WB_mem_result_ip;
      end
      READ_REGFILE: begin
        WB_regfile_write_valid = 1'b1;
        WB_regfile_write_data = WB_immediate_ip;
      end
      READ_PC4: begin
        WB_regfile_write_valid = 1'b1;
        WB_regfile_write_data = WB_pc_ip + 4;
      end
      default: begin
        WB_regfile_write_valid = 1'b0;
        WB_regfile_write_data = 32'hz;
      end
    endcase
  end

endmodule