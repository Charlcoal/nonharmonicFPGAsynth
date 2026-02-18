from math import pi


def midi_frequency_table():
    output = []
    for note in range(128):
        freq_Hz = 440 * 2 ** ((note - 69) / 12)
        output.append(round(freq_Hz * 2**18 / 44100))
    return output


def square_wave(n, base_freq):
    """
    generates the first n sin waves in the harmonic series for a square wave of the given frequency
    output: tuple of lists; frequencies, intensities, and phases of sin waves
    """
    freqs = [base_freq * (2 * i + 1) for i in range(n)]
    freqs = [0 if freq >= 2**18 else freq for freq in freqs]
    intensities = [round((2**17) * 4 / (pi * (2 * i + 1))) for i in range(n)]
    phases = [0 for i in range(n)]
    return (freqs, intensities, phases)


def write_files(files, names):
    """
    writes .mem files for frequency, intensity, and phase
    """
    for file_name, vals in zip(names, files):
        file = open(file_name, "w")
        file.writelines([hex(val)[2:] + "\n" for val in vals])
        file.close()


if __name__ == "__main__":
    write_files(
        square_wave(1024, 256),
        [
            "../data/add_synth_frequencies.mem",
            "../data/add_synth_intensities.mem",
            "../data/add_synth_phases.mem",
        ],
    )

    write_files([midi_frequency_table()], ["../data/midi_frequencies.mem"])
