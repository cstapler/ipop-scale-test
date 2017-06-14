# IPOP Scale Test

#### Initial Setup  
1. Clone repo to machine that you want to run the test on
2. Run lxcscript.sh
3. First pick `install` (Install dependencies needed on host machine and for default container)
4. Next `create` (Create and start specified number of containers, download ipop src to them)
5. If visualizer option was selected run `start-visualizer` (Net Visualizer: http://localhost:8888/IPOP)
6. Run `run`(Start up ipop processes on lxc nodes)

#### Tear Down
* Run `del` (Remove lxc containers running IPOP)
* Run `stop-visualizer` (Stop visualizer processes as well as mongodb server)

