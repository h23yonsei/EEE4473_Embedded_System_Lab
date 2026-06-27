# Week 09 — Chapter 7: 8x8 PE Implementation

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab implements the systolic array concepts from Chapter 6 in synthesizable SystemVerilog. A weight-stationary **Processing Element (PE)** performs multiply-accumulate (MAC) operations, and 64 PEs are connected in an **8x8 systolic array** for matrix multiplication.

## Key Concepts

- Weight-stationary PE: saves weight via `save_weight` control signal, then performs MAC
- Signed 8-bit inputs (data, weight) with 18-bit accumulator output
- 8x8 systolic array using `generate` blocks to instantiate and wire 64 PEs
- Data flow: input data moves horizontally, weights move vertically, accumulation flows downward
- Testbench reads 8x8 matrices from text files (`input.txt`, `weight.txt`)

## Architecture

```text
din_in[0] -> [PE00] -> [PE01] -> ... -> [PE07]
din_in[1] -> [PE10] -> [PE11] -> ... -> [PE17]
   ...         ...       ...              ...
din_in[7] -> [PE70] -> [PE71] -> ... -> [PE77]
                                          |
                                      acc_out[0..7]
```

## Files

| File | Type | Description |
|------|------|-------------|
| `pe.sv` | SystemVerilog | Processing Element — weight-stationary MAC unit |
| `sa_8x8.sv` | SystemVerilog | 8x8 Systolic Array — 64 PEs in a mesh |
| `tb_sa_8x8.sv` | Testbench | Loads matrices from text files and drives the array |
| `input.txt` | Data | 8x8 input data matrix (hex) |
| `weight.txt` | Data | 8x8 weight matrix (hex) |

## How to Run

1. Open in Vivado, add `pe.sv`, `sa_8x8.sv`, and `tb_sa_8x8.sv`
2. Place `input.txt` and `weight.txt` in the simulation working directory
3. Run behavioral simulation and verify accumulated outputs match expected matrix product
