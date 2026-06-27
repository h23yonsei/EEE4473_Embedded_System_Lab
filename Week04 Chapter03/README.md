# Week 04 — Chapter 3: BRAM and Text-LCD Display

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab explores storing data in FPGA Block RAM using COE files and displaying the stored text patterns on a text-LCD. The BRAM acts as ROM, initialized with hexadecimal-encoded ASCII characters that are read and displayed on the LCD.

## Key Concepts

- BRAM initialization via COE (Coefficient) files
- Hexadecimal radix encoding of ASCII text patterns
- 32-bit wide BRAM reads (4 characters per word)
- Text-LCD controller with 2-line, 16-character display
- Address control for sequencing through BRAM contents

## Files

| File | Type | Description |
|------|------|-------------|
| `textlcd.v` | Verilog | Text-LCD controller module |
| `my_coe.coe` | Data | COE file with hex-encoded text |
| `top.xdc` | Constraints | Xilinx constraints file |

## How to Run

1. Create a Vivado project with BRAM IP configured for 32-bit width
2. Initialize BRAM using `my_coe.coe`
3. Synthesize, generate bitstream, and program the FPGA
4. Verify text output on the physical text-LCD display
