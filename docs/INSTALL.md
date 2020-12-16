# Crane Getting started to Use The

### Crane 概念

[Crane](https://github.com/slzcc/crane) 致力于敏捷部署 [Kubernetes](https://kubernetes.io/) Cluster 方案, 它的灵感在于 [Kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) 的部署, 但与 Kubeadm 不同的是 Crane 通过 [Ansible](https://www.ansible.com/) 方式进行部署, 并实现了 Ansible in Docker 化方案(可借助于任何一台服务器借助于 Docker 启动容器方式部署 Crane.)。

Crane 是由我个人独立创作并维护的, 在使用范围上可能得不到一定的实践支持, 但是它还是通过我不停地对业务以及 Kubernetes 日常使用上的灵感进行支撑, 还希望爱好者可以通过自己的实践以及理解的程度上对 Crane 进行改进.

目前支持的操作系统: (其他版本请自行测试, 这里支持版本目的只是安装 Docker, 其他不受影响)
* Ubuntu 16.04
* Ubuntu 18.04 (默认的 `Ubuntu 18.04` 没有 `python`, 只有 `python3` 可执行文件, 所以需要在 `nodes` 文件中定义 `ansible_python_interpreter` 请自行配置, 可设为全局变量.)
* Ubuntu 20.04
* Centos7/8

以 v1.18.5 为例, 支持版本：
* Kubernetes A/C/S v1.20.0
* CoreDNS: v1.8.0
* Calico: v3.17.0
* HaProxy: v2.3.2
* Etcd: v3.4.9
* pause: v3.2

### 开始使用 Crane

使用 Crane 很简单, 有可能在一定程度上比 Kubeadm 都简单(国内源问题), 可以通过如下方式获取源码进行安装:

```
$ git clone -b v1.20.0.1 https://github.com/slzcc/crane.git
```

然后进入 crane 目录后, 首先修改 nodes 文件列表:

```
$ cat nodes

[kube-master]
# Master 节点列表 (第一次部署集群), 如果目标主机没用 python 则写明 python3 地址
35.243.68.255 ansible_python_interpreter=/usr/bin/python3

[kube-node]
# Node 节点列表
34.84.105.165

[etcd]
# Etcd 节点列表(Etcd 必须部署再 Master 节点中, Master 节点可任选)
35.243.68.255 ansible_python_interpreter=/usr/bin/python3

[k8s-cluster-add-master]
# 部署完集群后, 填写需要添加的 Master 节点列表 (第一次部署时, 这里必须留空)

[k8s-cluster-add-node]
# 部署完集群后, 填写需要添加的 Node 节点列表 (第一次部署时, 这里必须留空)

[etcd-cluster-add-node]
# 部署完集群后, 填写需要添加的 Etcd 节点列表 (第一次部署时, 这里必须留空)

[k8s-cluster-del-node]
# 部署完集群后, 填写需要移除的 Node 节点列表 (第一次部署时, 这里必须留空)

[etcd-cluster-del-node]
# 部署完集群后, 填写需要移除的 Etcd 节点列表 (第一次部署时, 这里必须留空)

[k8s-cluster:children]
kube-node
kube-master

[etcd-cluster:children]
etcd
etcd-cluster-add-node

[all:vars]
# 部署时的 SSH 配置项, 请结合自身情况填写, 如果用非 root 身份部署, 请对此用户配置免密登入
ansible_ssh_public_key_file='~/.ssh/id_rsa.pub'
ansible_ssh_private_key_file='~/.ssh/id_rsa'
ansible_ssh_port=22
ansible_ssh_user=shilei
```

定义好 nodes 后, 修改 group_vars/all.yml 配置文件, 只需要修改几项就可以进行集群的创建

```
# 此值对应集群的入口地址, 如果只是单点测试这里只需要写入示例的内网地址。
# 如果使用 VIP 这里请填写 VIP 地址并保证已经配置好了 VIP/RB 等配置，RB 应配置 6443 端口. 如果没有自行配置 VIP 请配置 is_keepalived 为 true, 让 crane 自行配置即可。
# 如果使用 SLB 这里请填写 SLB 地址并保证配置好后端 Master 服务器的 6443 端口.
k8s_load_balance_ip: 10.146.0.14

# 使用 Crane 部署时默认使用第一块网卡设备为 CNI 进行绑定 (VIP 也需要), 请填写服务器实例名称统一的物理网卡名称, 如果有两块网卡这里请填写正确的名称, 此值对 Calico 和 Keepalive 服务有效。
os_network_device_name: 'ens4'

# 当需要通过 Crane 部署 VIP 时, 请开启此配置为 true  (如不使用 VIP 请忽略填写)
is_keepalived: false

# 当开启了 VIP 后需要配置 kube proxy 用于识别的物理 IP 地址网段, 否则当通过 nodePort 无法被 VIP 转发流量, 此值为 VIP 后端网络网段 (如不使用 VIP 请忽略填写)
kube_proxy_node_port_addresses: ["10.100.21.0/24", "172.17.48.0/24"]
```

完成上述配置后, 可进行部署 Crane。

## Ansible in Docker

借助 Docker 无需本地安装 Ansible 也可进行对 Crane 的安装, 如果在需部署集群内的任意节点执行则会导致`中断`(如果在部署集群外执行则直接执行命令即可)，您需要配置下述说明文档配置 Dockerd 的 daemon.json 配置，如完成后然后执行下方命令进行 Crane 的安装: 

> 建议: 从创建集群之外的机器执行如下命令, 如过能保证本地有 docker 并且配置下面的配置后则可以在同一台机器执行。
> 如果本地机器有 ansible, 则可以使用 ansible-playbook 直接执行, 但不建议。

```
$ docker run --name crane --rm -i \
        -e ANSIBLE_HOST_KEY_CHECKING=false \
        -e TERM=xterm-256color \
        -e COLUMNS=238 \
        -e LINES=61 \
        -v ~/.ssh:/root/.ssh \
        -v ${PWD}:/crane \
        slzcc/crane:v1.18.5.0 \
        -i nodes main.yml -vv
```

> 如果实例上的 daemon.json 与部署的文件一致, 则不会导致 DockerD 重启, 可以在任意节点上使用 Ansible in Docker. 如果第一次部署请配置如下:

```
$ systemctl stop docker
$ cat > /etc/docker/daemon.json  <<EOF
{
    "registry-mirrors": ["https://4dyopx9i.mirror.aliyuncs.com"],
    "exec-opts": ["native.cgroupdriver=cgroupfs"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "1G"
    },
    "data-root": "/var/lib/docker",
    "insecure-registries": []
}
EOF
 
 $ systemctl start docker
```

> 通过自定义 daemin.json 来保证 Ansible in Docker 不重启 DockerD。

---

如不想使用 Ansible in Docker 可执行命令直接进行部署:

```
$ docker run --name crane --rm -i \
        -e ANSIBLE_HOST_KEY_CHECKING=false \
        -e TERM=xterm-256color \
        -e COLUMNS=238 \
        -e LINES=61 \
        -v ~/.ssh:/root/.ssh \
        -v ${PWD}:/crane \
        slzcc/crane:v1.18.5.0 \
        -i nodes main.yml -vv
```

如在部署过程中想销毁 Crane 则通过命令:

```
$ docker run --name crane --rm -i \
        -e ANSIBLE_HOST_KEY_CHECKING=false \
        -e TERM=xterm-256color \
        -e COLUMNS=238 \
        -e LINES=61 \
        -v ~/.ssh:/root/.ssh \
        -v ${PWD}:/crane \
        slzcc/crane:v1.18.5.0 \
        -i nodes remove_cluster.yml -vv
```

> 在 group_vars/all.yml 中适配需要清除的选项。默认只清除工作目录, 不清除二进制、镜像文件。

---

## Make Tasks

Makefile 中有如下 Tasks：

```
Tasks: add_etcd.yml
       add_nodes.yml
       k8s_certificate_rotation.yml
       remove_cluster.yml
       remove_k8s_nodes.yml
       remove_etcd_nodes.yml
       upgrade_version.yml
       add_master.yml
       etcd_certificate_rotation.yml
       main.yml
       test.yml
```

默认执行 main.yml, 如需操作其他 Tasks，请修改 CRANE_ENTRANCE 参数即可:

```
CRANE_ENTRANCE := main.yml
OPTION :=
```

执行启动命令:

```
$ make run_main
```

如果使用后发现什么问题请及时联系我进行解决: https://wiki.shileizcc.com/confluence/display/LM/Leave+a+message, 或提出 issue。
感谢支持!