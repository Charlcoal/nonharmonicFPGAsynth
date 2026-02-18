`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else  /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */

module synth_controller (
    input wire clk,
    input wire rst,
    input wire din_valid,
    input wire [6:0] status,
    input wire [6:0] data1,
    input wire [6:0] data2,
    output logic [17:0] frequency
);

  logic [6:0] cur_note;

  always_ff @(posedge clk) begin
    if (rst || (din_valid && status[6:4] == 3'b000 && data1 == cur_note)) begin
      frequency <= 18'd0;
    end else if (din_valid && status[6:4] == 3'b001) begin
      frequency <= freq_from_lookup;
      cur_note  <= data1;
    end
  end

  logic [17:0] freq_from_lookup;
  dist_ram #(
      .WIDTH(18),
      .DEPTH(128),
      .INIT_FILE(`FPATH(midi_frequencies.mem))
  ) freq_lookup (
      .clk (clk),
      .addr(data1),
      .we  (1'b0),
      .din (18'hXXXX),
      .dout(freq_from_lookup)
  );

endmodule

`default_nettype wire
