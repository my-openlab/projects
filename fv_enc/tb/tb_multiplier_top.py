from cocotb import start_soon, start, test
from cocotb.task import Task
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles,NextTimeStep, Event, First, Combine
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamFrame,AxiStreamSink)
import logging
import numpy as np


import sys
sys.path.append('../')


import he_scheme.rlwe_he_scheme_updated as rlwe_updated

class TB:
    
    def __init__(self, dut , mult_type: str = 'poly_mult'):

        self.dut = dut
        self.dut_rslt = []
        self.n = 16
        self.q = 2**8
        # polynomial modulus # X^n+1 
        self.poly_mod = np.array([1] + [0] * (self.n - 1) + [1]) 

        self.axis_p_src = AxiStreamSource(AxiStreamBus.from_prefix( dut, "p"), dut.clk, dut.s_rst_n, reset_active_level=False)
        self.axis_u_src = AxiStreamSource(AxiStreamBus.from_prefix( dut, "u"), dut.clk, dut.s_rst_n, reset_active_level=False)
        self.axis_z_sink = AxiStreamSink(AxiStreamBus.from_prefix( dut, "z"), dut.clk, dut.s_rst_n, reset_active_level=False)
        self.log = logging.getLogger(mult_type)
        self.log.setLevel(logging.INFO)
        logging.getLogger("cocotb.multiplier_top").setLevel(logging.ERROR) ## Disable cocotb's built in logging
        mult_filehandler = logging.FileHandler(f'build/{mult_type}.log')
        self.log.addHandler(mult_filehandler)
        self.log.info("Got DUT: {}".format(dut))
        # generate a clock
        start_soon(Clock(self.dut.clk, 5, units="ns").start())

    async def reset_routine(self):
        self.dut.s_rst_n.value = 0
        await ClockCycles(self.dut.clk, 2) # wait for 2 rising edges
        self.dut.s_rst_n.value = 1
        await ClockCycles(self.dut.clk, 10) # wait for 10 rising edges

    async def send_data(self, seq_id: int):
        self.log.info("Sending msg frame ...\n")
        self.data_p = np.random.randint(0,2**8, size=(1,16), dtype='uint8')
        frame_p = AxiStreamFrame(b''.join(self.data_p), tx_complete=Event())
        self.data_u = np.random.randint(0,2, size=(1,16), dtype='uint8')
        frame_u = AxiStreamFrame(b''.join(self.data_u), tx_complete=Event())
        await start_soon(self.axis_p_src.send(frame_p))
        await start_soon(self.axis_u_src.send(frame_u))
        # wait for one of the two transactions to complete
        await First(frame_p.tx_complete.wait(),frame_u.tx_complete.wait())
        await ClockCycles(self.dut.clk, 1) # wait for 1 rising edges
        self.log.info("DONE: Sending msg frame ...\n")
        # start result capture
        await start_soon(self.collect_data(seq_id))

    async def collect_data(self, seq_id): 
        rx = await self.axis_z_sink.recv()
        self.dut_rslt.append(rx.tdata)
        self.log.info(f"{seq_id}: {[x for x in rx.tdata]}")
        self.log.info(f"Expected:{rlwe_updated.polymul(self.data_p[0], self.data_u[0], self.q,self.poly_mod)}")
        


@test()
async def basic_test(dut):
    tb = TB(dut)

    await tb.reset_routine()
    await tb.send_data(1)


