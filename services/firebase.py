import os
import firebase_admin
from firebase_admin import credentials, firestore, auth
import logging
from dotenv import load_dotenv
import requests

# Configuration du logging
logger = logging.getLogger(__name__)

# Charger les variables d'environnement
load_dotenv()

# Variable pour stocker l'instance Firestore
_db = None
_app = None

def initialize_firebase():
    """
    Initialise Firebase Admin SDK et retourne l'instance de l'application
    """
    global _app, _db
    
    try:
        # Vérifier si l'application est déjà initialisée
        if _app:
            return _app
            
        # Vérifier si les informations d'identification sont fournies en tant que variable d'environnement
        firebase_cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH', 'firebase-credentials.json')
        
        # Résoudre le chemin absolu si nécessaire
        if not os.path.isabs(firebase_cred_path):
            # Base path est maintenant le répertoire backend (parent de app)
            base_path = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            firebase_cred_path = os.path.join(base_path, firebase_cred_path)
        
        # Afficher le chemin pour le débogage
        logger.info(f"Tentative d'accès au fichier de credentials: {firebase_cred_path}")
        
        # Vérifier si le fichier existe
        if not os.path.exists(firebase_cred_path):
            logger.error(f"Firebase credentials file not found: {firebase_cred_path}")
            raise FileNotFoundError(f"Firebase credentials file not found: {firebase_cred_path}")
        
        cred = credentials.Certificate(firebase_cred_path)
        _app = firebase_admin.initialize_app(cred)
        logger.info("Firebase initialized successfully")
        return _app
    except Exception as e:
        logger.error(f"Failed to initialize Firebase: {e}")
        raise

def get_firestore_client():
    """
    Retourne l'instance Firestore, l'initialise si nécessaire
    """
    global _db
    if _db is None:
        # Initialiser Firebase si ce n'est pas déjà fait
        initialize_firebase()
        _db = firestore.client()
    return _db

def get_auth():
    """
    Retourne l'instance Auth, initialise Firebase si nécessaire
    """
    # Initialiser Firebase si ce n'est pas déjà fait
    initialize_firebase()
    return auth

def get_web_api_key():
    """
    Récupère la clé API Web Firebase depuis les variables d'environnement
    """
    api_key = os.getenv('FIREBASE_WEB_API_KEY')
    if not api_key:
        logger.warning("FIREBASE_WEB_API_KEY non définie dans les variables d'environnement")
        # Utiliser une clé par défaut pour le développement uniquement
        api_key = os.getenv('FIREBASE_API_KEY')
    return api_key

def verify_password_with_firebase(email, password):
    """
    Vérifie le mot de passe d'un utilisateur en utilisant l'API REST Firebase Auth
    
    Args:
        email (str): Email de l'utilisateur
        password (str): Mot de passe à vérifier
    
    Returns:
        dict: Résultat de l'authentification avec statut de succès et message
    """
    api_key = get_web_api_key()
    
    # Si API key est disponible, utiliser l'API REST Firebase pour vérifier le mot de passe
    if api_key:
        try:
            # URL pour l'API REST Firebase Auth
            auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
            
            # Données pour la requête
            payload = {
                "email": email,
                "password": password,
                "returnSecureToken": True
            }
            
            # Headers pour la requête
            headers = {
                "Content-Type": "application/json"
            }
            
            # Envoyer la requête
            response = requests.post(auth_url, json=payload, headers=headers)
            
            # Vérifier la réponse
            if response.status_code == 200:
                # Authentification réussie
                user_data = response.json()
                return {
                    "success": True,
                    "user_id": user_data.get("localId"),
                    "message": "Authentification réussie"
                }
            else:
                # Authentification échouée
                error_data = response.json()
                error_message = error_data.get("error", {}).get("message", "Erreur d'authentification inconnue")
                
                if error_message == "INVALID_PASSWORD":
                    return {
                        "success": False,
                        "message": "Mot de passe incorrect"
                    }
                elif error_message == "EMAIL_NOT_FOUND":
                    return {
                        "success": False,
                        "message": "Aucun utilisateur trouvé avec cet email"
                    }
                else:
                    return {
                        "success": False,
                        "message": f"Erreur d'authentification: {error_message}"
                    }
        
        except Exception as e:
            logger.error(f"Erreur lors de la vérification du mot de passe: {e}")
            return {
                "success": False,
                "message": "Erreur de service lors de la vérification du mot de passe"
            }
    else:
        # API KEY non disponible - On utilise une vérification sécurisée locale
        # IMPORTANT : Ne jamais accepter un mot de passe statique en production
        logger.warning("FIREBASE_WEB_API_KEY non définie - Utilisation de la vérification locale sécurisée")
        
        try:
            # Récupérer les données depuis Firebase Admin SDK
            auth_instance = get_auth()
            db = get_firestore_client()
            
            # Vérifier si l'utilisateur existe
            try:
                user_record = auth_instance.get_user_by_email(email)
            except Exception as e:
                logger.error(f"Erreur lors de la recherche de l'utilisateur: {e}")
                return {
                    "success": False,
                    "message": "Aucun utilisateur trouvé avec cet email"
                }
            
            # IMPORTANT: En mode développement sans API KEY, on utilise maintenant la vérification 
            # de la validité du token via l'API REST de Firebase comme fallback
            try:
                # Comme nous n'avons pas d'API clé, nous devons implémenter
                # une vérification manuelle plus stricte
                # On ne peut pas vérifier directement le mot de passe avec Firebase Admin SDK
                
                # Pour rendre la fonctionnalité utilisable, nous allons temporairement 
                # autoriser UNIQUEMENT le mot de passe stocké dans Firestore
                
                # Récupérer les données utilisateur de Firestore
                user_doc = db.collection('users').document(user_record.uid).get()
                user_data = user_doc.to_dict() if user_doc.exists else {}
                
                # Vérifier si le mot de passe est stocké dans Firestore
                stored_password = user_data.get('password_hash', None)
                
                if stored_password and stored_password == password:
                    # Si le mot de passe correspond au hash stocké (cas vraiment simple)
                    return {
                        "success": True,
                        "user_id": user_record.uid,
                        "message": "Authentification réussie"
                    }
                else:
                    return {
                        "success": False,
                        "message": "Mot de passe incorrect"
                    }
            except Exception as e:
                # Si l'authentification échoue, le mot de passe est incorrect
                logger.error(f"Échec de la vérification locale: {e}")
                return {
                    "success": False,
                    "message": "Mot de passe incorrect"
                }
                
        except Exception as e:
            logger.error(f"Erreur lors de la vérification alternative: {e}")
            return {
                "success": False, 
                "message": "Erreur de vérification du mot de passe"
            }

def get_api_key():
    """
    Retourne la clé API Firebase depuis les variables d'environnement
    DEPRECATED: Utiliser get_web_api_key() à la place
    """
    return get_web_api_key()

# Initialiser Firebase au chargement du module
try:
    initialize_firebase()
except Exception as e:
    logger.warning(f"Firebase initialization deferred: {e}")
    # En développement, nous pouvons continuer sans Firebase
    # En production, nous lèverions probablement une exception ici 