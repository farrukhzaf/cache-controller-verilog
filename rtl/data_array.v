`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2025 12:19:38 AM
// Design Name: 
// Module Name: data_array
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

module data_array #(
    parameter CACHE_LINES = 1024,
    parameter BLOCK_WIDTH = 128,    // 4 words per line
    parameter WORD_WIDTH = 32,      // 32-bit words
    parameter INDEX_WIDTH = 10,
    parameter OFFSET_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst,
    
    // Processor Interface
    input  wire [INDEX_WIDTH-1:0]    index,
    input  wire [OFFSET_WIDTH-1:0]   offset,
    input  wire [WORD_WIDTH-1:0]     wdata,
    
    output  wire [WORD_WIDTH-1:0]     rdata,
    
    
    
    // Cache Controller Interface
    input  wire                     refill,
    input  wire                     update,
    
    // Main Memory Interface
    input  wire [BLOCK_WIDTH-1:0]   data_block
);

    localparam BYTE_OFFSET_WIDTH = $clog2(WORD_WIDTH/8);  // Bits for byte selection within word

    reg [BLOCK_WIDTH-1:0] data_mem[0:CACHE_LINES-1];
    
    
    assign rdata = data_mem[index][offset[OFFSET_WIDTH-1:BYTE_OFFSET_WIDTH]*WORD_WIDTH +: WORD_WIDTH];
    
    
    integer i;
    
    always @(posedge clk) begin
        
        if (rst) begin
            
            for (i = 0; i < CACHE_LINES; i = i + 1) begin 
                data_mem[i] <= {BLOCK_WIDTH{1'b0}};
            end
        end
        
        else begin
            
            if (refill) begin  
                data_mem[index] <= data_block;
            end
            
            else if (update) begin
                data_mem[index][offset[OFFSET_WIDTH-1:BYTE_OFFSET_WIDTH]*WORD_WIDTH +: WORD_WIDTH] <= wdata;
            end
        end    
                
    
    end
    
endmodule