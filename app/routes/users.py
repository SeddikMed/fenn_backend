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
            update_data['display_name'] = user_update.username
        
        # Mettre à jour l'URL de la photo si fourni
        if user_update.photo_url:
            update_data['photo_url'] = user_update.photo_url
        
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
        user_id = current_user['uid']
        logger.info(f"Début de l'upload d'image pour l'utilisateur: {user_id}")
        logger.info(f"Fichier reçu: {file.filename}, content-type: {file.content_type}")

        # S'assurer que le dossier existe
        os.makedirs(UPLOAD_DIR, exist_ok=True)
        
        # Créer un nom de fichier unique
        extension = os.path.splitext(file.filename)[1].lower() if file.filename and '.' in file.filename else '.jpg'
        acceptable_extensions = ['.jpg', '.jpeg', '.png', '.gif']
        
        if extension not in acceptable_extensions:
            logger.warning(f"Extension de fichier non supportée: {extension}")
            extension = '.jpg'  # Forcer une extension valide
        
        filename = f"{user_id}_{uuid.uuid4().hex}{extension}"
        file_path = os.path.join(UPLOAD_DIR, filename)
        logger.info(f"Chemin du fichier: {file_path}")
        
        # Lire et sauvegarder le fichier
        try:
            contents = await file.read()
            logger.info(f"Taille du fichier: {len(contents)} octets")
            
            with open(file_path, 'wb') as f:
                f.write(contents)
                
            logger.info(f"Fichier sauvegardé avec succès: {file_path}")
        except Exception as e:
            logger.error(f"Erreur lors de la sauvegarde du fichier: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Erreur lors de la sauvegarde du fichier: {str(e)}"
            )
        
        # Générer l'URL d'accès - URL relative pour le stockage, URL absolue pour la réponse
        relative_url = f"/uploads/{filename}"
        
        # Obtenir le domaine depuis la requête pour construire une URL absolue
        base_url = "http://192.168.1.25:8000"  # URL de base par défaut
        logger.info(f"URL de base: {base_url}, URL relative: {relative_url}")
        absolute_url = f"{base_url}{relative_url}"
        logger.info(f"URL absolue générée: {absolute_url}")
        
        # Obtenir les instances Firebase
        auth_instance = get_auth()
        db = get_firestore_client()
        
        try:
            # Mettre à jour le profil utilisateur avec l'URL absolue de la photo
            auth_instance.update_user(user_id, photo_url=absolute_url)
            db.collection('users').document(user_id).update({
                'photo_url': absolute_url,
                'lastUpdated': firestore.SERVER_TIMESTAMP
            })
            logger.info(f"Profil mis à jour avec succès pour l'utilisateur: {user_id}")
        except Exception as e:
            logger.error(f"Erreur lors de la mise à jour du profil: {e}")
            # Ne pas interrompre l'exécution, l'image reste valide mais le profil n'est pas mis à jour
        
        return {
            "success": True,
            "message": "Image téléchargée avec succès",
            "url": absolute_url  # URL absolue
        }
    except Exception as e:
        logger.exception(f"Exception dans upload_image: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Une erreur est survenue lors du traitement de l'image: {str(e)}"
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
