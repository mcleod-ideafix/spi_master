/*
 * This file is part of "SPI master core"
 * Copyright (c) 2018 Miguel Angel Rodriguez Jodar.
 * 
 * This program is free software: you can redistribute it and/or modify  
 * it under the terms of the GNU General Public License as published by  
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

`timescale 1us / 1us
`default_nettype none

module testbench_spi;
  reg clk, reset, read_master, write_master, write_slave;
  reg [7:0] din_master, din_slave;
  wire busy, sclk, miso, mosi;
  wire [7:0] dout_slave, dout_master;
  
  spi_master maestro (
    .clk(clk),
    .reset(reset),
    .din(din_master),
    .dout(dout_master),
    .read(read_master),
    .write(write_master),
    .busy(busy),
    .sclk(sclk),
    .miso(miso),
    .mosi(mosi)
  );
  
  spi_slave esclavo (
    .sclk(sclk),
    .mosi(mosi),
    .miso(miso),
    .din(din_slave),
    .dout(dout_slave),
    .write(write_slave)
  );
  
  initial begin
    $dumpfile ("dump.vcd");     //
    $dumpvars (0, testbench_spi);   // Interfaz con GTKWave
    clk = 1'b0;
    reset = 1'b1;
    read_master = 1'b0;
    write_master = 1'b0;
    write_slave = 1'b0;
    din_slave = 8'hFF;
    din_master = 8'h00;
    
    repeat (2)
      @(posedge clk);
    reset = 1'b0;
    repeat (2)
      @(posedge clk);
    
    repeat (256) begin  // probamos los 256 valores diferentes de 8 bits
      @(posedge clk);
      write_master = 1'b1;  // pulso alto a write para que se acepte el byte
      @(posedge clk);
      @(posedge clk);
      write_master = 1'b0;  // y ahora a bajo
      @(busy == 1'b0);  // esperamos a que se transmita
      @(posedge clk);
      din_master = din_master + 8'd1;  // y vamos a por el siguiente valor
    end
    $finish;
  end
  
  always begin
    clk = #5 ~clk;
  end
endmodule

`default_nettype wire
