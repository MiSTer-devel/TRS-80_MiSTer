//
// HT1080Z for MiSTer Z80 Register Loader - For Loading and Jumping to PC
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

module z80_regset
#( parameter
        SP_ADDR = 16'h4200              // Stack pointer address
)
(
    input wire [15:0] execute_addr,     // Start address for program start
    input wire execute_enable,   	    // Jump to start address (out_execute_addr) - Not implemented
    //input wire [211:0] dir_in,       // Z80 Register set as defined in T80pa / T80

    output logic [211:0] dir_out,       // Z80 Register set as defined in T80pa / T80
    output logic dir_set                // Signal to set registers
); 

always_comb
begin
    dir_out[211:0] <= {
        2'b0,               // 211-210 - IFF2, IFF1
        2'b0,               // 209-208 - IM
        127'b0,             // 207-080 - Regular and Alt registers
        //dir_in[211:80],
        execute_addr[15:8], // 079-071 - PCH
        execute_addr[7:0],  // 071-064 - PCL
        SP_ADDR[15:8],      // 063-056 - SPH
        SP_ADDR[7:0],       // 055-048 - SPL
        //dir_in[47:0]
        8'b0,               // 047-040 - R
        8'b0,               // 039-032 - I
        8'b1,               // 031-024 - Fp
        8'b1,               // 023-016 - Ap
        16'b1               // 015-000 - ACC
    };
end

assign dir_set = execute_enable;

endmodule