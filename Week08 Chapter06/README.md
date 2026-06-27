# Week 08 — Chapter 6: Systolic Array Theory

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab explores two hardware architectures for accelerating General Matrix Multiplication (GEMM) and General Matrix-Vector Multiplication (GEMV): the **Systolic Array** and the **Pipelined Adder Tree**. A Python simulator visualizes the cycle-by-cycle data flow through both architectures.

## Key Concepts

- 2D Systolic Array: output-stationary dataflow, data skewing, PE accumulation
- Adder Tree: parallel multiplication with O(log N) pipelined reduction
- GEMM (C = A x B) vs. GEMV (y = A x v) computational patterns
- Input buffering and staggering for correct PE timing
- Arithmetic intensity comparison between architectures

## Files

| File | Type | Description |
|------|------|-------------|
| `Chapter6_python_lab.ipynb` | Notebook | Interactive systolic array and adder tree simulators |

## How to Run

1. Open `Chapter6_python_lab.ipynb` in Jupyter or Google Colab
2. Run cells to see animated cycle-by-cycle simulations of 4x4 and 8x8 systolic arrays and adder trees
