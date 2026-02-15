`timescale 1ns / 1ps
`default_nettype none

// wrapper for vivado IP
// 20 cycle latency
module cordic_sin_pipelined (
    input wire clk,
    // angle in radians
    input wire [13:0] angle,  // signed fixed-point, X.X_XXXX_XXXX_XXXX
    input wire angle_valid,
    output logic [15:0] cos,  // signed fixed-point, XX.XX_XXXX_XXXX_XXXX
    output logic [15:0] sin,  // signed fixed-point, XX.XX_XXXX_XXXX_XXXX
    output logic out_valid
);

`ifdef SYNTHESIS
  logic [31:0] out_data;
  cordic_sincos_16 my_cordic (
      .aclk               (clk),                            // input  wire
      .s_axis_phase_tvalid(angle_valid),                    // input  wire
      .s_axis_phase_tdata ({angle[13], angle[13], angle}),  // input  wire [15:0]
      .m_axis_dout_tdata  (out_data),                       // output wire [31:0]
      .m_axis_dout_tvalid (out_valid)                       // output wire
  );

  assign sin = out_data[31:16];
  assign cos = out_data[15:0];
`else  /* ! SYNTHESIS */

  // minimum logic for latency matching
  logic [19:0][13:0] angle_pipe;
  logic [19:0] valid_pipe;

  always_ff @(posedge clk) begin
    angle_pipe <= {angle_pipe[18:0], angle};
    valid_pipe <= {valid_pipe[18:0], angle_valid};
  end

  assign sin = {angle_pipe[19], 2'b00};
  assign cos = {angle_pipe[19], 2'b00};
  assign out_valid = valid_pipe[19];

`endif  /* ! SYNTHESIS */

endmodule

`default_nettype wire
