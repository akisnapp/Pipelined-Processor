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
//      Load Store Unit for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module Mem_Stage (
  // General Inputs
  input logic clock,
  input logic reset,
  input logic data_gnt_i,

  // Inputs from decode
  input logic lsu_en_ip,                      // enable the LSU because it is a memory operation
  input load_store_func_code lsu_operator_ip, 

  // Input from ALU
  input logic alu_valid_ip,
  input logic [31:0] mem_addr_ip,             // address to access in mem for read/write

  // Input data from DRAM after load
  input logic [31:0] mem_data_ip,

  input logic [31:0] wb_alu_result_pt_ip,
  input logic wb_alu_result_valid_pt_ip,
  input write_back_mux_selector lsu_wb_mux_pt_ip,
  input logic [4:0] lsu_write_reg_addr_pt_ip,
  input logic [31:0] lsu_pc_addr_pt_ip,
  input logic [31:0] lsu_uimmd_pt_ip,

  output logic [31:0] wb_alu_result_pt_op,
  output logic wb_alu_result_valid_pt_op,
  output write_back_mux_selector lsu_wb_mux_pt_op,
  output logic [4:0] lsu_write_reg_addr_pt_op,
  output logic [31:0] lsu_pc_addr_pt_op,
  output logic [31:0] lsu_uimmd_pt_op,

  // Output to Decode
  output logic data_req_op,                  // validity of data address request
  output logic [31:0] load_mem_data_op,      // data from load to sent to decode 

  // Output to Data Memory to inform that valid to read data
  output logic data_addr_valid_op
);

  logic valid_mem_operation;
  assign valid_mem_operation = data_gnt_i & lsu_en_ip & alu_valid_ip;
  assign data_addr_valid_op = valid_mem_operation;

  // Pipeline Buffer
  always @(posedge clock) begin
    lsu_wb_mux_pt_op <= lsu_wb_mux_pt_ip;
    wb_alu_result_pt_op <= wb_alu_result_pt_ip;
    wb_alu_result_valid_pt_op <= wb_alu_result_valid_pt_ip;
    lsu_write_reg_addr_pt_op <= lsu_write_reg_addr_pt_ip;
    lsu_pc_addr_pt_op <= lsu_pc_addr_pt_ip;
    lsu_uimmd_pt_op <= lsu_uimmd_pt_ip;
  end

  always @(posedge clock) begin
    data_req_op = 1'b0;

    if (valid_mem_operation == 1'b1) begin
      data_req_op = 1'b1;
      case (lsu_operator_ip)
        LW: begin
          case (mem_addr_ip[1:0])
            2'b00: load_mem_data_op = mem_data_ip;
            default load_mem_data_op = 32'hz;
          endcase
        end
      endcase
    end
  end

endmodule