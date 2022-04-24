### Execution

Build docker stack based on docker-composed.yaml
```shell
docker-compose build
```

Initialize airflow database
```shell
docker-compose up airflow-init
```

Start all docker containers
```shell
docker-compose up
```

Login to Airflow web UI on `localhost:8080` with default creds: `airflow/airflow`

Run your DAG on the Web Console.

On finishing your run or to shut down the container/s:
```shell
docker-compose down
```

To stop and delete containers, delete volumes with database data, and download images, run:
```
docker-compose down --volumes --rmi all
```

or
```
docker-compose down --volumes --remove-orphans
```

