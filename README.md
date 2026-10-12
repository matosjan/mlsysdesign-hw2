# Домашнее задание №2
## Запуск

Нужны Docker и Docker Compose v2.

Скачайте код проекта и перейдите в его папку, чтобы выполнять команды из неё:

```bash
git clone https://github.com/matosjan/mlsysdesign-hw2.git
cd mlsysdesign-hw2
```

Скачайте [данные](https://www.kaggle.com/competitions/teta-ml-1-2025/data) и положите `train.csv` и `test.csv` в папку `data`.

Соберите образ загрузчика, запустите Kafka и ClickHouse, создайте топик и таблицы, затем отправьте CSV в Kafka:

```bash
docker compose build producer
docker compose up -d --wait kafka clickhouse
docker compose exec -T kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists --topic transactions --partitions 1 --replication-factor 1
docker compose exec -T clickhouse clickhouse-client --multiquery < sql/create_tables.sql
docker compose run --rm producer
```

Проверьте, что все строки дошли из Kafka в ClickHouse. Дождитесь значения **1 048 575**:

```bash
docker compose exec -T clickhouse clickhouse-client --query 'SELECT count() FROM hw2.transactions'
```

Получите категорию самой большой транзакции по каждому штату и сохраните результат в CSV:

```bash
docker compose exec -T clickhouse clickhouse-client --format CSVWithNames < sql/max_transaction_by_state.sql > results/max_transaction_by_state.csv
```

Остановка: `docker compose down`. Для загрузки заново: `docker compose down -v`, затем повторите запуск. Это удалит данные контейнеров; повторная загрузка без очистки создаст дубликаты.

## Результаты

В CSV — 51 строка: 50 штатов и округ Колумбия. Самая большая транзакция — **28 948,90**, штат **NE**, категория **travel**.

Для ускорения в DDL добавлена проекция `max_by_state`.

| Режим | Медиана, мс | Прочитано строк |
| --- | ---: | ---: |
| Без проекции | 69,476 | 1 048 575 |
| С проекцией | 3,932 | 51 |

Ускорение — около **17,7 раза**, результаты совпадают. Замер: 20 запусков после прогрева, два потока, кэш результатов выключен. Данные замера — `results/benchmark.csv`.
