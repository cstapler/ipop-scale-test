# IPOP Scale Test
Note: Current version only tested on Ubuntu 16.04 VM
#### Modes
* IPOP GroupVPN test
    * Create a separate instance of IPOP-VPN in GroupVPN Mode in each specified lxc container
* IPOP Switch-Mode test
   * Create instance of IPOP-VPN on host machine which is added to lxc-bridge to connect unmanaged containers to IPOP-VPN
#### Setup for IPOP GroupVPN test
1. Run lxcscript.sh, Enter `./scale_test.sh`
2. When prompted for mode selection, type `group-vpn`
3. Run `configure` (Install dependencies needed on host machine and for default container from which nodes are cloned from with the `containers-create` command)
4. Next `containers-create` (Create and start specified number of containers, build ipop src, and copy built ipop files to each container)
5. If visualizer option was enabled while running `containers-create` command run `visualizer-start` (Starts up two processes on host machine one running Net Visualizer found at http://localhost:8888/IPOP)
6. Run `ipop-run`(Start up ipop processes on lxc nodes)
#### Setup for IPOP Switch-Mode
* The steps for setting up IPOP-VPN in scale test environment are the same as setting up the scale test for GroupVPN Mode with exception to:
    * When prompted for mode selection, type `switch-mode`
#### Testing Environment
*  `logs` aggregates controller and tincan logs on host machine under logs directory along with a file with information on the status of each lxc container
* `ipop-test` begins a ipop scale testing shell to carry out connectivity and performance testing built on tools such as iperf and ping
#### Tear Down
* Run `containers-del` (Destroy all lxc node labeled containers)
* Run `visualizer-stop` (Stop visualizer processes)
######Note: ejabberd and mongodb will be installed on host machine as daemons which will start up automatically. Removal/Disabling of these services must be done manually.
