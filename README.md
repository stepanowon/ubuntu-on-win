# Ubuntu-24.04 리눅스 3개 노드 설정
- 이 컨텐츠는 "내 PC로 실습하는 k8s와 gitops 기반 CI/CD 자동화" 교육 과정을 위해 만들어졌습니다.
  
## 설정 내용

- user1/asdf 로 사용자 생성
- user1을 sudoer로 등록
- git, docker 설치
- hostname : server1 ~ server3
- ip 주소 : 192.168.56.101~103
- 모든 vm에 hosts 파일 등록 : server1~3

## 설치방법

- Oracle VirtualBox 설치 - https://www.virtualbox.org
- Vagrant 설치 - https://developer.hashicorp.com/vagrant/install?product_intent=vagrant

```ssh
git clone https://github.com/stepanowon/ubuntu-on-win
cd ubuntu-on-win
vagrant up

# 모두 설치 후
vagrant reload

# 사용자 계정/패스워드 --> user1/asdf
```

---

## Jenkins 설치

### JDK 설치

```ssh
# server1, 2, 3 모두에서 실행
sudo apt update
sudo apt install openjdk-21-jdk-headless
```

### Jenkins 설치

```ssh
# server1에서만 실행
sudo gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68
sudo gpg --export 7198F4B714ABFC68 | sudo tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install jenkins -y
```

### docker 설치(혹시 설치하지 않았다면)

```ssh
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo usermod -a -G docker jenkins

sudo systemctl enable docker
sudo systemctl start docker
sudo chmod 666 /var/run/docker.sock
```

### jenkins 초기 패스워드 획득

```ssh
# server1에서 실행
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Jenkins 서버 접속

- 브라우저를 열고 http://192.168.56.101:8080 으로 접속함

---

## Jenkins 분산 에이전트 추가

### 사전 조건

- Agent Node로 등록할 호스트, 인스턴스에는 JDK가 미리 설치되어 있어야 함

### SSH 키 생성(server1 에서)

```ssh
# ssh-keygen -t rsa 명령어로 키페어 생성
# 생성된 키페어 중 Public Key를 server, server3으로 복사
   ssh-copy-id 192.168.56.102
   ssh-copy-id 192.168.56.103
# jenkins의 Jenkins관리-Credential에 ssh Private Key 등록
```

### 노드 추가 시작(Jenkins UI 화면에서)

```ssh
# Jenkins 관리 - Nodes 로 이동하여 New Node 버튼 클릭
# 노드명은 적절히 예) 서버명 입력하고 Type을 Permanent Agent 지정 ---> Create

# ---다음 단계로---
# 설명은 간단히 알아보기 쉽게 : 서버명, IP 주소등 입력
# Number of executors : 2
# Remote Root Directory : /home/user1/jenkins-agent   (사용자 홈디렉토리에 생성)
   * 디렉토리 미리 생성해두어야 함
   * 디렉토리가 명령 실행시에 접근할 수 있는 권한이 있어야 함.
   * 루트에 디렉토리를 생성했다면 sudo!!
# Labels : agent 지정시 사용할 레이블
# launch method : launch agent via SSH
# Host : 192.168.56.202(연결하려는 Agent의 주소)
# Credentials : Jenkins Credentials에 등록한 자격증명 지정
# Host Key Verification Strategy : Manually trusted key Verification Strategy
# Availability : Keep this agent online as much as posiible
```

### 노드간 시간이 일치하지 않을 때

```sh
# 모든 노드에서 다음 명령어 실행
sudo timedatectl set-ntp yes
```

## Gitea 설치

### gitea를 위한 PostgreSQL 서버 준비

```sh
# server3 가상머신에 접속
ssh user1@192.168.56.103

# postgresql 서버 설치
$ sudo apt install postgresql -y
# postgresql 설정 파일 위치 확인
$ sudo -i -u postgres psql -U postgres -c 'SHOW config_file'

# etc/postgresql/16/main/postgresql.conf 설정 파일의 두가지 정보 변경
$ sudo vi /etc/postgresql/16/main/postgresql.conf
......
listen_addresses = '*'
password_encryption = scram-sha-256
......

# /etc/postgresql/16/main/pg_hba.conf 편집
# 클라이언트의 주소와 역할 이름을 지정하고 모든 데이터베이스에 연결을 허용할지 여부를 설정
$ sudo vi /etc/postgresql/16/main/pg_hba.conf

