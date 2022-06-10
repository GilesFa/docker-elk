# docker-elk
#此專案將會自動建立3節點的docker elasticsearch
#運行步驟:
1.  cd ~
2.  git clone https://github.com/GilesFa/docker-elk.git
3.  cd docker-elk
4.  ./elk-setup

#說明:
1. 請將docker-elk專案下載到/root目錄下
2. 設定elasticsearch密碼、ELK Vsersion(8.x 可能不適用) : /root/docker-elk/.env
3. 執行/root/docker-elk/elk-setup.sh
