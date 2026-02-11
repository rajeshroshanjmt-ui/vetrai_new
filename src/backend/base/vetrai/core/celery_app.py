from celery import Celery


def make_celery(app_name: str, config: str) -> Celery:
    celery_app = Celery(app_name)
    celery_app.config_from_object(config)
    celery_app.conf.task_routes = {"vetrai.worker.tasks.*": {"queue": "vetrai"}}
    return celery_app


celery_app = make_celery("vetrai", "vetrai.core.celeryconfig")
