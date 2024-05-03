# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.

import rlwe_he_scheme_updated as rlwe_updated
import numpy as np

if __name__ == '__main__':
    # Scheme's parameters :  static
    # polynomial size  : n= 128
    # polynomial modulo: X^128+1 
    # ciphertext modulo: q = 2^32
    # plaintext modulo : t = 2^8

    # Goal: optimize for throughput and latency on alveo U55c
    param_set= [(2,14,1),(7,32,8),(14,512,64),(4,64,16)]

    selected_set = 0
    # polynomial modulus degree
    n = 2 ** param_set[selected_set][0]
    # ciphertext modulus
    q = 2 ** param_set[selected_set][1]
    # plaintext modulus
    t = 2** param_set[selected_set][2]


    # base for relin_v1
    T = np.int64(2 ** int(param_set[selected_set][1]/2)) # sqrt

    # modulusswitching modulus
    p = q ** 3

    # polynomial modulus # X^n+1 
    poly_mod = np.array([1] + [0] * (n - 1) + [1]) 

    print("[+] poly_mod ({}):".format(poly_mod))

    # standard deviation for the error in the encryption
    std1 = 1
    # standard deviation for the error in the evaluateKeyGen_v2
    std2 = 1

    # Keygen on host computer (once)
    pk, sk = rlwe_updated.keygen(n, q, poly_mod, std1)

    print("[+] pk ({}):".format(pk))
    print("[+] sk ({}):".format(sk))

    # EvaluateKeygen_version1
    rlk0_v1, rlk1_v1 = rlwe_updated.evaluate_keygen_v1(sk, n, q, T, poly_mod, std1)
    print("[+] rlk0_v1:{}\n [+] rlk1_v1:{}".format(rlk0_v1, rlk1_v1))

    # EvaluateKeygen_version2
    # rlk0_v2, rlk1_v2 = rlwe_updated.evaluate_keygen_v2(sk, n, q, poly_mod, p, std2)
    # print("[+] rlk0_v2:{}\n [+] rlk1_v2:{}".format(rlk0_v2, rlk1_v2))

    # Encryption
    # the widths of this vectors should be n 
    # plain texts: coeffs. drawn from R_t 

    # pt1, pt2 = [1, 0, 1, 1], [1, 1, 0, 1] 

    if selected_set == 0: 
        pt1, pt2 = [0,0,0,0], [0,0,1,0] # failing case, 
    else:
        pt1, pt2 = rlwe_updated.gen_uniform_poly(n, t).tolist(), rlwe_updated.gen_uniform_poly(n, t).tolist()
    
    # cst1, cst2 = [0, 1, 1, 0], [0, 1, 0, 0] # plain text: coeffs. drawn from R_t 
    if selected_set == 0: 
        cst1, cst2  = [1,0,1,1], [1,0,0,1] # failing case as, pt4= [0,1,1], should it be [0,1,1,0] ?
    else:
        cst1, cst2  = rlwe_updated.gen_uniform_poly(n, t).tolist(), rlwe_updated.gen_uniform_poly(n, t).tolist()
    
    
    # Encryption operation that is target of acceleration
    # results are in: R_(q),  a pair each containing 128 symbols
    ct1 = rlwe_updated.encrypt(pk, n, q, t, poly_mod, pt1, std1) 
    ct2 = rlwe_updated.encrypt(pk, n, q, t, poly_mod, pt2, std1)

    print("[+] Ciphertext ct1({}):".format(pt1))
    print("")
    print("\t ct1_0:", ct1[0])
    print("\t ct1_1:", ct1[1])
    print("")

    print("[+] Ciphertext ct2({}):".format(pt2))
    print("")
    print("\t ct1_0:", ct2[0])
    print("\t ct1_1:", ct2[1])
    print("")

    # Evaluation

    # cypher text + cst1 
    ct3 = rlwe_updated.add_plain(ct1, cst1, q, t, poly_mod)
    pt3 = rlwe_updated.polyadd(cst1, pt1, t, poly_mod) # plain text equivalent

    # cypher text * cst2 
    ct4 = rlwe_updated.mul_plain(ct2, cst2, q, t, poly_mod)
    pt4 = rlwe_updated.polymul(rlwe_updated.decrypt(sk, n, q, t, poly_mod, cst2), pt2, t, poly_mod) # plain text equivalent

    # ct5 = (ct1 + cst1) + (cst2 * ct2)
    ct5 = rlwe_updated.add_cipher(ct3, ct4, q, poly_mod)
    pt5= rlwe_updated.polyadd(pt3, pt4, t, poly_mod) # plain text equivalent

    # multiplication operation: ct1*ct2
    ct6 = rlwe_updated.mul_cipher_v1(ct1, ct2, q, t, T, poly_mod, rlk0_v1, rlk1_v1)

    pt6 = rlwe_updated.polymul(pt1, pt2, t, poly_mod) # plain text equivalent

    # ct7 = rlwe_updated.mul_cipher_v2(ct1, ct2, q, t, p, poly_mod, rlk0_v2, rlk1_v2)

    # Decryption
    decrypted_ct3 = rlwe_updated.decrypt(sk, n, q, t, poly_mod, ct3)
    decrypted_ct4 = rlwe_updated.decrypt(sk, n, q, t, poly_mod, ct4)
    decrypted_ct5 = rlwe_updated.decrypt(sk, n, q, t, poly_mod, ct5)

    decrypted_ct6 = rlwe_updated.decrypt(sk, n, q, t, poly_mod, ct6)

    # decrypted_ct7 = rlwe_updated.decrypt(sk, n, q, t, poly_mod, ct7)

    assert (decrypted_ct3 == pt3).all(), \
        print("[+] Decrypted ct3=(ct1 + {}): {}, expected: {}".format(cst1, decrypted_ct3, pt3))
    
    assert (decrypted_ct4 == pt4).all(), \
        print("[+] Decrypted ct4=(ct2 * {}): {}, expected: {}".format(cst2, decrypted_ct4, pt4))
    
    assert (decrypted_ct5 == pt5).all(), \
        print("[+] Decrypted ct5=(ct1 + {} + {} * ct2): {}, expected: {}".format(cst1, cst2, decrypted_ct5, pt5))

    # Essentially does: pt5
    # print("[+] pt1 + {} + {} * pt2): {}".format(cst1, cst2, rlwe_updated.polyadd(
    #                                                                         rlwe_updated.polyadd(pt1, cst1, t, poly_mod),
    #                                                                         rlwe_updated.polymul(cst2, pt2, t, poly_mod),
    #                                                                         t, poly_mod)
    #                                                 ))
    assert (decrypted_ct6 == pt6).all(), \
        print("[+] Decrypted ct6=(ct1 * ct2): {}, expected: {}".format(decrypted_ct6, pt6))

    # print("[+] Decrypted ct7=(ct1 * ct2): {}".format(decrypted_ct7))
    # print("[+] pt1 * pt2: {}".format(rlwe_updated.polymul(pt1, pt2, t, poly_mod)))
   
