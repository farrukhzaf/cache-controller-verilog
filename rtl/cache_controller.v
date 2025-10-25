`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/25/2025 12:19:38 AM
// Design Name: 
// Module Name: cache_controller
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


module cache_controller #(
    parameter CACHE_LINES = 1024,
    parameter TAG_WIDTH = 18,
    parameter INDEX_WIDTH = 10,
    parameter OFFSET_WIDTH = 4
)(
    input  wire                     clk,
    input  wire                     rst,
    
    // Processor Interface
    input  wire [INDEX_WIDTH-1:0]    index,
    input  wire [TAG_WIDTH-1:0]    tag,
    input  wire                     read,
    input  wire                     write,
    input  wire                     flush,
    
    output reg                      stall,
    
    // Data Array Interface
    output reg                      refill,
    output reg                      update,
    
    // Main Memory Interface
    input  wire                     mem_ready,
    output reg                      mem_read,
    output reg                      mem_write
);


    // FSM states
    localparam IDLE = 0, ALLOCATE = 1, WRITE_MEMORY = 2;
    
    
    reg [TAG_WIDTH-1:0]tag_array[0:CACHE_LINES-1];
    reg                valid_bits[0:CACHE_LINES-1];
    
    

    reg [1:0] state, next_state;
    
    
    reg next_stall, next_refill, next_update, next_mem_read, next_mem_write;
    wire hit;
    
    
    
    integer i;
    
    always @(posedge clk) begin
        if (rst) begin
        
            state <= IDLE;
            stall <= 1'b0;
            refill <= 1'b0;
            update <= 1'b0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            for (i = 0; i < CACHE_LINES; i = i + 1) begin
                    valid_bits[i] <= 1'b0;
                    tag_array[i] <= {TAG_WIDTH{1'b0}};
            end
            
        end else begin
            state <= next_state;
            
            if (state == IDLE && flush) begin
                for (i = 0; i < CACHE_LINES; i = i + 1) begin
                    valid_bits[i] <= 1'b0;
                end
            end
            
            else if (state == ALLOCATE && mem_ready) begin
                tag_array[index] <= tag;
                valid_bits[index] <= 1'b1;
            end
            
            stall <= next_stall;
            refill <= next_refill;
            update <= next_update;
            mem_read <= next_mem_read;
            mem_write <= next_mem_write;
            
        end
    end
    
    
    assign hit = (tag_array[index] == tag) && valid_bits[index];
    
    always @(*) begin
    
        next_stall = 0;
        next_refill = 0;
        next_update = 0;
        next_mem_read = 0;
        next_mem_write = 0;
        
        next_state = state;
        
        case (state) 
            
            IDLE : begin
                if (flush)
                    next_state = IDLE;
                    
                else if (read && hit)
                  next_state = IDLE;  // Read hit
                  
                else if (read && !hit) begin
                  next_state = ALLOCATE;  // Read miss
                  next_stall = 1'b1;
                  next_mem_read = 1'b1;
                end
                  
                else if (write) begin
                  next_state = WRITE_MEMORY;  // Write (hit or miss)
                  next_stall = 1'b1;
                  next_mem_write = 1'b1;
                  if (hit) 
                    next_update = 1'b1;     // If hit then update cache also
                end
            end
            
            
            ALLOCATE : begin    // Fetch missing cache line from main memory
              
              if (!mem_ready) begin
                next_stall = 1'b1;
                next_mem_read = 1'b1;
              end
              else begin
                next_state = IDLE;
                next_refill = 1'b1;
                next_stall = 1'b0;
                
              end  
            end
            
            
            WRITE_MEMORY: begin
                
                if (!mem_ready) begin
                    next_stall = 1'b1;
                    next_mem_write = 1'b1;
                end
                else begin
                    next_state = IDLE;
                    next_stall = 1'b0;
                end 
            end       
            
       endcase
                    
   end
   
endmodule                 
                  
