import uuid

def generate_id() -> str:
    """生成唯一标识符"""
    return str(uuid.uuid4())