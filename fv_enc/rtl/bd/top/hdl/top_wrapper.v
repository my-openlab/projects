//Copyright 1986-2021 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2021.2 (lin64) Build 3367213 Tue Oct 19 02:47:39 MDT 2021
//Date        : Mon May  6 16:02:53 2024
//Host        : versal running 64-bit Ubuntu 22.04.4 LTS
//Command     : generate_target top_wrapper.bd
//Design      : top_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module top_wrapper
   (pcie_refclk_clk_n,
    pcie_refclk_clk_p,
    reset);
  input pcie_refclk_clk_n;
  input pcie_refclk_clk_p;
  input reset;

  wire pcie_refclk_clk_n;
  wire pcie_refclk_clk_p;
  wire reset;

  top top_i
       (.pcie_refclk_clk_n(pcie_refclk_clk_n),
        .pcie_refclk_clk_p(pcie_refclk_clk_p),
        .reset(reset));
endmodule
