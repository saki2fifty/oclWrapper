# oclWrapper
Wrapper to introduce cpu/openCL delay for nVidia multi-gpu PoST file creation (Spacemesh Blockchain).

Dependencies: gcc, Powershell

Install dependencies:
- sudo apt install build-essential (gcc)
- https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu?view=powershell-7.4 (Powershell install)

To run:
- pwsh ./oclWrapper.ps1 (To compile)
- LD_PRELOAD=./liboclwrapper.so SLEEP_DELAY=35 ./postcli [parameters]
- LD_PRELOAD=./liboclwrapper.so SLEEP_DELAY=35 ./h9-miner-spacemesh-linux-amd64 -gpuServer
- (Change the SLEEP_DELAY values > recompile > rerun)

Testing was only done on the h9 miner.

Results:
- cpu usage decrease
- greater MB/s during PoST file creation.

Notes:
- Mileage may vary; this may not work within your setup.  My setup:
  - OpenCL: v.1.2
  - Nvidia driver version: 470.239.06 (on a test instance)
  - Number of multi-gpu's tested concurrently: 10
  - CUDA version: 11.4
  - OS: Ubuntu v.20.04
