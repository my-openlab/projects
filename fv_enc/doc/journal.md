
# Python code

The code doesn't seem to always work. Either there is an algorithmic/parameters setting problem or the python code is overflow/underflowing sometimes. Interestingly, the values are close enough and approximately correct. Thus pointing to numerical precision errors.

<figure style="text-align: center;">
  <img src="errored_decryption.png" alt="decryption error">
  <figcaption>Decryption error</figcaption>
</figure>

I found the error:'my' model.py code was suppose to be :     
```
    cst1, cst2, pt1, pt2 = (rlwe_updated.gen_uniform_poly(n, t).tolist() for i in range(4))
and not 
    cst1, cst2, pt1, pt2 = (rlwe_updated.gen_uniform_poly(2**16, t).tolist() for i in range(4))

```
but this also points to an interesting observation. why should super long plain text cause rounding issues?


# Encryption

For every message(m) one has to calculate: 
$$
c_t = \left( \left[ (pk0 \cdot u + e_1 + \Delta \cdot m) \right]_{R_q} , \left[ (pk1 \cdot u + e_2) \right]_{R_q}  \in {R_q}\times {R_q} \right)
$$


# High level architecture
A high level system diagram for encryption is as shown here

<figure style="text-align: center;">
  <img src="FV12_encryption.svg" alt="Top dataflow model">
  <figcaption>Dataflow model</figcaption>
</figure>

## Design specifications:

The plaintexts **m** come from a flow. We assume that the interface is an **AXI stream**.
The resulting ciphertexts **ct=[ct1,ct0]** are sent out to a flow. We assume that the interface is an **AXI stream**.

All the encryptions use the same unique public key **pk=[pk1,pk0]**. 
The computation of this latter is done once on the host CPU.
The implemented parameter set is static. 
This can be one of A or B. Parameter set C is only used for part 2.


|Parameter set         |         |           |       |
|----------------------|---------|-----------|-------|
|                      |A        |B          |   C   |
| polynomial size      | 128     | 16384     | 16    |
|polynomial modulo     | X^128+1 | X^16384+1 | X^16+1|
|ciphertext modulo : q | 2^32    |2^512      | 2^64  |
|plaintext modulo : t  |2^8      | 2^64      | 2^16  |


### Challenge
 - The analysis will be done on 2 parameter sets: A and B
 - If assumptions are needed, feel free to define them.
 - Give an architecture of the design.
 - Describe your approach to the problem.
 - Give the strengths and the weaknesses of the chosen architecture.
 - Give the throughput and an estimation of the latency.
    - If possible give an estimation of the reachable clock frequency.

We want to optimize the **throughput** and the **latency**.

The target FPGA is a Xilinx Ultrascale+ technology on U55C Alveo card.


## Analysis
From the given use case, we know public key tuple [pk1, pk0] is pre-computed at the host once at the beginning and is used all encryptions.

for every **m**,
- sample: r1,r2: normal distribution in R
          u : binary, uniform distribution sample from R
- block_A  and block_B operation is independent of Block_D, provided **u** is saved for use in block_B
- Since q and t are constant $\Delta=\lfloor q/t \rfloor$ is also constant and can be expressed as a power of 2. Hence, scaling is just a left-shift operation on the individual fields of incoming message vector m. 

In our particular case i.e. for parameter sets A and B, m is left shifts of 24 and 448 respectively. It is good to note that even after scaling, field elements of 'scaled_m' is never greater than 'q'. So no overflows occur after scaling of field values and can still be represented in 'log2(q)' bits. In our case, it is 32 and 512 bit for parameter sets A and B respectively.

In summary, reducing the latency of encryption is constrained to calculation of one **poly_add** function.

```python
ct0 = polyadd(sum_pk0_e1, scaled_m, q, poly_mod)
```
Taking a closer look at this implementation.

```python
def polyadd(x, y, modulus, poly_mod):
    """Add two polynomials
    Args:
        x, y: two polynoms to be added.
        modulus: coefficient modulus.
        poly_mod: polynomial modulus.
    Returns:
        A polynomial in Z_modulus[X]/(poly_mod).
    """
    return np.int64(
        np.round(poly.polydiv(poly.polyadd(x, y) %
                              modulus, poly_mod)[1] % modulus)
    )
```
The poly.polydiv is in place to ensure the result of the first addition is still in "poly_mod" space. 
since we know both 'x' and 'y' passed here are already in 'poly_mod' we can safely ignore the poly_div operation. 

In other words, 'polyadd' can be simplified to element wise addition of **sum_pk0_e1** and **scaled_m** and then taking modulus of each element w.r.t. 'q'. We know that both 

$ \sum_{i=0}^{i=q-1}ct_0[i] =  sum\_pk0\_e1[i] + scaled\_m[i], \forall i = 0,1,...(q-1) $

We know that both, $sum\_pk0\_e1, scaled\_m < q$

therefore,

$ct_0[i] < 2*q$

but we need, $ct_0[i] < q$, so we take the modulus w.r.t q or just ignore the msb if it is set. 

or in simple terms, just do log2(q) bit + log2(q) addition ignoring the carry out bit.

```python
ct0 = (sum_pk0_e1 + scaled_m) 
ct0 = [ct if ct<q else ct-q for ct in ct0 ] # literally coding %q
```

Finally, the latency of calculation of encryption boils down how fast we can do multiprecision addition.

we leverage the 27-bit preadders in the DSP48E blocks, 

## 

Design goals: 
   
  - optimizing for throughput and the latency.

From the diagram alone, we can already see some pipelining of operations:

Block_A : independent of incoming data M

