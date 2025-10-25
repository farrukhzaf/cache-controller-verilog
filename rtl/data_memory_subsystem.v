`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2025 04:44:38 AM
// Design Name: 
// Module Name: data_memory_subsystem
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


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: data_memory_subsystem
// Description: Top-level cache memory subsystem integrating cache controller,
//              data array, and main memory interface
//////////////////////////////////////////////////////////////////////////////////

module data_memory_subsystem #(
    parameter CACHE_LINES = 1024,
    parameter TAG_WIDTH = 18,
    parameter INDEX_WIDTH = 10,
    parameter OFFSET_WIDTH = 4,
    parameter DATA_WIDTH = 32,
    parameter BLOCK_WIDTH = 128,
    parameter ADDR_WIDTH = 32,
    parameter MEM_SIZE = 65536,
    parameter LATENCY = 3
)(
    input  wire                     clk,
    input  wire                     rst,
    
    // Processor Interface
    input  wire [ADDR_WIDTH-1:0]    addr,
    input  wire                     read,
    input  wire                     write,
    input  wire [DATA_WIDTH-1:0]    wdata,
    input  wire                     flush,
    
    output wire [DATA_WIDTH-1:0]    rdata,
    output wire                     stall
);

    // ========================================================================
    // Address Decoding
    // ========================================================================
    // Split address into: tag, index, offset
    // addr[31:0] = {tag[17:0], index[9:0], offset[3:0]}
    
    wire [TAG_WIDTH-1:0]    tag;
    wire [INDEX_WIDTH-1:0]  index;
    wire [OFFSET_WIDTH-1:0] offset;
    
    assign tag    = addr[ADDR_WIDTH-1 : ADDR_WIDTH-TAG_WIDTH];           // addr[31:14]
    assign index  = addr[ADDR_WIDTH-TAG_WIDTH-1 : OFFSET_WIDTH];         // addr[13:4]
    assign offset = addr[OFFSET_WIDTH-1 : 0];                            // addr[3:0]
    
    
    // ========================================================================
    // Internal Signals - Cache Controller to Data Array
    // ========================================================================
    wire refill;    // Load entire 128-bit cache line
    wire update;    // Update single 32-bit word
    
    
    // ========================================================================
    // Internal Signals - Cache Controller to Main Memory
    // ========================================================================
    wire mem_read;
    wire mem_write;
    wire mem_ready;
    
    
    // ========================================================================
    // Internal Signals - Main Memory to Data Array
    // ========================================================================
    wire [BLOCK_WIDTH-1:0] data_block;  // 128-bit cache line from memory
    
    
    // ========================================================================
    // Module Instantiations
    // ========================================================================
    
    // ------------------------------------------------------------------------
    // Cache Controller - The control brain
    // ------------------------------------------------------------------------
    cache_controller #(
        .CACHE_LINES    (CACHE_LINES),
        .TAG_WIDTH      (TAG_WIDTH),
        .INDEX_WIDTH    (INDEX_WIDTH),
        .OFFSET_WIDTH   (OFFSET_WIDTH)
    ) cache_ctrl_inst (
        .clk            (clk),
        .rst            (rst),
        
        // From address decoder
        .index          (index),
        .tag            (tag),
        
        // From processor
        .read           (read),
        .write          (write),
        .flush          (flush),
        
        // To processor
        .stall          (stall),
        
        // To data array
        .refill         (refill),
        .update         (update),
        
        // Memory interface
        .mem_ready      (mem_ready),
        .mem_read       (mem_read),
        .mem_write      (mem_write)
    );
    
    
    // ------------------------------------------------------------------------
    // Data Array - Storage for cached data
    // ------------------------------------------------------------------------
    data_array #(
        .CACHE_LINES    (CACHE_LINES),
        .BLOCK_WIDTH    (BLOCK_WIDTH),
        .WORD_WIDTH     (DATA_WIDTH),
        .INDEX_WIDTH    (INDEX_WIDTH),
        .OFFSET_WIDTH   (OFFSET_WIDTH)
    ) data_array_inst (
        .clk            (clk),
        .rst            (rst),
        
        // Address inputs
        .index          (index),
        .offset         (offset),
        
        // Data from/to processor
        .wdata          (wdata),
        .rdata          (rdata),
        
        // Control from cache controller
        .refill         (refill),
        .update         (update),
        
        // Data from main memory
        .data_block     (data_block)
    );
    
    
    // ------------------------------------------------------------------------
    // Main Memory - Simulates memory with latency
    // ------------------------------------------------------------------------
    main_memory #(
        .MEM_SIZE       (MEM_SIZE),
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_WIDTH     (ADDR_WIDTH),
        .WORD_WIDTH     (DATA_WIDTH),
        .BLOCK_WIDTH    (BLOCK_WIDTH),
        .LATENCY        (LATENCY)
    ) main_mem_inst (
        .clk            (clk),
        .rst            (rst),
        
        // Address and data from processor/controller
        .addr           (addr),         // Full address goes to memory
        .wdata          (wdata),        // Write data from processor
        
        // Control from cache controller
        .mem_read       (mem_read),
        .mem_write      (mem_write),
        
        // Status to cache controller
        .mem_ready      (mem_ready),
        
        // Data to data array
        .data_block     (data_block)
    );

endmodule