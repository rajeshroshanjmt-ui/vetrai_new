from vetrai.services.base import Service
from vetrai.services.factory import ServiceFactory
from vetrai.services.job_queue.service import JobQueueService


class JobQueueServiceFactory(ServiceFactory):
    def __init__(self):
        super().__init__(JobQueueService)

    def create(self) -> Service:
        return JobQueueService()
