#!/bin/bash

IPOP_HOME="/home/ubuntu/ipop"
IPOP_TINCAN="$IPOP_HOME/ipop-tincan"
IPOP_CONTROLLER="controller.Controller"
HELP_FILE="./CONFIG.txt"
TINCAN="./ipop-tincan"
CONTROLLER="./Controllers"
DEFAULT_LXC_PACKAGES='python psmisc iperf'
DEFAULT_LXC_CONFIG='/var/lib/lxc/default/config'
DEFAULT_TINCAN_REPO='https://github.com/ipop-project/Tincan'
DEFAULT_CONTROLLERS_REPO='https://github.com/ipop-project/Controllers'

if [ -e $HELP_FILE ]; then
    min=$(cat $HELP_FILE | grep MIN | awk '{print $2}')
    max=$(cat $HELP_FILE | grep MAX | awk '{print $2}')
    nr_vnodes=$(cat $HELP_FILE | grep NR_VNODES | awk '{print $2}')
else
    echo -e "No of containers to be created::" 
    read max
    echo -e "MIN 1\nMAX $max\nNR_VNODES $max" > $HELP_FILE
fi

function options()
{
    read -p 'Enter from the following options:    
   install                        : install/prepare containers
   create                         : create and start containers
   start                          : restart containers
   stop                           : stop containers
   del                            : delete containers
   run                            : To run IPOP node
   kill                           : To kill IPOP node
> ' user_input
    echo $user_input
}

