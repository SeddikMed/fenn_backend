from fastapi import APIRouter, Depends, HTTPException, status, Form
import logging
from typing import List, Optional
from pydantic import BaseModel

# Import du service Firebase centralisé
try:
    from backend.app.models.schemas import ChatMessage, ChatResponse
    from backend.app.utils.auth import get_current_user
    from backend.app.services.firebase import get_firestore_client, get_auth
    from backend.app.services.chatbot import process_input #, update_user_progress, get_user_progress
except ImportError:
    # Fallback pour les imports relatifs
    from ..models.schemas import ChatMessage, ChatResponse
    from ..utils.auth import get_current_user
    from ..services.firebase import get_firestore_client, get_auth
    from ..services.chatbot import process_input #, update_user_progress, get_user_progress

# Configuration du logging
logger = logging.getLogger(__name__)

# Créer un routeur
router = APIRouter(
    prefix="/chat",
    tags=["Chat"],
    responses={401: {"description": "Non autorisé"}},
)

class ChatMessage(BaseModel):
    message: str

class ProgressUpdate(BaseModel):
    topic: str
    score: int

# Endpoint de test simple, sans authentification
@router.get("/test")
async def test_endpoint():
    """
    Simple endpoint de test pour vérifier la connexion
    """
    return {"status": "success", "message": "API Chatbot fonctionnelle"}

@router.post("/")
async def chat_endpoint(
    chat_message: ChatMessage,
    current_user: dict = Depends(get_current_user)
):
    """
    Endpoint pour interagir avec le chatbot
    """
    try:
        user_id = current_user["uid"]
        response = process_input(chat_message.message, user_id)
        return response
    except Exception as e:
        logger.error(f"Error in chat endpoint: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Une erreur est survenue lors du traitement de votre message"
        )

# @router.post("/progress")
# async def update_progress_endpoint(
#     progress: ProgressUpdate,
#     current_user: dict = Depends(get_current_user)
# ):
#     """
#     Met à jour la progression de l'utilisateur pour un quiz
#     """
#     try:
#         user_id = current_user["uid"]
#         update_user_progress(user_id, progress.topic, progress.score)
#         return {"success": True, "message": "Progression mise à jour avec succès"}
#     except Exception as e:
#         logger.error(f"Error updating progress: {str(e)}")
#         raise HTTPException(
#             status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#             detail="Erreur lors de la mise à jour de la progression"
#         )

# @router.get("/progress")
# async def get_progress_endpoint(
#     current_user: dict = Depends(get_current_user)
# ):
#     """
#     Récupère la progression de l'utilisateur
#     """
#     try:
#         user_id = current_user["uid"]
#         progress = get_user_progress(user_id)
#         return progress
#     except Exception as e:
#         logger.error(f"Error getting progress: {str(e)}")
#         raise HTTPException(
#             status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
#             detail="Erreur lors de la récupération de la progression"
#         )

@router.post("/send", response_model=ChatResponse)
async def send_message(message: ChatMessage, current_user: dict = Depends(get_current_user)):
    """
    Envoie un message et reçoit une réponse du système
    """
    try:
        # Log pour débuggage
        logger.info(f"Message reçu: {message.message} pour l'utilisateur {current_user['uid']}")
        
        # Obtenir l'instance Firestore
        db = get_firestore_client()
        user_id = current_user['uid']
        
        # Traiter le message avec notre chatbot
        chatbot_response = process_input(message.message, user_id)
        
        # Si la réponse est un str (cas gestion d'état), l'envelopper dans un dict
        if isinstance(chatbot_response, str):
            chatbot_response = {"text": chatbot_response}
        
        # Construire la réponse à afficher
        response_content = ""
        
        if chatbot_response.get("polite_response"):
            response_content = chatbot_response["polite_response"]
        elif chatbot_response.get("correction"):
            correction = chatbot_response["correction"]
            response_content = f"Correction: {correction['corrected']}\n\nExplications:\n"
            for expl in correction["explanations"]:
                response_content += f"- {expl}\n"
        elif chatbot_response.get("search_result"):
            response_content = chatbot_response["search_result"]
        else:
            response_content = chatbot_response.get("text", "Je suis votre assistant d'apprentissage d'anglais. Comment puis-je vous aider?")
        
        # Ajouter des suggestions si disponibles
        if chatbot_response.get("suggestions"):
            response_content += "\n\n" + "\n".join(chatbot_response["suggestions"])
        
        # Enregistrer le message de l'utilisateur
        chat_history_ref = db.collection('chat_history').document(user_id).collection('messages')
        chat_history_ref.add({
            'content': message.message,
            'role': 'user',
            'timestamp': firestore.SERVER_TIMESTAMP
        })
        
        # Enregistrer la réponse du système
        chat_history_ref.add({
            'content': response_content,
            'role': 'assistant',
            'timestamp': firestore.SERVER_TIMESTAMP
        })
        
        # Log pour débuggage
        logger.info(f"Réponse générée: {response_content[:100]}...")
        
        return {
            "response": response_content,
            "success": True
        }
    except Exception as e:
        logger.error(f"Error in send_message: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de l'envoi du message: {str(e)}"
        )

