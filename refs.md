https://iosonounrouter.wordpress.com/2020/05/20/alarms-with-contrail-analytics/

https://iosonounrouter.wordpress.com/2019/04/26/contrail-analytics-part-1-virtual-networks/

https://sureshkvl.gitbooks.io/opencontrail-beginners-tutorial/content/contrail-architecture/contrail-analytics.html

https://github.com/magnific0/wondershaper/tree/master

https://eldernode.com/tutorials/limit-bandwidth-on-ubuntu-and-debian/

http://172.16.0.19:8081/

sudo ip link set ens4 up

sudo ip addr add 10.0.0.10/24 dev ens4
sudo ip addr add 10.0.0.20/24 dev ens4

wondershaper/wondershaper -a tap66d9c3a0-52 -c
wondershaper/wondershaper -a tap66d9c3a0-52 -u 320 -d 320

sudo dd if=/dev/zero bs=1M count=10000 | nc 10.0.0.20 5000
nc -4l -s 10.0.0.20 -p 5000 > /dev/null

sudo tc qdisc del dev tap66d9c3a0-52 root
sudo tc qdisc add dev tap66d9c3a0-52 root handle 1: htb default 10
sudo tc class add dev tap66d9c3a0-52 parent 1: classid 1:10 htb rate 8kbit ceil 8kbit
sudo tc qdisc add dev tap66d9c3a0-52 parent 1:10 sfq perturb 10

sudo tc class change dev tap66d9c3a0-52 parent 1: classid 1:10 htb rate 4kbit ceil 4kbit

default_interval()
incremental_interval()

Check a VR's configuration
curl "http://172.16.0.19:8082/virtual-router/2245f56f-424e-4f3e-960f-75122ea75e4b" | python3 -m json.tool

Set the incremental interval:
curl -X PUT -H "X-Auth-Token: $OS_TOKEN" -H "Content-Type: application/json; charset=UTF-8" -d '{"virtual-router": {"agent_uve_incremental_interval": 1000}}' http://172.16.0.19:8082/virtual-router/2245f56f-424e-4f3e-960f-75122ea75e4b

Set the dispatch interval:
curl -X PUT -H "X-Auth-Token: $OS_TOKEN" -H "Content-Type: application/json; charset=UTF-8" -d '{"virtual-router": {"agent_uve_default_interval": 2000}}' http://172.16.0.19:8082/virtual-router/2245f56f-424e-4f3e-960f-75122ea75e4b
