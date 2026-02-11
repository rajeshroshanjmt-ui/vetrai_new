from fastapi_pagination import Page

from vetrai.helpers.base_model import BaseModel
from vetrai.services.database.models.flow.model import Flow
from vetrai.services.database.models.folder.model import FolderRead


class FolderWithPaginatedFlows(BaseModel):
    folder: FolderRead
    flows: Page[Flow]
