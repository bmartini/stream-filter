/*
 * Module:
 *  delay_mem
 *
 * Description:
 *  The delay_mem module is a memory that stores an image row before its sent
 *  to the filter.
 *
 * Created:
 *  Tue May  7 21:58:44 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */
`ifndef _delay_mem_
`define _delay_mem_


`default_nettype none

module delay_mem
  #(parameter
    IMG_WIDTH   = 8,

    MEM_AWIDTH  = 12,
    MEM_DEPTH   = 1<<MEM_AWIDTH)
   (input  wire                     clk,

    input  wire [MEM_AWIDTH-1:0]    cfg_delay,
    input  wire                     cfg_set,

    input  wire [IMG_WIDTH-1:0]     up_data,
    input  wire                     up_val,

    output reg  [IMG_WIDTH-1:0]     dn_data,
    output wire                     dn_val
);


    /**
     * Local parameters
     */



    /**
     * Internal signals
     */

    reg  [MEM_AWIDTH-1:0]   cfg_delay_r;
    reg                     cfg_set_r;

    reg  [IMG_WIDTH-1:0]    mem [0:MEM_DEPTH-1];
    reg  [MEM_AWIDTH-1:0]   wr_ptr;
    reg  [MEM_AWIDTH-1:0]   rd_ptr;

    wire [MEM_DEPTH-1:0]    rd_val;
    reg  [MEM_DEPTH:0]      rd_val_i;


    /**
     * Implementation
     */


    // register config
    always @(posedge clk)
        if (cfg_set) cfg_delay_r <= (cfg_delay - {{MEM_AWIDTH-1{1'b0}}, 1'b1});


    always @(posedge clk) begin
        cfg_set_r <= 1'b0;

        if (cfg_set) begin
            cfg_set_r <= 1'b1;
        end
    end



    // write to memory
    always @(posedge clk)
        if (cfg_set_r) begin
            wr_ptr <= cfg_delay_r;
        end
        else if (up_val) begin
            wr_ptr <= wr_ptr + {{MEM_AWIDTH-1{1'b0}}, 1'b1};

            if (wr_ptr == (MEM_DEPTH[MEM_AWIDTH-1:0]-1)) begin
                wr_ptr <= 'b0;
            end
        end


    always @(posedge clk)
        if (up_val) begin
            mem[wr_ptr] <= up_data;
        end


    // read from memory
    always @(posedge clk)
        if (cfg_set_r) begin
            rd_ptr <= 'b0;
        end
        else if (up_val) begin
            rd_ptr <= rd_ptr + {{MEM_AWIDTH-1{1'b0}}, 1'b1};

            if (rd_ptr == (MEM_DEPTH[MEM_AWIDTH-1:0]-1)) begin
                rd_ptr <= 'b0;
            end
        end


    always @(posedge clk)
        if (up_val) begin
            dn_data <= mem[rd_ptr];
        end



    assign dn_val   = rd_val[cfg_delay_r];

    assign rd_val   = rd_val_i[MEM_DEPTH-1:0];


    always @(posedge clk)
        if      (cfg_set_r) rd_val_i <= {MEM_DEPTH+1{1'b0}};
        else if (up_val)    rd_val_i <= {rd_val, 1'b1};




endmodule

`default_nettype wire

`endif //  `ifndef _delay_mem_
