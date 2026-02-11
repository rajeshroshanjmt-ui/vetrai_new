# celeryconfig.py
import os

vetrai_redis_host = os.environ.get("VETRAI_REDIS_HOST")
vetrai_redis_port = os.environ.get("VETRAI_REDIS_PORT")
# broker default user

if vetrai_redis_host and vetrai_redis_port:
    broker_url = f"redis://{vetrai_redis_host}:{vetrai_redis_port}/0"
    result_backend = f"redis://{vetrai_redis_host}:{vetrai_redis_port}/0"
else:
    # RabbitMQ
    mq_user = os.environ.get("RABBITMQ_DEFAULT_USER", "vetrai")
    mq_password = os.environ.get("RABBITMQ_DEFAULT_PASS", "vetrai")
    broker_url = os.environ.get("BROKER_URL", f"amqp://{mq_user}:{mq_password}@localhost:5672//")
    result_backend = os.environ.get("RESULT_BACKEND", "redis://localhost:6379/0")
# tasks should be json or pickle
accept_content = ["json", "pickle"]
