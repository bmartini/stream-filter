/*
 * Module:
 *  clip
 *
 * Description:
 *  The clip module removes junk values from the end of the results row.
 *
 * Created:
 *  Tue May 14 18:52:30 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */
`ifndef _clip_
`define _clip_


`default_nettype none

module clip
  #(parameter
    WIDTH_NB    = 3,
    IMG_WIDTH   = 8,

    MEM_AWIDTH  = 12,
    MEM_DEPTH   = 1<<MEM_AWIDTH)
   (input  wire                     clk,
    input  wire                     rst,

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
    reg  [MEM_AWIDTH-1:0]   cfg_clip;
    reg                     cfg_set_r;

    reg  [MEM_AWIDTH-1:0]   row_cnt;
    reg                     row_mask;
    reg                     dn_val_i;



    /**
     * Implementation
     */


    // register config
    always @(posedge clk)
        if (cfg_set) begin
            cfg_delay_r <= (cfg_delay - {{MEM_AWIDTH-1{1'b0}}, 1'b1});
            cfg_clip    <= (cfg_delay - WIDTH_NB[MEM_AWIDTH-1:0]);
        end


    always @(posedge clk) begin
        cfg_set_r <= 1'b0;

        if (cfg_set) begin
            cfg_set_r <= 1'b1;
        end
    end



    // count img row
    always @(posedge clk)
        if (cfg_set_r) begin
            row_cnt <= 'b0;
        end
        else if (up_val) begin
            row_cnt <= row_cnt + {{MEM_AWIDTH-1{1'b0}}, 1'b1};

            if (row_cnt >= cfg_delay_r) begin
                row_cnt <= 'b0;
            end
        end


    // clip junk from end of row
    always @(posedge clk) begin
        row_mask <= 1'b1;

        if (row_cnt > cfg_clip) begin
            row_mask <= 1'b0;
        end
    end



    // reg up data
    always @(posedge clk)
        dn_data <= up_data;


    always @(posedge clk)
        if (rst)    dn_val_i <= 1'b0;
        else        dn_val_i <= up_val;



    assign dn_val = dn_val_i & row_mask;



endmodule

`default_nettype wire

`endif //  `ifndef _clip_
