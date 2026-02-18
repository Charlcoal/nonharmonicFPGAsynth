`timescale 1ns / 1ps
`default_nettype none

// status codes beginning with 1111 are unsupported
module midi_receive (
    input wire clk,
    input wire rst,
    input wire din,
    output logic dout_valid,
    output logic [6:0] status,
    output logic [6:0] data1,
    output logic [6:0] data2
);

  logic uart_dout_valid;
  logic [7:0] uart_dout;

  logic is_reading_data;
  logic has_recieved_data_byte;
  logic is_single_data;  // for Program Change / Channel Pressure

  always_ff @(posedge clk) begin
    if (rst) begin
      dout_valid <= 0;

      is_reading_data <= 0;
      is_single_data <= 1'bX;
      has_recieved_data_byte <= 1'bX;
    end else begin
      if (uart_dout_valid) begin
        if (uart_dout[7]) begin
          // Status byte
          status <= uart_dout[6:0];
          is_single_data <= uart_dout[6:5] == 2'b10;
          has_recieved_data_byte <= 0;
          is_reading_data <= 1'b1;
        end else if (is_reading_data) begin
          // Data byte
          has_recieved_data_byte <= 1'b1;
          if (has_recieved_data_byte) begin
            data2 <= uart_dout[6:0];
          end else begin
            data1 <= uart_dout[6:0];
          end
          if (has_recieved_data_byte == 1 || is_single_data) begin
            dout_valid <= 1;
            is_reading_data <= 0;
          end
        end
      end else if (dout_valid) begin
        dout_valid <= 0;
      end
    end
  end

  uart_receive #(
      .BAUD_RATE(31250)
  ) uart_midi (
      .clk(clk),
      .rst(rst),
      .din(din),
      .dout_valid(uart_dout_valid),
      .dout(uart_dout)
  );
endmodule
`default_nettype wire
