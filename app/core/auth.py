from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# Fonction factice pour déboguer : accepte toute requête avec Authorization

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer())):
    # Ici, tu peux ajouter une vraie vérification du token JWT/Firebase
    # Pour le debug, on retourne un utilisateur bidon
    return {"uid": "debug_user"}
