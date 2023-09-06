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
//      Configuration File for opcodes and constant definitions
//
//***********************************************************

package CORE_PKG;

  /**
  * STORES OPCODE includes sb, sh, sw
  */
  parameter OPCODE_STORE = 7'h23;

  /**
  * LOAD opcode includes lb, lh, lw, lbu, lhu
  * 
  * I-type encoded with effective address obtained by adding rs1 
  * to SIGN-EXTENDED 12-bit offset value. 
  * 
  * LH loads a 16 bit value from mem and then SIGN-EXTENDS it to 
  * 32 bits before storing in rd while LHU ZERO-EXTENDS the 16-bit value
  */
  parameter OPCODE_LOAD = 7'h03;

  // FOR LOADS AND STORES. Misaligned addresses based on word, half-word, or byte 
  // will for our cases will raise a mis-aligned address exception and delegate it
  // to the OS. Not our problem! Possible implementations can handle it "invisibly" in hardware

  /**
  * BRANCH opcode includes beq, bne, blt, bge, bltu, and bgeu
  *
  * BEQ/BNE: take the branch if equal or not equal
  * blt[u]: take the branch ONLY IF rs1 < rs2 using signed/unsigned comparisions
  * bge[u]: take the branch if rs1 >= rs2 using signed/unsigned comparisions
  */
  parameter OPCODE_BRANCH = 7'h63;


  /**
  * JALR has its own opcode
  * 
  * Uses I-immd. Add a sign-extended 12-bit I-immd to value in rs1 then
  * setting the least significant bit to 0 (so multiples of 2). The addr.
  * of the instruction following the jump (current PC before jump + 4) is
  * written to register rd. 
  */
  parameter OPCODE_JALR = 7'h67;

  /**
  * JAL has its own opcode
  *
  * A J-immd is sign-extended and added to pc-address of the instruction 
  * to form the jump target address. NOTE that the 20 bit immd is encoded
  * in multiples of 2 bytes so the actual value is shifted by 2 before sign-extended.
  * The PC jumps to this address. At the same time, this the addr. following the jump
  * instruction (current PC no jump +4) is stored in register rd. If rd is reg. 0, then 
  * this is just a jump instruction. This is used to return to the PC later
  */
  parameter OPCODE_JAL = 7'h6f;

  /**
  * AUI has its own opcode
  * 
  * Add upper immd to PC. It is used to build pc-relative addresses. 
  * It is a U-type instruction with U-type immd. It forms a 32-bit offset
  * from the 20 but U-immediate by zero padding. This 32-bit offset is added
  * to the pc address of the AUI instr and placed in rd register. 
  */
  parameter OPCODE_AUIPC = 7'h17;

  /**
  * LUI has its own opcode
  *
  * Zero pads a 20 bit U-type immediate and places result in rd register. 
  */
  parameter OPCODE_LUI = 7'h37;

  /**
  * All register to register instructions
  */
  parameter OPCODE_OP = 7'h33;

  /**
  * All register immediate instructions
  */
  parameter OPCODE_OPIMM = 7'h13;


  //*************************
  // ALU Operations for Masking
  //*************************
  typedef enum logic [6:0] {
    ALU_NOP   = 7'b0000000,
    ALU_ADD   = 7'b0011000,
    ALU_SUB   = 7'b0011001,
    ALU_ADDU  = 7'b0011010,
    ALU_SUBU  = 7'b0011011,
    ALU_ADDR  = 7'b0011100,
    ALU_SUBR  = 7'b0011101,
    ALU_ADDUR = 7'b0011110,
    ALU_SUBUR = 7'b0011111,

    ALU_XOR = 7'b0101111,
    ALU_OR  = 7'b0101110,
    ALU_AND = 7'b0010101,

    // Shifts
    ALU_SRA = 7'b0100100,
    ALU_SRL = 7'b0100101,
    ALU_ROR = 7'b0100110,
    ALU_SLL = 7'b0100111,

    // Set Lower Than operations
    ALU_SLTS  = 7'b0000010,
    ALU_SLTU  = 7'b0000011,
    ALU_SLETS = 7'b0000110,
    ALU_SLETU = 7'b0000111
  } alu_opcode_e;

  typedef enum {
    REG_A, PC, OPA_NOP, PC4
  } operand_a_mux;

  typedef enum logic [2:0] {
    REG = 3'b000,
    I_IMMD = 3'b001,
    S_IMMD = 3'b010,
    U_IMMD = 3'b011,
    J_IMMD = 3'b100,
    OPB_NOP = 3'b101
  } operand_b_mux;

  typedef enum logic [3:0] {
    NOP,
    LW,
    LH,
    LB,
    LHU,
    LBU,
    SW,
    SH,
    SB
  } load_store_func_code;

  typedef enum logic [2:0] {
    NO_WRITEBACK = 3'b000,
    READ_ALU_RESULT = 3'b001, 
    READ_MEM_RESULT = 3'b010,
    READ_REGFILE = 3'b011,
    READ_PC4 = 3'b100,
    READ_COMPARATOR_RESULT = 3'b101
  } write_back_mux_selector;

  typedef enum {
    NEXTPC,
    ALU_RESULT,
    ALU_RESULT_JALR,
    OFFSET,
    NOP_PC_MUX
  } pc_mux;

  // operand_a is left and operand_b is right 

  typedef enum logic [2:0] {
    COMP_BEQ = 3'b000,
    COMP_BNE = 3'b001,
    COMP_BLT = 3'b100,
    COMP_BGE = 3'b101,
    COMP_BLT_U = 3'b110,
    COMP_BGE_U = 3'b111,
    
    // Set Lower Than operations
    COMP_SLTS  = 3'b010,
    COMP_SLTU  = 3'b011
  } comparator_func_code;

  typedef enum logic [2:0] {
    ORIGINAL_SELECT = 3'b000, 
    EX_RESULT_SELECT = 3'b001,
    MEM_RESULT_SELECT = 3'b010, 
    WB_RESULT_SELECT = 3'b011,
    MEM_DATA_EX_SELECT = 3'b100, // for stores where ex/wb data needs to get forwarded 
    MEM_DATA_WB_SELECT = 3'b101
  } forward_mux_code;

endpackage