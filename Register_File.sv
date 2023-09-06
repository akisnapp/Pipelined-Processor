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
//      32x32 Register File for a 5 Stage RISCV Processor
//
//***********************************************************
import CORE_PKG::*;

module Register_File#(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 32
) (
  input logic clock,
  input logic reset,

  // Read Port A
  input logic [ADDR_WIDTH-1:0] raddr_a_ip,
  output logic [DATA_WIDTH-1:0] raddr_a_op,

  // Read Port B
  input logic [ADDR_WIDTH-1:0] raddr_b_ip,
  output logic [DATA_WIDTH-1:0] raddr_b_op,

  // Write Port A
  input logic [ADDR_WIDTH-1:0] waddr_a_ip,
  input logic [DATA_WIDTH-1:0] wdata_a_ip,
  input logic we_a_ip                         // write enable for port A
);

  // Declare Number of Integer Registers including reserved register 0
  localparam NUM_INT_WORDS = 2 ** (ADDR_WIDTH); 

  // Declare signals used to select registers for writes based on write enable and input address
  logic [ADDR_WIDTH-1:0] waddr_a;
  logic [DATA_WIDTH-1:0] write_enable_a_dec;

  // Declare the Register File
  logic [DATA_WIDTH-1:0] RegisterFile [0:NUM_INT_WORDS-1];

  // Internal signal used for encoding
  assign waddr_a = waddr_a_ip;

  // Assign the output
  assign raddr_a_op = RegisterFile[raddr_a_ip];
  assign raddr_b_op = RegisterFile[raddr_b_ip];

  // Encoder the value of the address to a one-hot encoding 32 bit string
  // that'll be used to select the correct register file
  genvar gidx;
  generate
    for (gidx = 0; gidx < NUM_INT_WORDS; gidx++) begin : gen_we_encoder
      assign write_enable_a_dec[gidx] = (waddr_a == gidx) ? we_a_ip : 1'b0;
    end
  endgenerate

  // Create 32 D-FlipFlops/Latches that input corresponding enable signal and write values
  genvar x;
  generate
    DFlipFlop #(
      .DATA_WIDTH(DATA_WIDTH)
    ) RF0 (
      .clock(clock),
      .reset(reset),

      .enable(1'b0),
      .data_ip(wdata_a_ip),
      .data_op(RegisterFile[0])
    );

    for(x=1; x<NUM_INT_WORDS; x++) begin : RF
      DFlipFlop #(
      .DATA_WIDTH(DATA_WIDTH)
      ) RF (
        .clock(clock),
        .reset(reset),

        .enable(write_enable_a_dec[x]),
        .data_ip(wdata_a_ip),
        .data_op(RegisterFile[x])
      );
    end
  endgenerate

endmodule