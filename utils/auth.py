from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import os
from dotenv import load_dotenv

# Import du service Firebase centralisé
try:
    from backend.app.services.firebase import get_firestore_client, get_auth
except ImportError:
    # Fallback pour les imports relatifs
    from ..services.firebase import get_firestore_client, get_auth

# Charger les variables d'environnement
load_dotenv()

# Configuration JWT
SECRET_KEY = os.getenv("SECRET_KEY", "super-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 jours

# Configuration OAuth2
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """
    Crée un token JWT pour l'authentification
    
    Args:
        data: Données à inclure dans le token
        expires_delta: Durée de validité du token
        
    Returns:
        str: Token JWT encodé
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    """
    Vérifie le token JWT et récupère l'utilisateur courant
    
    Args:
        token: Token JWT fourni dans l'en-tête Authorization
        
    Returns:
        dict: Données de l'utilisateur
        
    Raises:
        HTTPException: Si le token est invalide ou expiré
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token invalide ou expiré",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        # Décodage du JWT
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        
        # Récupérer l'utilisateur depuis Firebase
        try:
            # Obtenir les instances Firebase
            auth_instance = get_auth()
            db = get_firestore_client()
            
            user_record = auth_instance.get_user(user_id)
            # Récupérer les données utilisateur depuis Firestore
            user_doc = db.collection('users').document(user_id).get()
            user_data = user_doc.to_dict() if user_doc.exists else {}
            
            return {
                "uid": user_id,
                "user_record": user_record,
                "user_data": user_data
            }
        except Exception as e:
            print(f"Error getting user: {e}")
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception
