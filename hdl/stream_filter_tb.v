/**
 * Testbench:
 *  stream_filter
 *
 * Created:
 *  Mon May 13 20:25:49 PDT 2019
 *
 * Author:
 *  Berin Martini (berin.martini@gmail.com)
 */

`timescale 1ns/10ps

`define TB_VERBOSE
//`define VERBOSE


`include "stream_filter.v"

module stream_filter_tb;

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

    localparam
        CFG_WIDTH   = 1,
        CFG_KERNEL  = 2,
        CFG_RESCALE = 3;


    localparam CFG_DWIDTH   = 32;
    localparam CFG_AWIDTH   = 5;

    localparam MEM_AWIDTH   = 8;
    localparam MEM_DEPTH    = 128;

    localparam IMG_WIDTH    = 16;
    localparam KER_WIDTH    = 16;

    localparam IMG_POINT    = 8;
    localparam KER_POINT    = 12;


    // signed fixed point ker representation to real
    function real ker_f2r;
        input signed [KER_WIDTH-1:0] value;

        begin
            ker_f2r = value / ((1<<KER_POINT) * 1.0);
        end
    endfunction

    // real to signed fixed point ker representation
    function signed [KER_WIDTH-1:0] ker_r2f;
        input real value;

        begin
            ker_r2f = value * (1<<KER_POINT);
        end
    endfunction

    // signed fixed point img representation to real
    function real img_f2r;
        input signed [IMG_WIDTH-1:0] value;

        begin
            img_f2r = value / ((1<<IMG_POINT) * 1.0);
        end
    endfunction

    // real to signed fixed point img representation
    function signed [IMG_WIDTH-1:0] img_r2f;
        input real value;

        begin
            img_r2f = value * (1<<IMG_POINT);
        end
    endfunction


`ifdef TB_VERBOSE
    initial begin
        $display("Testbench for 'stream_filter'");
    end
`endif


    /**
     *  signals, registers and wires
     */
    reg                     rst;

    reg  [7:0]              shift;
    reg  [7:0]              head;

    reg  [CFG_DWIDTH-1:0]   cfg_data;
    reg  [CFG_AWIDTH-1:0]   cfg_addr;
    reg                     cfg_valid;

    reg  [IMG_WIDTH-1:0]    image;
    reg                     image_val;

    wire [IMG_WIDTH-1:0]    result;
    wire                    result_val;


    /**
     * Unit under test
     */

    stream_filter #(
        .CFG_DWIDTH (CFG_DWIDTH),
        .CFG_AWIDTH (CFG_AWIDTH),

        .MEM_AWIDTH (MEM_AWIDTH),
        .MEM_DEPTH  (MEM_DEPTH),

        .IMG_WIDTH  (IMG_WIDTH),
        .KER_WIDTH  (KER_WIDTH))
    uut (
        .clk        (clk),
        .rst        (rst),

        .cfg_data   (cfg_data),
        .cfg_addr   (cfg_addr),
        .cfg_valid  (cfg_valid),

        .image      (image),
        .image_val  (image_val),

        .result     (result),
        .result_val (result_val)
    );


    /**
     * Wave form display
     */

    task display_signals;
        $display(
            "%d %d",
            $time, rst,

            "\tcfg %x %b",
            cfg_data,
            cfg_valid,

            "\timg: %x %12f %b",
            image,
            img_f2r(image),
            image_val,

            "\tres: %12f %b",
            img_f2r(result),
            result_val,

//            "\tdelay: %x %b %b",
//            uut.delay_data,
//            uut.delay_val,
//            uut.delay_.delay_val_i,

//            "\tfilter: %x %b",
//            uut.filter_data,
//            uut.filter_val,

//            "\tadd: %b\t%x",
//            uut.add_valid,
//            uut.add_data,

//            "\trescale: %x %b",
//            uut.rescale_data,
//            uut.rescale_valid,

//            "\tclip: %x %b",
//            uut.clip_data,
//            uut.clip_valid,

        );

    endtask // display_signals

    task display_header;
        $display(
            "\t\ttime\trst",

        );
    endtask


    /**
     * Testbench program
     */

    initial begin
        // init values
        rst = 0;

        shift       = KER_POINT;
        head        = IMG_WIDTH+KER_POINT-1;

        cfg_data    = 'b0;
        cfg_addr    = 'b0;
        cfg_valid   = 1'b0;

        image       = 'b0;
        image_val   = 1'b0;
        //end init

`ifdef TB_VERBOSE
    $display("RESET");
`endif

        repeat(6) @(negedge clk);
        rst <= 1'b1;
        repeat(6) @(negedge clk);
        rst <= 1'b0;
        repeat(5) @(negedge clk);

`ifdef TB_VERBOSE
    $display("send config");
`endif

        // {shift, head}
        cfg_data    <= {8'd0, 8'd0, shift, head};
        cfg_addr    <= CFG_RESCALE;
        cfg_valid   <= 1'b1;
        @(negedge clk);

        cfg_data    <= 32'd10;
        cfg_addr    <= CFG_WIDTH;
        cfg_valid   <= 1'b1;
        @(negedge clk);

        repeat(30) begin
            cfg_data    <= ker_r2f(0.5);
            cfg_addr    <= CFG_KERNEL;
            cfg_valid   <= 1'b1;
            @(negedge clk);
        end

        cfg_data    <= 'b0;
        cfg_addr    <= 'b0;
        cfg_valid   <= 1'b0;
        @(negedge clk);


`ifdef TB_VERBOSE
    $display("send data");
`endif

        repeat(10) @(negedge clk);

        repeat(30) begin
            image       <= img_r2f(img_f2r(image) + 16'd1);
            image_val   <= 1'b1;
            @(negedge clk);
        end

        image       <= 'b0;
        image_val   <= 1'b0;
        @(negedge clk);



        repeat(30) @(negedge clk);


`ifdef TB_VERBOSE
    $display("END");
`endif
        -> end_trigger;
    end

endmodule
