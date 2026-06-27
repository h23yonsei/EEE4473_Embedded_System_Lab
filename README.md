# EEE4473 Embedded System Lab

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab (임베디드시스템실험) |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This repository contains all lab materials for EEE4473 Embedded System Lab. The course progresses from digital logic fundamentals in Verilog HDL through machine learning theory to designing a hardware accelerator for neural network inference on an FPGA.

## Course Structure

| Week | Chapter | Topic | Tools |
|------|---------|-------|-------|
| [Week 01](Week01/) | — | Course Introduction | — |
| [Week 02](Week02%20Chapter01/) | Ch 1 | Verilog HDL Basics | Vivado |
| [Week 03](Week03%20Chapter02/) | Ch 2 | Floating-Point Multiplier | Vivado |
| [Week 04](Week04%20Chapter03/) | Ch 3 | BRAM and Text-LCD Display | Vivado |
| [Week 05](Week05%20Chapter04/) | Ch 4 | Introduction to Machine Learning | PyTorch, Colab |
| [Week 06](Week06%20Chapter05/) | Ch 5 | ML Operations | — |
| [Week 08](Week08%20Chapter06/) | Ch 6 | Systolic Array Theory | Python |
| [Week 09](Week09%20Chapter07/) | Ch 7 | 8x8 PE Implementation | Vivado |
| [Week 10](Week10%20Chapter08/) | Ch 8 | Tiling | Python |
| [Week 11](Week11%20Final%20Project/) | Final | MLP Hardware Accelerator | Vivado, Xilinx SDK |

## Topics Covered

### Digital Design (Weeks 02–04)
- Verilog HDL syntax, simulation, and testbench design
- IEEE 754 FP32 combinational multiplier
- Block RAM initialization and text-LCD interfacing

### Machine Learning (Weeks 05–06)
- MLP training and inference with PyTorch
- Activation functions, backpropagation, quantization

### Hardware Acceleration (Weeks 08–11)
- Systolic array and adder tree architectures for GEMM
- Processing Element (PE) design and 8x8 systolic array RTL
- Matrix tiling for on-chip memory constraints
- Final project: 16x16 output-stationary systolic array MLP accelerator on Xilinx Zynq-7020

## Platform

- **FPGA:** Xilinx Zynq-7020 (ZedBoard/PYNQ)
- **EDA:** Xilinx Vivado 2024.1 / Vitis SDK
- **ML:** Python 3, PyTorch, Google Colab

## License

Released under the [MIT License](LICENSE).
