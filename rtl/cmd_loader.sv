//
// HT1080Z for MiSTer IOCTL Loader Module
//
// Copyright (c) 2020 Stephen Eddy
//
// All additions by "theflynn49" (c) 2024 Alexey Melnikov and the MiSTer community
//
// Add clear memory function by theflynn49 nov. 2024
// it's a bit of a hack of this module's purpose, but clearing the memory is much like loading /dev/null in it ... 
//
// Add Load /BAS file function by theflynn49 nov. 2024 
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
	 input wire cpum1,
	 input wire erase_mem,						  // Erase all memory

    input wire      ioctl_download,         // Signal indicating an active download in progress
	 input wire  [15:0]      ioctl_index,    // Menu index used to upload the file
	 input wire              ioctl_wr,       // Signal be ioctl to write data (receive)
	 input wire [DATA-1:0]   ioctl_dout,     // Data being sent into the loader by ioctl
    input wire [23:0]       ioctl_addr,     // Offset into loaded file
	 output logic            ioctl_wait,     // Signal from the laoder to hold the current output data

    output logic loader_wr,			        // Signal to write to ram
    output logic loader_download,	        // Download in progress (active high)
    output logic [ADDR-1:0] loader_addr,    // Address in ram to write data to
    output logic [DATA-1:0] loader_data,    // Data to write to ram
	 input  wire  [DATA-1:0] loader_din,	  // Data to read from ram
    output logic [ADDR-1:0] execute_addr,   // Start address for program start
    output logic execute_enable,   	        // Jump to start address (out_execute_addr) 
	 input  wire  [1:0] execute_method,		  // How to call the program at the end of loading CAS/DOS/NONE
	 input  wire [ADDR-1:0] exec_stack,
    output logic [ADDR-1:0] dbg_min_addr,   // Start address for program start
    output logic [ADDR-1:0] dbg_max_addr,   // Start address for program start
	 
    output logic [31:0] iterations          // Used for debugging via SignalTap
); 

//const bit [15:0] SYSTEM_ENTRY_LSB='h40DF;
//const bit [15:0] SYSTEM_ENTRY_MSB='h40E0;

typedef enum bit [4:0] {IDLE, GET_TYPE0, GET_TYPE, GET_LEN, GET_LSB, GET_MSB, SETUP, TRANSFER, EXECUTE, IGNORE, FINISH, 
								WAIT_M1, WAIT_M1_B, WAIT_M1_E, LOAD_REGS, STACK2, STACK3,
								LOAD_BASIC_S1, LOAD_BASIC_S2, LOAD_BASIC_S3, LOAD_BASIC_S4, LOAD_BASIC_S5, LOAD_BASIC_INSERT_CODE,
								LOAD_BASIC, LOAD_BASIC_INSERT0, LOAD_BASIC_END, LOAD_BASIC_END2, SET_ZERO, DO_ZERO} loader_states;
loader_states state;

logic [8:0] block_len;
logic [7:0] block_type;
logic got_block ;
logic [15:0] next_addr ; // ptr on the next pointer in bas file to edit later
logic [15:0] prev_addr ; // ptr on the prev pointer in bas file to edit now
logic [3:0] byte_ctr ; // logic counter
logic [3:0] nullbytes ; // and counter for /BAS loader states 
logic [15:0] block_addr;
logic [15:0] basic_ptr; // pointer ro basic pgm
logic [15:0] himem_ptr; // pointer to end of memory
logic [15:0] last_zero_ptr; // last 00 inserted
logic seg_msb_is_0 ; 
logic first_block;

