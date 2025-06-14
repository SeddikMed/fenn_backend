from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import logging
import sys
import traceback
from pathlib import Path
from dotenv import load_dotenv

# Configuration du logging - Augmenter le niveau de détail
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Afficher des informations sur l'environnement Python
logger.info(f"Python version: {sys.version}")
logger.info(f"Current working directory: {os.getcwd()}")
logger.info(f"PYTHONPATH: {sys.path}")

# Chargement des variables d'environnement
load_dotenv()
logger.info("Environnement variables loaded")

# Import du service Firebase centralisé
try:
    logger.info("Attempting to import Firebase service with absolute import")
    from backend.app.services.firebase import initialize_firebase
except ImportError as e:
    logger.warning(f"Absolute import failed: {e}")
    # Fallback pour les imports relatifs
    try:
        logger.info("Trying relative import for Firebase")
        from .services.firebase import initialize_firebase
    except ImportError as e:
        logger.error(f"Both import methods failed for Firebase: {e}")
        logger.error(traceback.format_exc())
        raise

# Import des routeurs
try:
    logger.info("Attempting to import routes with absolute import")
    from backend.app.routes import auth, users, chat
except ImportError as e:
    logger.warning(f"Absolute import failed for routes: {e}")
    # Fallback pour les imports relatifs si nécessaire
    try:
        logger.info("Trying relative import for routes")
        from .routes import auth, users, chat
    except ImportError as e:
        logger.error(f"Both import methods failed for routes: {e}")
        logger.error(traceback.format_exc())
        raise

logger.info("All imports completed successfully")

# Initialisation de l'application FastAPI
logger.info("Creating FastAPI application...")
app = FastAPI(
    title="Fenn API",
    description="API Backend pour l'application Fenn d'apprentissage d'anglais",
    version="1.0.0"
)

# Configuration CORS pour permettre les requêtes depuis l'application Flutter
logger.info("Adding CORS middleware...")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # En production, spécifiez les domaines autorisés
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialiser Firebase Admin SDK
try:
    logger.info("Initializing Firebase...")
    initialize_firebase()
    logger.info("Firebase initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Firebase: {e}")
    logger.error(traceback.format_exc())
    # En développement, vous pouvez continuer sans Firebase
    # En production, vous devriez probablement lever une exception

# Dossier pour stocker les fichiers uploadés
UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)
logger.info(f"Upload directory created at: {UPLOAD_DIR.absolute()}")

# Inclure les routeurs - VERSION SIMPLIFIÉE POUR DIAGNOSTIQUER LE PROBLÈME
logger.info("Registering routes (SIMPLIFIED VERSION)...")
try:
    # Commenter temporairement les routeurs potentiellement problématiques
    app.include_router(auth.router)
    logger.info("Auth router registered")
    
    # Commenter le routeur users pour voir si c'est lui qui cause le problème
    # app.include_router(users.router)
    # logger.info("Users router registered")
    
    # Décommentons le routeur chat
    app.include_router(chat.router)
    logger.info("Chat router registered")
except Exception as e:
    logger.error(f"Error registering routes: {e}")
    logger.error(traceback.format_exc())
    raise

# Point de terminaison pour vérifier que l'API est en cours d'exécution
@app.get("/", tags=["Root"])
async def root():
    logger.info("Root endpoint called!")
    return {
        "message": "Bienvenue sur l'API Fenn",
        "version": "1.0.0",
        "status": "online"
    }

# Point de terminaison de test simple sans authentification
@app.get("/test", tags=["Test"])
async def test_endpoint():
    logger.info("Test endpoint called!")
    return {
        "status": "success",
        "message": "API Fenn fonctionnelle"
    }

logger.info("API startup complete, ready to accept requests")

# Ajouter un gestionnaire d'événements pour intercepter l'arrêt
@app.on_event("shutdown")
async def shutdown_event():
    logger.warning("Application is shutting down! This might be unexpected.")
    logger.warning(traceback.format_exc())

if __name__ == "__main__":
    import uvicorn
    # Pour le développement local uniquement
    logger.info("Starting development server...")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

