`ifndef _multiply_add_
`define _multiply_add_


`default_nettype none

module multiply_add
  #(parameter
    IMG_WIDTH   = 16,
    KER_WIDTH   = 16)
   (
    input  wire                             clk,
    input  wire                             rst,

    input  wire [KER_WIDTH-1:0]             cfg_ker,
    input  wire                             cfg_val,

    input  wire [IMG_WIDTH-1:0]             up_img,
    input  wire [IMG_WIDTH+KER_WIDTH-1:0]   up_acc,

    output reg  [IMG_WIDTH-1:0]             dn_img,
    output reg  [IMG_WIDTH+KER_WIDTH-1:0]   dn_acc
);



    function signed [IMG_WIDTH+KER_WIDTH-1:0] multiply;
        input signed [IMG_WIDTH-1:0] a1;
        input signed [KER_WIDTH-1:0] a2;

        begin
            multiply = a1 * a2;
        end
    endfunction


    function signed [IMG_WIDTH+KER_WIDTH-1:0] addition;
        input signed [IMG_WIDTH+KER_WIDTH-1:0]  a1;
        input signed [IMG_WIDTH+KER_WIDTH-1:0]  a2;

        begin
            addition = a1 + a2;
        end
    endfunction


    reg  [IMG_WIDTH-1:0]            dn_img_p3;
    reg  [IMG_WIDTH-1:0]            dn_img_p2;

    reg  [IMG_WIDTH-1:0]            up_img_p2;
    reg  [IMG_WIDTH-1:0]            up_img_p1;

    reg  [KER_WIDTH-1:0]            ker_p2;
    reg  [KER_WIDTH-1:0]            ker_p1;

    reg  [IMG_WIDTH+KER_WIDTH-1:0]  up_acc_p4;
    reg  [IMG_WIDTH+KER_WIDTH-1:0]  up_acc_p3;
    reg  [IMG_WIDTH+KER_WIDTH-1:0]  up_acc_p2;
    reg  [IMG_WIDTH+KER_WIDTH-1:0]  up_acc_p1;

    reg  [IMG_WIDTH+KER_WIDTH-1:0]  product_p3;


    always @(posedge clk)
        if (cfg_val) begin
            ker_p1 <= cfg_ker;
        end


    always @(posedge clk) begin
        up_img_p1   <= up_img;
        up_acc_p1   <= up_acc;
    end


    // delay up_img stream
    always @(posedge clk) begin
        dn_img_p2   <= up_img_p1;
        dn_img_p3   <= dn_img_p2;
        dn_img      <= dn_img_p3;
    end


`ifdef ALTERA_FPGA
    always @(posedge clk or posedge rst)
`else //!ALTERA_FPGA
    always @(posedge clk)
`endif
        if (rst) begin
            ker_p2      <= 'b0;
            up_img_p2   <= 'b0;
            up_acc_p2   <= 'b0;

            product_p3  <= 'b0;
            up_acc_p3   <= 'b0;

            up_acc_p4   <= 'b0;
            dn_acc      <= 'b0;
        end
        else begin
            ker_p2      <= ker_p1;
            up_img_p2   <= up_img_p1;
            up_acc_p2   <= up_acc_p1;

            product_p3  <= multiply(up_img_p2, ker_p2);
            up_acc_p3   <= up_acc_p2;

            up_acc_p4   <= addition(product_p3, up_acc_p3);
            dn_acc      <= up_acc_p4;
        end


endmodule

`default_nettype wire

`endif //  `ifndef _multiply_add_