@router.get("/history")
async def get_chat_history(current_user: dict = Depends(get_current_user)):
    """
    Récupère l'historique des conversations de l'utilisateur
    """
    try:
        # Obtenir l'instance Firestore
        db = get_firestore_client()
        user_id = current_user['uid']
        
        # Récupérer les messages depuis Firestore, limités aux 50 derniers messages et triés par date
        chat_history_ref = db.collection('chat_history').document(user_id).collection('messages')
        messages = chat_history_ref.order_by('timestamp', direction=firestore.Query.DESCENDING).limit(50).get()
        
        # Convertir les résultats en une liste formatée
        history = []
        for msg in messages:
            msg_data = msg.to_dict()
            history.append({
                'id': msg.id,
                'content': msg_data.get('content', ''),
                'role': msg_data.get('role', 'user'),
                'timestamp': msg_data.get('timestamp')
            })
        
        # Inverser pour obtenir l'ordre chronologique
        history.reverse()
        
        return {
            "messages": history,
            "success": True
        }
    except Exception as e:
        logger.error(f"Error in get_chat_history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la récupération de l'historique: {str(e)}"
        )

@router.delete("/clear-history")
async def clear_chat_history(current_user: dict = Depends(get_current_user)):
    """
    Efface l'historique des conversations de l'utilisateur
    """
    try:
        # Obtenir l'instance Firestore
        db = get_firestore_client()
        user_id = current_user['uid']
        
        # Récupérer tous les messages de l'utilisateur
        chat_history_ref = db.collection('chat_history').document(user_id).collection('messages')
        messages = chat_history_ref.get()
        
        # Supprimer chaque message
        for msg in messages:
            msg.reference.delete()
        
        return {
            "success": True,
            "message": "Historique de conversation effacé avec succès"
        }
    except Exception as e:
        logger.error(f"Error in clear_chat_history: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de la suppression de l'historique: {str(e)}"
        )

@router.post("/feedback")
async def submit_feedback(message_id: str = Form(...), feedback_type: str = Form(...), 
                         feedback_content: Optional[str] = Form(None), 
                         current_user: dict = Depends(get_current_user)):
    """
    Soumet un feedback sur une réponse spécifique
    """
    try:
        # Obtenir l'instance Firestore
        db = get_firestore_client()
        user_id = current_user['uid']
        
        # Créer une entrée de feedback
        feedback_data = {
            'message_id': message_id,
            'feedback_type': feedback_type,  # e.g., "helpful", "not_helpful", "incorrect", etc.
            'feedback_content': feedback_content,
            'user_id': user_id,
            'timestamp': firestore.SERVER_TIMESTAMP
        }
        
        # Stocker le feedback
        db.collection('feedback').add(feedback_data)
        
        return {
            "success": True,
            "message": "Feedback envoyé avec succès"
        }
    except Exception as e:
        logger.error(f"Error in submit_feedback: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erreur lors de l'envoi du feedback: {str(e)}"
        )

# Import pour firestore.SERVER_TIMESTAMP
from firebase_admin import firestore 