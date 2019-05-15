/*
 * Module:
 *  stream_filter
 *
 * Description:
 *  The stream_filter module is the wrapper containg the delay, filter etc
 *  modules.
 *
 * Created:
 *  Mon May 13 20:25:35 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */
`ifndef _stream_filter_
`define _stream_filter_


`include "delay.v"
`include "filter.v"
`include "group_add.v"
`include "rescale.v"
`include "clip.v"


`default_nettype none

module stream_filter
  #(parameter
    CFG_DWIDTH  = 32,
    CFG_AWIDTH  = 5,

    MEM_AWIDTH  = 16,
    MEM_DEPTH   = 1<<MEM_AWIDTH,

    IMG_WIDTH   = 16,
    KER_WIDTH   = 16)
   (input                           clk,
    input                           rst,

    input       [CFG_DWIDTH-1:0]    cfg_data,
    input       [CFG_AWIDTH-1:0]    cfg_addr,
    input                           cfg_valid,

    input       [IMG_WIDTH-1:0]     image,
    input                           image_val,

    output reg  [IMG_WIDTH-1:0]     result,
    output reg                      result_val
);


    /**
     * Local parameters
     */


    localparam NUM_WIDTH    = (IMG_WIDTH+KER_WIDTH);

    localparam HEIGHT_NB    = 3;
    localparam WIDTH_NB     = 3;


    localparam
        CFG_WIDTH   = 1,
        CFG_KERNEL  = 2,
        CFG_RESCALE = 3;


    /**
     * Internal signals
     */
    genvar i;

    reg  [MEM_AWIDTH-1:0]           cfg_delay;
    reg                             cfg_delay_set;

    reg  [KER_WIDTH-1:0]            cfg_ker;
    reg                             cfg_ker_set;

    reg  [7:0]                      cfg_shift;
    reg  [7:0]                      cfg_head;

    reg  [IMG_WIDTH-1:0]            image_data_1p;
    reg                             image_val_1p;

    wire [IMG_WIDTH*HEIGHT_NB-1:0]  delay_data;
    wire                            delay_val;

    wire [NUM_WIDTH*HEIGHT_NB-1:0]  filter_data;
    wire                            filter_val;

    wire [NUM_WIDTH-1:0]            add_data;
    reg                             add_valid_4p;
    reg                             add_valid_3p;
    reg                             add_valid_2p;
    reg                             add_valid_1p;
    reg                             add_valid;

    wire [IMG_WIDTH-1:0]            rescale_data;
    reg                             rescale_valid_3p;
    reg                             rescale_valid_2p;
    reg                             rescale_valid_1p;
    reg                             rescale_valid;

    wire [IMG_WIDTH-1:0]            clip_data;
    wire                            clip_valid;


    /**
     * Implementation
     */

    always @(posedge clk) begin
        cfg_delay       <= 'b0;
        cfg_delay_set   <= 1'b0;

        if (cfg_valid & (cfg_addr == CFG_WIDTH)) begin
            cfg_delay       <= cfg_data[KER_WIDTH-1:0];
            cfg_delay_set   <= 1'b1;
        end
    end


    always @(posedge clk) begin
        cfg_ker     <= 'b0;
        cfg_ker_set <= 1'b0;

        if (cfg_valid & (cfg_addr == CFG_KERNEL)) begin
            cfg_ker     <= cfg_data[KER_WIDTH-1:0];
            cfg_ker_set <= 1'b1;
        end
    end


    always @(posedge clk)
        if (cfg_valid & (cfg_addr == CFG_RESCALE)) begin
            cfg_shift   <= cfg_data[15: 8];
            cfg_head    <= cfg_data[ 7: 0];
        end



    // register incoming data
    always @(posedge clk)
        image_data_1p <= image;


    always @(posedge clk)
        if (rst)    image_val_1p <= 1'b0;
        else        image_val_1p <= image_val;


    always @(posedge clk) begin
        add_valid_4p        <= filter_val;
        add_valid_3p        <= add_valid_4p;
        add_valid_2p        <= add_valid_3p;
        add_valid_1p        <= add_valid_2p;
        add_valid           <= add_valid_1p;

        rescale_valid_3p    <= add_valid;
        rescale_valid_2p    <= rescale_valid_3p;
        rescale_valid_1p    <= rescale_valid_2p;
        rescale_valid       <= rescale_valid_1p;
    end



    always @(posedge clk) begin
        result      <= 'b0;
        result_val  <= 1'b0;

        if (clip_valid) begin
            result      <= clip_data;
            result_val  <= 1'b1;
        end
    end



    delay #(
        .HEIGHT_NB  (HEIGHT_NB),
        .IMG_WIDTH  (IMG_WIDTH),

        .MEM_AWIDTH (MEM_AWIDTH),
        .MEM_DEPTH  (MEM_DEPTH))
    delay_ (
        .clk        (clk),
        .rst        (rst),

        .cfg_delay  (cfg_delay),
        .cfg_set    (cfg_delay_set),

        .up_data    (image_data_1p),
        .up_val     (image_val_1p),

        .delay      (delay_data),
        .delay_val  (delay_val)
    );


    filter #(
        .HEIGHT_NB  (HEIGHT_NB),
        .WIDTH_NB   (WIDTH_NB),

        .IMG_WIDTH  (IMG_WIDTH),
        .KER_WIDTH  (KER_WIDTH))
    filter_ (
        .clk        (clk),
        .rst        (rst),

        .cfg_ker    (cfg_ker),
        .cfg_val    (cfg_ker_set),

        .up_img     (delay_data),
        .up_val     (delay_val),

        .result     (filter_data),
        .result_val (filter_val)
    );


    group_add #(
        .GROUP_NB   (WIDTH_NB),
        .NUM_WIDTH  (NUM_WIDTH))
    group_add_ (
        .clk        (clk),

        .up_data    (filter_data),
        .dn_data    (add_data)
    );


    rescale #(
        .NUM_WIDTH  (NUM_WIDTH),
        .IMG_WIDTH  (IMG_WIDTH))
    rescale_ (
        .clk        (clk),

        .shift      (cfg_shift),
        .head       (cfg_head),

        .up_data    (add_data),
        .dn_data    (rescale_data)
    );


    clip #(
        .WIDTH_NB   (WIDTH_NB),
        .IMG_WIDTH  (IMG_WIDTH),

        .MEM_AWIDTH (MEM_AWIDTH),
        .MEM_DEPTH  (MEM_DEPTH))
    clip_ (
        .clk        (clk),
        .rst        (rst),

        .cfg_delay  (cfg_delay),
        .cfg_set    (cfg_delay_set),

        .up_data    (rescale_data),
        .up_val     (rescale_valid),

        .dn_data    (clip_data),
        .dn_val     (clip_valid)
    );


endmodule

`default_nettype wire

`endif //  `ifndef _stream_filter_
