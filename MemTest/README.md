# Memtest

This is a reworking of the MEMTEST program publihed in the 4K Static Ram documentation.
It requires MINIMON.

It should be loaded into RAM at F000 and executed with the MINIMON cammand as follows.

    G F000
Thi will prompt for the start and end addresses in the normal MINIMON format.

    S <start addr> F <end addr +1>

E.g. the following parameters will test all memory from 0000 upto and including 1FFF

    S 0000 F 2000

