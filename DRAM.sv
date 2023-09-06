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
//      Data Memory of a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module DRAM (
  // General Inputs
  input logic clock,
  input logic mem_en,

  // Inputs from LSU
  input logic data_req_ip,                    // Validity fo data addr sent from LSU 

  // Input from ALU
  input logic [31:0] data_addr_ip,            // Address calcualted from MEM for memory access

  // Inputs from Decode
  input logic [31:0] wdata_ip,                // data to store into memory by a store instruction
  input load_store_func_code lsu_operator,

  // Module Outputs
  output logic mem_gnt_op,                    // DRAM is ready to output instruction data to decode (sent to Fetch Unit)

  // Outputs to Decode
  output logic [31:0] load_data_op            // Data to send to LSU for a load instr.
);

  // Static parameters to set memory during compile time
  localparam PARAM_MEM_length = 1024;
  localparam data_addr = 0;

  // Declare Byte Addressed DRAM
  logic [7:0] data_RAM [0:PARAM_MEM_length-1];
  logic data_req;

  // Big Endian variation since the MSB bit (bits 31) is stored at the lowest address
  // Not Synthesizable but for simulation, create a RAM memory system for access and writes
  initial begin
    for (int i = 0; i < PARAM_MEM_length; i++) 
      data_RAM[i] = 0; //initialize the RAM with all zeros
  end

  // Signal to Fetch Unit that memory is ready or not
  assign mem_gnt_op = mem_en ? 1 : 0;
  assign data_req = data_req_ip;

  // Read Addr. Port 1 for load data
  always @(*) begin
    if (data_req_ip == 1'b1) begin
      // address is aligned so can just read directly by adding
      case (lsu_operator)
        LW: begin
          load_data_op[31:24] = data_RAM[data_addr + data_addr_ip];
          load_data_op[23:16] = data_RAM[data_addr + data_addr_ip + 1];
          load_data_op[15:8] = data_RAM[data_addr + data_addr_ip + 2];
          load_data_op[7:0] = data_RAM[data_addr + data_addr_ip + 3];
        end
        default: 
          load_data_op[31:8] = 32'bz;
      endcase
    end
  end

endmodule