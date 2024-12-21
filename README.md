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
