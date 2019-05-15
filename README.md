# Stream Filter

This is a hardware filter that takes a streamed raster image and performs a
configurable convolution. The output of the filter will be smaller then the
original.


## UUT Modules

To simulate HDL modules a testbench must have been written and Icarus Verilog
installed. To testbench the module run the "sim-module" script from this repos
root directory with the modules name as argument.

``` bash
./sim-module <modules-name>
```

All hdl modules get copied into a *uut* directory and the Icarus simulator is
invoked to compile and run the modules testbench.

