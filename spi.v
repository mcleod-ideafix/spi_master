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

module spi_master (
  // Host interface
  input wire clk,  // 2 veces la frecuencia de SCLK 
  input wire reset,
  input wire [7:0] din,
  output reg [7:0] dout,
  input wire read,
  input wire write,
  output reg busy,
  // SPI interface
  input wire miso,
  output reg mosi,
  output reg sclk
);
  
  localparam  
    REPOSO  = 2'd0,
    TRANSF1 = 2'd1,
    TRANSF2 = 2'd2;
    
  reg [7:0] regspi = 8'hFF;    // registro de 8 bits de desplazamiento, SPI
  reg [1:0] estado = REPOSO;   // estado del autómata
  reg [3:0] cntbits = 4'b1000; // contador de 0 a 8 para saber por cuál bit vamos
  
  always @(posedge clk) begin
    if (reset == 1'b1) begin   // el reset nos deja en el estado de reposo
      regspi <= 8'hFF;
      estado <= REPOSO;
      cntbits <= 4'b1000;
      sclk <= 1'b0;
    end
    else begin
      case (estado)
        REPOSO:                // en este estado esperamos un pulso de lectura o escritura
          begin
            if (read == 1'b1) begin  // si se recibe pulso de lectura...
              estado <= TRANSF1;
              dout <= regspi;  // copiamos al bus de datos lo que hubiera en el reg. SPI
              regspi <= 8'hFF; // metemos 11111111 en dicho registro SPI
              cntbits <= 4'b0000; // y comenzamos la cuenta progresiva para enviar estos ocho "1"s
            end
            else if (write == 1'b1) begin  // si se recibe pulso de escritura...
              estado <= TRANSF1;
              regspi <= din;   // metemos en el registro SPI el dato que queremos enviar
              cntbits <= 4'b0000; // y comenzamos la cuenta progresiva para enviar estos 8 bits
            end
          end
        TRANSF1:  // en este estado pasamos de 0 a 1 en SCLK
          begin
            if (cntbits[3] == 1'b0) begin  // hemos enviado 8 bits? Si es que no...
              sclk <= 1'b1;            // ponemos el reloj SPI a 1 
              estado <= TRANSF2;       // y vamos al estado siguiente
            end
            else
              estado <= REPOSO;        // si es que si, volvemos al estado de reposo
          end
        TRANSF2:  // en este estado pasamos de 1 a 0 en SCLK y desplazamos el registro SPI
          begin
            sclk <= 1'b0;                  // ponemos el reloj SPI a 0
            regspi <= {regspi[6:0], miso}; // desplazamos a la izquierda el registro SPI
            cntbits <= cntbits + 4'd1;     // incrementamos la cuenta de bits transmitidos
            estado <= TRANSF1;             // y volvemos de nuevo a TRANSF1
          end
      endcase
    end
  end
  
  always @* begin
    if (estado == REPOSO)   // si no estoy en reposo, es que estoy ocupado
      busy = 1'b0;
    else
      busy = 1'b1;
    mosi = regspi[7];  // MOSI es siempre el bit 7 del registro SPI
  end
endmodule


// This module is basically for testing the master core in simulation, but it may be usefull in a real environment, so you
// can have to CPLD/FPGAs communication to each other using the SPI protocol.
module spi_slave (
  // SPI interface
  input wire sclk,
  input wire mosi,
  output reg miso,
  // Host interface
  input wire [7:0] din,
  output reg [7:0] dout,
  input wire write
);
  
  reg [7:0] regspi = 8'hFF;    // registro de 8 bits de desplazamiento, SPI
  
  always @(negedge sclk) begin
    if (write == 1'b1)
      regspi <= din;
    else
      regspi <= {regspi[6:0], mosi};
  end
  
  always @* begin
    dout = regspi;
    miso = regspi[7];
  end
endmodule

`default_nettype wire
