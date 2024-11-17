//
// HT1080Z for MiSTer IOCTL Loader Module
//
// Copyright (c) 2020 Stephen Eddy
//
// Add clear memory function by theflynn49 nov. 2024
// it's a bit of a hack of this module's purpose, but clearing the memory is much like loading /dev/null in it ... 
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
//
// * Redistributions in synthesized form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//
// * Neither the name of the author nor the names of other contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written agreement from the author.
//
// * License is granted for non-commercial use only.  A fee may not be charged
//   for redistributions as source code or in synthesized/hardware form without 
//   specific prior written agreement from the author.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

module cmd_loader
#( parameter
        DATA = 8,                           // Data bus width
        ADDR = 16,                          // Address bus width
        INDEX = 2                           // Index of file type in menu
)
(
    input wire clock, reset,                // I/O clock and async reset
	 input wire erase_mem,						  // Erase all memory

    input wire      ioctl_download,         // Signal indicating an active download in progress
	 input wire  [7:0]       ioctl_index,    // Menu index used to upload the file
	 input wire              ioctl_wr,       // Signal be ioctl to write data (receive)
	 input wire [DATA-1:0]   ioctl_dout,     // Data being sent into the loader by ioctl
    input wire [23:0]       ioctl_addr,     // Offset into loaded file
	 output logic            ioctl_wait,     // Signal from the laoder to hold the current output data

    output logic loader_wr,			        // Signal to write to ram
    output logic loader_download,	        // Download in progress (active high)
    output logic [ADDR-1:0] loader_addr,    // Address in ram to write data to
    output logic [DATA-1:0] loader_data,    // Data to write to ram
    output logic [ADDR-1:0] execute_addr,   // Start address for program start
    output logic execute_enable,   	        // Jump to start address (out_execute_addr) - Not implemented
    output logic [31:0] iterations          // Used for debugging via SignalTap
); 

//const bit [15:0] SYSTEM_ENTRY_LSB='h40DF;
//const bit [15:0] SYSTEM_ENTRY_MSB='h40E0;

typedef enum bit [3:0] {IDLE, GET_TYPE, GET_LEN, GET_LSB, GET_MSB, SETUP, TRANSFER, EXECUTE, IGNORE, FINISH, SET_ZERO, DO_ZERO} loader_states;
loader_states state;

logic [8:0] block_len;
logic [7:0] block_type;
logic [15:0] block_addr;
logic old_download = 0;
logic first_block;

always_ff @(posedge clock or posedge reset)
begin

	if (reset)
	begin
		execute_enable <= 0;
		loader_addr <= '0;
		execute_addr <= '0;
		loader_data <= '0;
	//	old_download <= 0;
		state <= IDLE;
		loader_download <= 0;
		ioctl_wait <= 0;
		block_addr <= '0;
        iterations <= 0;
        first_block <= 0;
	end 
	else begin

		loader_wr <= '0;
		ioctl_wait <= '0;
		execute_enable <= 0;

        iterations <= iterations + 32'd1;   // Used for debugging

		case(state)
			IDLE: begin 		// No transfer occurring
				if(~old_download && ioctl_download && ioctl_index==INDEX && ioctl_addr == '0) begin
					loader_download <= 1;
					state <= GET_TYPE;
				end
				if (erase_mem) begin
					loader_download <= 1;
					state <= SET_ZERO;
				end
			end
			GET_TYPE: begin		// Start of transfer, load block type
				if(ioctl_wr) begin
					block_type <= ioctl_dout;
					if(ioctl_dout ==8'd0) begin	// EOF
						loader_download <= 0;
						state <= IDLE;
                    end else state <= GET_LEN;
				end
			end
			GET_LEN: begin		// Setup len or finish transfer
				if(ioctl_wr) begin
					if(block_type == 8'd1) begin
						case(ioctl_dout)
						8'd2: block_len <= 9'd256;
						8'd1: block_len <= 9'd255;
						8'd0: block_len <= 9'd254;
						default: block_len <= 9'((ioctl_dout - 2 ) & 9'd255);
						endcase
						state <= GET_LSB;
					end 
                    else if (block_type == 8'd2) begin
						block_len <= 9'd0;
						state <= GET_LSB;
					end 
                    else begin
						block_len <= ioctl_dout;
						state <= IGNORE;
					end
				end
			end
			GET_LSB: begin
				if(ioctl_wr) begin
					block_addr[7:0] <= ioctl_dout;
					state <= GET_MSB;
				end 
			end
			GET_MSB: begin
				if(ioctl_wr) begin
					block_addr[15:8] <= ioctl_dout;
					//ioctl_wait <= 0; // should maybe be 1?
					state <= SETUP;
				end 
			end
			SETUP: begin		
				if(block_type == 8'd1) begin	// Data block
					//loader_addr <= block_addr;
					state <= TRANSFER;
                    first_block <= 1;
                end 
                else if (block_type == 8'd2) begin	
                    state <= EXECUTE;
                    // Write into system entry point for '/'
                    //loader_addr <= SYSTEM_ENTRY_LSB;
                    //loader_data <= block_addr[7:0];
                    //loader_wr <= 1;
				end 
                else begin	// Should only ever be 1 or 2, so error state
					state <= FINISH;
				end
			end
			TRANSFER: begin
                if(block_len > 9'd0) begin
                    if(ioctl_wr) begin
                        if (first_block) begin
                            loader_addr <= block_addr; 
                            first_block <= 0;
                        end
                        else begin 
                            loader_addr <= loader_addr + 16'd1;
                        end
                        block_len <= block_len - 9'd1;
                        loader_data <= ioctl_dout;
                        loader_wr <= 1;
    				end
                end else begin	// Move to next block in chain
                    state <= GET_TYPE;
                    //ioctl_wait <= 1;
                    loader_wr <= 0;
                end
			end
			IGNORE: begin
                if(block_len > 9'd0) begin
                    if(ioctl_wr) begin
                        block_len <= block_len - 9'd1;
                    end
                end else begin	// Move to next block in chain
                    if(block_type == 8'd0 || block_type == 8'd2) begin
                        state <= FINISH; 
                    end else begin
                        //ioctl_wait <= 1;
                        state <= GET_TYPE;
                    end
                end
			end
            EXECUTE: begin
                //loader_addr <= SYSTEM_ENTRY_MSB;
                //loader_data <= block_addr[15:8];
                //loader_wr <= 1;
				execute_addr <= block_addr;
				execute_enable <= 1;	// toggle execute flag

                if(block_len > 2)  begin
                	state <= IGNORE; 
                end 
                else begin
                	state <= FINISH; 
                end					
            end
            FINISH: begin
                loader_download <= 0;
                state <= IDLE;
            end
				SET_ZERO: begin
					loader_addr <= 16'h4000 ; // erase memory from 4000 to FFFF
					state <= DO_ZERO ;
				end
				DO_ZERO: begin
					if (&loader_addr == 1'b1) begin
						state <= FINISH ;
						execute_addr <= 16'd0 ; // reboot
						execute_enable <= 1;	
					end else begin	
						loader_data <= 8'd0 ;
                  loader_wr <= 1;
						loader_addr <= loader_addr + 16'd1 ;
					end
				end
		endcase
        // Increment iteration counter
        // Reset back when ioctl download ends
        if(old_download && ~ioctl_download && ioctl_index == INDEX) begin
            old_download <= 0;
            loader_download <= 0;
            state <= IDLE;
        end
	end
end
endmodule

