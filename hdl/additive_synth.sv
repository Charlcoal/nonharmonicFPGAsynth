`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else  /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */


module additive_synth (
    input wire clk,
    input wire rst,
    output logic signed [19:0] sample_out,
    output logic sample_valid
);
  localparam SAMPLE_CYCLE_LENGTH = 2272;

  logic [11:0] sample_cycle_count;

  always_ff @(posedge clk) begin
    if (rst || sample_cycle_count >= SAMPLE_CYCLE_LENGTH - 1) begin
      sample_cycle_count <= 0;
    end else begin
      sample_cycle_count <= sample_cycle_count + 1'b1;
    end
  end

  logic [9:0] frequency_read_index;
  logic [9:0] phase_read_index;
  logic [9:0] phase_write_index;
  logic [9:0] intensity_read_index;

  always_ff @(posedge clk) begin
    frequency_read_index <= sample_cycle_count[9:0];
    phase_read_index <= sample_cycle_count[9:0];
    phase_write_index <= sample_cycle_count[9:0] - 10'd3;
    intensity_read_index <= sample_cycle_count[9:0] - 10'd20;
  end

  logic is_writing;

  logic [17:0] intensity;
  logic [17:0] frequency;
  logic [17:0] cur_phase;
  logic [17:0] next_phase;

  always_ff @(posedge clk) begin
    next_phase <= cur_phase + frequency;
    is_writing <= sample_cycle_count >= 12'd3 && sample_cycle_count < 12'd1027;
  end

  logic sin_input_valid;
  logic sin_valid;
  logic last_sin_valid;
  logic signed [15:0] sin;
  logic signed [35:0] accum;

  always_ff @(posedge clk) begin
    sin_input_valid <= sample_cycle_count >= 12'd2 && sample_cycle_count < 12'd1026;
    last_sin_valid  <= sin_valid;
    if (sin_valid) begin
      accum <= accum + $signed(sin) * $signed({1'b0, intensity});
    end else begin
      accum <= 0;
    end
    sample_valid <= !sin_valid && last_sin_valid;
    sample_out   <= accum[35:16];
  end

  cordic_sin_pipelined my_sin (
      .clk        (clk),
      .angle_valid(sin_input_valid),
      .angle      (cur_phase[17:4]),
      .sin        (sin),
      .cos        (),
      .out_valid  (sin_valid)
  );

  // 2 cycle delay
  xilinx_single_port_ram_read_first #(
      .RAM_WIDTH(18),  // Specify RAM data width
      .RAM_DEPTH(1024),  // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("HIGH_PERFORMANCE"),  // "HIGH_PERFORMANCE" or "LOW_LATENCY"
      // Specify name/location of RAM initialization file if using one (leave blank if not)
      .INIT_FILE(
      `FPATH(add_synth_intensities.mem)
      )
  ) intensity_BRAM (
      .addra(intensity_read_index),  // Address bus, width determined from RAM_DEPTH
      .dina(0),  // RAM input data, width determined from RAM_WIDTH
      .clka(clk),  // Clock
      .wea(0),  // Write enable
      .ena(1),  // RAM Enable, for additional power savings, disable port when not in use
      .rsta(rst),  // Output reset (does not affect memory contents)
      .regcea(1),  // Output register enable
      .douta(intensity)  // RAM output data, width determined from RAM_WIDTH
  );

  // 2 cycle delay
  xilinx_single_port_ram_read_first #(
      .RAM_WIDTH(18),  // Specify RAM data width
      .RAM_DEPTH(1024),  // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("HIGH_PERFORMANCE"),  // "HIGH_PERFORMANCE" or "LOW_LATENCY"
      // Specify name/location of RAM initialization file if using one (leave blank if not)
      .INIT_FILE(
      `FPATH(add_synth_frequencies.mem)
      )
  ) frequency_BRAM (
      .addra(frequency_read_index),  // Address bus, width determined from RAM_DEPTH
      .dina(0),  // RAM input data, width determined from RAM_WIDTH
      .clka(clk),  // Clock
      .wea(0),  // Write enable
      .ena(1),  // RAM Enable, for additional power savings, disable port when not in use
      .rsta(rst),  // Output reset (does not affect memory contents)
      .regcea(1),  // Output register enable
      .douta(frequency)  // RAM output data, width determined from RAM_WIDTH
  );

  // 2 cycle delay
  xilinx_true_dual_port_read_first_1_clock_ram #(
      .RAM_WIDTH(18),  // Specify RAM data width
      .RAM_DEPTH(1024),  // Specify RAM depth (number of entries)
      .RAM_PERFORMANCE("HIGH_PERFORMANCE"),  // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
      .INIT_FILE (                        // Specify name/location of RAM initialization file if using one (leave blank if not)
      `FPATH(add_synth_phases.mem)
      )
  ) phase_BRAM (
      .addra(phase_read_index),  // Port A address bus, width determined from RAM_DEPTH
      .addrb(phase_write_index),  // Port B address bus, width determined from RAM_DEPTH
      .dina(0),  // Port A RAM input data
      .dinb(next_phase),  // Port B RAM input data
      .clka(clk),  // Clock
      .wea(0),  // Port A write enable
      .web(is_writing),  // Port B write enable
      .ena(1),  // Port A RAM Enable, for additional power savings, disable port when not in use
      .enb(1),  // Port B RAM Enable, for additional power savings, disable port when not in use
      .rsta(0),  // Port A output reset (does not affect memory contents)
      .rstb(0),  // Port B output reset (does not affect memory contents)
      .regcea(1),  // Port A output register enable
      .regceb(1),  // Port B output register enable
      .douta(cur_phase),  // Port A RAM output data
      .doutb()  // Port B RAM output data
  );

endmodule

`default_nettype wire
