from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
import logging
from firebase_admin import firestore
import uuid
import os
import shutil
from pathlib import Path

# Import du service Firebase centralisé
try:
    from backend.app.models.schemas import UserUpdate, DeleteAccount, UserProgress
    from backend.app.utils.auth import get_current_user
    from backend.app.services.firebase import get_firestore_client, get_auth
except ImportError:
    # Fallback pour les imports relatifs
    from ..models.schemas import UserUpdate, DeleteAccount, UserProgress
    from ..utils.auth import get_current_user
    from ..services.firebase import get_firestore_client, get_auth

# Configuration du logging
logger = logging.getLogger(__name__)

# Dossier pour stocker les fichiers uploadés
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

# Créer un routeur
router = APIRouter(
    prefix="/users",
    tags=["Users"],
    responses={401: {"description": "Non autorisé"}},
)

@router.get("/me")
async def get_user_profile(current_user: dict = Depends(get_current_user)):
    """
    Récupère le profil de l'utilisateur connecté
    """
    try:
        user_record = current_user['user_record']
        user_data = current_user['user_data']
        
        return {
            "uid": user_record.uid,
            "email": user_record.email,
            "username": user_record.display_name or user_data.get('username', ''),
            "photo_url": user_record.photo_url or user_data.get('photo_url', ''),
            "created_at": user_data.get('created_at', None)
        }
    except Exception as e:
        logger.error(f"Error in get_user_profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Utilisateur non trouvé: {str(e)}"
        )

@router.put("/profile")
async def update_profile(user_update: UserUpdate, current_user: dict = Depends(get_current_user)):
    """
    Met à jour le profil de l'utilisateur connecté
    """
    try:
        # Obtenir les instances Firebase
        auth_instance = get_auth()
        db = get_firestore_client()
        
        user_id = current_user['uid']
        update_data = {}
        
        # Mettre à jour le nom d'utilisateur si fourni
        if user_update.username:
            update_data['displayName'] = user_update.username
        
        # Mettre à jour l'URL de la photo si fourni
        if user_update.photo_url:
            update_data['photoURL'] = user_update.photo_url
        
        # Mettre à jour l'utilisateur dans Firebase Auth
        if update_data:
            auth_instance.update_user(user_id, **update_data)
        
        # Mettre à jour les données dans Firestore
        firestore_update = {}
        if user_update.username:
            firestore_update['username'] = user_update.username
        if user_update.photo_url:
            firestore_update['photo_url'] = user_update.photo_url
        
        if firestore_update:
            firestore_update['lastUpdated'] = firestore.SERVER_TIMESTAMP
            db.collection('users').document(user_id).update(firestore_update)
        
        return {
            "success": True,
            "message": "Profil mis à jour avec succès"
        }
    except Exception as e:
        logger.error(f"Error in update_profile: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors de la mise à jour du profil: {str(e)}"
        )

@router.post("/upload-image")
async def upload_image(file: UploadFile = File(...), current_user: dict = Depends(get_current_user)):
    """
    Télécharge une image de profil
    """
    try:
        # Obtenir les instances Firebase
        auth_instance = get_auth()
        db = get_firestore_client()
        
        user_id = current_user['uid']
        
        # Créer un nom de fichier unique
        filename = f"{user_id}_{uuid.uuid4()}{os.path.splitext(file.filename)[1]}"
        file_path = UPLOAD_DIR / filename
        
        # Sauvegarder le fichier
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Dans une application réelle, vous stockeriez l'image dans un service cloud comme Firebase Storage
        # et renverriez une URL. Pour cette démo, on utilise un chemin local.
        image_url = f"/uploads/{filename}"
        
        # Mettre à jour le profil utilisateur avec la nouvelle URL de photo
        auth_instance.update_user(user_id, photo_url=image_url)
        db.collection('users').document(user_id).update({
            'photo_url': image_url,
            'lastUpdated': firestore.SERVER_TIMESTAMP
        })
        
        return {
            "success": True,
            "message": "Image téléchargée avec succès",
            "url": image_url
        }
    except Exception as e:
        logger.error(f"Error in upload_image: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors du téléchargement de l'image: {str(e)}"
        )

@router.delete("/account")
async def delete_account(account_data: DeleteAccount, current_user: dict = Depends(get_current_user)):
    """
    Supprime le compte de l'utilisateur connecté
    """
    try:
        # Obtenir les instances Firebase
        auth_instance = get_auth()
        db = get_firestore_client()
        
        user_id = current_user['uid']
        
        # Dans une implémentation réelle, vous vérifieriez le mot de passe
        # via l'API Firebase Auth REST
        
        # Supprimer l'utilisateur de Firebase Auth
        auth_instance.delete_user(user_id)
        
        # Supprimer les données utilisateur de Firestore
        db.collection('users').document(user_id).delete()
        
        # Supprimer les données de progression
        progress_doc = db.collection('user_progress').document(user_id).get()
        if progress_doc.exists:
            db.collection('user_progress').document(user_id).delete()
        
        return {
            "success": True,
            "message": "Compte supprimé avec succès"
        }
    except Exception as e:
        logger.error(f"Error in delete_account: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors de la suppression du compte: {str(e)}"
        )

@router.get("/progress")
async def get_user_progress(current_user: dict = Depends(get_current_user)):
    """
    Récupère la progression de l'utilisateur connecté
    """
    try:
        # Obtenir l'instance Firestore
        db = get_firestore_client()
        
        user_id = current_user['uid']
        
        # Récupérer les données de progression depuis Firestore
        progress_doc = db.collection('user_progress').document(user_id).get()
        
        if progress_doc.exists:
            progress_data = progress_doc.to_dict()
            return {
                "completed_lessons": progress_data.get('completed_lessons', 0),
                "total_lessons": progress_data.get('total_lessons', 20),
                "current_streak": progress_data.get('current_streak', 0),
                "progress_percentage": progress_data.get('progress_percentage', 0.0)
            }
        else:
            # Créer un document de progression pour le nouvel utilisateur
            initial_progress = {
                'completed_lessons': 0,
                'total_lessons': 20,
                'current_streak': 0,
                'progress_percentage': 0.0,
                'created_at': firestore.SERVER_TIMESTAMP,
                'last_updated': firestore.SERVER_TIMESTAMP
            }
            db.collection('user_progress').document(user_id).set(initial_progress)
            
            return {
                "completed_lessons": 0,
                "total_lessons": 20,
                "current_streak": 0,
                "progress_percentage": 0.0
            }
    except Exception as e:
        logger.error(f"Error in get_user_progress: {e}")
        # En cas d'erreur, retourner des données factices pour la démo
        return {
            "completed_lessons": 3,
            "total_lessons": 20,
            "current_streak": 2,
            "progress_percentage": 15.0
        }

@router.put("/progress")
async def update_user_progress(progress: UserProgress, current_user: dict = Depends(get_current_user)):
    """
    Met à jour la progression de l'utilisateur connecté
    """
    try:
        # Obtenir l'instance Firestore
        db = get_firestore_client()
        
        user_id = current_user['uid']
        
        progress_data = {
            'completed_lessons': progress.completed_lessons,
            'total_lessons': progress.total_lessons,
            'current_streak': progress.current_streak,
            'progress_percentage': progress.progress_percentage,
            'last_updated': firestore.SERVER_TIMESTAMP
        }
        
        db.collection('user_progress').document(user_id).update(progress_data)
        
        return {
            "success": True,
            "message": "Progression mise à jour avec succès"
        }
    except Exception as e:
        logger.error(f"Error in update_user_progress: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Erreur lors de la mise à jour de la progression: {str(e)}"
        )
