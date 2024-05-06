modular addition:

FPGA DSP48E

W = 27 bits
cypher text modulo = 32 or 512

is stored in 't' W-bit words = $\lceil 32/27 \rceil= 2$ or $\lceil 512/27 \rceil= 19$

multiprecision addition takes: 2 or 19 clock cycles

so:
```latex
(c,sum) = (a+b) mod 2^{W*t} 

If c = 1, then 
    subtract p from sum = (C[t − 1], . . . , C[2], C[1], C[0]);
Else if sum ≥ p 
    then sum ← sum − p.
```

## Reference articles: 
- [FAB](https://bu-icsg.github.io/publications/2023/fhe_accelerator_fpga_hpca2023.pdf)
- [Post-Quantum Cryptographic Hardware Primitives](https://arxiv.org/pdf/1903.03735)
- [Blog post](https://bit-ml.github.io/blog/post/homomorphic-encryption-toy-implementation-in-python)
- [Fast Arithmetic Hardware Library For RLWE-Based Homomorphic Encryption](https://ascslab.org/papers/he-library.pdf)
- [RISE](https://arxiv.org/pdf/2302.07104)
- [MAD](https://bu-icsg.github.io/publications/2023/Agrawal_MICRO_2023.pdf)

First, a 54-bit limb width enables effective utilization of both the 18 -bit multipliers and the 27 - bit preadders within the DSP slices of the FPGA through multi-word arithmetic [31]. DSP slices have multipliers that are **18×27-bit** wide. Using multi-word arithmetic, we can split 54-bit operands into multiple 18-bit operands and operate over them in parallel. To perform integer additions, we split the 54 -bit operands into two 27-bit operands to leverage the 27-bit preadders in the DSP blocks. Second, a 54-bit limb width allows us to make the most of the scarce on-chip memory resources, which includes both UltraRAM (URAM) and Block-RAM (BRAM). On U 280 cards, a URAM block can store 72-bit wide data and a BRAM block can store 18 -bit wide data. Therefore, with 54 -bit (a multiple of 18) coefficients in the vectors, we can effectively utilize the entire data width of the on-chip memory resources by combining multiple B/URAM blocks to store single/multiple coefficients at a given address.

...

For multi-word modular addition and subtraction, we follow Algorithms 2.7 and 2.8 respectively, proposed by Hankerson et al. [31]. Both of these algorithms require a correction step (on line 2 in Algorithms 2.7 and 2.8) for modular reduction, which leads to 54 -bit addition/subtraction operations again. Subsequently, we modify the correction step in both the algorithms to perform multiple 27-bit operations instead. With multi-word arithmetic and all the pipeline registers in place for the DSP blocks, both algorithms perform modular addition and subtraction in **7 clock cycles**. 
