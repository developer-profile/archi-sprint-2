# mongo-sharding-repl

## Как запустить

Запускаем шардированную и реплицированную mongodb и приложение

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
      _id : "rs0",
      members: [
        { _id : 0, host : "shard1:27018" },
      ]
    }
);

rs.add({ _id: 1, host: "shard1secondary1:27021" });
rs.add({ _id: 2, host: "shard1secondary2:27022" });
rs.status()
```

```shell
docker exec -it shard2 mongosh --port 27019
```
```shell
> rs.initiate(
    {
      _id : "rs1",
      members: [
        { _id : 0, host : "shard2:27019" },
      ]
    }
  );

rs.add({ _id: 1, host: "shard2secondary1:27023" });
rs.add({ _id: 2, host: "shard2secondary2:27024" });

```

Инцициализируйте роутер и наполните его тестовыми данными:
```shell
docker exec -it mongos_router mongosh --port 27020
```

```shell
> sh.addShard( "rs0/shard1:27018");
> sh.addShard( "rs1/shard2:27019");

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
