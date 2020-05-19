//
// HT1080Z for MiSTer IOCTL Loader Module
//
// Copyright (c) 2020 Stephen Eddy
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
        ADDR = 16                           // Address bus width
)
(
    input wire clock, reset,                // I/O clock and async reset

    input wire  ioctl_download,             // Signal indicating an active download in progress
	input wire  [7:0] ioctl_index,          // Menu index used to upload the file
	input wire        ioctl_wr,             // Signal be ioctl to write data (receive)
	input wire [DATA-1:0] ioctl_dout,       // Data being sent into the loader by ioctl
	output reg        ioctl_wait = 0,       // Signal from the laoder to hold the current output data

    output reg loader_wr = 0,			            // Signal to write to ram
    output reg loader_download = 0,	                // Download in progress (active high)
    output reg [ADDR-1:0] loader_addr = ADDR-1'd0,  // Address in ram to write data to
    output reg [DATA-1:0] loader_data = DATA-1'd0,  // Data to write to ram
    output reg [ADDR-1:0] execute_addr = ADDR-1'd0, // Start address for program start
    output reg execute_enable =0	                // Jump to start address (out_execute_addr) - Not implemented
); 

localparam [2:0] 
    IDLE = 0,
    GET_TYPE = 1,
    GET_LEN = 2,
    GET_LSB = 3,
    GET_MSB = 4,
    SETUP = 5,
    TRANSFER = 6,
    IGNORE = 7;

(* syn_encoding = "safe" *) reg[2:0] state, state_next;  

always @(posedge clock, posedge reset) begin
    if (reset) begin
        state <= IDLE;
    end
    else begin
        state <= state_next;
    end
end 

wire loader_wr_next;		
wire loader_download_next;	
wire loader_addr_inc;       
wire [ADDR-1:0] loader_addr_load;      
wire [DATA-1:0] loader_data_next;  // Data to write to ram
wire [ADDR-1:0] execute_addr_next; // Start address for program start
wire execute_enable_next;	

wire ioctl_wait_next;
wire [8:0] block_len_next;
wire [7:0] block_type_next;
wire [ADDR-1:0] block_addr_next;

always @(state, ioctl_download, ioctl_index, ioctl_wr, ioctl_dout, block_type, block_len, block_addr, loader_download, trigger_start)
begin

    loader_wr_next = 0;
    loader_download_next = loader_download;
    block_addr_next = 0;
    loader_addr_inc = 0;
    loader_addr_load = 0;
    loader_data_next = {DATA{1'b0}};
    loader_addr_load = 0;
    execute_addr_next = {ADDR{1'b0}};
    execute_enable_next = 0;
    loader_addr_load = 0;

    ioctl_wait_next = 0;
    block_len_next = block_len;
    block_type_next = block_type;
    state_next = state;

    case(state)
        IDLE: begin 		// No transfer occurring
            if(trigger_start) begin
                loader_download_next = 1;
                state_next = GET_TYPE;
            end
        end
        GET_TYPE: begin		// Start of transfer, load block type
            ioctl_wait_next = 0;
            if(ioctl_wr) begin
                block_type_next = ioctl_dout;
                if(ioctl_dout == 8'd0) begin	// EOF
                    loader_download_next = 0;
                    state_next = IDLE;
                end else begin
                    state_next = GET_LEN;
                end
            end
        end
        GET_LEN: begin		// Setup len or finish transfer
            if(ioctl_wr) begin
                if(block_type == 8'd1) begin
                    case(ioctl_dout)
                    8'd2: block_len_next = 9'd256;
                    8'd1: block_len_next = 9'd0;
                    default: block_len_next = (ioctl_dout - 2) & 9'd255;
                    endcase
                    state_next = GET_LSB;
                end else if(block_type == 8'd2) begin
                    block_len_next = 9'd0;
                    state_next = GET_LSB;
                end else begin
                    block_len_next = ioctl_dout;
                    state_next = IGNORE;
                end
            end
        end
        GET_LSB: begin
            if(ioctl_wr) begin
                block_addr_next[7:0] = ioctl_dout;
                state_next = GET_MSB;
            end 
        end
        GET_MSB: begin
            if(ioctl_wr) begin
                block_addr_next[15:8] = ioctl_dout;
                ioctl_wait_next = 1;
                state_next = SETUP;
            end 
        end
        SETUP: begin		
            if(block_type == 8'd1) begin	// Data block
                loader_addr_load = 1;
                state_next = TRANSFER;
            end if(block_type == 8'd2) begin	
                execute_addr_next = block_addr;
                execute_enable_next = 1;	// toggle execute flag
                if(block_len > 2)  begin
                    state_next = IGNORE; 
                end else begin
                    loader_download_next = 0;
                    state_next = IDLE; 
                end					
            end else begin	// Should only ever be 1 or 2, so error state
                loader_download_next = 0;
                state_next = IDLE;
            end
        end
        TRANSFER: begin
            if(ioctl_wr) begin
                if(block_len > 0) begin
                    loader_addr_inc = 1;
                    block_len_next = block_len - 1;
                    loader_data_next = ioctl_dout;
                    loader_wr_next = 1;
                end else begin	// Move to next block in chain
                    state_next = GET_TYPE;
                    loader_wr_next = 0;
                end
            end
        end
        IGNORE: begin
            if(ioctl_wr) begin
                if(block_len > 0) begin
                    block_len_next = block_len - 1;
                end else begin
                    if(block_type == 8'd0 || block_type == 8'd2) begin
                        state_next = IDLE; 
                        loader_download_next = 0;
                    end else state_next = GET_TYPE;
                end
            end
        end
    endcase
end

reg [8:0] block_len = 9'd0;
reg [7:0] block_type = 8'd0;
reg [ADDR-1:0] block_addr = {ADDR{1'b0}};
reg old_download = 0; 
reg trigger_start = 0;

// Output stage
always @(posedge clock, posedge reset)
begin 
    if (reset) begin
        old_download = 0;
        trigger_start = 0;
        loader_wr <= 0;
        loader_download <= 0;
        loader_addr <= {ADDR{1'b0}};
        loader_data <= {DATA{1'b0}};
        execute_addr <= {ADDR{1'b0}};
        execute_enable <= 0;
        ioctl_wait <= 0;
        block_len <= 9'd0;
        block_type <= 8'd0;
        block_addr <= {ADDR{1'b0}};
    end
    else begin
        loader_wr <= loader_wr_next;
        loader_download <= loader_download_next;
        loader_addr <= loader_addr_load ? block_addr : loader_addr_inc ? loader_addr + 1 : loader_addr;
        loader_data <= loader_data_next;
        execute_addr <= execute_addr_next;
        execute_enable <= execute_enable_next;
        ioctl_wait <= ioctl_wait_next;
        block_len <= block_len_next;
        block_type <= block_type_next;
        block_addr <= block_addr_next;
        if(~old_download && ioctl_download && ioctl_index > 1) begin
            trigger_start <= 1; 
            old_download <= ioctl_download;
        end else trigger_start <= 0;
    end
end
endmodule