#!/bin/bash
#------------------------環境設定-------------------------#
#停用swap
swapoff -a
sed -i '/swap/d' /etc/fstab #刪除swap
#調整kernel參數
echo "vm.swappiness=1" | tee -a /etc/sysctl.conf
echo "vm.max_map_count = 262144"| tee -a /etc/sysctl.conf
#套用Kernel參數
sysctl -p
#調整使用者檔案限制，檔案/etc/security/limits.conf
echo "* soft nofile 65535" | tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | tee -a /etc/security/limits.conf
echo "* soft memlock unlimited" | tee -a /etc/security/limits.conf
echo "* hard memlock unlimited" | tee -a /etc/security/limits.conf
echo "* soft nofile 65535" | tee -a /etc/security/limits.conf
#------------------------git clone elk repo-------------------------#
# git clone https://github.com/GilesFa/docker-elk.git
#-----------------------啟動docker-compose-------------------------#
docker-compose -f /root/docker-elk/docker-compose.yml up -d
echo "watting for 120 seconds..."
/usr/bin/sleep 120
echo "check elasticsearch cluster status"
curl http://elastic:password@127.0.0.1:9200
curl http://elastic:password@127.0.0.1:9200/_cat/nodes
#------------------------設定cluster認證-------------------------#
docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-certutil ca
#這邊會出現互動式程序，直接按兩次enter

/usr/bin/sleep 5

#將ca複製到本地
docker cp es01:usr/share/elasticsearch/elastic-stack-ca.p12 /root/docker-elk/

#複製ca到每個節點
docker cp /root/docker-elk/elastic-stack-ca.p12 es01:usr/share/elasticsearch/config/
docker cp /root/docker-elk/elastic-stack-ca.p12 es02:usr/share/elasticsearch/config/
docker cp /root/docker-elk/elastic-stack-ca.p12 es03:usr/share/elasticsearch/config/

#------------------------設定cluster密碼-------------------------#
docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

#這邊會出現互動式程序

#------------------------再次檢查叢集狀態-------------------------#
echo "watting for 30 seconds..."
/usr/bin/sleep 30
curl http://elastic:password@127.0.0.1:9200
curl http://elastic:password@127.0.0.1:9200/_cat/nodes
