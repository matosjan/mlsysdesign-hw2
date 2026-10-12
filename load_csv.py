import argparse
import csv
import json

from confluent_kafka import Producer


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("files", nargs="+")
    parser.add_argument("--bootstrap-servers", default="kafka:9092")
    parser.add_argument("--topic", default="transactions")
    args = parser.parse_args()

    producer = Producer({
        "bootstrap.servers": args.bootstrap_servers,
        "enable.idempotence": True,
        "compression.type": "lz4",
    })
    errors = []

    def delivered(error, message):
        if error and not errors:
            errors.append(str(error))

    for filename in args.files:
        count = 0
        with open(filename, encoding="utf-8-sig", newline="") as file:
            for row in csv.DictReader(file):
                value = json.dumps(row, ensure_ascii=False).encode("utf-8")
                while True:
                    try:
                        producer.produce(args.topic, value=value, on_delivery=delivered)
                        break
                    except BufferError:
                        producer.poll(0.1)
                producer.poll(0)
                if errors:
                    raise RuntimeError(errors[0])
                count += 1

        remaining = producer.flush(120)
        if errors or remaining:
            raise RuntimeError(errors[0] if errors else f"Не отправлено сообщений: {remaining}")
        print(f"{filename}: отправлено {count} строк", flush=True)


if __name__ == "__main__":
    main()
