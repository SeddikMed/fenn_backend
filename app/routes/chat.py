from fastapi import APIRouter, HTTPException
from app.models.chat_models import ChatRequest, ChatResponse
from app.core.chatbot_adapter import process_api_input
from app.core.session_manager import get_session, save_session
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

@router.post("/chat/send", response_model=ChatResponse)
async def send_message(request: ChatRequest):
    """
    Endpoint principal pour le chatbot (POST /chat/send)
    """
    try:
        logger.info(f"Message reçu: {request.user_input} pour l'utilisateur {request.user_id}")
        session_data = get_session(request.user_id)
        result = process_api_input(
            user_input=request.user_input,
            user_id=request.user_id,
            session_data=session_data
        )
        updated_session = result.get("session_data", session_data)
        save_session(request.user_id, updated_session)
        # Gestion spéciale pour l'activation (messages multiples)
        if "messages" in result:
            # Concatène les textes des messages pour compatibilité Flutter
            text = "\n".join([m["text"] for m in result["messages"]])
            response_data = ChatResponse(
                text=text,
                type=result.get("type", "activation"),
                session_data=updated_session,
                suggestions=result.get("suggestions", []),
                data=result.get("data", {})
            )
        else:
            response_data = ChatResponse(
                text=result["text"],
                type=result.get("type", "text"),
                session_data=updated_session,
                suggestions=result.get("suggestions", []),
                data=result.get("data", {})
            )
        logger.info(f"Réponse envoyée: {response_data.model_dump()}")
        return response_data
    except Exception as e:
        import traceback
        logger.error(f"Erreur dans send_message: {e}")
        logger.error(traceback.format_exc())  # Ajoute la stacktrace complète dans les logs
        return ChatResponse(
            text="Désolé, une erreur s'est produite. Veuillez réessayer.",
            type="error",
            session_data={},
            suggestions=["Réessayer", "Menu principal"],
            data={"error": str(e)}
        )


@router.get("/test")
async def test_endpoint():
    """
    Simple endpoint de test pour vérifier la connexion
    """
    return {"status": "success", "message": "API Chatbot fonctionnelle"}

from fastapi import Depends
from app.core.auth import get_current_user

@router.get("/chat/history")
async def chat_history(current_user: dict = Depends(get_current_user)):
    """
    Retourne l'historique de session pour l'utilisateur authentifié (basé sur _sessions en mémoire).
    """
    import logging
    from app.core.session_manager import get_session
    logger = logging.getLogger("app.routes.chat")
    try:
        user_id = current_user["uid"]
        logger.info(f"Récupération historique pour utilisateur: {user_id}")
        session = get_session(user_id)
        history = session.get('history', [])
        return {"messages": history}
    except Exception as e:
        logger.error(f"Erreur dans get_chat_history: {e}")
        return {"messages": []}

@router.get("/chat/health")
async def chat_health():
    """Route de test pour vérifier que le chatbot fonctionne"""
    return {"status": "ok", "message": "Chatbot is running"}
