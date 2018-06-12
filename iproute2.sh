#!/bin/bash
IF1=eth2
IF2=eth3
IP1=192.168.1.199
IP2=192.168.2.199
P1=192.168.1.128
P2=192.168.2.128
P1_NET=192.168.1.0/24
P2_NET=192.168.2.0/24

#额外创建两个路由表， T1 和 T2。 加入到/etc/iproute2/rt_tables
echo 200 T1 >> /etc/iproute2/rt_tables
echo 201 T2 >> /etc/iproute2/rt_tables
#设置两个路由表中的路由：
ip route add $P1_NET dev $IF1 src $IP1 table T1 
ip route add default via $P1 table T1 
ip route add $P2_NET dev $IF2 src $IP2 table T2 
ip route add default via $P2 table T2 
#下一步，我们设置“main”路由表。把包通过网卡直接路由到与网卡相连的局域
#网上不失为一个好办法。要注意“src” 参数，他们能够保证选择正确的出口IP
#地址。
ip route add $P1_NET dev $IF1 src $IP1 
ip route add $P2_NET dev $IF2 src $IP2
ip route add default via $P1
ip rule add from $IP1 table T1 
ip rule add from $IP2 table T2
#负载均衡
ip route add default scope global nexthop via $P1 dev $IF1 weight 1 nexthop via $P2 dev $IF2 weight 1 