# Database administrative login by Unix domain socket
local   all             postgres                                trust
......

# 다음 열은 추가
host    giteadb         gitea           192.168.56.0/24         scram-sha-256

------------------
# 편집이 끝났다면 서비스 재시작
$ sudo systemctl restart postgresql.service

# 새로운 postgresql 데이터베이스 사용자 추가
# 데이터베이스 : giteadb
# 사용자 : gitea / giteapwd

$ psql -U postgres
psql (16.6 (Ubuntu 16.6-0ubuntu0.24.04.1))
Type "help" for help.

# 사용자명/패스워드는 적절하게 변경하여 사용할 수 있음
CREATE ROLE gitea WITH LOGIN PASSWORD 'giteapwd';

# 데이터베이스 생성. 데이머베이스명을 적절하게 변경할 수 있음
CREATE DATABASE giteadb WITH OWNER gitea TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';

# psql을 빠져나오기 위해 다음 명령어 사용
exit

# 연결 테스트
$ psql "postgres://gitea@192.168.56.103/giteadb"

```

### gitea 설치

```sh
# server2 가상머신 접속
ssh user1@192.168.56.102

# 새로운 사용자 추가
sudo adduser --system --shell /bin/bash --gecos 'Git Version Control' --group --disabled-password --home /home/git  git

# 바이너리 파일 다운로드, 복사
VERSION=1.22.6
sudo wget -O /tmp/gitea https://dl.gitea.io/gitea/${VERSION}/gitea-${VERSION}-linux-amd64
sudo mv /tmp/gitea /usr/local/bin
sudo chmod +x /usr/local/bin/gitea

# 맥OS 용 다운로드, 복사
VERSION=1.22.6
sudo wget -O /tmp/gitea https://dl.gitea.io/gitea/${VERSION}/gitea-${VERSION}-linux-arm64
sudo mv /tmp/gitea /usr/local/bin
sudo chmod +x /usr/local/bin/gitea

# 필요한 디렉토리 설정
sudo mkdir -p /var/lib/gitea/{custom,data,log}
sudo chown -R git:git /var/lib/gitea/
sudo chmod -R 750 /var/lib/gitea/
sudo mkdir /etc/gitea
sudo chown root:git /etc/gitea
sudo chmod 770 /etc/gitea

# systemd로 등록 & 시작

sudo wget https://raw.githubusercontent.com/go-gitea/gitea/refs/heads/release/v1.22/contrib/systemd/gitea.service \
     -P /etc/systemd/system/

sudo systemctl enable gitea
sudo systemctl start gitea

# 상태 확인
sudo systemctl status gitea

# 방화벽에서 3000번 포트 허용
sudo ufw allow 3000/tcp

```

### gitea 설정

- 브라우저 접속
  - http://192.168.56.102:3000 으로 접속하여 브라우저 기반의 설정 시작
  - 만일 chrome, firefox로 접속되지 않는다면 edge, safari 브라우저를 사용할 것
- gitea 초기 설정 화면이 브라우저에 나타나면 다음과 같이 설정할 것
  - 데이터베이스 설정
    - 데이터베이스 유형 : PostgreSQL
    - 호스트 : 192.168.56.103:5432
    - 이름(사용자명) : gitea
    - 비밀번호 : giteapwd
    - 데이터베이스 이름 : giteadb
    - 나머지 설정은 기본값으로
  - 기본 설정
    - 사이트 제목 : 임의의 이름 지정(예: 테스트 깃서버)
    - 실행사용자명 : git
    - 나머지는 기본값으로 지정
  - 관리자 계정 설정
    - 관리자 이름 : admin1
    - 이메일 주소 : admin1@test.com
    - 비밀번호 : admin1pwd

- 새로운 gitea 사용자 추가
  - 브라우저 화면 오른쪽 상단의 사용자 아이콘 클릭 후 '사이트 관리' 클릭
  - 'Identity & Access' 아래의 '사용자 계정' 클릭
  - 사용자 계정 생성
    - 인증 소스 : 로컬
    - User visibility : Limited
    - 사용자명 : user1
    - 이메일주소 : user1@test.com
    - 비밀번호 : user1pwd
    - '사용자에게 비밀번호 변경을 요청 (권장됨)' 체크 해제

- 사용자 생성 후 로그아웃하고 생성된 사용자로 다시 로그인
