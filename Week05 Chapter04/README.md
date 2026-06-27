# Week 05 — Chapter 4: Introduction to Machine Learning

| | |
|---|---|
| **Course** | EEE4473 Embedded System Lab |
| **Semester** | 2026 Spring, Yonsei University |

## Overview

This lab introduces machine learning by building and training an MLP model for MNIST handwritten digit classification using PyTorch. The notebook also demonstrates 8-bit dynamic quantization for model compression. The model achieves 98.36% full-precision accuracy and 98.33% after int8 quantization.

## Key Concepts

- MLP architecture: Linear → BatchNorm → ReLU layers
- Training loop: forward pass, loss (CrossEntropyLoss), backpropagation, optimizer (Adam)
- MNIST dataset: 60,000 training / 10,000 test images (28x28 grayscale)
- GPU-accelerated training with CUDA
- 8-bit quantization (`torch.quantization.quantize_dynamic`)

## Files

| File | Type | Description |
|------|------|-------------|
| `Exp4_students.ipynb` | Notebook | MLP training and quantization on MNIST |

## How to Run

1. Open `Exp4_students.ipynb` in Google Colab (GPU runtime recommended)
2. Mount Google Drive when prompted for dataset storage
3. Run all cells sequentially
