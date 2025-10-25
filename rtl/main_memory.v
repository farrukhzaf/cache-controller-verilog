`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2025 12:19:38 AM
// Design Name: 
// Module Name: main_memory
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

module main_memory #(
    parameter MEM_SIZE = 65536,        // Memory size in words (256KB)
    parameter DATA_WIDTH = 32,         // Word width
    parameter ADDR_WIDTH = 32,         // Word width
    parameter WORD_WIDTH = 32,         // 32-bit words
    parameter BLOCK_WIDTH = 128,       // Cache line width
    parameter LATENCY = 3              // Memory latency cycles
)(
    input  wire                    clk,
    input  wire                    rst,
    
    
    // Processor Interface
    input  wire [ADDR_WIDTH-1:0]   addr,
    input  wire [DATA_WIDTH-1:0]   wdata,
    
    // Cache Controller Interface
    input  wire                    mem_read,
    input  wire                    mem_write,
    
    output reg                     mem_ready,
    
    
    // Data Array Interface
    output reg [BLOCK_WIDTH-1:0]  data_block    // 128-bit cache line read
);

    
    // Calculate derived parameters
    localparam WORDS_PER_BLOCK = BLOCK_WIDTH / DATA_WIDTH;  // 128/32 = 4
    localparam WORD_OFFSET_BITS = $clog2(WORDS_PER_BLOCK);  // log2(4) = 2
    localparam BYTE_OFFSET_BITS = $clog2(DATA_WIDTH/8);     // log2(4) = 2
    localparam BLOCK_OFFSET_BITS = WORD_OFFSET_BITS + BYTE_OFFSET_BITS; // 2+2 = 4
    localparam MEM_ADDR_WIDTH = $clog2(MEM_SIZE*WORD_WIDTH/8);

    
    reg [WORD_WIDTH-1:0] memory_array[0:MEM_SIZE-1];        //256-KB (18 bits)
    
    reg [1:0] latency_counter;
    
    // Latched address and data for operation
    reg [ADDR_WIDTH-1:0] latched_addr;
    reg [DATA_WIDTH-1:0] latched_wdata;
    reg latched_read;
    reg latched_write;

    integer i, j;
    
    // Read logic
    always @(posedge clk) begin
    
        if (rst) begin
        
            // Reset all control signals
            mem_ready <= 1'b1;
            latency_counter <= 2'b00;
            data_block <= {BLOCK_WIDTH{1'b0}};
            latched_addr <= {ADDR_WIDTH{1'b0}};
            latched_wdata <= {DATA_WIDTH{1'b0}};
            latched_read <= 1'b0;
            latched_write <= 1'b0;
            
            for (i = 0; i < MEM_SIZE; i = i + 1) begin
                memory_array[i] <= {WORD_WIDTH{1'b0}};   
            end
        end
        
        else begin 
            if ((mem_read || mem_write) && mem_ready) begin
                
                mem_ready <= 1'b0;
                latency_counter <= LATENCY - 1;
                
                // Latch inputs (registered by memory as per spec)
                latched_addr <= addr;
                latched_wdata <= wdata;
                latched_read <= mem_read;
                latched_write <= mem_write;
            end
            
            // Count down while busy
            else if (!mem_ready && latency_counter > 0) begin
                latency_counter <= latency_counter - 1'b1;
            end
            
            else if (!mem_ready && latency_counter == 0) begin
                mem_ready <= 1'b1;
                
                // Perform the actual memory operation
                if (latched_read) begin
                    // READ: Fetch cache line using parametric loop
                    for (j = 0; j < WORDS_PER_BLOCK; j = j + 1) begin
                        data_block[j*DATA_WIDTH +: DATA_WIDTH] <= 
                            memory_array[{latched_addr[MEM_ADDR_WIDTH-1:BLOCK_OFFSET_BITS], 
                                         j[WORD_OFFSET_BITS-1:0]}];
                    end
                end
                
                else if (latched_write) begin
                    // WRITE: Store single 32-bit word
                    // Convert byte address to word address using addr[31:2]
                    memory_array[latched_addr[MEM_ADDR_WIDTH-1:2]] <= latched_wdata;
                end
            end
        end
    end
                    
     

endmodule