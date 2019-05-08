/**
 * Testbench:
 *  delay
 *
 * Created:
 *  Tue May  7 22:43:23 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */

`timescale 1ns/10ps

`define TB_VERBOSE
//`define VERBOSE


`include "delay.v"

module delay_tb;

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

    localparam HEIGHT_NB    = 3;
    localparam IMG_WIDTH    = 8;

    localparam MEM_AWIDTH   = 8;
    localparam MEM_DEPTH    = 15;


`ifdef TB_VERBOSE
    initial begin
        $display("Testbench for 'delay'");
    end
`endif


    /**
     *  signals, registers and wires
     */
    reg                             rst;

    reg  [MEM_AWIDTH-1:0]           cfg_delay;
    reg                             cfg_set;

    reg  [IMG_WIDTH-1:0]            up_data;
    reg                             up_val;

    wire [IMG_WIDTH*HEIGHT_NB-1:0]  delay;
    wire                            delay_val;


    /**
     * Unit under test
     */

    delay #(
        .HEIGHT_NB   (HEIGHT_NB),
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

        .delay      (delay),
        .delay_val  (delay_val)
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

            "\tdn <data: %d %d %d, val: %b>",
            delay[(2*IMG_WIDTH) +: IMG_WIDTH],
            delay[(1*IMG_WIDTH) +: IMG_WIDTH],
            delay[(0*IMG_WIDTH) +: IMG_WIDTH],
            delay_val,
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

        repeat(30) begin
            up_data <= up_data + 1;
            up_val  <= 1'b1;
            @(negedge clk);
        end
        //up_data <= 'b0;
        up_val  <= 1'b0;
        repeat(5) @(negedge clk);


        repeat(30) begin
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
