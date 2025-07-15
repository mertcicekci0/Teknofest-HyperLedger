#!/bin/bash

# Teknofest İHA/SİHA Blockchain Takip Sistemi
# Network Başlatma Scripti

export PATH=${PWD}/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/fabric-samples/config/

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function print_help() {
  echo "Kullanım: "
  echo "  network.sh <Mode> [Flags]"
  echo "    <Mode>"
  echo "      - 'up' - Fabric ağını başlat"
  echo "      - 'down' - Fabric ağını durdur"
  echo "      - 'restart' - Fabric ağını yeniden başlat"
  echo "      - 'createChannel' - Kanal oluştur"
  echo "      - 'deployCC' - Chaincode deploy et"
  echo "      - 'test' - Test scriptini çalıştır"
  echo
  echo "    Flags:"
  echo "    -ca <use CAs> -  CA'lar ile sertifika oluştur (default false)"
  echo "    -c <channel name> - Kanal adı (default \"mychannel\")"
  echo "    -s <dbtype> - Peer State Database türü: goleveldb (default) or couchdb"
  echo "    -r <max retry> - Maksimum deneme sayısı (default 5)"
  echo "    -d <delay> - Peer'lar arası bekleme süresi (default 3s)"
  echo "    -i <imagetag> - Docker imaj tag'i (default \"latest\")"
  echo "    -v - Verbose - detaylı log"
  echo
  echo " Örnekler:"
  echo "   network.sh up"
  echo "   network.sh up createChannel"
  echo "   network.sh createChannel -c mychannel"
  echo "   network.sh deployCC"
  echo "   network.sh down"
}

# Default değerler
CHANNEL_NAME="mychannel"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"
DATABASE="goleveldb"

# Parse command line arguments
while [[ $# -ge 1 ]] ; do
  key="$1"
  case $key in
  -h )
    print_help
    exit 0
    ;;
  -c )
    CHANNEL_NAME="$2"
    shift
    ;;
  -ca )
    CRYPTO="Certificate Authorities"
    ;;
  -r )
    MAX_RETRY="$2"
    shift
    ;;
  -d )
    DELAY="$2"
    shift
    ;;
  -s )
    DATABASE="$2"
    shift
    ;;
  -i )
    IMAGETAG="$2"
    shift
    ;;
  -v )
    VERBOSE=true
    ;;
  * )
    EXPMODE="$1"
    shift
    ;;
  esac
  shift
done

# Determine mode of operation and printing out what we asked for
if [ "$EXPMODE" == "up" ]; then
  infoln "Teknofest Fabric Ağını Başlatıyor ..."
elif [ "$EXPMODE" == "createChannel" ]; then
  infoln "Kanal Oluşturuluyor: '$CHANNEL_NAME'"
elif [ "$EXPMODE" == "down" ]; then
  infoln "Teknofest Fabric Ağını Durduruyor ..."
elif [ "$EXPMODE" == "restart" ]; then
  infoln "Teknofest Fabric Ağını Yeniden Başlatıyor ..."
else
  print_help
  exit 1
fi

# Log fonksiyonları
function infoln() {
  echo -e "${GREEN}${1}${NC}"
}

function warnln() {
  echo -e "${YELLOW}${1}${NC}"
}

function errorln() {
  echo -e "${RED}${1}${NC}"
}

function fatalln() {
  errorln "$1"
  exit 1
}

# Docker kontrol
function checkPrereqs() {
  ## Check if your have cloned the peer binaries and configuration files.
  peer version > /dev/null 2>&1

  if [[ $? -ne 0 || ! -d "fabric-samples/config" ]]; then
    errorln "Peer binary ve configuration dosyaları bulunamadı.."
    errorln
    errorln "Fabric samples repository'sini indirin:"
    errorln "    curl -sSL https://bit.ly/2ysbOFE | bash -s"
    exit 1
  fi
  # use the fabric tools container to see if the samples and binaries were downloaded correctly.
  peer version > /dev/null 2>&1

  if [ $? -ne 0 ]; then
    fatalln "Fabric binary bulunamadı.. terminating"
  fi

  infoln "✓ Docker ve Fabric binary'leri hazır"
}

