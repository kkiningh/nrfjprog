nrfprog
==========

This is a loose shell port of the nrfjprog.exe program distributed by Nordic.
It relies on [JLinkExe](https://www.segger.com/jlink-software.html) to
interface with the JLink hardware.

The generated scripts were basically lifted from the Makefiles distributed with
the [nrf51-pure-gcc-setup](https://github.com/hlnd/nrf51-pure-gcc-setup)
project.

usage:

```
nrfjprog <action> [hexfile]
```

where action is one of:
 * `--reset`
 * `--pin-reset`
 * `--erase-all`
 * `--program`
 * `--programs`

 Credits
 =======

 Thanks to @hlnd for the initial scripts.
 Thanks to @ssfrr for the repo this was forked from.
