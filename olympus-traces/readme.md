# Olympus-trace

This docker images is prebuilt by myslef to contain both metricbeat & filebeat pre-configured.

It should allow you to simply send metrics & logs of what you need on Elasticsearch free stack (managed by myself).

## How build

I will not provide any acces to vault so you wll get null as placeholder into password field.

````shell
docker build --build-arg VAULT_TOKEN="" --build-arg VAULT_ADDR="" -t mowquito/olympus-traces:latest .

````

# How install

````shell
sudo docker run -it --rm --detach \
 --mount type=bind,source=/proc,target=/hostfs/proc,readonly \
 --mount type=bind,source=/sys/fs/cgroup,target=/hostfs/sys/fs/cgroup,readonly \
 --mount type=bind,source=/,target=/hostfs,readonly \
 --mount type=bind,source=/var/run/dbus/system_bus_socket,target=/hostfs/var/run/dbus/system_bus_socket,readonly \
 --env DBUS_SYSTEM_BUS_ADDRESS='unix:path=/hostfs/var/run/dbus/system_bus_socket' \
 --net=host --cgroupns=host \
 mowquito/olympus-traces:0.1.5

````