while true; do
    line=($(options))
    cmd=${line[0]}
    case $cmd in

        ("install")
            ### obtain network device and ip4 address
            NET_TEST=$(ip route get 8.8.8.8)
            NET_DEV=$(echo $NET_TEST | awk '{print $5}')
            NET_IP4=$(echo $NET_TEST | awk '{print $7}')
            
            sudo apt-get update
            sudo apt-get -y install lxc
            # Install ubuntu OS in the lxc-container
            sudo lxc-create -n default -t ubuntu
            sudo chroot /var/lib/lxc/default/rootfs apt-get -y update
            sudo chroot /var/lib/lxc/default/rootfs apt-get -y install $DEFAULT_LXC_PACKAGES
            sudo chroot /var/lib/lxc/default/rootfs apt-get -y install software-properties-common python-software-properties
	    
	    #Prepare Tincan for compilation
            sudo chroot /var/lib/lxc/default/rootfs add-apt-repository -y ppa:ubuntu-toolchain-r/test
            sudo chroot /var/lib/lxc/default/rootfs apt-get -y update
            sudo chroot /var/lib/lxc/default/rootfs apt-get -y install g++-4.9 git
	    sudo chroot /var/lib/lxc/default/rootfs rm /usr/bin/gcc
	    sudo chroot /var/lib/lxc/default/rootfs rm /usr/bin/g++
	    sudo chroot /var/lib/lxc/default/rootfs ln -s /usr/bin/gcc-4.9 /usr/bin/gcc
	    sudo chroot /var/lib/lxc/default/rootfs ln -s /usr/bin/g++-4.9 /usr/bin/g++

            # install python-pip and sleekXMPP
            sudo chroot /var/lib/lxc/default/rootfs apt-get -y install 'python-pip'
            sudo chroot /var/lib/lxc/default/rootfs pip install 'sleekxmpp' pystun psutil
            echo 'lxc.cgroup.devices.allow = c 10:200 rwm' | sudo tee --append $DEFAULT_LXC_CONFIG
            # use IP aliasing to bind turnserver to this ipv4 address
            sudo ifconfig $NET_DEV:0 $NET_IP4 up
            # prepare turnserver config file
            sudo sed -i "s/listen_address = .*/listen_address = { \"$NET_IP4\" }/g" $NODE_TURNSERVER_CONFIG
            sudo cp $NODE_TURNSERVER_CONFIG $TURNSERVER_CONFIG
            ### configure network
            # replace symmetric NATs (MASQUERAGE) with full-cone NATs (SNAT)
            for i in $(sudo iptables -L POSTROUTING -t nat --line-numbers | awk '$2=="MASQUERADE" {print $1}'); do
                sudo iptables -t nat -D POSTROUTING $i
            done
            sudo iptables -t nat -A POSTROUTING -o $NET_DEV -j SNAT --to-source $NET_IP4
            # open TCP ports (for ejabberd)
            for i in 5222 5269 5280; do
                sudo iptables -A INPUT -p tcp --dport $i -j ACCEPT
                sudo iptables -A OUTPUT -p tcp --dport $i -j ACCEPT
            done
            # open UDP ports (for STUN and TURN)
            for i in 3478 19302; do
                sudo iptables -A INPUT -p udp --sport $i -j ACCEPT
                sudo iptables -A OUTPUT -p udp --sport $i -j ACCEPT
            done
            # Install local ejabberd server
            sudo apt-get -y install ejabberd
            # prepare ejabberd server config file
            os_version=$(lsb_release -r -s)
            # restart ejabberd service
            if [ $os_version = '14.04' ]; then
                sudo cp ./config/ejabberd.cfg /etc/ejabberd/ejabberd.cfg
                sudo ejabberdctl restart
            else
		sudo apt-get -y install erlang-p1-stun
                sudo cp ./config/ejabberd.yml /etc/ejabberd/ejabberd.yml
                sudo systemctl restart ejabberd.service
            fi
            # wait for ejabberd service to start
            sleep 15
            # create admin user
            sudo ejabberdctl register admin ejabberd password
        ;;
        ("create")
            NET_TEST=$(ip route get 8.8.8.8)
            NET_DEV=$(echo $NET_TEST | awk '{print $5}')
            NET_IP4=$(echo $NET_TEST | awk '{print $7}')
            echo "Creating containers..."
            echo "Downloading executable and code"
            # Check if IPOP controller executables already exists
            if [ -e $CONTROLLER ]; then
                echo "Controller modules already present in the current path.Do you want to continue with container creation (T/F).."
                read user_input
                if [ $user_input = 'F' ]; then
                    echo -e "\e[1;31mEnter IPOP Controller github URL(default: $DEFAULT_CONTROLLERS_REPO \e[0m"
                    read githuburl_ctrl
		    if [ -z "$githuburl_ctrl"]; then
			    githuburl_ctr=$DEFAULT_CONTROLLERS_REPO
		    fi
                    git clone $githuburl_ctrl
                    echo -e "Do you want to continue using master branch(Y/N):"
                    read user_input
                    if [ $user_input = 'N' ]; then
                        echo -e "Enter git repo branch name:"
                        read github_branch
                        cd Controllers
                        git checkout $github_branch
                        cd ..
                    fi
                fi
            else
                echo -e "\e[1;31mEnter IPOP Controller github URL(default: $DEFAULT_CONTROLLERS_REPO \e[0m"
	        read githuburl_ctrl
		if [ -z "$githuburl_ctrl"]; then
		    githuburl_ctr=$DEFAULT_CONTROLLERS_REPO
		fi 
		git clone $githuburl_ctr
		echo -e "Do you want to continue using master branch(Y/N):"
                read user_input
                if [ $user_input = 'N' ]; then
                    echo -e "Enter git repo branch name:"
                    read github_branch
                    cd Controllers
                    git checkout $github_branch
                    cd ..
                fi
            fi
            # Check whether Tincan executables exists in the current path
            if [ -e $TINCAN ]; then
                echo "Tincan binary present, aborting build script execution!!!"
            else
                echo "***************Building Tincan binary***************"
		echo -e "\e[1;31mEnter github URL for Tincan (default: $DEFAULT_TINCAN_REPO) \e[0m"
		read github_tincan
		if [ -z "$github_tincan" ] ; then
		    github_tincan=$DEFAULT_TINCAN_REPO
		fi

                git clone $github_tincan
                echo -e "Do you want to continue using master branch(Y/N):"
                read user_input
                if [ $user_input = 'N' ]; then
                    echo -e "Enter git repo branch name:"
                    read github_branch
                    cd Tincan
                    git checkout $github_branch
                    cd ..
                fi
                cd ./Tincan/trunk/build/
		make
                cd ../../..
                cp ./Tincan/trunk/out/release/x64/ipop-tincan .
            fi
            echo -e "\e[1;31Do you want to set default IPOP network configuration(Y/N): \e[0m"
            read user_input
            echo -e "\e[1;31mEnable Visulaization (T/F): \e[0m"
            read visualizer
            if [ $visualizer = 'T' ]; then
                isvisual=true
            else
                isvisual=false
            fi
            if [ $user_input = 'Y' ]; then 
                topology_param="1 0 0 3"
            else
                topology_param=""
                echo -e "\e[1;31m Enter No of Successor Links: \e[0m"
                read user_input
                topology_param="$topology_param $user_input"
                echo -e "\e[1;31m Enter Max No of Chords Links: \e[0m"
                read user_input
                topology_param="$topology_param $user_input"
                echo -e "\e[1;31m Enter Max No of Ondemand Links: \e[0m"
                read user_input
                topology_param="$topology_param $user_input"
                echo -e "\e[1;31m Enter Max No of Inbound Links: \e[0m"
                read user_input
                topology_param="$topology_param $user_input"
            fi
            for i in $(seq $min $max); do
                sudo bash -c "
                lxc-clone default node$i;
                sudo lxc-start -n node$i --daemon;
                sudo lxc-attach -n node$i -- bash -c 'sudo mkdir -p $IPOP_HOME; sudo mkdir /dev/net; sudo mknod /dev/net/tun c 10 200; sudo chmod 0666 /dev/net/tun';
                "
                sudo cp -r ./Controllers/controller/ "/var/lib/lxc/node$i/rootfs$IPOP_HOME"
                sudo cp ./ipop-tincan "/var/lib/lxc/node$i/rootfs$IPOP_HOME"
                sudo cp './ipop.bash' "/var/lib/lxc/node$i/rootfs$IPOP_HOME"
                sudo lxc-attach -n node$i -- bash -c "sudo chmod +x $IPOP_TINCAN; sudo chmod +x $IPOP_HOME/ipop.bash;"
                sudo lxc-attach -n node$i -- bash -c "sudo $IPOP_HOME/ipop.bash config $i GroupVPN $NET_IP4 $isvisual $topology_param"
                echo "Container node$i started"
                for j in $(seq $min $max); do
                    if [ "$i" != "$j" ]; then
                        sudo ejabberdctl add_rosteritem "node$i" ejabberd "node$j" ejabberd "node$j" ipop both
                    fi
                done
            done
            sudo rm -r Controllers
            sudo rm -r Tincan
        ;;
        ("start")
            echo -e "\e[1;31mStarting containers.... \e[0m"
            for i in $(seq $min $max); do
                sudo bash -c "sudo lxc-start -n node$i --daemon;"
                echo "Container node$i started!!"
            done
        ;;
        ("del")
            echo -e "\e[1;31mContainer deletion inprogress .... \e[0m"
            for i in $(seq $min $max); do
                for j in $(seq $min $max); do
                    if [ "$i" != "$j" ]; then
                        sudo ejabberdctl delete_rosteritem "node$i" ejabberd "node$j" ejabberd
                    fi
                done
                sudo lxc-stop -n "node$i"
                sudo lxc-destroy -n "node$i"
                echo "Container node$i deleted !!"
            done
        ;;
        ("stop")
            echo -e "\e[1;31mStopping container... \e[0m"
            for i in $(seq $min $max); do
                sudo lxc-stop -n "node$i"
            done
            wait
        ;;
        ("run")
            echo -e "\e[1;31mEnter # To RUN all containers or Enter the container number.  (e.g. Enter 1 to start node1)\e[0m"
            read user_input
            if [ $user_input = '#' ]; then 
                for i in $(seq $min $max); do
                    sudo lxc-attach -n node$i -- bash -c "cd /home/ubuntu/ipop/; sudo /home/ubuntu/ipop/ipop-tincan &> ./tin.log &"
                    sudo lxc-attach -n node$i -- bash -c "cd /home/ubuntu/ipop/; sudo python -m controller.Controller -c ./ipop-config.json &> ./ctr.log &"
                done
            else
                sudo lxc-attach -n node$user_input -- bash -c "cd /home/ubuntu/ipop/; sudo /home/ubuntu/ipop/ipop-tincan &> ./tin.log &"
                sudo lxc-attach -n node$user_input -- bash -c "cd /home/ubuntu/ipop/; sudo python -m controller.Controller -c ./ipop-config.json &> ./ctr.log &"
            fi
            wait
        ;;
        ("kill")
            # kill IPOP tincan and controller
            echo -e "\e[1;31mEnter # To KILL all containers or Enter the container number.  (e.g. Enter 1 to stop node1)\e[0m"
            read user_input
            if [ $user_input = '#' ]; then 
                for i in $(seq $min $max); do
                    sudo lxc-attach -n node$i -- bash -c "sudo $IPOP_HOME/ipop.bash kill"   
                done
            else
                sudo lxc-attach -n node$i -- bash -c "ps aux | grep $IPOP_TINCAN | awk '{print $2}' | xargs sudo kill -9"
                sudo lxc-attach -n node$i -- bash -c "ps aux | grep $IPOP_CONTROLLER | awk '{print $2}' | xargs sudo kill -9"    
            fi    
        ;;
        ("quit")
            exit 0
        ;;
    esac
done
