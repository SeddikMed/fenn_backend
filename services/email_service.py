import os
import logging
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from pydantic import EmailStr
from typing import List

# Configuration du logging
logger = logging.getLogger(__name__)

# Récupérer les paramètres depuis les variables d'environnement
# Configuration pour Elastic Email
EMAIL_HOST = os.getenv("EMAIL_HOST", "smtp.elasticemail.com")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", "2525"))
EMAIL_USERNAME = os.getenv("EMAIL_USERNAME", "mohamedseddikbacha@gmail.com")
EMAIL_PASSWORD = os.getenv("EMAIL_PASSWORD", "586357A6C171963ABDB4618EEAEDAE0D0D97A148CA500A9EA2E9CD65A65630835D9CD81E0C2700A553C494A34E74DF82")
EMAIL_FROM = os.getenv("EMAIL_FROM", "mohamedseddikbacha@gmail.com")
EMAIL_FROM_NAME = os.getenv("EMAIL_FROM_NAME", "Fenn App")

# Vérifier si les variables essentielles sont définies
if not all([EMAIL_USERNAME, EMAIL_PASSWORD]):
    logger.warning("Les variables d'environnement EMAIL_USERNAME et/ou EMAIL_PASSWORD ne sont pas définies")

# Configuration de FastMail
conf = ConnectionConfig(
    MAIL_USERNAME=EMAIL_USERNAME,
    MAIL_PASSWORD=EMAIL_PASSWORD,
    MAIL_FROM=EMAIL_FROM,
    MAIL_PORT=EMAIL_PORT,
    MAIL_SERVER=EMAIL_HOST,
    MAIL_FROM_NAME=EMAIL_FROM_NAME,
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True
)

# Initialiser FastMail
try:
    fastmail = FastMail(conf)
    logger.info(f"Service email configuré avec succès : {EMAIL_HOST}:{EMAIL_PORT}")
except Exception as e:
    logger.error(f"Erreur lors de l'initialisation du service email : {str(e)}")
    fastmail = None

async def send_password_reset_email(email: EmailStr, reset_link: str) -> bool:
    """
    Envoie un email de réinitialisation de mot de passe
    
    Args:
        email (EmailStr): Email du destinataire
        reset_link (str): Lien de réinitialisation du mot de passe
    
    Returns:
        bool: True si l'email a été envoyé avec succès, False sinon
    """
    try:
        # Créer le contenu HTML de l'email
        html_content = f"""
        <html>
        <head>
            <title>Réinitialisation de votre mot de passe Fenn</title>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #4A90E2; color: white; padding: 10px 20px; text-align: center; }}
                .content {{ padding: 20px; }}
                .button {{ display: inline-block; background-color: #4A90E2; color: white; text-decoration: none; 
                          padding: 10px 20px; border-radius: 5px; margin: 20px 0; }}
                .footer {{ font-size: 12px; color: #888; text-align: center; margin-top: 30px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Fenn App</h1>
                </div>
                <div class="content">
                    <h2>Réinitialisation de votre mot de passe</h2>
                    <p>Bonjour,</p>
                    <p>Vous avez demandé à réinitialiser votre mot de passe pour votre compte Fenn.</p>
                    <p>Cliquez sur le bouton ci-dessous pour définir un nouveau mot de passe :</p>
                    <p><a href="{reset_link}" class="button">Réinitialiser mon mot de passe</a></p>
                    <p>Si vous n'avez pas demandé à réinitialiser votre mot de passe, vous pouvez ignorer cet email.</p>
                    <p>Le lien de réinitialisation est valable pendant 1 heure.</p>
                    <p>Si le bouton ne fonctionne pas, vous pouvez copier et coller ce lien dans votre navigateur :</p>
                    <p>{reset_link}</p>
                    <p>Cordialement,<br>L'équipe Fenn</p>
                </div>
                <div class="footer">
                    <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        # Configuration du message
        message = MessageSchema(
            subject="Réinitialisation de votre mot de passe Fenn",
            recipients=[email],
            body=html_content,
            subtype=MessageType.html
        )
        
        # Envoi de l'email
        await fastmail.send_message(message)
        logger.info(f"Email de réinitialisation envoyé à {email}")
        return True
        
    except Exception as e:
        logger.error(f"Erreur lors de l'envoi de l'email de réinitialisation à {email}: {str(e)}")
        return False

async def send_password_reset_success_email(email: EmailStr) -> bool:
    """
    Envoie un email de confirmation après une réinitialisation de mot de passe réussie
    
    Args:
        email (EmailStr): Email du destinataire
    
    Returns:
        bool: True si l'email a été envoyé avec succès, False sinon
    """
    try:
        # Créer le contenu HTML de l'email
        html_content = f"""
        <html>
        <head>
            <title>Confirmation de réinitialisation de mot de passe Fenn</title>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #4A90E2; color: white; padding: 10px 20px; text-align: center; }}
                .content {{ padding: 20px; }}
                .success {{ color: #28a745; }}
                .footer {{ font-size: 12px; color: #888; text-align: center; margin-top: 30px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>Fenn App</h1>
                </div>
                <div class="content">
                    <h2 class="success">Mot de passe modifié avec succès</h2>
                    <p>Bonjour,</p>
                    <p>Votre mot de passe a été modifié avec succès.</p>
                    <p>Si vous n'êtes pas à l'origine de cette action, veuillez immédiatement nous contacter.</p>
                    <p>Cordialement,<br>L'équipe Fenn</p>
                </div>
                <div class="footer">
                    <p>Cet email a été envoyé automatiquement. Merci de ne pas y répondre.</p>
                </div>
            </div>
        </body>
        </html>
        """
        
        # Configuration du message
        message = MessageSchema(
            subject="Confirmation de réinitialisation de mot de passe Fenn",
            recipients=[email],
            body=html_content,
            subtype=MessageType.html
        )
        
        # Envoi de l'email
        await fastmail.send_message(message)
        logger.info(f"Email de confirmation de réinitialisation envoyé à {email}")
        return True
        
    except Exception as e:
        logger.error(f"Erreur lors de l'envoi de l'email de confirmation à {email}: {str(e)}")
        return False 