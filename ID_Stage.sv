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
//      Instruction Decode Stage for a 5 Stage RISCV Processor
//
//***********************************************************

import CORE_PKG::*;

module ID_Stage (
  // General Inputs
  input logic clock,
  input logic reset,
  input logic [31:0] pc,
  input logic [31:0] pc4, 

  // Inputs from MEM
  input logic instr_data_valid_ip,            // If the instruction sent from MEM to decode is valid
  input logic [31:0] instr_data_ip,           // The instruction to deocde from the Fetch module
  input logic [4:0] mem_dest_reg_ip,         // Required for stalling

  // Inputs from WB
  input logic [4:0] write_reg_addr_ip,
  input logic [31:0] wb_data_ip,
  input logic wb_data_valid_ip,

  // Outputs to ALU
  output logic alu_en_op,
  output alu_opcode_e alu_operator_op,        // Selects the ALU operation to perform
  output logic [31:0] alu_operand_a_ex_op,    // First operand to ALU
  output logic [31:0] alu_operand_b_ex_op,    // Second operand to ALU

  // Pass through to Writeback
  output logic [4:0] write_reg_addr_op,
  output write_back_mux_selector wb_mux_op,
  output logic [31:0] id_pc_addr_pt_op,
  output logic [31:0] id_uimmd_pt_op,

  // Outputs to LSU
  output logic en_lsu_op,
  output load_store_func_code lsu_operator_op,          // which type of load or stre instruction to execute 

  // Outputs to MEM
  output logic [31:0] mem_wdata_op,

  // Output to Forward Unit
  output logic [6:0] EX_instruction_opcode,
  output logic [4:0] ID_src1_reg_addr,
  output logic [4:0] ID_src2_reg_addr,

  // Outputs to Fetch for informing of Jump
  output logic [31:0] pc_branch_offset_op,
  output pc_mux pc_mux_op,

  // I ADDED THIS
  //input logic stall_ip,

  // Stall signal to send to Fetch
  output logic stall_op,
  output logic flush_op // I ADDED THIS
);

  // Declare parameters to extract source and destination registers and immediate values
  localparam REG_S1_MSB = 19;
  localparam REG_S1_LSB = 15;

  localparam REG_S2_MSB = 24;
  localparam REG_S2_LSB = 20;

  localparam REG_DEST_MSB = 11;
  localparam REG_DEST_LSB = 7;

  localparam I_IMM_MSB = 31;
  localparam I_IMM_LSB = 20;

  logic [31:0] valid_instr_to_decode;

  // Inputs to RegFile Read ports to select data
  logic [4:0] regfile_read_addr_a_id;  // source register 1 based on MSB and LSB mask
  logic [4:0] regfile_read_addr_b_id;  // source register 2

  // Write Port to select which regfile
  logic [4:0] regfile_write_addr_a_id;

  // Reg File Outputs
  logic [31:0] regfile_a_out;
  logic [31:0] regfile_b_out;

  // Reg File Write enable
  write_back_mux_selector writeback_mux;
  logic regfile_write_data_valid;
  logic [31:0] regfile_write_data;

  // J-Type Immediate for JAL Instr.
  logic [31:0] J_IMM;

  // Mux to select values for operand 2 or source reg 1. 
  operand_a_mux operand_a_select;

  // Mux to select which value to select as operand b or source reg 2. 
  operand_b_mux operand_b_select;


  /*
  * Internal wires for ID_EX Pipeline Buffer to ALU and Comparator and Flush Controller
  */
  logic alu_en;
  alu_opcode_e alu_operator;
  logic [31:0] alu_operand_a_ex;
  logic [31:0] alu_operand_b_ex;
  logic comparator_en;
  comparator_func_code comparator_func;

  /*
  * Internal wires for ID_EX Pipeline Buffer to forward to memory stage
  */
  logic en_lsu;
  load_store_func_code lsu_operator;
  logic [31:0] mem_wdata;

  /*
  * Internal wires for ID_EX Pipeline Buffer to forward to Flush Control
  * For ALU address calculation in jumps or possible branching
  */
  logic [31:0] pc_branch_offset;
  pc_mux pc_mux_inter;

  assign valid_instr_to_decode = instr_data_valid_ip ? instr_data_ip : 32'bz;

  always @(*) begin
    alu_operator = ALU_NOP; // Default assignment

    operand_a_select = OPA_NOP;
    operand_b_select = OPB_NOP;

    writeback_mux = NO_WRITEBACK;
    mem_wdata = 32'bz;       // data to send to mem for store 

    en_lsu = 1'b0;
    lsu_operator = LW; // Default Assignment. Fine as long as LSU is not enabled  //I CHANGED THIS FROM LW TO NOP

    // Comparator defaults 
    comparator_func = COMP_BEQ; // default but not enabled comparator 
    comparator_en = 1'b0;
    pc_branch_offset = 32'bz;

    // PC Defaults
    pc_mux_inter = NEXTPC;   // Set the PC Mux

    case(valid_instr_to_decode[6:0])

      OPCODE_OP: begin // Register-Register ALU operation

        // RV321 ALU Instr.
        operand_a_select = REG_A;
        operand_b_select = REG;
        writeback_mux = READ_ALU_RESULT;
        case({valid_instr_to_decode[31:25], valid_instr_to_decode[14:12]})
          10'b0000_000_000: alu_operator = ALU_ADD; // ADD
          10'b0100_000_000: alu_operator = ALU_SUB; // SUB
          10'b0000_000_010: alu_operator = ALU_SLTS; // Set lower then signed (default SLT)
        endcase
      end

      OPCODE_OPIMM: begin // Register-Immediate ALU operations
        operand_a_select = REG_A;
        operand_b_select = I_IMMD;
        writeback_mux = READ_ALU_RESULT;
        case(valid_instr_to_decode[14:12])
          3'b000: alu_operator = ALU_ADD; // ADDI
        endcase
      end

      OPCODE_LOAD: begin
        en_lsu = 1'b1;

        operand_a_select = REG_A;
        operand_b_select = I_IMMD;
        writeback_mux = READ_MEM_RESULT;
        alu_operator = ALU_ADD;
        case(valid_instr_to_decode[14:12]) 
          3'b000: lsu_operator = LB; // Load Byte
        endcase
      end
      

      OPCODE_JAL: begin
        pc_mux_inter = ALU_RESULT;
        writeback_mux = READ_PC4;

        // Form the J-Immedate encoding
        J_IMM = $signed({valid_instr_to_decode[31], valid_instr_to_decode[19:12], valid_instr_to_decode[20], valid_instr_to_decode[30:21], 1'b0});

        alu_operator = ALU_ADD;
        operand_a_select = PC;
        operand_b_select = J_IMMD;
        lsu_operator_op = 3'b000;
        en_lsu = 1'b0;
      end

    endcase
  end

  assign regfile_read_addr_a_id = valid_instr_to_decode[REG_S1_MSB:REG_S1_LSB];
  assign regfile_read_addr_b_id = valid_instr_to_decode[REG_S2_MSB:REG_S2_LSB];

  assign regfile_write_addr_a_id = valid_instr_to_decode[REG_DEST_MSB:REG_DEST_LSB];

  // Determine whether or not to enable the ALU
  assign alu_en = (alu_operator == ALU_NOP) ? 1'b0 : 1'b1;

  // Assign a and b operands to ALU 
  always @(*) begin
    case(operand_a_select)
      OPA_NOP: alu_operand_a_ex = 32'bz;
      REG_A: alu_operand_a_ex = regfile_a_out;
      PC: alu_operand_a_ex = pc;
      PC4: alu_operand_a_ex = pc + 4;
    endcase
  end

  always @(*) begin
    case(operand_b_select)
      REG: alu_operand_b_ex = regfile_b_out;
      I_IMMD: alu_operand_b_ex = $signed(valid_instr_to_decode[I_IMM_MSB:I_IMM_LSB]);
      J_IMMD: alu_operand_b_ex = J_IMM;
      OPB_NOP: alu_operand_b_ex = 32'bz;
    endcase
  end

  // ID_EX Pipeline Buffer
  always_ff @(posedge clock) begin
    if ((stall_op == 1'b1) | (reset == 1'b1)) begin
      // Instructions to send to EX Stage
      alu_en_op <= 0;
      alu_operator_op <= ALU_NOP;
      alu_operand_a_ex_op <= 0;
      alu_operand_b_ex_op <= 0;

      // Forwarded Instruction State to memory
      en_lsu_op <= 0;
      lsu_operator_op <= NOP;
      mem_wdata_op <= 0;

      // Forwarded Instruction State to Flush Control
      pc_branch_offset_op <= 0;
      pc_mux_op <= NOP_PC_MUX;
      wb_mux_op <= NO_WRITEBACK;
      write_reg_addr_op <= 0;
      EX_instruction_opcode <= 0;
      ID_src1_reg_addr <= 0;
      ID_src2_reg_addr <= 0;

      // Forwarded PC addr.
      id_pc_addr_pt_op <= 0;
      id_uimmd_pt_op <= 0;

    end else begin
      // Instructions to send to EX Stage
      alu_en_op <= alu_en;
      alu_operator_op <= alu_operator;
      alu_operand_a_ex_op <= alu_operand_a_ex;
      alu_operand_b_ex_op <= alu_operand_b_ex;

      // Forwarded Instruction State to memory
      en_lsu_op <= en_lsu;
      lsu_operator_op <= lsu_operator;
      mem_wdata_op <= mem_wdata;

      // Forwarded Instruction State to Flush Control
      pc_branch_offset_op <= pc_branch_offset;
      pc_mux_op <= pc_mux_inter;

      wb_mux_op <= writeback_mux;

      write_reg_addr_op <= regfile_write_addr_a_id;

      EX_instruction_opcode <= valid_instr_to_decode[6:0];

      ID_src1_reg_addr <= regfile_read_addr_a_id;
      ID_src2_reg_addr <= regfile_read_addr_b_id;

      // Forwarded PC addr.
      id_pc_addr_pt_op <= pc;
    end
  end

  Register_File #(
    .ADDR_WIDTH(5),
    .DATA_WIDTH(32)
  ) register_file (
    .clock(clock),
    .reset(reset),

    .raddr_a_ip(regfile_read_addr_a_id),
    .raddr_a_op(regfile_a_out),

    .raddr_b_ip(regfile_read_addr_b_id),
    .raddr_b_op(regfile_b_out),

    .waddr_a_ip(write_reg_addr_ip),
    .wdata_a_ip(wb_data_ip),
    .we_a_ip(wb_data_valid_ip)
  );

  Stall_Control StallController_Module (
		.reset(reset), 

		.ID_instr_opcode_ip(valid_instr_to_decode[6:0]),
		.ID_src1_addr_ip(regfile_read_addr_a_id),
		.ID_src2_addr_ip(regfile_read_addr_b_id),

		//The destination register from the different stages
		.EX_reg_dest_ip(write_reg_addr_op),  // destination register from EX pipe
    .LSU_reg_dest_ip(mem_dest_reg_ip),
		.WB_reg_dest_ip(write_reg_addr_ip),
		.WB_write_reg_en_ip(wb_data_valid_ip),

		// The opcode of the current instr. in ID/EX
		.EX_instr_opcode_ip(EX_instruction_opcode),

    // ADDED these for outputs of stall and flush
		.stall_op(stall_op), 
    .flush_op(flush_op)
	);

endmodule