#!/usr/bin/env python

import sys
import cmd
import tempfile
import lxc

class ScaleTestCL(cmd.Cmd):
    prompt = "(scale-test) "
    def do_ping(self, arg):
        """Ping test: e.g. ping node1 node2 5
           format: cmd (node to send ping) (node to receive ping) (ping count)
        """
        nodes = arg.split()
        ping_output = ping_test(nodes[0], nodes[1], int(nodes[2]))
        print("Output: {}".format(ping_output))

    def do_pingall(self, arg):
        """Test Ping between all active nodes
        """
        pingall_test()

    def do_status(self, arg):
        'List defined containers with associated ip addreses'
        container_status_check()

    def do_exit(self, arg):
        'Exit command-line scale testing interface'
        return True

def run(node, command):
    with tempfile.NamedTemporaryFile() as out_file:
        node.attach_wait(lxc.attach_run_command, command, stdout=out_file.file)
        out_file.seek(0)
        output = out_file.readlines()
        return output

def ping_test(sender_name, receiver_name, packet_count):
    sender = lxc.Container(sender_name)
    receiver = lxc.Container(receiver_name)

    r_ips = receiver.get_ips()
    if len(r_ips) != 2:
        raise ValueError("IPOP Virtual Network Interface is not running on " +\
                          "ping receiver {0}".format(receiver.name))
    r_ipop_ip = r_ips[1]

    ping_command = ["ping", "-c", str(packet_count), r_ipop_ip]
    ping_output = run(sender, ping_command)
    return ping_output

def pingall_test():
    containers = lxc.list_containers(as_object=True)
    for current_container in containers:
        name = current_container.name
        if name not in ["default"]:
            for other_container in containers:
                other_name = other_container.name
                if other_name not in ["default", name]:
                    ping_output = ping_test(name, other_name, 5)
                    parsed_ping = parse_ping(ping_output)
                    print("{0} pinging {1}: ".format(name.capitalize(), other_name.capitalize())),
                    if parsed_ping["packet_loss"] < 1:
                        print("ping successful, Stats: {}".format(parsed_ping))
                    else:
                        print("ping unsuccessful, Packet Loss: {}"\
                              .format(parsed_ping["packet_loss"]))
                    print("".center(30, "-"))

def parse_ping(ping_lines):
    stats = ping_lines[-2:]
    xmit_stats = stats[0].split(",")
    packet_loss = float(xmit_stats[2].split("%")[0])
    if packet_loss > 50:
        return {"packet_loss": packet_loss}
    timing_stats = stats[1].split("=")[1].split("/")
    ping_min = float(timing_stats[0])
    ping_avg = float(timing_stats[1])
    ping_max = float(timing_stats[2])
    return {"packet_loss": packet_loss,
            "ping_min": ping_min,
            "ping_avg": ping_avg,
            "ping_max": ping_max
           }

def container_status_check():
    containers = lxc.list_containers(as_object=True)
    for container in containers:
        status = "running" if container.running else "not running"
        print("Container: {0} is {1} | ip addresses: {2}" \
              .format(container.name, status, container.get_ips()))

def main():
    """Peform various testing operations on scale test environment
    """
    ScaleTestCL().cmdloop()


if __name__ == "__main__":
    main()
