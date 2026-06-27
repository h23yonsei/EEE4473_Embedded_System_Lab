# Week 11 — Final Project: MLP Hardware Accelerator

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This project designs and implements a hardware accelerator that runs a 4-layer MLP inference for the Google Speech Commands dataset on a Xilinx Zynq-7020 FPGA (ZedBoard/PYNQ). The accelerator uses a **16x16 output-stationary systolic array** with tiling to perform int8 matrix multiplication across all four layers, classifying 16 audio spectrograms into spoken digits. The accelerator processes 16 audio clips in a single batch and outputs predicted speech commands via UART.

## Key Concepts

- 16x16 output-stationary systolic array with tiling
- Tiling for matrices larger than the PE array, with partial sum accumulation
- Int8 quantization with static scale factors and inter-layer requantization
- ReLU activation with saturation to [0, 127]
- PS-PL interface: ARM Cortex-A9 reads results from PL BRAM via interrupt-driven flow

## Architecture

```text
Input (16x768) -> [W1: 128x768] -> [W2: 128x128] -> [W3: 128x128] -> [W4: 16x128] -> Output (16x16)
                   Layer 1           Layer 2           Layer 3           Layer 4
```

- **Systolic Array:** 16x16 PEs, output-stationary dataflow
- **Tiling:** Matrices larger than 16x16 are decomposed into tiles with partial sum accumulation
- **Quantization:** All data and weights are int8; inter-layer requantization with static scale factors
- **Activation:** ReLU applied after each layer, saturating to [0, 127]

## Files

| File | Type | Description |
|------|------|-------------|
| **NumPy Reference** | | |
| `numpy_reference/numpy_reference.py` | Python | Golden reference — runs the full 4-layer MLP pipeline in NumPy |
| `numpy_reference/weights/` | Data | Pre-trained int8 weights and input data |
| `numpy_reference/weights/input_spectrogram.bin` | Data | 16 audio spectrograms (16x768, int8) |
| `numpy_reference/weights/layer{1-4}_weights.bin` | Data | Layer weights (int8) |
| `numpy_reference/weights/bin2hex.py` | Utility | Converts binary weights to hex for BRAM initialization |
| `numpy_reference/weights/bram_init.txt` | Data | Hex-formatted BRAM initialization data |
| **Vivado/SDK Project** | | |
| `finalprj_rps/` | Project | Xilinx SDK workspace with platform, BSP, and application projects |
| `finalprj_rps/rps_z7020_tk.xdc` | Constraints | Constraints file for Zynq-7020 |
| `finalprj_rps/260612_bram_1.xsa` | Data | Exported hardware design |
| **Documents** | | |

## How to Run

### NumPy Reference

```bash
cd numpy_reference
python numpy_reference.py
```

### Hardware Deployment

1. Open `finalprj_rps/finalprj_rps.xpr` in Xilinx Vivado
2. Generate bitstream and export hardware (.xsa)
3. In Xilinx SDK, build and run `helloworld.c` on the Zynq PS
4. Connect UART terminal (115200 baud) to see prediction results
