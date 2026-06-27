# Week 03 — Chapter 2: Floating-Point Multiplier

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab implements a combinational IEEE 754 single-precision (FP32) floating-point multiplier in Verilog. The module takes two 32-bit inputs and produces a 32-bit FP32 result using pure combinational logic (no clock). A 7-segment display driver is also implemented for on-board visualization.

## Key Concepts

- IEEE 754 FP32 format: sign, exponent (8-bit), mantissa (23-bit)
- Sign calculation via XOR, exponent addition with bias correction (-127)
- 24-bit mantissa multiplication producing a 48-bit product
- Normalization and rounding (shift vs. no-shift cases)
- Edge cases: zero, overflow (infinity), underflow

## Files

| File | Type | Description |
|------|------|-------------|
| `fp32_multiplier.v` | Verilog | FP32 multiplier module |
| `top.sv` | Testbench | Testbench with automated test cases |
| `top.v` | Verilog | 7-segment display driver controller |
| `top.xdc` | Constraints | Xilinx constraints file |

## How to Run

1. Open in Vivado, add `fp32_multiplier.v` and `top.sv`
2. Run behavioral simulation — 10 test cases verify multiplication results against expected FP32 outputs
