#!/bin/bash
#------------------------環境設定-------------------------
#停用swap
swapoff -a
sed -i '/swap/d' fstab #刪除swap
#調整kernel參數
echo "vm.swappiness=1" | tee -a /etc/sysctl.conf
echo "vm.max_map_count = 262144 | tee -a /etc/sysctl.conf
#套用Kernel參數
sysctl -p
#調整使用者檔案限制，檔案/etc/security/limits.conf
echo "* soft nofile 65535
* hard nofile 65535
* soft memlock unlimited # For memroy lock
* hard memlock unlimited
" >>/etc/security/limits.conf


#------------------------git clone elk repo-------------------------
# git clone 

#-----------------------啟動docker-compose-------------------------
docker-compose -f /root/docker/elk/docker-compose.yml up -d
curl http://elastic:password@127.0.0.1:9200
curl http://elastic:password@127.0.0.1:9200/_cat/nodes
#------------------------設定cluster認證-------------------------
docker exec -it es02 /usr/share/elasticsearch/bin/elasticsearch-certutil ca
#這邊會出現互動式程序

docker cp elastic-stack-ca.p12 es01:usr/share/elasticsearch/config/
docker cp elastic-stack-ca.p12 es02:usr/share/elasticsearch/config/
docker cp elastic-stack-ca.p12 es03:usr/share/elasticsearch/config/

#------------------------設定cluster密碼-------------------------
docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

#這邊會出現互動式程序
