# OoO_6502

## Notes

This project operates on a slightly simplified model of the 6502's interfaces:
as with Arlet Ottens' verilog-6502 core, memory interfaces are considered to be
synchronous.

## Setup

This repository is set up to be built on Linux and similar Unix systems. On
Windows, it can be run through WSL.

* Install the required tools:
  * `git`
  * `python3`
  * `make`
  * `iverilog`
  * `gtkwave`
  * `cc65`
* Clone the repository:
```
git clone <URL>
cd <repo name>
git subomodule init --update
```

## Running

* To run all tests, type `make test` (or just `make`).
* To delete intermediate files (useful if something gets bugged), type `make clean`.
* To run only Verilog testbenches, type `make test-vl`.
* To run a particular testbench, type `make vl_test_<testname>`.
* To view the graph output from a given test, run `gtkwave waveforms/<testname>.fst`.

## Test system

The CPU designs in this repository are tested using a basic minimal system, with
a memory map as follows:
* ROM: 32 KB, address 0x8000 - 0xFFFF
* RAM: 16 KB, address 0x0000 - 0x3FFF
