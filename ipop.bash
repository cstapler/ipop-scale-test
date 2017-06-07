#!/bin/bash

cd $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
IPOP_CONFIG="./ipop-config.json"
case $1 in
    ("config")
        # create config file
        ipop_id=$2
        vpn_type=$3
        serv_addr=$4
        # options reserved by scale-test
        CFx_xmpp_username="node${ipop_id}@ejabberd"
        CFx_xmpp_password="password"
        CFx_xmpp_host=$serv_addr
        CFx_xmpp_port='5222'
        BaseTopologyManager_ip4='172.31.'$(($ipop_id / 256))'.'$(($ipop_id % 256))
        CFx_ip4_mask='16'
        CentralVisualizer_name=$ipop_id
        CentralVisualizer_central_visualizer_addr=$serv_addr":8080/insertdata"
        isVisulizerEnabled=$5
        # available options
        BaseTopologyManager_num_successors=$6
        BaseTopologyManager_num_chords=$7
        BaseTopologyManager_num_on_demand=$8
        BaseTopologyManager_num_inbound=$9
        echo -e \
            "{"\
                "\n  \"CFx\": {"\
                "\n    \"Model\": \"$vpn_type\""\
                "\n  },"\
                "\n  \"Logger\": {"\
                "\n    \"LogLevel\": \"WARNING\","\
                "\n    \"LogOption\": \"File\","\
                "\n    \"BackupLogFileCount\": 5,"\
                "\n    \"LogFileName\": \"ctr.log\","\
                "\n    \"LogFileSize\": 10000"\
                "\n  },"\
		"\n  \"Tincan\": {"\
		"\n    \"Loglevel\": \"WARNING\","\
		"\n    \"Log\": {"\
	        "\n       \"Level\": \"ERROR\","\
		"\n       \"Device\": \"File\","\
		"\n       \"Directory\": \"./logs/\","\
		"\n       \"Filename\": \"tincan_log\","\
		"\n       \"MaxArchives\": 10, "\
		"\n       \"MaxFileSize\": 1048576,"\
		"\n       \"ConsoleLevel\": \"NONE\""\
		"\n     }, "\
		"\n    \"Vnets\": [{"\
                "\n       \"IP4\": \"$BaseTopologyManager_ip4\","\
                "\n       \"IP4Prefix\": $CFx_ip4_mask, "\
                "\n       \"XMPPModuleName\": \"XmppClient\", "\
                "\n       \"TapName\": \"ipop_tap0\","\
                "\n       \"Description\": \"Ethernet Device\","\
                "\n       \"IgnoredNetInterfaces\": [\"ipop_tap0\", \"ipop_tap1\", \"Bluetooth Network Connection\", \"VMware Network Adapter VMnet1\", \"VMware Network Adapter VMnet2\"],"\
                "\n       \"L2TunnellingEnabled\": 1"\
                "\n     }],"\
		"\n     \"Stun\": [\"stun.l.google.com:19302\"],"\
                "\n     \"Turn\": [{"\
                "\n        \"Address\": \"***REMOVED***:19302\","\
                "\n        \"User\": \"***REMOVED***\","\
                "\n        \"Password\": \"***REMOVED***\""\
                "\n     }]"\
                "\n  },"\
                "\n  \"XmppClient\": {"\
                "\n    \"Enabled\": true,"\
                "\n    \"Username\": \"$CFx_xmpp_username\","\
                "\n    \"Password\": \"$CFx_xmpp_password\","\
                "\n    \"AddressHost\": \"$CFx_xmpp_host\","\
                "\n    \"Port\": \"$CFx_xmpp_port\","\
                "\n    \"TapName\": \"ipop_tap0\","\
                "\n    \"AuthenticationMethod\": \"password\","\
                "\n    \"AcceptUntrustedServer\": true,"\
                "\n    \"TimerInterval\": 15,"\
		"\n    \"dependencies\": [ \"Logger\" ] "\
                "\n  },"\
                "\n  \"BaseTopologyManager\": {"\
                "\n    \"NumberOfSuccessors\": $BaseTopologyManager_num_successors,"\
                "\n    \"NumberOfChords\": $BaseTopologyManager_num_chords,"\
                "\n    \"NumberOfOnDemand\": $BaseTopologyManager_num_on_demand,"\
                "\n    \"NumberOfInbound\": $BaseTopologyManager_num_inbound,"\
		"\n    \"InitialLinkTTL\": 120,"\
	        "\n    \"LinkPulse\": 180,"\
		"\n    \"OnDemandLinkTTL\": 60,"\
		"\n    \"TimerInterval\": 1,"\
		"\n    \"TopologyRefreshInterval\": 15,"\
		"\n    \"NumberOfPingsToPeer\": 5,"\
		"\n    \"PeerPingInterval\": 300,"\
		"\n    \"MaxConnRetry\": 5,"\
		"\n    \"dependencies\": [ \"Logger\" ]"\
                "\n  },"\
		"\n  \"TincanDispatcher\": {"\
		"\n    \"dependenices\": [ \"Logger\" ]"\
		"\n  },"\
		"\n  \"TincanListener\": {"\
		"\n    \"SocketReadWaitTime\": 15,"\
		"\n    \"dependencies\": [ \"Logger\", \"TincanDispatcher\" ]"\
		"\n  },"\
		"\n  \"TincanSender\": {"\
		"\n    \"dependencies\": [ \"Logger\" ] "\
		"\n  },"\
                "\n  \"OverlayVisualizer\": {"\
                "\n    \"Enabled\": $isVisulizerEnabled,"\
                "\n    \"WebServiceAddress\": \"$CentralVisualizer_central_visualizer_addr\","\
		"\n    \"TopologyDataQueryInterval\": 2,"\
		"\n    \"WebServiceDataPostInterval\": 2,"\
		"\n    \"TimerInterval\": 5,"\
		"\n    \"NodeName\": \"visualizer\","\
		"\n    \"dependencies\": [ \"Logger\" ]"\
                "\n  },"\
		"\n  \"BroadCastController\": { "\
		"\n    \"Enabled\": true,"\
		"\n    \"dependencies\": [ \"Logger\" ]"\
		"\n  },"\
		"\n  \"BroadCastForwarder\": { "\
		"\n    \"Enabled\": true,"\
		"\n    \"dependencies\": [ \"Logger\" ]"\
		"\n  },"\
	        "\n  \"Multicast\": { "\
		"\n    \"Enabled\": true,"\
		"\n    \"OnDemandThreshold\": 15,"\
		"\n    \"dependencies\": [ \"Logger\" ]"\
		"\n  },"\
	        "\n  \"ConnectionManager\": { "\
                "\n    \"InitialLinkTTL\": 120,"\
		"\n    \"ChordLinkTTL\": 180,"\
		"\n    \"OndemandLinkRateThreshold\": 128,"\
		"\n    \"dependencies\": [ \"Logger\" ] "\
		"\n  }"\
                "\n}"\
        > $IPOP_CONFIG
        ;;
    ("kill")
            ps aux | grep "ipop-tincan" | awk '{print $2}' | xargs sudo kill -9
            ps aux | grep "controller.Controller" | awk '{print $2}' | xargs sudo kill -9
        ;;
esac
