/**
 * Testbench:
 *  clip
 *
 * Created:
 *  Tue May 14 18:52:30 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */

`timescale 1ns/10ps

`define TB_VERBOSE
//`define VERBOSE


`include "clip.v"

module clip_tb;

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

    localparam WIDTH_NB     = 3;
    localparam IMG_WIDTH    = 8;

    localparam MEM_AWIDTH   = 8;
    localparam MEM_DEPTH    = 15;


`ifdef TB_VERBOSE
    initial begin
        $display("Testbench for 'clip'");
    end
`endif


    /**
     *  signals, registers and wires
     */
    reg                     rst;


    reg  [MEM_AWIDTH-1:0]   cfg_delay;
    reg                     cfg_set;

    reg  [IMG_WIDTH-1:0]    up_data;
    reg                     up_val;

    wire [IMG_WIDTH-1:0]    dn_data;
    wire                    dn_val;


    /**
     * Unit under test
     */

    clip #(
        .WIDTH_NB   (WIDTH_NB),
        .IMG_WIDTH  (IMG_WIDTH),

        .MEM_AWIDTH (MEM_AWIDTH),
        .MEM_DEPTH  (MEM_DEPTH))
    uut (
        .clk        (clk),
        .rst        (rst),

        .cfg_delay  (cfg_delay),
        .cfg_set    (cfg_set),

        .up_data    (up_data),
        .up_val     (up_val),

        .dn_data    (dn_data),
        .dn_val     (dn_val)
    );


    /**
     * Wave form display
     */

    task display_signals;
        $display(
            "%d %d",
            $time, rst,

            "\tup <data: %d, val: %b>",
            up_data,
            up_val,

            "\tdn <data: %d, val: %b>",
            dn_data,
            dn_val,

            "\trow <cnt: %d, mask: %b>",
            uut.row_cnt,
            uut.row_mask,
        );

    endtask // display_signals

    task display_header;
        $display(
            "\t\ttime rst",

        );
    endtask


    /**
     * Testbench program
     */

    initial begin
        // init values
        rst = 0;

        cfg_delay   = 'b0;
        cfg_set     = 1'b0;

        up_data     = 'b0;
        up_val      = 1'b0;
        //end init

`ifdef TB_VERBOSE
    $display("RESET");
`endif

        repeat(6) @(negedge clk);
        rst         <= 1'b1;
        repeat(6) @(negedge clk);
        rst         <= 1'b0;
        repeat(5) @(negedge clk);


`ifdef TB_VERBOSE
    $display("send cfg delay");
`endif

        @(negedge clk);

        cfg_delay   <= 'd10;
        cfg_set     <= 1'b1;
        @(negedge clk);

        cfg_delay   <= 'b0;
        cfg_set     <= 1'b0;
        repeat(5) @(negedge clk);


`ifdef TB_VERBOSE
    $display("send image data");
`endif

        repeat(5) @(negedge clk);

        //repeat(30) begin
        //repeat(29) begin
        //repeat(28) begin
        repeat(27) begin
            up_data <= up_data + 1;
            up_val  <= 1'b1;
            @(negedge clk);
        end
        //up_data <= 'b0;
        up_val  <= 1'b0;
        repeat(5) @(negedge clk);


        //repeat(30) begin
        //repeat(31) begin
        //repeat(32) begin
        repeat(33) begin
            up_data <= up_data + 1;
            up_val  <= 1'b1;
            @(negedge clk);
        end
        up_data <= 'b0;
        up_val  <= 1'b0;
        repeat(15) @(negedge clk);


`ifdef TB_VERBOSE
    $display("END");
`endif
        -> end_trigger;
    end

endmodule
