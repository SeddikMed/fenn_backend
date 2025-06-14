from pydantic import BaseModel, EmailStr, Field
from typing import Optional

# Modèles pour l'authentification
class UserCreate(BaseModel):
    email: EmailStr
    username: str
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserUpdate(BaseModel):
    username: Optional[str] = None
    photo_url: Optional[str] = None

class PasswordReset(BaseModel):
    email: EmailStr

class PasswordChange(BaseModel):
    current_password: str
    new_password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class DeleteAccount(BaseModel):
    password: str

# Modèle pour la progression de l'utilisateur
class UserProgress(BaseModel):
    completed_lessons: int = Field(default=0)
    total_lessons: int = Field(default=20)
    current_streak: int = Field(default=0)
    progress_percentage: float = Field(default=0.0)

# Modèles pour le chat
class ChatMessage(BaseModel):
    message: str

class ChatResponse(BaseModel):
    success: bool
    response: str

class ChatHistoryItem(BaseModel):
    user_message: str
    bot_response: str
    timestamp: Optional[str] = None
