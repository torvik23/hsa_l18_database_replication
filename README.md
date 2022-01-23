# HSA L18: Database. Replication

## Overview
This is an example project to show how to set up MySQL Cluster.

### Task:
* Setup master-slave replication (Master: mysql_master, Slave: mysql_slave1, mysql_slave2)
* Write script that will frequently write data to database
* Turn off mysql-slave1.
* Remove a column in database on slave node

## Getting Started

### Preparation
1. Make sure that you have installed Python3 with the next plugins:
- [mysql-connector-python](https://pypi.org/project/mysql-connector-python/)
- [Faker](https://pypi.org/project/Faker/)

2. Run the docker containers to setup MySQL master-slave replication.
```bash
  docker-compose up -d
```

Be sure to use ```docker-compose down -v``` to cleanup after you're done with tests.

3. Run the python script to generate fake data.
```bash
  python ./application/generator.py
```

## Test cases

### Check Slaves
#### Server `mysql_slave1`. Number of rows must be equal to 1000.
```bash
$ docker exec mysql_slave1 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SELECT count(*) AS rows_amount FROM note;'"

rows_amount
1000
```

#### Server `mysql_slave2`. Number of rows must be equal to 1000.
```bash
$ docker exec mysql_slave2 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SELECT count(*) AS rows_amount FROM note;'"

rows_amount
1000
```

### Turn off `mysql_slave1` server
Check TOP10 last IDs on `mysql_slave1` server before stop.
```bash
$ docker exec mysql_slave1 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SELECT id AS top10_last_ids FROM note ORDER BY id DESC LIMIT 10;'"

top10_last_ids
1000
999
998
997
996
995
994
993
992
991
```

Stop `mysql_slave1` container.
```bash
$ docker-compose stop mysql_slave1
Stopping mysql_slave1 ... done
```
Run the python script to generate more fake data.
```bash
$ python ./application/generator.py
Inserting 1000 rows...
Done!
```
Check TOP10 last IDs on mysql_master server.
```bash
$ docker exec mysql_master sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SELECT id AS top10_last_ids FROM note ORDER BY id DESC LIMIT 10;'"

=>    top10_last_ids
=>    2000
=>    1999
=>    1998
=>    1997
=>    1996
=>    1995
=>    1994
=>    1993
=>    1992
=>    1991
```
Start `mysql_slave1` container.
```bash
$ docker-compose start mysql_slave1                      
Starting mysql_slave1 ... done
```

Check TOP10 last IDs on mysql_master server multiple times after start.
```bash
$ docker exec mysql_slave1 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SELECT id AS top10_last_ids FROM note ORDER BY id DESC LIMIT 10;'"

$ First time call. The data is still outdated:
=>    top10_last_ids
=>    1000
=>    999
=>    998
=>    997
=>    996
=>    995
=>    994
=>    993
=>    992
=>    991

$ Second time call. The data is started to be sync:
=>    top10_last_ids
=>    1200
=>    1199
=>    1198
=>    1197
=>    1196
=>    1195
=>    1194
=>    1193
=>    1192
=>    1191

$ Third time call. The data sync is done:
=>    top10_last_ids
=>    2000
=>    1999
=>    1998
=>    1997
=>    1996
=>    1995
=>    1994
=>    1993
=>    1992
=>    1991
```

### Remove column on `mysql_slave2` server
Check `note` table columns on `mysql_slave2` container before column drop.
```bash
$ docker exec mysql_slave2 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SHOW COLUMNS FROM note;'"

Field:
id
title
description
created
modified
```
Drop `description` column from `note` table.
```bash
$ docker exec mysql_slave2 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; ALTER TABLE note DROP COLUMN description;'"
```
Check that `description` column is dropped in `note` table on `mysql_slave2` container.
```bash
$ docker exec mysql_slave2 sh -c "export MYSQL_PWD=pAsSw1oR2D3; mysql -u root -e 'USE hsa_l18; SHOW COLUMNS FROM note;'"

Field:
id
title
created
modified
```
Run the python script to generate fake data.
```bash
$ python ./application/generator.py
Inserting 1000 rows...
Done!
```

Now we check docker `mysql_slave2` container logs and see that slave replica is broken.
````
$ docker logs mysql_slave2
...
[ERROR] Slave SQL for channel '': Column 2 of table 'hsa_l18.note' cannot be converted from type 'blob' to type 'timestamp', Error_code: 1677
[ERROR] Error running query, slave SQL thread aborted. Fix the problem, and restart the slave SQL thread with "SLAVE START". We stopped at log 'mysql-bin.000003' position 370749.
```