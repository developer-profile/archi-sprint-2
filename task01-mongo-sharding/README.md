# mongo-sharding

## Как запустить

Запускаем шардированную mongodb и приложение

```shell
docker compose up -d
```

Подключитесь к серверу конфигурации и сделайте инициализацию:
```shell
docker exec -it configSrv mongosh --port 27017
```

```shell
> rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
> exit();
```

Инициализируйте шарды:
```shell
docker exec -it shard1 mongosh --port 27018
```
```shell
> rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
      ]
    }
);
> exit();
```

```shell
docker exec -it shard2 mongosh --port 27019
```
```shell
> rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 1, host : "shard2:27019" }
      ]
    }
  );
> exit();
```

Инцициализируйте роутер и наполните его тестовыми данными:
```shell
docker exec -it mongos_router mongosh --port 27020
```

```shell
> sh.addShard( "shard1/shard1:27018");
> sh.addShard( "shard2/shard2:27019");

> sh.enableSharding("somedb");
> sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

> use somedb

> for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

> db.helloDoc.countDocuments() 
> exit();
```
Получится результат — 1000 документов.

Сделайте проверку на шардах:
```shell
 docker exec -it shard1 mongosh --port 27018
 ```
 ```shell
 > use somedb;
 > db.helloDoc.countDocuments();
 > exit();
```

 Получится результат — 492 документа.
Сделайте проверку на втором шарде:
```shell
docker exec -it shard2 mongosh --port 27019
```
```shell
 > use somedb;
 > db.helloDoc.countDocuments();
 > exit();
```

Получится результат — 508 документов.

## Дополнительно

Полезно будет подключиться к своей шардированной БД при помощи mongodb compass, где в качествестве строки подключения следует указать mongodb://127.0.0.1:27020/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.3.3

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080 - увидите информацию по текущей топологии бд с которой взаимодействует сервис.

Откройте в браузере http://localhost:8080/helloDoc/count чтобы увидеть количество документов в БД.