# Week 02 — Chapter 1: Verilog HDL Basics

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab introduces the basics of Verilog HDL by analyzing a "mystery module" that generates sequential prime numbers. The module uses three phases — *initialization*, *preparation*, and *calculation* — to find and output primes using 8-bit registers.

## Key Concepts

- Combinational vs. sequential logic in Verilog
- Clock-driven state machines with `always @(posedge clk)`
- Simulation testbench design (clock generation, reset assertion)

## Files

| File | Type | Description |
|------|------|-------------|
| `tb_mystery_module.v` | Testbench | Testbench for the prime number generator module |

## How to Run

1. Open in Vivado and add the mystery module source (provided separately) along with `tb_mystery_module.v`
2. Run behavioral simulation — observe prime numbers output on `out[7:0]` over 1000 ns
