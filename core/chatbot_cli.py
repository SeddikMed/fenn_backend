import os
import json
from typing import List, Dict
from transformers import pipeline
from langdetect import detect
from deep_translator import GoogleTranslator
from sentence_transformers import SentenceTransformer
import joblib

# --- Détection de langue ---
def detect_lang(user_input: str) -> str:
    """
    Détection de la langue du texte utilisateur.

    Args:
    user_input (str): Texte utilisateur.

    Returns:
    str: Code de la langue détectée.
    """
    user_input = user_input.lower()
    darija_keywords = ["wach", "kifach", "smahli", "bghit", "ch7al", "nta", "nti", "labas", "rani", "khir", "salam", "alaykoum","wee","kirek"]
    english_keywords = ["how", "what", "can", "do", "you", "i", "my", "your", "the", "is","hello", "hi", "hey", "good morning", "good evening", "good night", "how are you"]
    if any(word in user_input for word in darija_keywords):
        return "dz"
    elif any(word in user_input for word in english_keywords):
        return "en"
    else:
        return "fr"

# --- Prédiction d'intention (exemple) ---
# (À adapter selon ton modèle réel)
vectorizer = joblib.load(os.path.join("data", "final_vectorizer.pkl"))
intent_model = joblib.load(os.path.join("data", "final_intent_model.pkl"))

def predict_intent(text: str) -> str:
    """
    Prédiction de l'intention du texte utilisateur.

    Args:
    text (str): Texte utilisateur.

    Returns:
    str: Intention prédite.
    """
    X = vectorizer.transform([text])
    return intent_model.predict(X)[0]

# --- Génération du menu principal ---
def generate_menu_text(lang: str) -> str:
    """
    Génération du menu principal.

    Args:
    lang (str): Code de la langue.

    Returns:
    str: Menu principal.
    """
    # Charger les traductions
    with open(os.path.join("data", "translations.json"), "r", encoding="utf-8") as f:
        translations = json.load(f)
    menu = [
        f"1. {translations['quiz_option'][lang]}",
        f"2. {translations['parcours_option'][lang]}",
        f"3. {translations['context_option'][lang]}",
        f"4. {translations['correction_option'][lang]}",
        f"5. {translations['progress_option'][lang]}",
        f"6. {translations['logs_option'][lang]}",
        f"7. {translations['challenge_option'][lang]}",
        f"8. {translations['revision_option'][lang]}",
        f"9. {translations['exit_option'][lang]}"
    ]
    return translations['menu_title'][lang] + "\n" + "\n".join(menu)

# --- Quiz ---
def get_quiz_data_by_lang(lang_code: str) -> list:
    """
    Récupération des données du quiz pour une langue donnée.
    """
    import os
    import json
    filename_map = {
        "fr": "quiz_by_level_no_theme.json",
        "en": "quiz_by_level_englich.json",
        "dz": "quiz_by_level_darija.json"
    }
    filename = filename_map.get(lang_code, "quiz_by_level_no_theme.json")
    filepath = os.path.join("data", filename)
    if not os.path.exists(filepath):
        raise FileNotFoundError(f"Fichier de quiz introuvable pour la langue {lang_code}: {filepath}")
    with open(filepath, "r", encoding="utf-8") as f:
        quiz_data = json.load(f)
    return quiz_data


def get_quiz_question_by_id(question_id: int, lang_code: str) -> str:
    """
    Récupération d'une question du quiz par son ID.

    Args:
    question_id (int): ID de la question.
    lang_code (str): Code de la langue.

    Returns:
    str: Question du quiz.
    """
    quiz_data = get_quiz_data_by_lang(lang_code)
    for question in quiz_data:
        if question["id"] == question_id:
            return question["question"]
    return None

def get_quiz_answer_by_id(question_id: int, lang_code: str) -> str:
    """
    Récupération d'une réponse du quiz par son ID.

    Args:
    question_id (int): ID de la question.
    lang_code (str): Code de la langue.

    Returns:
    str: Réponse du quiz.
    """
    quiz_data = get_quiz_data_by_lang(lang_code)
    for question in quiz_data:
        if question["id"] == question_id:
            return question["answer"]
    return None

