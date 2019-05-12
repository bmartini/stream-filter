/**
 * Testbench:
 *  filter
 *
 * Created:
 *  Wed May  8 21:38:55 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */

`timescale 1ns/10ps

`define TB_VERBOSE
//`define VERBOSE


`include "filter.v"

module filter_tb;

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

    localparam GROUP_NB     = 4;

    localparam HEIGHT_NB    = 3;
    localparam WIDTH_NB     = 3;

    localparam IMG_WIDTH    = 16;
    localparam IMG_FIXED    = IMG_WIDTH/4;

    localparam KER_WIDTH    = 8;
    localparam KER_FIXED    = KER_WIDTH/2;


    // transform signed fixed point representation to real
    function real img_f2r;
        input signed [IMG_WIDTH-1:0] value;

        begin
            img_f2r = value / ((1<<IMG_FIXED) * 1.0);
        end
    endfunction

    function real ker_f2r;
        input signed [KER_WIDTH-1:0] value;

        begin
            ker_f2r = value / ((1<<KER_FIXED) * 1.0);
        end
    endfunction

    function real result_f2r;
        input signed [IMG_WIDTH+KER_WIDTH-1:0] value;

        begin
            result_f2r = value / ((1<<(IMG_FIXED+KER_FIXED)) * 1.0);
        end
    endfunction

    // transform real to signed fixed point representation
    function signed [IMG_WIDTH-1:0] img_r2f;
        input real value;

        begin
            img_r2f = value * (1<<IMG_FIXED);
        end
    endfunction

    function signed [KER_WIDTH-1:0] ker_r2f;
        input real value;

        begin
            ker_r2f = value * (1<<KER_FIXED);
        end
    endfunction


`ifdef TB_VERBOSE
    initial begin
        $display("Testbench for 'filter'");
    end
`endif


    /**
     *  signals, registers and wires
     */
    reg                                                 rst = 0;

    reg  signed [KER_WIDTH-1:0]                         cfg_ker;
    reg                                                 cfg_val;

    reg  signed [HEIGHT_NB*IMG_WIDTH-1:0]               up_img;
    reg                                                 up_val;

    wire signed [HEIGHT_NB*(IMG_WIDTH+KER_WIDTH)-1:0]   result;
    wire                                                result_val;


    /**
     * Unit under test
     */

    filter #(
        .HEIGHT_NB  (HEIGHT_NB),
        .WIDTH_NB   (WIDTH_NB),

        .IMG_WIDTH  (IMG_WIDTH),
        .KER_WIDTH  (KER_WIDTH))
    uut (
        .clk        (clk),
        .rst        (rst),

        .cfg_ker    (cfg_ker),
        .cfg_val    (cfg_val),

        .up_img     (up_img),
        .up_val     (up_val),

        .result     (result),
        .result_val (result_val)
    );


    /**
     * Wave form display
     */

    task display_signals;
        $display(
            "%d\t%d",
            $time, rst,

            "\t%f\t%b",
            ker_f2r(cfg_ker),
            cfg_val,

            "\t%b",
            uut.token,

            "\t%f\t%f\t%f\t%b",
            img_f2r(up_img[2*IMG_WIDTH +: IMG_WIDTH]),
            img_f2r(up_img[1*IMG_WIDTH +: IMG_WIDTH]),
            img_f2r(up_img[0*IMG_WIDTH +: IMG_WIDTH]),
            up_val,

            "\t%f\t%f\t%f\t%b",
            result_f2r(result[2*(IMG_WIDTH+KER_WIDTH) +: (IMG_WIDTH+KER_WIDTH)]),
            result_f2r(result[1*(IMG_WIDTH+KER_WIDTH) +: (IMG_WIDTH+KER_WIDTH)]),
            result_f2r(result[0*(IMG_WIDTH+KER_WIDTH) +: (IMG_WIDTH+KER_WIDTH)]),
            result_val,

        );

    endtask // display_signals

    task display_header;
        $display(
            "\t\ttime\trst",

            "\tc_k",
            "\t\tc_v",
            "\ttoken",

            "\t\tu1",
            "\t\tu2",
            "\t\tu3",
            "\t\tuv",

            "\tr1",
            "\t\tr2",
            "\t\tr3",
            "\t\trv",
        );
    endtask


    /**
     * Testbench program
     */

    initial begin
        // init values
        cfg_ker = 'b0;
        cfg_val = 1'b0;

        up_img  = 1'b0;
        up_val  = 1'b0;
        //end init

`ifdef TB_VERBOSE
    $display("RESET");
`endif

        repeat(6) @(negedge clk);
        rst <= 1'b1;
        repeat(6) @(negedge clk);
        rst <= 1'b0;
        @(negedge clk);


`ifdef TB_VERBOSE
    $display("send cfg with interrupted stream");
`endif
        @(negedge clk);

        repeat(4) begin
            cfg_ker <= ker_r2f(0.5);
            cfg_val <= 1'b1;
            @(negedge clk);
        end

        cfg_val <= 1'b0;
        @(negedge clk);

        repeat(5) begin
            cfg_ker <= ker_r2f(0.5);
            cfg_val <= 1'b1;
            @(negedge clk);
        end

        cfg_val <= 1'b0;
        repeat(6) @(negedge clk);


`ifdef TB_VERBOSE
    $display("send img data stream");
`endif
        @(negedge clk);

        repeat(10) begin
            up_img[2*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(1.5) + up_img[2*IMG_WIDTH +: IMG_WIDTH];
            up_img[1*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(1.0) + up_img[1*IMG_WIDTH +: IMG_WIDTH];
            up_img[0*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(0.5) + up_img[0*IMG_WIDTH +: IMG_WIDTH];
            up_val <= 1'b1;
            @(negedge clk);
        end

        up_img[2*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(1.5);
        up_img[1*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(1.0);
        up_img[0*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(0.5);
        up_val <= 1'b1;
        @(negedge clk);

        repeat(9) begin
            up_img[2*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(1.5) + up_img[2*IMG_WIDTH +: IMG_WIDTH];
            up_img[1*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(1.0) + up_img[1*IMG_WIDTH +: IMG_WIDTH];
            up_img[0*IMG_WIDTH +: IMG_WIDTH] <= img_r2f(0.5) + up_img[0*IMG_WIDTH +: IMG_WIDTH];
            up_val <= 1'b1;
            @(negedge clk);
        end

        up_val <= 1'b0;
        repeat(20) @(negedge clk);


`ifdef TB_VERBOSE
    $display("END");
`endif
        -> end_trigger;
    end

endmodule
