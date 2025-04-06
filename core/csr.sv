`timescale 1ns / 1ps

import enums::*;

// Control and Status Register interface
module csr (
    input csr_t csr_id,
    input logic [31:0] wd,
    output logic [31:0] rd,

    input  logic mie,
    input  logic mpie,
    output logic mie_next,
    output logic mpie_next,

    input logic mtip,
    input logic msip,
    input logic meip,

    input  logic mtie,
    input  logic msie,
    input  logic meie,
    output logic mtie_next,
    output logic msie_next,
    output logic meie_next,

    input  logic [31:2] mtvec_base,
    output logic [31:2] mtvec_base_next,

    input  logic [63:0] mcycle,
    input  logic [63:0] minstret,
    output logic [63:0] mcycle_next,
    output logic [63:0] minstret_next,

    input  logic mcycle_inhibit,
    input  logic minstret_inhibit,
    output logic mcycle_inhibit_next,
    output logic minstret_inhibit_next,

    input  logic [31:0] mscratch,
    output logic [31:0] mscratch_next,

    input  logic [31:0] mepc,
    output logic [31:0] mepc_next,

    input  mcause_t mcause,
    output mcause_t mcause_next,

    input  logic [31:0] mtval,
    output logic [31:0] mtval_next
);

    always_comb begin
        case (csr_id)
            CSR_MISA:
            rd = {
                // 32-bit instructions
                2'b01,
                4'b0,
                // extensions: I
                26'b00_0000_0000_0000_0001_0000_0000
            };

            CSR_MVENDORID: rd = 32'b0;  // mvendorid

            CSR_MARCHID: rd = 32'b0;  // marchid

            CSR_MIMPID: rd = 32'b0;  // mimpid

            CSR_MHARTID: rd = 32'b0;  // mhartid

            CSR_MSTATUS:
            rd = {
                1'b0,  // SD (FS and XS are hardwired to 0)
                8'b0,  // reserved
                1'b0,  // TSR (S-mode unsupported)
                1'b0,  // TW (U-mode and S-mode unsupported)
                1'b0,  // TVM (S-mode unsupported)
                1'b0,  // MXR (S-mode unsupported)
                1'b0,  // SUM (S-mode unsupported)
                1'b0,  // MPRV (U-mode unsupported)
                2'b0,  // XS (no user extensions)
                2'b0,  // FS (F extension unsupported)
                2'b11,  // MPP (M-mode)
                2'b00,  // reserved
                1'b0,  // SPP (S-mode unsupported)
                mpie,
                1'b0,  // reserved
                1'b0,  // SPIE (S-mode unsupported)
                1'b0,  // UPIE (user-level interrupts unsupported)
                mie,
                1'b0,  // reserved
                1'b0,  // SIE (S-mode unsupported)
                1'b0  // UIE (user-level interrupts unsupoprted)
            };

            CSR_MTVEC:
            rd = {
                mtvec_base,  // base
                2'd0  // mode (direct)
            };

            CSR_MIP:
            rd = {
                20'b0,  // reserved
                meip,
                1'b0,  // reserved
                1'b0,  // SEIP (S-mode unsupported)
                1'b0,  // UEIP (U-mode unsupported)
                mtip,
                1'b0,  // reserved
                1'b0,  // STIP (S-mode unsupported)
                1'b0,  // UTIP (U-mode unsupported)
                msip,
                1'b0,  // reserved
                1'b0,  // SSIP (S-mode unsupported)
                1'b0  // USIP (U-mode unsupported)
            };

            CSR_MIE:
            rd = {
                20'b0,  // reserved
                meie,
                1'b0,  // reserved
                1'b0,  // SEIE (S-mode unsupported)
                1'b0,  // UEIE (U-mode unsupported)
                mtie,
                1'b0,  // reserved
                1'b0,  // STIE (S-mode unsupported)
                1'b0,  // UTIE (U-mode unsupported)
                msie,
                1'b0,  // reserved
                1'b0,  // SSIE (S-mode unsupported)
                1'b0  // USIE (U-mode unsuuported)
            };

            CSR_MCYCLE:  rd = mcycle[31:0];
            CSR_MCYCLEH: rd = mcycle[63:32];

            CSR_MINSTRET:  rd = minstret[31:0];
            CSR_MINSTRETH: rd = minstret[63:32];

            CSR_MCOUNTEREN: rd = 32'b0;

            CSR_MCOUNTINHIBIT:
            rd = {
                29'b0,  // unimplemented counters
                minstret_inhibit,
                1'b0,  // required as per the spec
                mcycle_inhibit
            };

            CSR_MSCRATCH: rd = mscratch;

            CSR_MEPC: rd = mepc;

            CSR_MCAUSE: rd = 32'(mcause);

            CSR_MTVAL: rd = mtval;

            default: rd = {32{1'b0}};
        endcase
    end

    mcause_t recognized_causes[] = {
        MCAUSE_MSI,
        MCAUSE_MTI,
        MCAUSE_MEI,
        MCAUSE_INSTR_ADDR_MISALIGN,
        MCAUSE_INSTR_ADDR_FAULT,
        MCAUSE_ILLEGAL_INSTR,
        MCAUSE_BREAKPOINT,
        MCAUSE_LOAD_ADDR_MISALIGN,
        MCAUSE_LOAD_ACCESS_FAULT,
        MCAUSE_STORE_ADDR_MISALIGN,
        MCAUSE_STORE_ACCESS_FAULT,
        MCAUSE_M_ECALL
    };

    always_comb begin
        logic is_recognized_cause;

        mie_next = mie;
        mpie_next = mpie;

        mtie_next = mtie;
        msie_next = msie;
        meie_next = meie;

        mtvec_base_next = mtvec_base;

        mcycle_next = mcycle;
        minstret_next = minstret;

        mcycle_inhibit_next = mcycle_inhibit;
        minstret_inhibit_next = minstret_inhibit;

        mscratch_next = mscratch;

        mepc_next = mepc;
        mcause_next = mcause;
        mtval_next = mtval;

        case (csr_id)
            CSR_MSTATUS: {mpie_next, mie_next} = {wd[7], wd[3]};
            CSR_MTVEC: mtvec_base_next = wd[31:2];
            CSR_MIE: {mtie_next, msie_next, meie_next} = {wd[11], wd[7], wd[3]};
            CSR_MCYCLE: mcycle_next[31:0] = wd;
            CSR_MCYCLEH: mcycle_next[63:32] = wd;
            CSR_MINSTRET: minstret_next[31:0] = wd;
            CSR_MINSTRETH: minstret_next[63:32] = wd;
            CSR_MCOUNTINHIBIT: {mcycle_inhibit_next, minstret_inhibit_next} = {wd[0], wd[2]};
            CSR_MSCRATCH: mscratch_next = wd;
            CSR_MEPC: mepc_next = {wd[31:2], 2'b00};

            CSR_MCAUSE: begin
                is_recognized_cause = (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[0]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[1]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[2]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[3]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[4]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[5]) ||   
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[6]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[7]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[8]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[9]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[10]) ||
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[11]) ||   
                                    (mcause_t'({wd[31], wd[3:0]}) == recognized_causes[12]);

                if (is_recognized_cause && wd[30:4] == 0) begin
                    mcause_next = mcause_t'(wd);
                end
            end


            CSR_MTVAL: mtval_next = wd;

            default: ;
        endcase
    end

endmodule
