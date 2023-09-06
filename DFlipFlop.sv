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
//      System Verilog of a DFlipFlop
//
//***********************************************************

module DFlipFlop #(
  parameter DATA_WIDTH = 32
) (
  input logic clock,
  input logic reset,

  // enable signal to determine if this FlipFlop was selected
  // in this case better to use latch
  input logic enable,
  input logic [DATA_WIDTH-1:0] data_ip,
  output logic [DATA_WIDTH-1:0] data_op
);

  always_ff @(posedge clock) begin
    if (reset == 1'b1)
      data_op <= 0;
    else if (enable == 1'b1)
      data_op <= data_ip;
  end

endmodule