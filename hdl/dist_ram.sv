`timescale 1ns / 1ps
`default_nettype none

module dist_ram #(
    parameter WIDTH = 16,
    parameter DEPTH = 64,
    parameter INIT_FILE = ""
) (
    input  wire                      clk,
    input  wire  [$clog2(DEPTH)-1:0] addr,
    input  wire                      we,
    input  wire  [        WIDTH-1:0] din,
    output logic [        WIDTH-1:0] dout
);

  logic [WIDTH-1:0] data[DEPTH-1:0];
  assign dout = data[addr];

  always_ff @(posedge clk) begin
    if (we) begin
      data[addr] <= din;
    end
  end

  // initiallize the memory with the specified init file,
  // or zero out the memory otherwize
  generate
    if (INIT_FILE != "") begin : use_init_file
      initial $readmemh(INIT_FILE, data, 0, DEPTH - 1);
    end else begin : init_lutram_to_zero
      integer ram_index;
      initial
        for (ram_index = 0; ram_index < DEPTH; ram_index = ram_index + 1)
          data[ram_index] = {WIDTH{1'b0}};
    end
  endgenerate

endmodule

`default_nettype wire
