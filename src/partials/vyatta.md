# Simulating TKO on vSphere with Tanzu networking utilizing Vyatta

> **Note**: this alternative networking implementation is intended for **testing purposes only**.

vSphere distributed switches operate at Layer 2. Therefore, you might need to provision a router that can create the network above.

[Vyatta VyOS](https://vyos.io) is a lightweight network OS that provides packet forwarding and DHCP services. This section will guide you through setting up a simple Vyatta router in your lab that can simulate the reference architecture network diagram.

Out-of-scope alternatives:

* VMware NSX-T
* [Enable IP packet forwarding](https://linuxhint.com/enable_ip_forwarding_ipv4_debian_linux/)

[Download](https://vyos.net/get/nightly-builds/) the ISO for the latest rolling release and [follow the instructions](https://docs.vyos.io/en/latest/installation/install.html#live-installation) to install it onto an ESXi VM.

Ensure that this VM:

* Has at least two vCPUs,
* Has one NIC per port group created above (there should be six total), and
* That all NICs are para-virtual VMXNET NICs

Next, go into the vCenter portal and connect to the VM's console. Log in with the username `vyos` and the password `vyos`.

Next, install VyOS onto the machine's disk. Type `install image`, follow the instructions, then shut the machine down, disconnect its CD-ROM drive, then power it on and log in again.

Next, configure your WAN interface. We'll assume that the externally-accessible network is on subnet `10.213.234.0/24`

Next, run `ifconfig eth0`. Take note of the MAC address for this interface. In vCenter, ensure that the NIC created for this VM with this MAC address is connected to your external network.

We'll assume that your externally-accessible NIC is `eth0`.

Once confirmed, assign this interface with a static IP address in its subnet:

```text
configure
set interface loopback lo # Might already exist
set interface ethernet eth0 address 10.213.234.4/24
set interfaces ethernet eth0 description WAN
set protocols static route 0.0.0.0/0 next-hop 10.213.234.1
```

Next, turn on SSH:

```text
set service ssh
```

Finally, commit and save your changes:

```text
commit
save
```

Run `ifconfig eth0` again. Verify that its `inet` address matches the IP address
you provided earlier (`10.213.234.4` in this case).

Next, verify that your router can communicate with the Internet by using
`traceroute` to a known IP address, like 1.1.1.1:

```text
traceroute to 1.1.1.1 (1.1.1.1), 30 hops max, 60 byte packets
 1  10.213.234.1 (10.213.234.1)  0.257 ms  0.248 ms  0.224 ms
...more hops
15  1.1.1.1 (1.1.1.1)  5.170 ms 172.68.188.20 (172.68.188.20)  5.717 ms 1.1.1.1 (1.1.1.1)  5.179 ms
```

Next, SSH into the router from your machine:

```sh
# password is vyos
ssh vyos@10.213.234.4
```

Once connected, configure the rest of the interfaces. First, run `ifconfig` to
see which device corresponds to each MAC address. Take note of this.

Next, enter configuration mode:

```text
configure
```

then repeat the block below for each interface.

```text
set interface eth1 address 172.16.10.1/24
# Name this after the port group for each subnet
set interface eth1 description "nsx_alb_management_pg"
```

Run `show interface ethernet` once done. Confirm that your result looks something like
the below:

```text
 ethernet eth0 {
     address 10.213.234.4/24
     description WAN
     hw-id 00:50:56:be:3c:b9
 }
 ethernet eth1 {
+    address 172.16.80.1/27
+    description "NSX ALB Management Network"
     hw-id 00:50:56:be:9a:f9
 }
 ethernet eth2 {
+    address 172.16.81.1/27
+    description "TKG Management Network"
     hw-id 00:50:56:be:85:fc
 }
 ethernet eth3 {
+    address 172.16.82.1/27
+    description "TKG VIP Network"
     hw-id 00:50:56:be:b5:fc
 }
 ethernet eth4 {
+    address 172.16.83.1/27
     hw-id 00:50:56:be:6b:c9
 }
[edit]
```

Next, enable the DHCP service and create two DHCP pools:

<!-- markdownlint-disable-->
```text
set service dhcp-server dynamic-dns-update
set service dhcp-server shared-network-name nsx-alb-mgmt-network subnet 172.16.80.0/24
set service dhcp-server shared-network-name nsx-alb-mgmt-network subnet 172.16.80.0/24 default-router 172.16.80.1
set service dhcp-server shared-network-name nsx-alb-mgmt-network subnet 172.16.80.0/24 range 0 start 172.16.80.200
set service dhcp-server shared-network-name nsx-alb-mgmt-network subnet 172.16.80.0/24 range 0 stop 172.16.80.252
set service dhcp-server shared-network-name nsx-alb-mgmt-network name-server 8.8.8.8
set service dhcp-server shared-network-name nsx-alb-mgmt-network name-server 4.4.4.4

set service dhcp-server shared-network-name tkg-mgmt-network subnet 172.16.81.0/24
set service dhcp-server shared-network-name tkg-mgmt-network subnet 172.16.81.0/24 default-router 172.16.81.1
set service dhcp-server shared-network-name tkg-mgmt-network subnet 172.16.81.0/24 range 0 start 172.16.81.200
set service dhcp-server shared-network-name tkg-mgmt-network subnet 172.16.81.0/24 range 0 stop 172.16.81.252
set service dhcp-server shared-network-name tkg-mgmt-network name-server 8.8.8.8
set service dhcp-server shared-network-name tkg-mgmt-network name-server 4.4.4.4

set service dhcp-server shared-network-name tkg-workload-network subnet 172.16.82.0/24
set service dhcp-server shared-network-name tkg-workload-network subnet 172.16.82.0/24 default-router 172.16.82.1
set service dhcp-server shared-network-name tkg-workload-network subnet 172.16.82.0/24 range 0 start 172.16.82.200
set service dhcp-server shared-network-name tkg-workload-network subnet 172.16.82.0/24 range 0 stop 172.16.82.252
set service dhcp-server shared-network-name tkg-workload-network name-server 8.8.8.8
set service dhcp-server shared-network-name tkg-workload-network name-server 4.4.4.4
```
<!-- markdownlint-enable-->

Confirm that this is correct with `show service dhcp-server`. Your output should
look like the below:

```
 shared-network-name nsx-alb-mgmt-network {
     authoritative
     name-server 10.213.234.252
     subnet 172.16.80.0/24 {
         default-router 172.16.80.1
         domain-name tkg.local
         domain-search tkg.local,pez.vmware.com
         name-server 10.213.234.252
         range 0 {
             start 172.16.80.200
             stop 172.16.80.252
         }
     }
 }
 shared-network-name tkg-mgmt-network {
     authoritative
     domain-name tkg.local
     domain-search tkg.local,pez.vmware.com
     name-server 10.213.234.252
     name-server 10.192.2.10
     name-server 10.192.2.11
     subnet 172.16.81.0/24 {
         default-router 172.16.81.1
         range 0 {
             start 172.16.81.200
             stop 172.16.81.252
         }
     }
 }
 shared-network-name tkg-workload-network {
     authoritative
     subnet 172.16.82.0/24 {
         default-router 172.16.82.1
         domain-name tkg.local
         domain-search tkg.local,pez.vmware.com
         name-server 10.213.234.252
         name-server 10.192.2.10
         name-server 10.192.2.11
         range 0 {
             start 172.16.82.200
             stop 172.16.82.252
         }
     }
 }
```

Next, enable NAT so that machines connected to these networks can access the
Internet through the externally-accessible interface:

```text
set nat source rule 1 description "allow nat outbound"
set nat source rule 1 outbound-interface eth0
set nat source rule 1 translation address masquerade
```

Confirm that this is correct with `show nat`. Your output should look like the
below:

```text
+source {
+    rule 1 {
+        description "allow nat outbound"
+        outbound-interface eth0
+        translation {
+            address masquerade
+        }
+    }
+}
[edit]
```

Finally, commit and save your changes.

```sh
commit
save
```

You can terminate your SSH session once finished.
