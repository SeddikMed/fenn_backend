# Backend Fenn - API Python avec FastAPI

Ce backend fournit une API RESTful pour l'application mobile Fenn d'apprentissage de langues. 
Il gère l'authentification, le stockage des données utilisateur, la progression de l'apprentissage et les fonctionnalités de chat.

## Technologies utilisées

- FastAPI: Framework API moderne et rapide
- Firebase Auth: Pour l'authentification des utilisateurs
- Firestore: Base de données NoSQL pour stocker les données
- JWT: Gestion des tokens d'authentification

## Structure du projet

```
backend/
│
├── app/
│   ├── main.py          # Point d'entrée principal de l'application
│   ├── routes/          # Modules de routes API
│   ├── models/          # Modèles de données
│   ├── services/        # Services d'application
│   └── utils/           # Fonctions utilitaires
│
├── uploads/             # Dossier pour les fichiers téléchargés
├── firebase-credentials.json  # Fichier de configuration Firebase
├── requirements.txt     # Dépendances Python
└── README.md            # Documentation
```

## Configuration

1. **Prérequis**
   - Python 3.10+
   - Un compte Firebase avec Firestore activé

2. **Configuration Firebase**
   - Créez un projet Firebase
   - Activez Firebase Authentication et Firestore
   - Générez un fichier de clés de service Firebase (`firebase-credentials.json`)
   - Placez ce fichier à la racine du dossier backend

3. **Variables d'environnement**
   Créez un fichier `.env` à la racine du projet avec les variables suivantes:

   ```
   FIREBASE_CREDENTIALS_PATH=firebase-credentials.json
   SECRET_KEY=votre-clé-secrète-pour-jwt
   ```

## Installation

1. **Créer un environnement virtuel**
   ```bash
   python -m venv venv
   source venv/bin/activate  # Sur Windows: venv\Scripts\activate
   ```

2. **Installer les dépendances**
   ```bash
   pip install -r requirements.txt
   ```

## Exécution

Pour démarrer le serveur en mode développement:
```bash
cd app
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## API Endpoints

### Authentification
- `POST /auth/register` - Inscription d'un nouvel utilisateur
- `POST /auth/login` - Connexion d'un utilisateur
- `POST /auth/reset-password` - Demande de réinitialisation de mot de passe
- `PUT /auth/password` - Changer le mot de passe
- `POST /auth/logout` - Déconnexion

### Utilisateurs
- `GET /users/me` - Récupérer le profil utilisateur
- `PUT /users/profile` - Mettre à jour le profil utilisateur
- `POST /users/upload-image` - Télécharger une image de profil
- `DELETE /users/account` - Supprimer un compte utilisateur

### Progression
- `GET /users/progress` - Récupérer la progression de l'utilisateur
- `PUT /users/progress` - Mettre à jour la progression

### Chat
- `POST /chat/message` - Envoyer un message au chatbot
- `GET /chat/history` - Récupérer l'historique des conversations

## Documentation

Une fois l'API lancée, la documentation interactive OpenAPI est disponible aux adresses:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Intégration ML pour le Chat

À l'avenir, le chatbot sera amélioré avec un modèle d'apprentissage automatique pour:
- Répondre aux questions sur la langue
- Corriger des phrases et la grammaire
- Fournir des traductions et des explications
- Adapter les réponses au niveau de l'utilisateur

# Configuration de l'envoi d'emails pour Fenn

## Prérequis
- Avoir un compte Gmail
- Activer l'authentification à deux facteurs sur votre compte Gmail

## Étape 1 : Créer un mot de passe d'application pour Gmail

1. Connectez-vous à votre compte Google
2. Accédez à la gestion de votre compte Google : https://myaccount.google.com/
3. Dans le panneau de navigation, sélectionnez "Sécurité"
4. Dans la section "Connexion à Google", sélectionnez "Validation en deux étapes" (activez-la si ce n'est pas déjà fait)
5. En bas de la page, sélectionnez "Mots de passe des applications"
6. Donnez un nom à l'application (ex. "Fenn App")
7. Cliquez sur "Créer"
8. Google vous fournira un mot de passe d'application à 16 caractères - **copiez ce mot de passe**

## Étape 2 : Configurer le fichier .env

1. Ouvrez le fichier `.env` dans le dossier `backend/`
2. Remplacez les valeurs suivantes :
   ```
   EMAIL_USERNAME=votre-adresse-gmail@gmail.com
   EMAIL_PASSWORD=votre-mot-de-passe-d-application
   ```
3. Vous pouvez également personnaliser l'adresse d'expédition et le nom de l'expéditeur :
   ```
   EMAIL_FROM=no-reply@fenn-app.com
   EMAIL_FROM_NAME=Fenn App
   ```

## Étape 3 : Tester l'envoi d'emails

1. Démarrez l'application backend avec `python run.py`
2. Utilisez la fonctionnalité "Mot de passe oublié" dans l'application
3. Vérifiez les logs pour vous assurer qu'il n'y a pas d'erreurs d'envoi d'email
4. Vérifiez votre boîte de réception pour confirmer la réception de l'email

## Dépannage

Si vous rencontrez des problèmes pour envoyer des emails :

1. Vérifiez que votre mot de passe d'application est correctement copié dans le fichier `.env`
2. Assurez-vous que l'authentification à deux facteurs est activée sur votre compte Gmail
3. Vérifiez si Gmail n'a pas bloqué l'envoi d'emails depuis des applications moins sécurisées
4. Consultez les logs de l'application pour voir les erreurs spécifiques
5. Si Gmail bloque les connexions, allez dans votre compte et confirmez que vous êtes bien à l'origine de la tentative de connexion

## Utilisation en production

Pour un environnement de production, il est recommandé d'utiliser :
- Un service d'email dédié comme SendGrid, Mailgun ou Amazon SES
- Un domaine d'email vérifié pour éviter que vos emails ne soient marqués comme spam
- Des certificats SSL/TLS valides
- Un serveur SMTP dédié avec des limites d'envoi plus élevées 