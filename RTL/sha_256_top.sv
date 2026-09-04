`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.09.2026 17:31:59
// Design Name: 
// Module Name: sha_256_top
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


module sha_256_top(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [255:0] data_in,
    input logic [5:0] length,
    output logic [255:0] hash,
    output logic ready
    );
    
    logic [511:0] padded_chunk;
    logic [31:0] w_bridge;
    logic [5:0] round_counter;
    
    logic compress_init;
    logic compress_en;
    
    typedef enum logic [1:0] {idle,init,run,done}  state_t;
    state_t state;
    
    padder padder1(.data_in(data_in),.length(length),.data_out(padded_chunk));
    
    message_shedule message(.clk(clk),.rst(rst),.en(compress_en),.data_in(padded_chunk),.round_counter(round_counter),.w_out(w_bridge));
    
    compression_core core(.clk(clk),.rst(rst),.init(compress_init),.en(compress_en),.round_counter(round_counter),.w_in(w_bridge),.hash(hash));
    
    always_ff @ (posedge clk)
    begin
        if(!rst)
        begin
            state<=idle;
            round_counter<='0;
        end
        else
        case(state)
        idle:
        begin
            if(start)
            begin
                state<=init;
            end
            else
            begin
                state<=idle;
            end
        end
        init:
        begin
            state<=run;
        end
        run:
        begin
            if(round_counter==6'd63)
            begin
                state<=done;
            end
            else
            begin
                round_counter<=round_counter+1'b1;
            end
        end
        done:
        begin
            state<=idle;
        end
        default:state<=idle;
        endcase
    end
    
    always_comb
    begin
        compress_init=1'b0;
        compress_en=1'b0;
        ready=1'b0;
        case(state)
        idle:
        begin
        end
        
        init:
        begin
            compress_init=1'b1;
        end
        
        run:
        begin
            compress_en=1'b1;
        end
        
        done:
        begin
            ready=1'b1;
        end
        endcase
    end
        
endmodule:sha_256_top
