import sha_256_pkg::*;
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2026 16:41:29
// Design Name: 
// Module Name: compression_core
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


module compression_core(
    input logic clk,
    input logic rst,
    input logic init, 
    input logic en,
    input logic [5:0] round_counter,
    input logic [31:0] w_in,
    output logic [255:0] hash
    );
    logic [31:0] a,b,c,d,e,f,g,h;
    logic [31:0] T1,T2;
    logic [31:0] a_next,b_next,c_next,d_next,e_next,f_next,g_next,h_next;

    function automatic logic [31:0] bigsigma0(input logic [31:0] x);
        return {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};
    endfunction:bigsigma0

    function automatic logic [31:0] bigsigma1(input logic [31:0] x);
        return {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};
    endfunction:bigsigma1

    function automatic logic [31:0] ch(input logic [31:0] x,y,z);
        return (x & y) ^ (~x & z);
    endfunction:ch

    function automatic logic [31:0] maj(input logic [31:0] x,y,z);
        return (x & y) ^ (x & z) ^ (y & z);
    endfunction:maj

    always_comb
    begin
        T1=h+bigsigma1(e)+ch(e,f,g)+K[round_counter]+w_in;
        T2=bigsigma0(a)+maj(a,b,c);
        a_next=T1+T2;
        b_next=a;
        c_next=b;
        d_next=c;
        e_next=d+T1;
        f_next=e;
        g_next=f;
        h_next=g;
    end

    always_ff @ (posedge clk)
    begin
        if(!rst)
        begin
        {a,b,c,d,e,f,g,h}<='0;
        end
        else if(init)
        begin
            a<=H0_INIT;
            b<=H1_INIT;
            c<=H2_INIT;
            d<=H3_INIT;
            e<=H4_INIT;
            f<=H5_INIT;
            g<=H6_INIT;
            h<=H7_INIT;
        end
        else if(en)
        begin
            a<=a_next;
            b<=b_next;
            c<=c_next;
            d<=d_next;
            e<=e_next;
            f<=f_next;
            g<=g_next;
            h<=h_next;
        end
    end
    
    always_comb 
    begin
        hash='0;
        if(round_counter == 6'd63)
        begin
            hash = {(H0_INIT + a), (H1_INIT + b), (H2_INIT + c), (H3_INIT + d),(H4_INIT + e), (H5_INIT + f), (H6_INIT + g), (H7_INIT + h)};
        end
    end
    
    
endmodule:compression_core
