interfaces {
    ethernet eth0 {
        address 10.213.234.4/24
        address dhcp
        description WAN
        hw-id 00:50:56:be:00:50
    }
    ethernet eth1 {
        address 172.16.10.1/24
        description "NSX ALB Mgmt Network"
        hw-id 00:50:56:be:ab:b5
    }
    ethernet eth2 {
        address 172.16.40.1/24
        description "TKG Management Network"
        hw-id 00:50:56:be:1a:c0
    }
    ethernet eth3 {
        address 172.16.50.1/24
        description "TKG Mgmt VIP Network"
        hw-id 00:50:56:be:49:98
    }
    ethernet eth4 {
        address 172.16.80.1/24
        description "TKG Cluster VIP Network"
        hw-id 00:50:56:be:10:08
    }
    ethernet eth5 {
        address 172.16.70.1/24
        description "TKG Workload VIP Network"
        hw-id 00:50:56:be:38:77
    }
    ethernet eth6 {
        address 172.16.60.1/24
        description "TKG Workload Segment"
        hw-id 00:50:56:be:01:3b
    }
    loopback lo {
    }
}
service {
    dhcp-server {
        shared-network-name tkg-mgmt-network {
            subnet 172.16.40.0/24 {
                default-router 172.16.40.1
                name-server 10.92.2.10
                name-server 10.92.2.11
                range 0 {
                    start 172.16.40.200
                    stop 172.16.40.252
                }
            }
        }
        shared-network-name tkg-workload-network {
            subnet 172.16.60.0/24 {
                default-router 172.16.60.1
                name-server 10.92.2.10
                name-server 10.92.2.11
                range 0 {
                    start 172.16.60.200
                    stop 172.16.60.252
                }
            }
        }
    }
    ssh {
        port 22
    }
}
system {
    config-management {
        commit-revisions 100
    }
    conntrack {
        modules {
            ftp
            h323
            nfs
            pptp
            sip
            sqlnet
            tftp
        }
    }
    console {
        device ttyS0 {
            speed 115200
        }
    }
    host-name vyos
    login {
        user vyos {
            authentication {
                encrypted-password $6$MBzikxAbGIo/RM10$U9.9fcL0ry/brmlDPyQHVm/7xxIQERcr5/KBrAQN3iJijRXKsRtyPqpaB7j8cGH35T2kycWMxtGgPlcUHxqOZ.
                plaintext-password ""
            }
        }
    }
    name-server 10.192.2.10
    name-server 10.192.2.11
    ntp {
        server time1.vyos.net {
        }
        server time2.vyos.net {
        }
        server time3.vyos.net {
        }
    }
    syslog {
        global {
            facility all {
                level info
            }
            facility protocols {
                level debug
            }
        }
    }
}


// Warning: Do not remove the following line.
// vyos-config-version: "bgp@2:broadcast-relay@1:cluster@1:config-management@1:conntrack@3:conntrack-sync@2:dhcp-relay@2:dhcp-server@6:dhcpv6-server@1:dns-forwarding@3:firewall@7:flow-accounting@1:https@3:interfaces@25:ipoe-server@1:ipsec@8:isis@1:l2tp@4:lldp@1:mdns@1:nat@5:nat66@1:ntp@1:openconnect@1:ospf@1:policy@2:pppoe-server@5:pptp@2:qos@1:quagga@9:rpki@1:salt@1:snmp@2:ssh@2:sstp@4:system@22:vrf@3:vrrp@3:vyos-accel-ppp@2:wanloadbalance@3:webproxy@2"
// Release version: 1.4-rolling-202202010836
