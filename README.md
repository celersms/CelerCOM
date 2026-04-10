[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14511390.svg)](https://doi.org/10.5281/zenodo.14511390) 
[![SWH](https://archive.softwareheritage.org/badge/swh:1:dir:9235e8de72f0b46248790dd935bd8bea7664d599/)](https://archive.softwareheritage.org/swh:1:dir:9235e8de72f0b46248790dd935bd8bea7664d599;origin=https://github.com/celersms/CelerCOM)

# CelerCOM

CelerCOM is a minimalistic Java library, which can be used to interact with external devices
over COM ports, for example: USB, virtual COM. It can be used to interact with TTY and FIFO files as well. The library has no external dependencies. Native
drivers are included for 32-bit and 64-bit Windows and Linux. A pure Java driver is available as
a fallback for other OS and architectures.  

## How to use

Just add `CelerCOM.jar` to you classpath. The API is described in the [javadoc documentation](https://www.celersms.com/doc/CelerCOM/com/celer/package-summary.html).  

## TTY Example

[The TTY example](src/com/celer/TTY.java) shows how to read and write text commands (i.e. AT commands)
through the console.
