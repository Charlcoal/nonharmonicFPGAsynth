import random
import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys

from cocotb.clock import Clock
from cocotb.triggers import (
    Timer,
    ClockCycles,
    RisingEdge,
    FallingEdge,
    ReadOnly,
    ReadWrite,
    with_timeout,
    First,
    Join,
)
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner

from random import getrandbits


async def reset(rst, clk):
    """Helper function to issue a reset signal to our module"""
    rst.value = 1
    await ClockCycles(clk, 3)
    rst.value = 0
    await ClockCycles(clk, 2)


@cocotb.test()
async def test_additive_synth(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # set all inputs to 0
    # use helper function to assert reset signal
    await reset(dut.rst, dut.clk)

    await ClockCycles(dut.clk, 40)


def test_additive_synth_runner():
    """Run the additive_synth runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [
        proj_path / "hdl" / "additive_synth.sv",
        proj_path / "hdl" / "cordic_sin_pipelined.sv",
        proj_path / "hdl" / "xilinx_single_port_ram_read_first.v",
        proj_path / "hdl" / "xilinx_true_dual_port_read_first_1_clock_ram.v",
    ]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="additive_synth",
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale=("1ns", "1ps"),
        waves=True,
    )
    run_test_args = []
    runner.test(
        hdl_toplevel="additive_synth",
        test_module="test_additive_synth",
        test_args=run_test_args,
        waves=True,
    )


if __name__ == "__main__":
    test_additive_synth_runner()
