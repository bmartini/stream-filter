/**
 * Testbench:
 *  multiply_add
 *
 * Created:
 *  Wed May  8 18:53:31 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */

`timescale 1ns/10ps

`define TB_VERBOSE
//`define VERBOSE


`include "multiply_add.v"

module multiply_add_tb;

    /**
     * Clock and control functions
     */

    // Generate a clk
    reg clk = 0;
    always #1 clk = !clk;

    // End of simulation event definition
    event end_trigger;
    always @(end_trigger) $finish;

`ifdef TB_VERBOSE
    // Display header information
    initial #1 display_header();
    always @(end_trigger) display_header();

    // And strobe signals at each clk
    always @(posedge clk) display_signals();
`endif

//    initial begin
//        $dumpfile("result.vcd"); // Waveform file
//        $dumpvars;
//    end


    /**
     * Local parameters
     */

    localparam IMG_WIDTH    = 8;
    localparam KER_WIDTH    = 16;


`ifdef TB_VERBOSE
    initial begin
        $display("Testbench for 'multiply_add' up_img: %d, cfg_ker: %d, dn_acc: %d",
            IMG_WIDTH, KER_WIDTH, (IMG_WIDTH+KER_WIDTH));
    end
`endif


    /**
     *  signals, registers and wires
     */

    reg  rst;

    reg     [KER_WIDTH-1:0]             cfg_ker;
    reg                                 cfg_val;

    reg     [IMG_WIDTH-1:0]             up_img;
    reg     [IMG_WIDTH+KER_WIDTH-1:0]   up_acc;

    wire    [IMG_WIDTH-1:0]             dn_img;
    wire    [IMG_WIDTH+KER_WIDTH-1:0]   dn_acc;


    /**
     * Unit under test
     */

    multiply_add #(
        .IMG_WIDTH  (IMG_WIDTH),
        .KER_WIDTH  (KER_WIDTH))
    uut (
        .clk        (clk),
        .rst        (rst),

        .cfg_ker    (cfg_ker),
        .cfg_val    (cfg_val),

        .up_img        (up_img),
        .up_acc        (up_acc),

        .dn_img     (dn_img),
        .dn_acc     (dn_acc)
    );


    /**
     * Wave form display
     */

    task display_signals;
        $display(
            "%d\t%d",
            $time, rst,

            "\t%b\t%d",
            cfg_val,
            $signed(cfg_ker),

            "\t%d\t%d",
            $signed(up_img),
            $signed(up_acc),

            "\t%d\t%d",
            $signed(dn_img),
            $signed(dn_acc),
        );
    endtask

    task display_header;
        $display(
            "\t\ttime\trst",

            "\tval",
            "\tker",

            "\tup_img",
            "\tup_acc",

            "\t\tdn_img",
            "\t\tdn_acc",

        );
    endtask


    /**
     * Testbench program
     */


    initial begin
        // init values
        rst = 0;

        cfg_ker = 'b0;
        cfg_val = 1'b0;

        up_img = 'b0;
        up_acc = 'b0;
        //end init

`ifdef TB_VERBOSE
    $display("RESET");
`endif

        repeat(6) @(posedge clk);
        rst <= 1'b1;
        repeat(6) @(posedge clk);
        rst <= 1'b0;
        repeat(6) @(posedge clk);


`ifdef TB_VERBOSE
    $display("set kernel weight");
`endif

        @(negedge clk);
        cfg_ker <= 'd2;
        cfg_val <= 1'b1;
        @(negedge clk);
        cfg_ker <= 'd0;
        cfg_val <= 1'b0;
        @(negedge clk);


`ifdef TB_VERBOSE
    $display("test continuous stream");
`endif

        up_img <= 'd1;
        up_acc <= 'd1;
        @(negedge clk);
        repeat (10) begin
            up_img <= up_img + 'b1;
            up_acc <= 1'b1;

            @(negedge clk);
        end

        up_img <=  'b0;
        up_acc <=  'b0;
        repeat (10) @(negedge clk);



`ifdef TB_VERBOSE
    $display("END");
`endif
        -> end_trigger;
    end

endmodule
