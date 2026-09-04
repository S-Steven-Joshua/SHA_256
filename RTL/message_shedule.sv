`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2026 11:26:05
// Design Name: 
// Module Name: message_shedule
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// since in sha256 the first 16 word come from the chunk andresr from 16-64 we need register we
// create a register each of 32 bit reducing the memory size

/*
let us say we have round_counter at 50 then first we calculate  50-16 =34
j=16-(50-24)=0 so w[i-16] is at w[0]
then for w[i-15]
50-15=35
j=16-(50-35)=1;
for w[i-7] we get  w[9];
for w[i-2] we get w[14]
*/
module message_shedule(
    input  logic         clk,
    input  logic         rst,
    input  logic         en,
    input  logic [511:0] data_in,
    input  logic [5:0]   round_counter,
    output logic [31:0]  w_out
);
    logic [31:0] W [15:0];
    logic [31:0] w_next;
    logic [31:0] s0;
    logic [31:0] s1;

    function automatic logic [31:0] sigma0(input logic [31:0] x);
        return {x[6:0], x[31:7]} ^ {x[17:0], x[31:18]} ^ (x>>3);
    endfunction: sigma0
    
    function automatic logic [31:0] sigma1(input logic [31:0] x);
        return {x[16:0], x[31:17]} ^ {x[18:0], x[31:19]} ^ (x>>10);
    endfunction: sigma1 

    always_comb begin
        if (round_counter < 16) begin
            w_next = data_in[(511 - 32*round_counter) -: 32];
            s0     = '0;
            s1     = '0;
        end else begin
            s0 = sigma0(W[1]);   
            s1 = sigma1(W[14]);  

            w_next = s1 + W[9] + s0 + W[0]; 
        end
    end

    assign w_out = w_next;

    always_ff @(posedge clk) 
    begin
        if (!rst) 
        begin
            for(int i=0; i<16; i++) 
            begin
                W[i] <= '0;
            end
        end 
        else if (en) 
        begin
            for(int i=0; i<15; i++) 
            begin
                W[i] <= W[i+1];
            end
            W[15] <= w_next;
        end
    end
    
endmodule: message_shedule
