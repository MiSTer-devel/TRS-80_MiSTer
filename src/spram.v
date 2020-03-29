//
// spram.v
//
// sdram controller implementation for the MiSTer board by 
// 
// Copyright (c) 2019 Alan Steremberg 
// 
// This source file is free software: you can redistribute it and/or modify 
// it under the terms of the GNU General Public License as published 
// by the Free Software Foundation, either version 3 of the License, or 
// (at your option) any later version. 
// 
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>. 
//

module spram #(
    parameter data_width = 8,
    parameter addr_width = 10
) (
    // Port A
    input   wire                clock,
    input   wire                wren,
    input   wire    [addr_width-1:0]  address,
    input   wire    [data_width-1:0]  data,
    output  reg     [data_width-1:0]  q,
     
    input wire cs
);
 
// Shared memory
reg [data_width-1:0] mem [(2**addr_width)-1:0];
 
// Port A
always @(posedge clock) begin
    q      <= mem[address];
    if(wren) begin
        q      <= data;
        mem[address] <= data;
    end
end
 
 
endmodule
