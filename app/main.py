from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
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
    from app.services.firebase import initialize_firebase
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
    from app.routes import auth, users, chat
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
from fastapi.security import HTTPBearer
from fastapi.openapi.models import APIKey, APIKeyIn, SecuritySchemeType
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="Fenn API",
    description="API Backend pour l'application Fenn d'apprentissage d'anglais",
    version="1.0.0",
    swagger_ui_init_oauth={},
    openapi_tags=[],
    openapi_url="/openapi.json",
)

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
    )
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT"
        }
    }
    for path in openapi_schema["paths"].values():
        for method in path.values():
            method.setdefault("security", []).append({"BearerAuth": []})
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi


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

# Monter le dossier uploads pour accéder aux images téléchargées
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
logger.info(f"Static files directory for uploads mounted at: /uploads")

# Dossier pour les fichiers statiques
STATIC_DIR = Path(__file__).parent / "static"
if STATIC_DIR.exists():
    logger.info(f"Mounting static files directory: {STATIC_DIR}")
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
else:
    logger.warning(f"Static directory does not exist: {STATIC_DIR}")

# Inclure les routeurs - VERSION SIMPLIFIÉE POUR DIAGNOSTIQUER LE PROBLÈME
logger.info("Registering routes (SIMPLIFIED VERSION)...")
try:
    # Commenter temporairement les routeurs potentiellement problématiques
    app.include_router(auth.router)
    logger.info("Auth router registered")
    
    # Décommenter le routeur users pour activer les fonctionnalités de profil
    app.include_router(users.router)
    logger.info("Users router registered")
    
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

@app.get("/debug/routes")
async def list_routes():
    """Liste toutes les routes disponibles pour debug"""
    return [
        {"path": route.path, "methods": list(route.methods), "name": route.name}
        for route in app.routes if hasattr(route, 'methods') and hasattr(route, 'path')
    ]

if __name__ == "__main__":
    import uvicorn
    logger.info("Starting development server...")
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
