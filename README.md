# Cyrix 486 processor write-back experiment

## intent
It is notoriously difficult to see any effect of the internal write-back cache of the Cx486 processor
if fast L2 cache is available. This repository includes a simple tool that exercises a code pattern
that causes enough write pressure on the Cx486 processor to make a performance difference visible
between write-back being enabled and disabled.

This tool is mostly meant to check whether a "L1 writeback enable/disable" switch in the BIOS setup
does what it claims to do.

## how it works
A write-through cycle on a Cx486 takes at least 2 clocks. If the mainboard operates a write-back L2
cache at zero write wait-states, that exactly how long a write-through cycle takes on the Cx486.
To see a performance improvement, we need to cause more than one write cycle per two clocks. This is
non-trivial, as even `MOV [BX], DX` takes 2 clocks, so the write-back L2 cache can keep up with it.
To put even more write-pressure onto the front-side bus, this program misaligns `BX` in a way that
it spans two 32-bit words, so two external cycles are needed to satifsy the `MOV` instruction.
This actually does have the intended effect of proving that the L1 cache is operating in write-back
mode.

WBTEST reports how many nanoseconds an unaligned write is slower or faster than an unaligned read.

## extra utilities
WBON and WBOFF are included and contain code to enable or disable L1 write-back according to the
algorithm proposed by Cyrix in their BIOS writers guide. This is mostly meant to be able to test
the test program to quickly switch between a write-through and a write-back scenario. You *can* use
it on your own board to enable L1WB even if the BIOS does not do - put at your own risk. If the
BIOS does not enable L1WB, the chipset is most likely not set up to deal with dirty lines in the
L1 cache. This tool is *not* meant to properly configure a Cx486 processor to deal with this
situation, there are already some cache enablers around for this problem.

## results
On an Opti 82c895 board with a Cx486DX at 40MHz and L2 at 0WS for writes, I observe the
following results (this is the worst case for L1 WB test measurements, to my knowledge):

```
C:\WBTEST>wbtest
013.7 ns faster unaligned stores than unaligned loads

C:\WBTEST>wboff

C:\WBTEST>wbtest
002.8 ns faster unaligned stores than unaligned loads
```

It seems the Cyrix processor is better in dealing with unaligned stores than with unaligned loads,
which is likely due to decoupling of stores from the execution unit via the store buffer. But
obviously it is faster (by just "half" a clock cycle of 25ns) at 40MHz if L1WB is enabled.

Obviously, you get much more pronounced differences if you turn of L2 cache and set DRAM waitstates
to maximum (the BIOS of that board calls it "1WS", but this does not mean the 486 cycle is performed
with just 1 wait-state):

```
C:\WBTEST>wbtest
013.7ns faster unaligned stores than unaligned loads

C:\WBTEST>wboff

C:\WBTEST>wbtest
098.6 ns slower unaligned stores than unaligned loads
```

This is a slowdown by around 100ns compared to the previous example, so 4 clocks per unaligned
store. As each unaligned store performs two write cycles, this means 2 wait-states per write
cycle. The identical performance results in the case of enabled write-back cache is a strong
indication that if L1WB is enabled, the code in fact runs completely inside the L1 cache.
