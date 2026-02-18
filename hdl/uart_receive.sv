`timescale 1ns / 1ps  //
`default_nettype none

module uart_receive #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        din,
    output logic       dout_valid,
    output logic [7:0] dout
);
  localparam BAUD_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

  logic [$clog2(BAUD_BIT_PERIOD)-1:0] baud_count;
  logic [$clog2(BAUD_BIT_PERIOD)-1:0] next_baud_count;

  typedef enum {
    IDLE = 0,
    START = 1,
    DATA = 2,
    STOP = 3,
    TRANSMIT = 4
  } uart_state_t;


  logic              baud_trigger;
  uart_state_t       state;
  uart_state_t       next_state;
  logic        [7:0] data_recieved;
  logic        [7:0] next_data_recieved;
  logic        [2:0] bit_count;
  logic        [2:0] next_bit_count;


  assign dout_valid = state == TRANSMIT;
  assign dout = data_recieved;

  always_comb begin
    if (!rst && state != IDLE) begin
      if (baud_count == (BAUD_BIT_PERIOD - 1)) begin
        baud_trigger = 1'b1;
        next_baud_count = 0;
      end else begin
        baud_trigger = 1'b0;
        next_baud_count = baud_count + 1;
      end
    end else begin
      baud_trigger = 1'b0;
      next_baud_count = BAUD_BIT_PERIOD >> 1;
    end
  end

  always_comb begin
    if (rst) begin
      next_state = IDLE;
      next_bit_count = 3'bXXX;
      next_data_recieved = 8'hXX;

    end else if (state == IDLE && ~din) begin
      next_state = START;
      next_bit_count = 3'bXXX;
      next_data_recieved = 8'hXX;

    end else if (state == START && baud_trigger) begin
      if (din) begin
        next_state = IDLE;
        next_bit_count = 3'bXXX;
      end else begin
        next_state = DATA;
        next_bit_count = 3'b000;
      end
      next_data_recieved = 8'hXX;

    end else if (state == DATA && baud_trigger) begin
      if (bit_count == 3'b111) begin
        next_state = STOP;
        next_bit_count = 3'bXXX;
      end else begin
        next_state = DATA;
        next_bit_count = bit_count + 1;
      end
      next_data_recieved = {din, data_recieved[7:1]};

    end else if (state == STOP && baud_trigger) begin
      if (din) begin
        next_state = TRANSMIT;
        next_data_recieved = data_recieved;
      end else begin
        next_state = IDLE;
        next_data_recieved = 8'hXX;
      end
      next_bit_count = 3'bXXX;

    end else if (state == TRANSMIT) begin
      next_state = IDLE;
      next_bit_count = 3'bXXX;
      next_data_recieved = 8'hXX;

    end else begin
      next_state = state;
      next_bit_count = bit_count;
      next_data_recieved = data_recieved;
    end
  end

  always_ff @(posedge clk) begin
    baud_count <= next_baud_count;
    state <= next_state;
    data_recieved <= next_data_recieved;
    bit_count <= next_bit_count;
  end



endmodule  // uart_receive

`default_nettype wire
