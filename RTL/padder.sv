`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2026 10:18:39
// Design Name: 
// Module Name: padder
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


module padder(
    input logic [255:0] data_in,//we send in bytes
    input logic [5:0] length,//so a max of 32 bytes each ascii values take 1 byte so 32 character at a time,
    output logic [511:0] data_out
    );
    
    logic [63:0] data_size;
    
    assign data_size= {58'b0,length}<<3;//max is 6 bits so 58 bits will be zero left shifting by 3 multiplies by 8
    
    integer i;

    always_comb 
    begin
        data_out='0;
        for(i=0;i<32;i++)
        begin
            if(i<length)
            begin
                data_out[511- 8*i -: 8]=data_in[255- i*8 -: 8];
            end
        end
        data_out[511-length*8]=1'b1;
        data_out[63:0]=data_size;
    end
    
    
endmodule:padder 
