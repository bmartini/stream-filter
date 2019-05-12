/*
 * Module:
 *  filter
 *
 * Description:
 *  The filter module receives a stream of image data and multiplies them with
 *  pre-loaded kernel values.
 *
 * Created:
 *  Wed May  8 21:38:35 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */
`ifndef _filter_
`define _filter_


`include "multiply_add.v"

module filter
  #(parameter
    HEIGHT_NB   = 3,
    WIDTH_NB    = 3,

    IMG_WIDTH   = 8,
    KER_WIDTH   = 16)
   (input  wire                                         clk,
    input  wire                                         rst,

    input  wire [KER_WIDTH-1:0]                         cfg_ker,
    input  wire                                         cfg_val,

    input  wire [HEIGHT_NB*IMG_WIDTH-1:0]               up_img,
    input  wire                                         up_val,

    output wire [HEIGHT_NB*(IMG_WIDTH+KER_WIDTH)-1:0]   result,
    output wire                                         result_val
);


    /**
     * Local parameters
     */

    localparam MAC_NB       = HEIGHT_NB*WIDTH_NB;
    localparam MAC_PIPELINE = 5;


    /**
     * Internal signals
     */
    genvar h;
    genvar w;


    // array to pass image data between multiply_add
    wire [IMG_WIDTH-1:0]            img [0:((WIDTH_NB+1)*HEIGHT_NB)-1];

    // array to pass accumulated data between multiply_add
    wire [IMG_WIDTH+KER_WIDTH-1:0]  acc [0:((WIDTH_NB+1)*HEIGHT_NB)-1];



    reg  [MAC_NB-1:0]   token;
    wire [2*MAC_NB-1:0] token_i;

    reg  [MAC_PIPELINE*WIDTH_NB-1:0]    valid;
    wire [MAC_PIPELINE*WIDTH_NB:0]      valid_i;


    /**
     * Implementation
     */


    assign token_i = {token, token};


    always @(posedge clk)
        if      (rst)       token <= 'b1;
        else if (cfg_val)   token <= token_i[MAC_NB-1 +: MAC_NB];





    assign result_val   = valid[MAC_PIPELINE*WIDTH_NB-1];

    assign valid_i      = {valid, up_val};


    always @(posedge clk)
        if (rst)    valid <= 'b0;
        else        valid <= {valid, up_val};



    generate
        for (h=0;  h<HEIGHT_NB; h=h+1) begin : HEIGHT_


            assign img[h*(WIDTH_NB+1)] = up_img[h*IMG_WIDTH +: IMG_WIDTH];

            assign acc[h*(WIDTH_NB+1)] = {IMG_WIDTH+KER_WIDTH{1'b0}};

            assign result[h*(IMG_WIDTH+KER_WIDTH) +: (IMG_WIDTH+KER_WIDTH)]
                    = acc[h*(WIDTH_NB+1)+HEIGHT_NB];



            for (w=0; w<WIDTH_NB; w=w+1) begin: WIDTH_

                multiply_add #(
                    .IMG_WIDTH  (IMG_WIDTH),
                    .KER_WIDTH  (KER_WIDTH))
                multiply_add_ (
                    .clk        (clk),
                    .rst        (rst),

                    .cfg_ker    (cfg_ker),
                    .cfg_val    (cfg_val & token[h*WIDTH_NB + w]),

                    .up_img     (img[h*(WIDTH_NB+1) + w]),
                    .up_acc     (acc[h*(WIDTH_NB+1) + w]),

                    .dn_img     (img[h*(WIDTH_NB+1) + w + 1]),
                    .dn_acc     (acc[h*(WIDTH_NB+1) + w + 1])
                );

            end
        end
    endgenerate


endmodule

`endif //  `ifndef _filter_
