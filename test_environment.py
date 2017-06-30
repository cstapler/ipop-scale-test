#!/usr/bin/env python

import sys
import tempfile
import lxc

def run(node, command):
    with tempfile.NamedTemporaryFile() as out_file:
        node.attach_wait(lxc.attach_run_command, command, stdout=out_file.file)
        out_file.seek(0)
        output = out_file.readlines()
        print(output)
        return output

def ping_test(sender, receiver, packet_count):
    r_ips = receiver.get_ips()
    if len(r_ips) != 2:
        raise ValueError("IPOP Virtual Network Interface is not running on ping receiver {0}" \
                          .format(receiver.name))
    r_ipop_ip = r_ips[1]

    ping_command = ["ping", "-c", str(packet_count), r_ipop_ip]
    print("{0} pinging {1}".format(sender.name, receiver.name).center(30, "-"))
    ping_output = run(sender, ping_command)
    return ping_output

def main():
    """Peform an enviornment status check
    """
    node1 = lxc.Container(name="node1")

    print("Node 1 status:".center(30, "-"))
    print("Is running: {0}".format(node1.running).center(30))
    print("Is defined: {0}".format(node1.defined).center(30))
    print("node name: {0}".format(node1.name).center(30))
    print("".center(30, "-"))

    containers = lxc.list_containers(as_object=True)

    for container in containers:
        name = container.name
        if name not in ["default", "node1"]:
            print("ping test from node 1 to {0}: {1}" \
                .format(container.name, ping_test(node1, container, 5)))
            print("".center(30, "-"))


if __name__ == "__main__":
    main()
