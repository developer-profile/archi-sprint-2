#!/bin/bash

#
# Initializing color vars
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
NC=$(tput sgr0)
###
# Starting cluster
###
echo -e "${GREEN}Starting cluster${NC} ${GREEN}TASK01 MONGO SHARDING${NC}\n\n"
#
cd ./task01-mongo-sharding/scripts
docker compose -f ../compose.yaml up -d


###
# Инициализируем бд
###

# docker compose exec -T mongodb1 mongosh <<EOF
# use somedb
# for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
# EOF

# Example
#
# docker compose exec -T <service-name> mongosh --port <mongo port> --quiet <<EOF
# <mongosh commands here>
# EOF
#  Например, так выглядят команды для отображения количества документов в БД somedb инстанса shard1:
# docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
# use somedb
# db.helloDoc.countDocuments()
# EOF

# Инициализация сервера конфигураций
echo -e  "\n\n${GREEN}Initializing config server${NC}\n\n"
#
docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
EOF

# Инициализация шардов
echo -e "\n\n${GREEN}Initializing shards${NC}\n\n"
echo -e "\n\n${GREEN}Initializing shard number${NC} ${RED}one${NC}\n\n"
#
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
      ]
    }
);
EOF


# 
# Инициализация шардов
# 
echo -e "\n\n${GREEN}Initializing shard number${NC} ${RED}two${NC}\n\n"
#
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 0, host : "shard2:27019" },
      ]
    }
  );
EOF

# 
# Инициализируем роутер и наполняем данными
# 
echo -e "\n\n${GREEN}Initializing router and inserting data. Should be total${NC} ${RED}1000${NC}\n\n"
#
docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb;
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i});
db.helloDoc.countDocuments();
EOF


# 
# Проверка на шардах
# 
echo -e "\n\n${GREEN}Checking data in shards${NC}\n\n"
#
echo -e "\n\n${GREEN}Checking data in${NC} ${RED}shard1${NC}. Should be ${RED}492${NC}\n\n"
#
docker compose exec -T shard1 mongosh --port 27018 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF
#
echo -e "\n\n${GREEN}Checking data in ${RED}shard2${NC}. Should be ${RED}508${NC}\n\n"
#
docker compose exec -T shard2 mongosh --port 27019 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
EOF

#
echo -e "\n\n${GREEN}It's${NC} ${RED}finished!${NC}\n\n"
#

#
echo -e "\n\n${GREEN}To${NC} ${RED}destroy${NC} everything with volumes run ${RED}monga-destroy.sh${NC}\n\n"
#
cd ../../