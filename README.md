# IPOP Scale Test
Note: Current version only tested on Ubuntu 16.04 VM

#### Initial Setup
1. Clone repo to machine that you want to run the test on
2. Run lxcscript.sh
3. First pick `install` (Install dependencies needed on host machine and for default container)
4. Next `create` (Create and start specified number of containers, download ipop src to them)
5. If visualizer option was selected run `start-visualizer` (Net Visualizer: http://localhost:8888/IPOP)
6. Run `run`(Start up ipop processes on lxc nodes)
#### Testing Environment
*  `log` aggregates controller and tincan logs on host machine under logs directory along with a file with information on the status of each lxc container
* `test` begins a ipop scale testing shell to carry out connectivity and performance testing built on tools such as iperf and ping
#### Tear Down
* Run `del` (Remove lxc containers running IPOP)
* Run `stop-visualizer` (Stop visualizer processes as well as mongodb server)

