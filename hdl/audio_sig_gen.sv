`timescale 1ns / 1ps
`default_nettype none

module audio_sig_gen (
    input wire clk,
    input wire rst,
    output logic [11:0] sample_cycle_count
);
  parameter SAMPLE_CYCLE_LENGTH = 2272;

  always_ff @(posedge clk) begin
    if (rst || sample_cycle_count >= SAMPLE_CYCLE_LENGTH - 1) begin
      sample_cycle_count <= 0;
    end else begin
      sample_cycle_count <= sample_cycle_count + 1'b1;
    end
  end
endmodule

`default_nettype wire