# Network başlatma
function networkUp() {
  checkPrereqs
  
  if [ ! -d "organizations/peerOrganizations" ]; then
    createOrgs
  fi

  COMPOSE_FILES="-f docker-compose.yml"
  
  if [ "${DATABASE}" == "couchdb" ]; then
    COMPOSE_FILES="${COMPOSE_FILES} -f docker-compose-couch.yml"
  fi

  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Docker containerları başlatılamadı"
  fi
  
  infoln "✓ Teknofest Fabric Ağı başarıyla başlatıldı!"
}

# Network durdurma
function networkDown() {
  # stop org3 containers also in addition to org1 and org2, in case we were running sample to add org3
  docker-compose -f docker-compose.yml down --volumes --remove-orphans
  docker-compose -f docker-compose-couch.yml down --volumes --remove-orphans
  
  # Don't remove the generated artifacts -- note, the ledgers are always removed
  if [ "$MODE" != "restart" ]; then
    # Bring down the network, deleting the volumes
    #Cleanup the chaincode containers
    clearContainers
    #Cleanup images
    removeUnwantedImages
    # remove orderer block and other channel configuration transactions and certs
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
    ## remove fabric ca artifacts
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db'
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db'
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
    docker run --rm -v "$(pwd):/data" busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  fi
  
  infoln "✓ Teknofest Fabric Ağı durduruldu"
}

# Container temizleme
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    infoln "No containers available for deletion"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Image temizleme
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    infoln "No images available for deletion"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Organizasyon sertifikaları oluşturma
function createOrgs() {
  if [ -d "organizations/peerOrganizations" ]; then
    rm -Rf organizations/peerOrganizations && rm -Rf organizations/ordererOrganizations
  fi

  # Cryptogen ile sertifika oluştur
  infoln "✓ Cryptogen ile sertifikalar oluşturuluyor..."
  
  which cryptogen
  if [ "$?" -ne 0 ]; then
    fatalln "cryptogen tool bulunamadı. Exiting"
  fi
  
  infoln "Org1 sertifikaları oluşturuluyor"
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org1.yaml --output="organizations"
  
  infoln "Org2 sertifikaları oluşturuluyor"  
  cryptogen generate --config=./organizations/cryptogen/crypto-config-org2.yaml --output="organizations"
  
  infoln "Orderer Org sertifikaları oluşturuluyor"
  cryptogen generate --config=./organizations/cryptogen/crypto-config-orderer.yaml --output="organizations"
}

# Kanal oluşturma
function createChannel() {
  infoln "Kanal oluşturuluyor: $CHANNEL_NAME"
  
  scripts/createChannel.sh $CHANNEL_NAME $DELAY $MAX_RETRY $VERBOSE
  if [ $? -ne 0 ]; then
    fatalln "Kanal oluşturulamadı"
  fi
}

# Chaincode deploy etme
function deployCC() {
  infoln "UAV Tracker Chaincode deploy ediliyor..."
  
  scripts/deployCC.sh $CHANNEL_NAME uav-tracker ../chaincode/uav-tracker/ javascript
  if [ $? -ne 0 ]; then
    fatalln "Chaincode deploy edilemedi"
  fi
}

# Ana execution logic
if [ "${EXPMODE}" == "up" ]; then
  networkUp
elif [ "${EXPMODE}" == "createChannel" ]; then
  createChannel
elif [ "${EXPMODE}" == "deployCC" ]; then
  deployCC
elif [ "${EXPMODE}" == "down" ]; then
  networkDown
elif [ "${EXPMODE}" == "restart" ]; then
  networkDown
  networkUp
elif [ "${EXPMODE}" == "test" ]; then
  infoln "Test scripti çalıştırılıyor..."
  ./test-uav.sh
else
  print_help
  exit 1
fi
