import random
import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys
import matplotlib.pyplot as plt

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


async def signed(val, bits):
    if val >= (2 ** (bits - 1)):
        return val - (2**bits)
    return val


@cocotb.test()
async def test_additive_synth(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # set all inputs to 0
    # use helper function to assert reset signal
    dut.base_freq_in.value = 2048
    dut.sample_cycle_count.value = 0
    await reset(dut.rst, dut.clk)

    output = []
    for _ in range(500000):
        await FallingEdge(dut.clk)
        sample_cycle = dut.sample_cycle_count.value + 1
        dut.sample_cycle_count.value = sample_cycle % 2272
        if dut.sample_valid.value == 1:
            output.append(await signed(int(dut.sample_out.value), 20) / 2**18)

    fig, ax = plt.subplots()
    # ax.plot(output)
    ax.magnitude_spectrum(output, scale="dB")
    plt.show()


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