always_ff @(posedge clock or posedge reset)
begin

	if (reset)
	begin
		execute_enable <= 0;
		got_block <= 0 ;
		loader_addr <= '0;
		execute_addr <= '0;
		loader_data <= '0;
		state <= IDLE;
		loader_download <= 0;
		ioctl_wait <= 0;
		block_addr <= '0;
      iterations <= 0;
      first_block <= 0;
		basic_ptr <= '0 ;
		himem_ptr <= 16'hffff ;
		dbg_max_addr<=16'h4000 ;
		dbg_min_addr<=16'hffff ;
	end 
	else begin

		loader_wr <= '0;
      iterations <= iterations + 32'd1;   // Used for debugging
		// if ( (state<FINISH) && (state != IDLE) && (cpum1=='0) ) loader_download <= 1;
		
		case(state)
			IDLE: begin 		// No transfer occurring
				execute_enable <= 0;
				ioctl_wait <= 0;		
				if(ioctl_download && ioctl_index[5:0]==INDEX && ioctl_index[15:6]==0 && ioctl_addr == '0) begin  // index 2.0
			//		loader_download <= 1;   // this will be done the next time M1 goes to 0, by the statement a few lines above
													// because we can't wait unless we break the stream down here (that could be fixed later)
													// and we CANNOT raise loader_download to stop the CPU if M1 is not low
					dbg_max_addr<=16'h4000 ;
					dbg_min_addr<=16'hffff ;
					state <= WAIT_M1 ;
					ioctl_wait <= 1 ; 
					if (ioctl_wr) begin
						got_block <= 1 ;
						block_type = ioctl_dout ;
					end else got_block <= 0 ;
				end else
				if(ioctl_download && ioctl_index[5:0]==INDEX && ioctl_index[15:6]==1 && ioctl_addr == '0) begin  // index 2.1
					ioctl_wait<=1 ; 
					state <= WAIT_M1_B;
					if (ioctl_wr) begin
						got_block <= 1 ;
						block_type = ioctl_dout ;
					end else got_block <= 0 ;
				end 
				else if (erase_mem) begin
					state <= WAIT_M1_E;
				end
			end
			WAIT_M1: begin
				if (cpum1=='0) begin
					loader_download <= 1;
					state <= GET_TYPE0;	
				end 
				if (got_block == 0) begin
					if (ioctl_wr) begin
						got_block <= 1 ;
						block_type = ioctl_dout ;
					end
				end
			end
			WAIT_M1_B: begin
				if (cpum1=='0) begin
					loader_addr <= 16'h40A4 ; // address of pointer to the Begining of basic in memory
					loader_download <= 1;
					state <= LOAD_BASIC_S1;
				end 
				if (got_block == 0) begin
					if (ioctl_wr) begin
						got_block <= 1 ;
						block_type = ioctl_dout ;
					end
				end				
			end
			WAIT_M1_E: begin
				if (cpum1=='0) begin
					loader_download <= 1;
					state <= SET_ZERO;	
				end 
			end
			
			GET_TYPE0: begin		// very first block type
				ioctl_wait <= 0 ;
				if (got_block) begin
					if(block_type ==8'd0) begin	// EOF
						loader_download <= 0;
						state <= IDLE;
               end else state <= GET_LEN;
				end else begin
					state <= GET_TYPE ;
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
									if (dbg_min_addr>block_addr && block_addr >= 16'h4000) dbg_min_addr <= block_addr ;
									if (dbg_max_addr<block_addr) dbg_max_addr <= block_addr ;
                       end
                        else begin 
                           loader_addr <= loader_addr + 16'd1; 
									if (dbg_max_addr<=loader_addr) dbg_max_addr <= loader_addr + 16'd1 ;
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
                        state <= LOAD_REGS; 
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
            if(block_len > 2)  begin
              	state <= IGNORE; 
            end else begin
					state <= LOAD_REGS; 
            end					
         end
			LOAD_REGS: begin
				case (execute_method) 
				2'b00, 
				2'b01 :
					begin
						execute_enable <= 1; // toggle execute flag : note that we don't need the CPU clock for this to work**
						state <= FINISH ;
					end
				2'b11 :		// Experimental, but it was disapointing. (push 402D on stack before jmping)
					begin
						loader_addr <= exec_stack-16'd1 ;
						loader_data <= 8'h2D ; // prepare a return addr to 402Dh
						loader_wr <= 1;
						state <= STACK2 ;
					end 
				default:
					state <= FINISH ;
				endcase ;	
			end
			STACK2: begin
				loader_addr <= exec_stack-16'd2;
				loader_data <= 8'h40 ; // prepare a return addr to 042Dh
				loader_wr <= 1;
				state <= STACK3 ;
			end
			STACK3: begin
				loader_wr <= 0;
				state <= FINISH ;	
				execute_enable <= 1;
			end
			FINISH: begin
               loader_download <= 0; // free the CPU
					execute_enable <= 0;	// toggle execute flag back
               state <= IDLE;
         end
			LOAD_BASIC_S1: begin  // expect FF and read LSB(pointer to basic prg)
					if(got_block && block_type==8'hff) begin
							loader_addr <= loader_addr + 16'd1; // MSB of pointer
							state <= LOAD_BASIC_S2 ;
					end else begin // wrong basic FF header
							state <= IDLE ;   // abort
							ioctl_wait <= 0 ;
							loader_download <= 0;
				   end
			end
			LOAD_BASIC_S2: begin // read LSB(pointer to basic prg)
				basic_ptr[7:0] <= loader_din ;
				loader_addr <= 16'h40b1 ; // LSB of pointer to HIMEM
				state <= LOAD_BASIC_S3 ;
 			end
			LOAD_BASIC_S3: begin // read MSB(pointer to basic prg)
					basic_ptr[15:8] <= loader_din ;
					loader_addr <= loader_addr + 16'd1; // MSB of pointer
					state <= LOAD_BASIC_S4 ;
 				end
			LOAD_BASIC_S4: begin // read  Himem LSB(pointer to basic prg)
					himem_ptr[7:0] <= loader_din ;
					loader_addr <= basic_ptr - 16'd1 ; // MSB of pointer
					last_zero_ptr <= basic_ptr - 16'd1 ;
					state <= LOAD_BASIC_S5 ;
 				end
			LOAD_BASIC_S5: begin // read HiMem MSB(pointer to basic prg)
			//		himem_ptr[15:8] <= loader_din ;
					himem_ptr <= { loader_din, himem_ptr[7:0] } - 16'd256 ; // reserve a few bytes for safety or else basic crashes
			//	loader_addr <= loader_addr + 16'd1;
					if (basic_ptr > 16'h4200 && {loader_din, himem_ptr[7:0]} > basic_ptr) begin
						nullbytes <= 4'd0 ;
						byte_ctr <= 4'd0 ;
						prev_addr <= basic_ptr ;
						state <= LOAD_BASIC ;
					end else begin
						state <= FINISH ; // Incoherent pointers
					end
					ioctl_wait <= 0; // either case, let's roll the rest of the file
 				end
			LOAD_BASIC: begin
				if(ioctl_wr) begin
					loader_wr <= 1;
					if (byte_ctr != 4'd4) byte_ctr <= byte_ctr + 4'd1 ;  // keep track of byte number in the line for the first bytes to skip ptr and line number
					case (byte_ctr)
						4'd0: begin
							loader_data <= loader_addr[7:0] + 8'd1 ;
							next_addr <= loader_addr + 16'd1  ;
							loader_addr <= prev_addr ;
							seg_msb_is_0 = |ioctl_dout ; // test if msb of address is 0
						end
						4'd1: begin
							loader_data <= next_addr[15:8] ;
							loader_addr <= prev_addr + 16'd1 ;
						   prev_addr <= next_addr  ;
							if (ioctl_dout == 8'd0 && seg_msb_is_0==0) begin // end of file
								nullbytes <= 4'd0 ;	
								state <= LOAD_BASIC_INSERT_CODE ;
							end
						end
						4'd2: begin
							loader_addr <= next_addr + 16'd2;
							loader_data <= ioctl_dout;
						end
						4'd3: begin
							loader_addr <= loader_addr + 16'd1;
							loader_data <= ioctl_dout;
						end
						default: begin
							loader_data <= ioctl_dout;
							loader_addr <= loader_addr + 16'd1;
							if (ioctl_dout == 8'd0) begin 
								byte_ctr <= 4'd0 ; 
								last_zero_ptr <= loader_addr + 16'd1;
							end
						end
					endcase
					// 3 null bytes is eod-of-file
				end
				if (~ioctl_download || loader_addr>himem_ptr) begin
					state <= LOAD_BASIC_INSERT0 ;	
					nullbytes <= 4'd0 ;
				end
			end
			LOAD_BASIC_INSERT0: begin
			   if (nullbytes==4'd0) 
					loader_addr <= last_zero_ptr + 16'd1 ; else 
				   loader_addr <= loader_addr + 16'd1 ;
				loader_data <= 8'd0 ;
				nullbytes <= nullbytes + 4'd1 ;
				loader_wr <= 1;
				if (nullbytes == 4'd1) begin
					nullbytes <= 4'd1 ; // skip reset loader_data to next_addr
					state <= LOAD_BASIC_INSERT_CODE ;
				end
			end
			LOAD_BASIC_INSERT_CODE: begin
				loader_wr <= 1;		
				nullbytes <= nullbytes + 4'd1 ;
				case (nullbytes)
					4'd0: begin
						loader_data <= 8'd0 ;
						loader_addr <= next_addr + 16'd2;
					end
					4'd1: begin
						loader_data <= 8'd0;
						loader_addr <= loader_addr + 16'd1 ;
					end
					4'd2: begin
						nullbytes <= 4'd1 ;  // 0+1
						loader_addr <= 16'h40f9 ;
						prev_addr <= loader_addr ;
						loader_data <= loader_addr[7:0];
						state <= LOAD_BASIC_END ;
					end
				endcase
			end
			LOAD_BASIC_END: begin   // Load Himem pointer and the next two data pointers @ 40f9, 40fb, 40fd
				if (nullbytes[0]==0) 
					loader_data <= prev_addr[7:0]; else
					loader_data <= prev_addr[15:8]; 
				loader_wr <= 1;
				nullbytes <= nullbytes + 4'd1 ;
				loader_addr <= loader_addr + 16'd1 ; 
				if (nullbytes == 4'd5) state <= FINISH ;
			end

			SET_ZERO: begin
				loader_addr <= 16'h4000 ; // erase memory from 4000 to FFFF
				state <= DO_ZERO ;
			end
			DO_ZERO: begin
				if (loader_addr == 16'h0fffd) begin  // allow a few cycles for the CPU to get the REGset signal
					execute_addr <= 16'hffe1 ; // reboot, call CLS, and ret to 0000
					execute_enable <= 1;
				end
				if (loader_addr == 16'h0ffff) begin
				   if (~erase_mem) begin  // end of pulse ?
						state <= FINISH ;
					end	
				end else begin
			      if (loader_addr[15:4] == 12'h0ffe) // insert clear routine at ffe1 (next addr)
						loader_data <= 	 // f3 21 00 3c 11 01 3c 3e  20 77 01 ff 03 ed b0 c3 00 00
							(loader_addr[3:0] == 4'h00) ? 8'hf3 : // di
							(loader_addr[3:0] == 4'h01) ? 8'h21 : // ld hl,3c00h
							(loader_addr[3:0] == 4'h02) ? 8'h00 : 
							(loader_addr[3:0] == 4'h03) ? 8'h3c : 
							(loader_addr[3:0] == 4'h04) ? 8'h11 : // ld de,3c01h
							(loader_addr[3:0] == 4'h05) ? 8'h01 : 
							(loader_addr[3:0] == 4'h06) ? 8'h3c : 
							(loader_addr[3:0] == 4'h07) ? 8'h3e : // ld a,20h
							(loader_addr[3:0] == 4'h08) ? 8'h20 : 
							(loader_addr[3:0] == 4'h09) ? 8'h77 : // ld (hl),a
							(loader_addr[3:0] == 4'h0a) ? 8'h01 : // ld bc,03ffh
							(loader_addr[3:0] == 4'h0b) ? 8'hff : 
							(loader_addr[3:0] == 4'h0c) ? 8'h03 : 
							(loader_addr[3:0] == 4'h0d) ? 8'hed : // ldir
							(loader_addr[3:0] == 4'h0e) ? 8'hb0 : 
							(loader_addr[3:0] == 4'h0f) ? 8'hc3 : 8'd0 ; // jp 0000h	
						else 
							loader_data <= 8'd0 ;
						loader_wr <= 1;
						loader_addr <= loader_addr + 16'd1 ;
				end
			end
		endcase

        // Reset back when ioctl download ends
		  // If ioctl_download drops and we are in a state waiting for wr strobes, something is going wrong, so reset.
		  // If we are not in state waiting for data, or in a state expecting ioctl_download to drop, lets continue the normal work.
      if((state<FINISH) && (state != IDLE) && ~ioctl_download && ioctl_index == INDEX) begin
         loader_download <= 0;
         state <= IDLE;
      end
	end
end
endmodule

