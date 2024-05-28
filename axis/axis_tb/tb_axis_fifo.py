import cocotb
from cocotb.task import Task
from cocotb.utils import get_sim_time
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles,NextTimeStep, Event, First, Combine
from cocotbext.axi import (AxiStreamBus, AxiStreamSource, AxiStreamFrame,AxiStreamSink)
import logging
import numpy as np


class TB:
    
    def __init__(self, dut , logger: str):
       
        self.dut = dut
        self.set_logger(logger)
        self.print_dut_info()

        self.dut_rslt = []

        self.axis_src = AxiStreamSource(AxiStreamBus.from_prefix( dut, "s_axis"), dut.clk, dut.srst_n, reset_active_level=False)
        self.axis_sink = AxiStreamSink(AxiStreamBus.from_prefix( dut, "m_axis"), dut.clk, dut.srst_n, reset_active_level=False)
        # generate a clock
        cocotb.start_soon(Clock(self.dut.clk, 5, units="ns").start())



    # set logger
    def set_logger(self,logger):
        self.log = logging.getLogger(logger)
        self.log.setLevel(logging.INFO)
        logging.getLogger(f"cocotb.{logger}").setLevel(logging.ERROR) ## Disable cocotb's built in logging
        log_filehandler = logging.FileHandler(f'build/{logger}.log')
        self.log.addHandler(log_filehandler)

    def print_dut_info(self):
        self.log.info("Got DUT: {}".format(self.dut))
        # self.log.info("DATA_W {}".format(dir(self.dut))) # displays signals and instances in dut


    async def reset_routine(self):
        self.dut.srst_n.value = 0
        await ClockCycles(self.dut.clk, 2) # wait for 2 rising edges
        self.dut.srst_n.value = 1
        await ClockCycles(self.dut.clk, 10) # wait for 10 rising edges

    async def send_data(self, seq_id: int):
        self.data_in = np.random.randint(0,(2**8) -1, size=(1,10), dtype='uint8')
        self.log.info(f"{self.data_in[0] = }")
        # self.data_in = np.array([246, 10, 84, 13], dtype='uint8')
        frame_in = AxiStreamFrame(b''.join(self.data_in[0]), tx_complete=Event())
        await cocotb.start_soon(self.axis_src.send(frame_in))
        await cocotb.start_soon(self.collect_data(seq_id))
        await ClockCycles(self.dut.clk, 1) # wait for 1 rising edges
        self.log.info(f"@{get_sim_time(units='ns')} DONE: Sending msg frame ...")
        # start result capture
        

    async def collect_data(self, seq_id): 
        rx = await self.axis_sink.recv()
        self.log.info(f"@{get_sim_time(units='ns')} DONE: recving msg frame ...")
        self.dut_rslt.append(rx.tdata)
        self.log.info(f"Frame {seq_id = }:")
        self.log.info(f"{self.data_in.tolist() =  }")
        self.log.info(f"{[x for x in rx.tdata] = }")
        


@cocotb.test()
async def basic_test(dut):
    tb = TB(dut, logger=str(dut))

    await tb.reset_routine()
    await tb.send_data(1)
    await ClockCycles(tb.dut.clk, 100) # wait for 100 rising edges