# --- Correction ---
def correct_answer(user_answer: str, correct_answer: str) -> bool:
    """
    Vérification de la correction d'une réponse.

    Args:
    user_answer (str): Réponse de l'utilisateur.
    correct_answer (str): Réponse correcte.

    Returns:
    bool: True si la réponse est correcte, False sinon.
    """
    return user_answer.lower() == correct_answer.lower()

# --- Progression ---
def get_user_progress(user_id: str) -> Dict:
    """
    Récupération des données de progression d'un utilisateur.

    Args:
    user_id (str): ID de l'utilisateur.

    Returns:
    Dict: Données de progression.
    """
    # Charger les données de progression
    with open(os.path.join("data", "user_progress.json"), "r", encoding="utf-8") as f:
        user_progress = json.load(f)
    return user_progress.get(user_id, {})

def update_user_progress_cli(user_id: str, progress: Dict) -> None:
    """
    Mise à jour des données de progression d'un utilisateur.

    Args:
    user_id (str): ID de l'utilisateur.
    progress (Dict): Nouvelles données de progression.
    """
    # Charger les données de progression
    with open(os.path.join("data", "user_progress.json"), "r", encoding="utf-8") as f:
        user_progress = json.load(f)
    user_progress[user_id] = progress
    with open(os.path.join("data", "user_progress.json"), "w", encoding="utf-8") as f:
        json.dump(user_progress, f)

# --- Badges ---
def get_user_badges(user_id: str) -> List:
    """
    Récupération des badges d'un utilisateur.

    Args:
    user_id (str): ID de l'utilisateur.

    Returns:
    List: Badges de l'utilisateur.
    """
    # Charger les données de badges
    with open(os.path.join("data", "user_badges.json"), "r", encoding="utf-8") as f:
        user_badges = json.load(f)
    return user_badges.get(user_id, [])

def add_user_badge(user_id: str, badge: str) -> None:
    """
    Ajout d'un badge à un utilisateur.

    Args:
    user_id (str): ID de l'utilisateur.
    badge (str): Badge à ajouter.
    """
    # Charger les données de badges
    with open(os.path.join("data", "user_badges.json"), "r", encoding="utf-8") as f:
        user_badges = json.load(f)
    user_badges.setdefault(user_id, []).append(badge)
    with open(os.path.join("data", "user_badges.json"), "w", encoding="utf-8") as f:
        json.dump(user_badges, f)

# --- Logs ---
def get_user_logs(user_id: str) -> List:
    """
    Récupération des logs d'un utilisateur.

    Args:
    user_id (str): ID de l'utilisateur.

    Returns:
    List: Logs de l'utilisateur.
    """
    # Charger les données de logs
    with open(os.path.join("data", "user_logs.json"), "r", encoding="utf-8") as f:
        user_logs = json.load(f)
    return user_logs.get(user_id, [])

def add_user_log(user_id: str, log: str) -> None:
    """
    Ajout d'un log à un utilisateur.

    Args:
    user_id (str): ID de l'utilisateur.
    log (str): Log à ajouter.
    """
    # Charger les données de logs
    with open(os.path.join("data", "user_logs.json"), "r", encoding="utf-8") as f:
        user_logs = json.load(f)
    user_logs.setdefault(user_id, []).append(log)
    with open(os.path.join("data", "user_logs.json"), "w", encoding="utf-8") as f:
        json.dump(user_logs, f)

# --- Traduction ---
def translate_text(text: str, lang_code: str) -> str:
    """
    Traduction d'un texte.

    Args:
    text (str): Texte à traduire.
    lang_code (str): Code de la langue cible.

    Returns:
    str: Texte traduit.
    """
    translator = GoogleTranslator(source='auto', target=lang_code)
    return translator.translate(text)
