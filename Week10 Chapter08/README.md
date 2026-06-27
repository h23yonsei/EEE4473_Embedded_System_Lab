# Week 10 — Chapter 8: Tiling

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab addresses the memory-bound problem of executing large matrix multiplications on hardware with limited on-chip buffers. **Tiling** decomposes large matrices into smaller tiles that fit within on-chip SRAM, enabling data reuse and reducing off-chip memory traffic.

## Key Concepts

- On-chip vs. off-chip memory constraints (e.g., ResNet-50's 940 KB layer vs. 128 KB buffer)
- Tiling: splitting input, weight, and output matrices into working sets
- Nested loop structure: outer loop over tiles, inner loop over elements
- Zero-padding for tiles that extend beyond matrix boundaries
- Interactive visualization of tile traversal and partial sum accumulation on an 8x8 PE array

## Files

| File | Type | Description |
|------|------|-------------|
| `Chapter8_python_lab.ipynb` | Notebook | Interactive tiling visualization with sliders |

## How to Run

1. Open `Chapter8_python_lab.ipynb` in Jupyter or Google Colab
2. Use the interactive sliders to adjust matrix dimensions (M, N, K) and step through tile iterations
3. Observe how tiles map to the global memory view and the 8x8 hardware array
