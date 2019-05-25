/*
 * Module:
 *  delay
 *
 * Description:
 *  The delay module the groups the delay memory modules so that the streamed
 *  image data is kept around so it can be sent to the filter all at once.
 *
 * Created:
 *  Tue May  7 22:43:13 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */
`ifndef _delay_
`define _delay_

`include "delay_mem.v"


`default_nettype none

module delay
  #(parameter
    HEIGHT_NB   = 3,
    IMG_WIDTH   = 8,

    MEM_AWIDTH  = 12,
    MEM_DEPTH   = 1<<MEM_AWIDTH)
   (input  wire                             clk,
    input  wire                             rst,

    input  wire [MEM_AWIDTH-1:0]            cfg_delay,
    input  wire                             cfg_set,

    input  wire [IMG_WIDTH-1:0]             up_data,
    input  wire                             up_val,

    output wire [IMG_WIDTH*HEIGHT_NB-1:0]   delay,
    output wire                             delay_val
);


    /**
     * Local parameters
     */


    /**
     * Internal signals
     */


    reg  [IMG_WIDTH-1:0]    up_data_r;
    reg                     up_val_r;
    wire [HEIGHT_NB-1:0]    delay_val_i;


    /**
     * Implementation
     */


    genvar h;
    generate
        for (h=1; h<HEIGHT_NB; h=h+1) begin : DELAY_MEM_


            delay_mem #(
                .IMG_WIDTH  (IMG_WIDTH),

                .MEM_AWIDTH (MEM_AWIDTH),
                .MEM_DEPTH  (MEM_DEPTH))
            delay_mem_ (
                .clk        (clk),
                .rst        (rst),

                .cfg_delay  (cfg_delay),
                .cfg_set    (cfg_set),

                .up_data    (delay[((h-1)*IMG_WIDTH) +: IMG_WIDTH]),
                .up_val     (delay_val_i[h-1] & up_val_r),

                .dn_data    (delay[(h*IMG_WIDTH) +: IMG_WIDTH]),
                .dn_val     (delay_val_i[h])
            );


        end
    endgenerate



    always @(posedge clk) begin
        up_data_r   <= up_data;
        up_val_r    <= up_val;
    end


    assign delay[0 +: IMG_WIDTH] = up_data_r;

    assign delay_val_i[0] = up_val_r;

    assign delay_val = &(delay_val_i);



endmodule

`default_nettype wire

`endif //  `ifndef _delay_
