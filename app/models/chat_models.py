from pydantic import BaseModel
from typing import Optional, Dict, Any

class ChatRequest(BaseModel):
    user_input: str
    user_id: str = "default"
    session_data: Optional[Dict[str, Any]] = None

class ChatResponse(BaseModel):
    text: str
    type: str
    session_data: Dict[str, Any]
    # Ajoute d'autres champs si besoin (ex: suggestions, themes, etc.)
