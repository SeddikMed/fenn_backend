import json
import random
import re
import os
import unicodedata
from pathlib import Path
from transformers import pipeline
from langdetect import detect
from deep_translator import GoogleTranslator
import joblib
import logging

# Initialisation du logger
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)

# Chemin absolu du dossier racine du projet
PROJECT_ROOT = Path(__file__).resolve().parents[4]
DATA_DIR = PROJECT_ROOT / "data"
MODEL_DIR = Path(__file__).resolve().parents[2] / "data" / "chatbot"

# Gestion de session utilisateur en mémoire
user_sessions = {}

# Etats possibles : 'inactive', 'waiting_language', 'main_menu', 'in_module'
# Structure : user_sessions[user_id] = {'state': ..., 'language': ..., ...}

# Liste des salutations reconnues pour activer le bot
ACTIVATION_GREETINGS = [
    'salut fenn', 'hello fenn', 'coucou fenn', 'hi fenn', 'hey fenn', 'bonjour fenn', 'salam fenn'
]

def is_greeting(text):
    t = text.strip().lower()
    return any(t.startswith(greet) for greet in ACTIVATION_GREETINGS)

# Fonction utilitaire pour charger un fichier JSON depuis DATA_DIR
def load_json_data(filename):
    filepath = DATA_DIR / filename
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        logger.error(f"Erreur lors du chargement de {filename} : {str(e)}")
        return {}

# Chargement centralisé de toutes les données
quiz_data_fr = load_json_data("quiz_by_level_no_theme.json")
quiz_data_en = load_json_data("quiz_by_level_english.json")
quiz_data_ar = load_json_data("quiz_by_level_darija.json")
context_data_main = load_json_data("enriched_contexts_with_martyrs.json")
context_data_extra = load_json_data("contexts.json")
recettes_data = load_json_data("recettes_algeriennes_etapes_detaillees_complet.json")
translations = load_json_data("translations.json")
progress_data = load_json_data("progress_tracker.json")
badges_data = load_json_data("badges.json")
intents_data = load_json_data("intent_dataset_enriched.json")

# --- Fonction utilitaire pour poser une question de quiz au bon niveau, dans l'ordre du fichier JSON ---
def ask_quiz_question(user_id):
    session = user_sessions.get(user_id)
    lang = session.get('language', 'fr')
    level = session.get('quiz_level', 'beginner')
    quiz_data = quiz_data_fr if lang == 'fr' else quiz_data_en if lang == 'en' else quiz_data_ar
    questions = quiz_data.get(level, [])
    if not questions:
        if lang == 'fr':
            return "Aucune question disponible pour ce niveau."
        elif lang == 'en':
            return "No questions available for this level."
        else:
            return "لا توجد أسئلة لهذا المستوى."
    # Index de progression séquentielle
    idx = session.get('quiz_question_index', 0)
    if idx >= len(questions):
        session['state'] = 'main_menu'
        session.pop('quiz_question_index', None)
        session.pop('quiz_level', None)
        session.pop('current_quiz', None)
        user_sessions[user_id] = session
        if lang == 'fr':
            return "Tu as terminé toutes les questions de ce niveau ! Tape 'menu' pour revenir au menu principal."
        elif lang == 'en':
            return "You have finished all questions for this level! Type 'menu' to return to the main menu."
        else:
            return "أنهيت جميع أسئلة هذا المستوى! اكتب 'menu' للعودة إلى القائمة الرئيسية."
    question_data = questions[idx]
    session['quiz_question_index'] = idx + 1
    session['current_quiz'] = question_data if 'options' in question_data else {
        'question': question_data['question'],
        'options': {chr(65+i).lower(): opt for i, opt in enumerate(question_data.get('choices', []))},
        'answer': question_data['answer'][0].lower() if isinstance(question_data['answer'], str) else question_data['answer']
    }
    user_sessions[user_id] = session
    return format_quiz_question(session['current_quiz'])

# Chargement des modèles
vectorizer = joblib.load(MODEL_DIR / "intent_vectorizer.pkl")
intent_model = joblib.load(MODEL_DIR / "intent_classifier.pkl")
grammar_corrector = pipeline('text2text-generation', model='prithivida/grammar_error_correcter_v1')

# Utilitaires

def translate(text, source='en', target='fr'):
    return GoogleTranslator(source=source, target=target).translate(text)

def rule_based_correct(sentence):
    s = sentence.lower().strip()
    original = sentence
    corrections = []
    if "i has" in s:
        sentence = sentence.replace("i has", "I have")
        corrections.append("'I' prend 'have', pas 'has'.")
    if "she go" in s:
        sentence = sentence.replace("she go", "she goes")
        corrections.append("'She' prend 'goes' au présent simple.")
    if "i am agree" in s:
        sentence = sentence.replace("i am agree", "I agree")
        corrections.append("'I agree' est correct, pas 'I am agree'.")
    if "can to" in s:
        sentence = sentence.replace("can to", "can")
        corrections.append("Après un modal (can), on ne met pas 'to'.")
    if "i am student" in s:
        sentence = sentence.replace("i am student", "I am a student")
        corrections.append("Il manque l'article 'a'.")
    if corrections:
        return {
            "original": original,
            "corrected": sentence,
            "explanations": corrections
        }
    return None

def correct_grammar_with_model(sentence):
    corrected = grammar_corrector(f"gec: {sentence}", max_length=64)[0]['generated_text']
    return corrected

def predict_intent(text):
    cleaned = re.sub(r"[^a-zA-ZÀ-ÿ0-9\s]", "", text.lower().strip())
    vect = vectorizer.transform([cleaned])
    prediction = intent_model.predict(vect)[0]
    return prediction

def start_learning_path(user_id, lang):
    # Le parcours commence toujours par le niveau débutant
    if lang == 'fr':
        return "Bienvenue dans le parcours d'apprentissage ! Tu vas commencer par le niveau débutant."
    elif lang == 'en':
        return "Welcome to the learning path! You will start with the beginner level."
    else:
        return "مرحبا بك في مسار التعلم! ستبدأ بمستوى المبتدئين."

def handle_learning_path(user_input, user_id, lang):
    session = user_sessions.get(user_id)
    if user_input.strip().lower() == 'menu':
        session['state'] = 'main_menu'
        user_sessions[user_id] = session
        return process_input('', user_id)
    # Initialisation du parcours si besoin
    if 'learning_level' not in session:
        session['learning_level'] = 0  # 0: beginner, 1: intermediate, 2: advanced
        session['learning_question_index'] = 0
        user_sessions[user_id] = session
    levels = ['beginner', 'intermediate', 'advanced']
    level_labels = {
        'fr': ['débutant', 'intermédiaire', 'avancé'],
        'en': ['beginner', 'intermediate', 'advanced'],
        'ar': ['مبتدئ', 'متوسط', 'متقدم']
    }
    lang_code = lang if lang in ['fr', 'en', 'ar'] else 'fr'
    quiz_data = quiz_data_fr if lang == 'fr' else quiz_data_en if lang == 'en' else quiz_data_ar
    # Avancer dans les questions
    current_level = levels[session['learning_level']]
    questions = quiz_data.get(current_level, [])
    idx = session['learning_question_index']
    # Vérifie la réponse précédente si ce n'est pas la première fois
    if idx > 0:
        prev_question = questions[idx-1]
        correct = False
        options = prev_question.get('options') or {chr(65+i).lower(): opt for i, opt in enumerate(prev_question.get('choices', []))}
        answer_value = prev_question['answer'].lower() if isinstance(prev_question['answer'], str) else prev_question['answer']
        # Cherche la clé (lettre) correspondant à la bonne réponse
        correct_key = None
        for k, v in options.items():
            if v.lower() == answer_value:
                correct_key = k
                break
        user_answer = user_input.strip().lower()
        correct = False
        if user_answer == answer_value or user_answer == (correct_key or '').lower():
            correct = True
        # Feedback immédiat
        if lang == 'fr':
            feedback = "Bonne réponse ! ✅" if correct else f"Incorrect. ❌ La bonne réponse était : {correct_key.upper()}) {answer_value}"
        elif lang == 'en':
            feedback = "Correct! ✅" if correct else f"Incorrect. ❌ The correct answer was: {correct_key.upper()}) {answer_value}"
        else:
            feedback = "إجابة صحيحة! ✅" if correct else f"إجابة خاطئة. ❌ الجواب الصحيح هو: {correct_key.upper()}) {answer_value}"
    else:
        feedback = ''
    # Prochaine question
    if idx < len(questions):
        question = questions[idx]
        session['learning_question_index'] += 1
        user_sessions[user_id] = session
        q_text = format_quiz_question(question)
        if feedback:
            return f"{feedback}\n\n{q_text}"
        else:
            return q_text
    else:
        # Passage au niveau suivant
        if session['learning_level'] < 2:
            session['learning_level'] += 1
            session['learning_question_index'] = 0
            user_sessions[user_id] = session
            if lang == 'fr':
                return f"Bravo, tu passes au niveau {level_labels[lang_code][session['learning_level']]} ! 🎉\nTape une réponse pour continuer."
            elif lang == 'en':
                return f"Congrats, you move to {level_labels[lang_code][session['learning_level']]} level! 🎉\nType an answer to continue."
            else:
                return f"تهانينا، انتقلت إلى مستوى {level_labels[lang_code][session['learning_level']]}! 🎉\nاكتب إجابة للمتابعة."
        else:
            # Fin du parcours
            session['state'] = 'main_menu'
            session.pop('learning_level', None)
            session.pop('learning_question_index', None)
            user_sessions[user_id] = session
            if lang == 'fr':
                return "Félicitations, tu as terminé tout le parcours d'apprentissage ! 🎓\nTape 'menu' pour revenir au menu principal."
            elif lang == 'en':
                return "Congratulations, you have completed the entire learning path! 🎓\nType 'menu' to return to the main menu."
            else:
                return "مبروك، أنهيت كل مسار التعلم! 🎓\nاكتب 'menu' للعودة إلى القائمة الرئيسية."


def start_context(user_id, lang):
    def extract_titles(contexts):
        themes = []
        for key, val in contexts.items():
            if isinstance(val, dict):
                title_fr = val.get('title', '')
                title_en = val.get('title_en', '')
                title_ar = val.get('title_ar', '')
                themes.append({'key': key, 'fr': title_fr, 'en': title_en, 'ar': title_ar})
            else:
                themes.append({'key': key, 'fr': key, 'en': key, 'ar': key})
        return themes
    all_themes = extract_titles(context_data_extra)
    if lang == 'fr':
        msg = "Bienvenue dans le module Contexte !\nVoici la liste des thèmes disponibles dans le module :\n"
        for t in all_themes:
            titre = t['fr'] or t['key']
            msg += f"- {titre}\n"
        msg += "Donne-moi un thème ou tape 'menu' pour revenir."
        return msg
    elif lang == 'en':
        msg = "Welcome to the Context module!\nHere is the list of available topics in the module:\n"
        for t in all_themes:
            titre = t['en'] or t['fr'] or t['key']
            msg += f"- {titre}\n"
        msg += "Give me a topic or type 'menu' to go back."
        return msg
    else:
        msg = "مرحبا بك في وحدة السياق!\nهذه قائمة المواضيع المتوفرة في الوحدة:\n"
        for t in all_themes:
            titre = t['ar'] or t['fr'] or t['key']
            msg += f"- {titre}\n"
        msg += "أعطني موضوعًا أو اكتب 'menu' للرجوع."
        return msg

import unicodedata

def normalize_text(text):
    # Supprime les accents et met en minuscule
    return ''.join(c for c in unicodedata.normalize('NFD', text)
                   if unicodedata.category(c) != 'Mn').lower()

def handle_context(user_input, user_id, lang):
    if user_input.strip().lower() == 'menu':
        user_sessions[user_id]['state'] = 'main_menu'
        return process_input('', user_id)
    
    theme = normalize_text(user_input.strip())
    context = None
    source = None
    # Recherche floue dans enriched_contexts_with_martyrs.json
    for key, val in context_data_main.items():
        key_norm = normalize_text(key)
        title_norm = normalize_text(val.get('title', ''))
        title_en_norm = normalize_text(val.get('title_en', ''))
        if (
            theme in key_norm or key_norm in theme or
            (title_norm and theme in title_norm) or
            (title_en_norm and theme in title_en_norm) or
            key_norm.startswith(theme) or theme.startswith(key_norm) or
            (title_norm and (theme in title_norm or title_norm in theme)) or
            (title_en_norm and (theme in title_en_norm or title_en_norm in theme))
        ):
            context = val
            source = 'main'
            break
    # Si rien trouvé, cherche dans contexts.json (toujours en recherche floue)
    if not context:
        for key, val in context_data_extra.items():
            key_norm = normalize_text(key)
            title_norm = normalize_text(val.get('title', '')) if isinstance(val, dict) else ''
            if (
                theme in key_norm or key_norm in theme or
                (title_norm and theme in title_norm) or
                key_norm.startswith(theme) or theme.startswith(key_norm) or
                (title_norm and (theme in title_norm or title_norm in theme))
            ):
                context = val
                source = 'extra'
                break
    if context:
        # Affichage enrichi pour les contextes de type vocabulaire ou liste
        title = context.get('title', key) if isinstance(context, dict) else key
        # Cas 1 : vocabulaire (champ 'words' ou 'phrases')
        vocab_key = None
        for k in ['words', 'phrases', 'vocabulaire', 'expressions']:
            if isinstance(context, dict) and k in context and isinstance(context[k], dict):
                vocab_key = k
                break
        if vocab_key:
            lines = []
            for mot, trad in context[vocab_key].items():
                if isinstance(trad, dict):
                    if lang == 'fr':
                        # Affiche la traduction anglaise pour chaque expression française
                        en_val = trad.get('en', '-')
                        if isinstance(en_val, list):
                            en_val = ', '.join(str(x) for x in en_val)
                        lines.append(f"{mot} : {en_val}")
                    elif lang == 'en':
                        # Affiche chaque expression anglaise suivie de la traduction française
                        en_val = trad.get('en', '-')
                        fr_val = trad.get('fr', '-')
                        if isinstance(en_val, list):
                            for eng in en_val:
                                lines.append(f"{eng} : {fr_val}")
                        else:
                            lines.append(f"{en_val} : {fr_val}")
                    else:
                        # Pour l'arabe ou autre, fallback comportement précédent
                        val = trad.get(lang, trad.get('fr') or trad.get('en') or trad.get('ar') or str(trad))
                        if isinstance(val, list):
                            val = ', '.join(str(x) for x in val)
                        lines.append(f"{mot} : {val}")
                elif isinstance(trad, list):
                    lines.append(f"{mot} : {', '.join(str(x) for x in trad)}")
                else:
                    lines.append(f"{mot} : {trad}")
            details = '\n'.join(lines)
        # Cas 2 : dict contenant principalement des listes ou dicts
        elif isinstance(context, dict):
            # Si pas de history/summary, mais d'autres champs list/dict
            details = context.get('history') or context.get('summary')
            if not details:
                # Cherche le premier champ list/dict non vide
                details = None
                for v in context.values():
                    if isinstance(v, (list, dict)):
                        if isinstance(v, list):
                            details = '\n'.join(str(x) for x in v)
                        elif isinstance(v, dict):
                            # Si dict multilingue, afficher la langue courante
                            lines = []
                            for k2, v2 in v.items():
                                if isinstance(v2, dict):
                                    val = v2.get(lang, v2.get('fr') or v2.get('en') or v2.get('ar') or str(v2))
                                    if isinstance(val, list):
                                        val = ' | '.join(str(x) for x in val)
                                    lines.append(f"{k2} : {val}")
                                elif isinstance(v2, list):
                                    lines.append(f"{k2} : {' | '.join(str(x) for x in v2)}")
                                else:
                                    lines.append(f"{k2} : {v2}")
                            details = '\n'.join(lines)
                        break
            if not details:
                # Fallback : premier champ texte
                details = next((v for v in context.values() if isinstance(v, str)), str(context))
        else:
            details = str(context)
        if lang == 'fr':
            return f"{title} :\n{details}"
        elif lang == 'en':
            return f"{title} :\n{details}"
        else:
            return f"{title} :\n{details}"
    else:
        # Fallback : matching avec les exemples de l'intent 'chat_context'
        chat_context_examples = []
        for intent in intents_data.get('intents', []):
            if intent.get('label') == 'chat_context':
                chat_context_examples = intent.get('examples', [])
                break
        user_input_norm = normalize_text(user_input.strip())
        found_similar = any(normalize_text(ex) == user_input_norm or user_input_norm in normalize_text(ex) or normalize_text(ex) in user_input_norm for ex in chat_context_examples)
        if found_similar:
            if lang == 'fr':
                return "Bien sûr ! Donne-moi un mot-clé ou un thème précis (ex : indépendance, histoire, guerre, etc.) et je te raconte ce que je sais."
            elif lang == 'en':
                return "Of course! Give me a keyword or a specific topic (e.g. independence, history, war, etc.) and I'll tell you what I know."
            else:
                return "بالطبع! أعطني كلمة مفتاحية أو موضوعا محددا (مثلا: الاستقلال، التاريخ، الحرب...) وسأخبرك بما أعرف."
        # Si toujours rien trouvé, propose une liste de thèmes disponibles
        available_themes = list(context_data_main.keys()) + list(context_data_extra.keys())
        themes_display = ', '.join(sorted(set(available_themes))[:12]) + (', ...' if len(available_themes) > 12 else '')
        if lang == 'fr':
            return f"Désolé, je n'ai pas trouvé de contexte pour le thème '{user_input}'.\nVoici quelques thèmes disponibles : {themes_display}"
        elif lang == 'en':
            return f"Sorry, I couldn't find any context for topic '{user_input}'.\nHere are some available topics: {themes_display}"
        else:
            return f"عذرا، لم أجد سياقا للموضوع '{user_input}'.\nهذه بعض المواضيع المتوفرة: {themes_display}"

def start_grammar_correction(user_id, lang):
    if lang == 'fr':
        return "Envoie-moi une phrase à corriger, ou tape 'menu' pour revenir."
    elif lang == 'en':
        return "Send me a sentence to correct, or type 'menu' to go back."
    else:
        return "أرسل لي جملة لتصحيحها أو اكتب 'menu' للرجوع."

def handle_grammar_correction(user_input, user_id, lang):
    if user_input.strip().lower() == 'menu':
        user_sessions[user_id]['state'] = 'main_menu'
        return process_input('', user_id)
    # Correction simple avec le modèle existant
    corrected = correct_grammar_with_model(user_input)
    if lang == 'fr':
        return f"Phrase corrigée : {corrected}"
    elif lang == 'en':
        return f"Corrected sentence: {corrected}"
    else:
        return f"الجملة المصححة: {corrected}"

def show_user_progress(user_id, lang):
    # Affiche la vraie progression (voir handle_progress)
    return handle_progress('', user_id, lang)

def handle_progress(user_input, user_id, lang):
    if user_input.strip().lower() == 'menu':
        user_sessions[user_id]['state'] = 'main_menu'
        return process_input('', user_id)
    # Récupère la progression de l'utilisateur
    progress = progress_data if progress_data.get('user_id') == user_id else progress_data
    total_score = progress.get('total_score', 0)
    quizzes = progress.get('quizzes', {})
    if lang == 'fr':
        details = '\n'.join([f"- {theme} : {score}" for theme, score in quizzes.items()])
        return (f"Voici ta progression :\n"
                f"Score total : {total_score}\n"
                f"Détail par thème :\n{details}\n"
                "Continue comme ça ! 🚀")
    elif lang == 'en':
        details = '\n'.join([f"- {theme} : {score}" for theme, score in quizzes.items()])
        return (f"Here is your progress:\n"
                f"Total score: {total_score}\n"
                f"By topic:\n{details}\n"
                "Keep up the good work! 🚀")
    else:
        details = '\n'.join([f"- {theme} : {score}" for theme, score in quizzes.items()])
        return (f"هاهي تقدمك :\n"
                f"المجموع الكلي : {total_score}\n"
                f"تفصيل حسب الموضوع :\n{details}\n"
                "واصل العمل الجيد! 🚀")

def show_user_logs(user_id, lang):
    # Historique simulé : à remplacer par un vrai suivi si besoin
    logs = [
        {"date": "2025-06-13 16:10", "module": "Quiz", "detail": "Niveau: débutant, Score: 3/5"},
        {"date": "2025-06-13 16:15", "module": "Parcours d'apprentissage", "detail": "Terminé: niveau débutant"},
        {"date": "2025-06-13 16:20", "module": "Correction grammaticale", "detail": "Phrase corrigée: 'He go to school' → 'He goes to school'"},
        {"date": "2025-06-13 16:25", "module": "Progression", "detail": "Score total: 12"},
    ]
    if lang == 'fr':
        msg = "Voici ton historique récent :\n"
        for log in logs:
            msg += f"- [{log['date']}] {log['module']} : {log['detail']}\n"
        return msg
    elif lang == 'en':
        msg = "Here is your recent history:\n"
        for log in logs:
            msg += f"- [{log['date']}] {log['module']}: {log['detail']}\n"
        return msg
    else:
        msg = "هاهو سجلك الأخير :\n"
        for log in logs:
            msg += f"- [{log['date']}] {log['module']} : {log['detail']}\n"
        return msg


def handle_logs(user_input, user_id, lang):
    if user_input.strip().lower() == 'menu':
        user_sessions[user_id]['state'] = 'main_menu'
        return process_input('', user_id)
    if lang == 'fr':
        return "(Démo) Module logs : {}".format(user_input)
    elif lang == 'en':
        return "(Demo) Logs module: {}".format(user_input)
    else:
        return "(عرض) وحدة السجلات: {}".format(user_input)

import time

def start_challenge(user_id, lang):
    session = user_sessions.get(user_id, {})
    session['state'] = 'waiting_challenge_level'
    session['challenge_score'] = 0
    session['challenge_index'] = 0
    session['challenge_questions'] = []
    session['challenge_start_time'] = None
    session['challenge_question_time'] = None
    user_sessions[user_id] = session
    if lang == 'fr':
        return "Bienvenue dans le challenge ! Choisis ton niveau (débutant, intermédiaire, avancé) :"
    elif lang == 'en':
        return "Welcome to the challenge! Choose your level (beginner, intermediate, advanced):"
    else:
        return "مرحبا بك في التحدي! اختر المستوى (مبتدئ، متوسط، متقدم):"

def handle_challenge_level_selection(user_input, user_id):
    session = user_sessions.get(user_id, {})
    lang = session.get('language', 'fr')
    level_map = {
        'fr': {'débutant': 'beginner', 'intermédiaire': 'intermediate', 'avancé': 'advanced'},
        'en': {'beginner': 'beginner', 'intermediate': 'intermediate', 'advanced': 'advanced'},
        'ar': {'مبتدئ': 'beginner', 'متوسط': 'intermediate', 'متقدم': 'advanced'}
    }
    user_level = user_input.strip().lower()
    level = None
    # Recherche du niveau selon la langue
    for k, v in level_map.get(lang, {}).items():
        if user_level == k:
            level = v
            break
    if not level:
        # Accept also English levels for all
        if user_level in ['beginner','intermediate','advanced']:
            level = user_level
        else:
            if lang == 'fr':
                return "Merci de choisir : débutant, intermédiaire ou avancé."
            elif lang == 'en':
                return "Please choose: beginner, intermediate or advanced."
            else:
                return "يرجى اختيار: مبتدئ، متوسط أو متقدم."
    # Charger les données de quiz selon la langue
    quiz_data = quiz_data_fr if lang == 'fr' else quiz_data_en if lang == 'en' else quiz_data_ar
    questions = quiz_data.get(level, [])
    if not questions:
        if lang == 'fr':
            return "Aucune question disponible pour ce niveau."
        elif lang == 'en':
            return "No questions available for this level."
        else:
            return "لا توجد أسئلة لهذا المستوى."
    selected = random.sample(questions, min(5, len(questions)))
    session['challenge_questions'] = selected
    session['challenge_index'] = 0
    session['challenge_score'] = 0
    session['challenge_level'] = level
    session['state'] = 'in_challenge'
    session = user_sessions.get(user_id, {})
    lang = session.get('language', 'fr')
    idx = session.get('challenge_index', 0)
    questions = session.get('challenge_questions', [])
    max_time_global = 30
    now = time.time()
    elapsed_global = now - session.get('challenge_start_time', now)
    feedback = ''
    if idx >= len(questions):
        session['state'] = 'main_menu'
        user_sessions[user_id] = session
        if lang == 'fr':
            return "Le challenge est déjà terminé. Tape 'menu' pour revenir au menu principal."
        elif lang == 'en':
            return "The challenge is already finished. Type 'menu' to return to the main menu."
        else:
            return "لقد انتهى التحدي بالفعل. اكتب 'menu' للعودة إلى القائمة الرئيسية."
    current_q = questions[idx]
    # Vérification réponse
    correct = False
    answer_value = current_q['answer'].lower() if isinstance(current_q['answer'], str) else current_q['answer']
    options = current_q.get('options') or {chr(65+i).lower(): opt for i, opt in enumerate(current_q.get('choices', []))}
    correct_key = None
    for k, v in options.items():
        if v.lower() == answer_value:
            correct_key = k
            break
    user_answer = user_input.strip().lower()
    # Sécurisation de l'accès à la clé dans les options
    if user_answer == answer_value or user_answer == (correct_key or '').lower():
        correct = True
    elif user_answer in options:
        # Si la clé existe mais n'est pas la bonne réponse
        correct = False
    else:
        # Réponse invalide (clé inexistante)
        if lang == 'fr':
            return f"Réponse invalide. Merci de choisir parmi les options proposées : {', '.join(options.keys()).upper()}"
        elif lang == 'en':
            return f"Invalid answer. Please choose from the available options: {', '.join(options.keys()).upper()}"
        else:
            return f"إجابة غير صالحة. يرجى اختيار أحد الحروف التالية: {', '.join(options.keys()).upper()}"

    # Feedback chrono
    if elapsed_global > max_time_global:
        if lang == 'fr':
            feedback = f"⏰ Temps écoulé pour le challenge. La bonne réponse était : {correct_key.upper()}) {answer_value}\n"
        elif lang == 'en':
            feedback = f"⏰ Time's up for the challenge. The correct answer was: {correct_key.upper()}) {answer_value}\n"
        else:
            feedback = f"⏰ انتهى الوقت للتحدي. الجواب الصحيح هو: {correct_key.upper()}) {answer_value}\n"
        session['state'] = 'main_menu'
        user_sessions[user_id] = session
        if lang == 'fr':
            return f"Échec du challenge. Score : 0/5\n{feedback}Tape 'menu' pour revenir au menu principal."
        elif lang == 'en':
            return f"Challenge failed. Score: 0/5\n{feedback}Type 'menu' to return to the main menu."
        else:
            return f"فشل التحدي. النتيجة: 0/5\n{feedback}اكتب 'menu' للعودة إلى القائمة الرئيسية."
    elif not correct:
        if lang == 'fr':
            feedback = f"Incorrect. ❌ La bonne réponse était : {correct_key.upper()}) {answer_value}\n"
        elif lang == 'en':
            feedback = f"Incorrect. ❌ The correct answer was: {correct_key.upper()}) {answer_value}\n"
        else:
            feedback = f"إجابة خاطئة. ❌ الجواب الصحيح هو: {correct_key.upper()}) {answer_value}\n"
        session['state'] = 'main_menu'
        user_sessions[user_id] = session
        if lang == 'fr':
            return f"Échec du challenge. Score : 0/5\n{feedback}Tape 'menu' pour revenir au menu principal."
        elif lang == 'en':
            return f"Challenge failed. Score: 0/5\n{feedback}Type 'menu' to return to the main menu."
        else:
            return f"فشل التحدي. النتيجة: 0/5\n{feedback}اكتب 'menu' للعودة إلى القائمة الرئيسية."
    options_str = ''
    for k, v in options.items():
        options_str += f"{k.upper()}) {v}\n"
    if lang == 'fr':
        return f"⏱ Question : {q}\n{options_str}Réponds (lettre ou texte, 15s max) :"
    elif lang == 'en':
        return f"⏱ Question: {q}\n{options_str}Answer (letter or text, 15s max):"
    else:
        return f"⏱ السؤال: {q}\n{options_str}أجب (حرف أو نص، 15 ثانية كحد أقصى):"

def start_review(user_id, lang):
    if lang == 'fr':
        return "Bienvenue dans la révision ! Tape un sujet ou 'menu' pour revenir."
    elif lang == 'en':
        return "Welcome to the review! Type a topic or 'menu' to go back."
    else:
        return "مرحبا بك في المراجعة! اكتب موضوعًا أو 'menu' للرجوع."

def handle_review(user_input, user_id, lang):
    if user_input.strip().lower() == 'menu':
        user_sessions[user_id]['state'] = 'main_menu'
        return process_input('', user_id)
    if lang == 'fr':
        return "(Démo) Révision : {}".format(user_input)
    elif lang == 'en':
        return "(Demo) Review: {}".format(user_input)
    else:
        return "(عرض) المراجعة: {}".format(user_input)

def process_input(user_input, user_id="default"):
    global user_sessions
    session = user_sessions.get(user_id, {'state': 'inactive', 'language': None})
    user_input_clean = user_input.strip().lower()
    logger.info(f"[CHATBOT] user_id={user_id} | state={session['state']} | input='{user_input_clean}'")

    # 1. Etat INACTIF : attend une salutation
    if session['state'] == 'inactive':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat INACTIF | Attend salutation")
        if is_greeting(user_input_clean):
            session['state'] = 'waiting_language'
            user_sessions[user_id] = session
            logger.info(f"[CHATBOT] user_id={user_id} | Passe à l'état 'waiting_language'")
            # Directement demander la langue, sans étape intermédiaire
            return "Quelle langue veux-tu utiliser ? (français, darija, anglais)\nWhich language do you want to use? (French, Darija, English)\nأي لغة تريد أن تستعمل؟ (فرنسية، الدارجة، الإنجليزية)"
        else:
            return "Pour activer Fennlingo, commence par me saluer (exemple : 'salut fenn')."

    # 2. Attente choix explicite de la langue
    elif session['state'] == 'waiting_language':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat WAITING_LANGUAGE")
        # On vérifie la langue choisie directement
        lang_input = user_input.strip().lower()
        logger.info(f"[CHATBOT] user_id={user_id} | Langue choisie: {lang_input}")
        if lang_input in ['fr', 'français', 'francais', 'french']:
            lang = 'fr'
        elif lang_input in ['en', 'anglais', 'english']:
            lang = 'en'
        elif lang_input in ['ar', 'darija', 'arabe', 'العربية', 'الدارجة']:
            lang = 'ar'
        else:
            logger.warning(f"[CHATBOT] user_id={user_id} | Langue non reconnue: {lang_input}")
            return "Merci de préciser : français, darija ou anglais."
        session['language'] = lang
        session['state'] = 'main_menu'
        user_sessions[user_id] = session
        logger.info(f"[CHATBOT] user_id={user_id} | Passe à l'état 'main_menu' avec langue {lang}")
        if lang == 'fr':
            menu = """
Bienvenue sur Fennlingo ! Que veux-tu faire ?
1. Quiz
2. Parcours d'apprentissage
3. Contexte
4. Correction grammaticale
5. Progression
6. Logs
7. Challenge
8. Révision
9. Quitter
(Tu peux répondre par un numéro ou une phrase, ex : 'je veux un quiz')
"""
        elif lang == 'en':
            menu = """
Welcome to Fennlingo! What do you want to do?
1. Quiz
2. Learning Path
3. Context
4. Grammar Correction
5. Progress
6. Logs
7. Challenge
8. Review
9. Exit
(You can reply with a number or a sentence, e.g.: 'I want a quiz')
"""
        else:
            menu = """
مرحبا بك في Fennlingo! واش حاب تدير؟
1. كويز
2. مسار التعلم
3. السياق
4. تصحيح القواعد
5. التقدم
6. السجلات
7. التحدي
8. مراجعة
9. الخروج
(تقدر تجاوب برقم أو جملة، مثال: 'حاب كويز')
"""
        return menu

    # 3. Menu principal : attend un choix
    elif session['state'] == 'main_menu':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat MAIN_MENU")
        lang = session.get('language', 'fr')
        # Table de correspondance multilingue pour chaque choix
        choices = {
            'quiz':      ['1', 'quiz', 'اختبار', 'كويز', 'je veux un quiz', 'bghit quiz', 'i want a quiz'],
            'learning':  ['2', 'learning path', 'parcours', 'مسار التعلم', 'parcours d\'apprentissage', 'مسار', 'i want to learn', 'je veux apprendre'],
            'context':   ['3', 'context', 'سياق', 'contexte', 'contextes'],
            'grammar':   ['4', 'grammar', 'correction grammaticale', 'تصحيح القواعد', 'correct grammar', 'corrige', 'corriger'],
            'progress':  ['5', 'progress', 'progression', 'progrès', 'تقدم', 'statistiques', 'stats'],
            'logs':      ['6', 'logs', 'سجلات', 'journal'],
            'challenge': ['7', 'challenge', 'تحدي', 'défi'],
            'review':    ['8', 'review', 'مراجعة', 'révision'],
            'exit':      ['9', 'exit', 'خروج', 'quitter']
        }
        selected = None
        for key, values in choices.items():
            if user_input_clean in values:
                selected = key
                break
        if selected == 'quiz':
            session['state'] = 'in_quiz'
            user_sessions[user_id] = session
            return start_quiz(user_id)
        elif selected == 'learning':
            session['state'] = 'in_learning_path'
            user_sessions[user_id] = session
            return handle_learning_path(user_input, user_id, lang)
        elif selected == 'context':
            session['state'] = 'in_context'
            user_sessions[user_id] = session
            return start_context(user_id, lang)
        elif selected == 'grammar':
            session['state'] = 'in_grammar'
            user_sessions[user_id] = session
            return handle_grammar_correction(user_input, user_id, lang)
        elif selected == 'progress':
            session['state'] = 'in_progress'
            user_sessions[user_id] = session
            return handle_progress(user_input, user_id, lang)
        elif selected == 'logs':
            session['state'] = 'in_logs'
            user_sessions[user_id] = session
            return show_user_logs(user_id, lang)
        elif selected == 'challenge':
            session['state'] = 'in_challenge'
            user_sessions[user_id] = session
            return start_challenge(user_id, lang)
        elif selected == 'review':
            session['state'] = 'in_review'
            user_sessions[user_id] = session
            return start_review(user_id, lang)
        elif selected == 'exit':
            session['state'] = 'inactive'
            user_sessions[user_id] = session
            if lang == 'fr':
                return "À bientôt !"
            elif lang == 'en':
                return "See you soon!"
            else:
                return "إلى اللقاء!"
        else:
            # Réafficher le menu si la saisie n'est pas comprise
            if lang == 'fr':
                menu = """
Bienvenue sur Fennlingo ! Que veux-tu faire ?
1. Quiz
2. Parcours d'apprentissage
3. Contexte
4. Correction grammaticale
5. Progression
6. Logs
7. Challenge
8. Révision
9. Quitter
(Tu peux répondre par un numéro ou une phrase, ex : 'je veux un quiz')
"""
            elif lang == 'en':
                menu = """
Welcome to Fennlingo! What do you want to do?
1. Quiz
2. Learning Path
3. Context
4. Grammar Correction
5. Progress
6. Logs
7. Challenge
8. Review
9. Exit
(You can reply with a number or a sentence, e.g.: 'I want a quiz')
"""
            else:
                menu = """
مرحبا بك في Fennlingo! واش حاب تدير؟
1. كويز
2. مسار التعلم
3. السياق
4. تصحيح القواعد
5. التقدم
6. السجلات
7. التحدي
8. مراجعة
9. الخروج
(تقدر تجاوب برقم أو جملة، مثال: 'حاب كويز')
"""
            return menu


    # 4. En plein quiz ou choix du niveau
    elif session['state'] in ['in_quiz', 'waiting_quiz_level', 'in_quiz_level']:
        logger.info(f"[CHATBOT] user_id={user_id} | Etat {session['state'].upper()}")
        return handle_quiz_answer(user_input, user_id)
    elif session['state'] == 'in_learning_path':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_LEARNING_PATH")
        return handle_learning_path(user_input, user_id, session.get('language', 'fr'))
    elif session['state'] == 'in_context':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_CONTEXT")
        return handle_context(user_input, user_id, session.get('language', 'fr'))
    elif session['state'] == 'in_grammar':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_GRAMMAR")
        return handle_grammar_correction(user_input, user_id, session.get('language', 'fr'))
    elif session['state'] == 'in_progress':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_PROGRESS")
        return handle_progress(user_input, user_id, session.get('language', 'fr'))
    elif session['state'] == 'in_logs':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_LOGS")
        return handle_logs(user_input, user_id, session.get('language', 'fr'))
    elif session['state'] == 'in_challenge':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_CHALLENGE")
        return handle_challenge(user_input, user_id, session.get('language', 'fr'))
    elif session['state'] == 'in_review':
        logger.info(f"[CHATBOT] user_id={user_id} | Etat IN_REVIEW")
        return handle_review(user_input, user_id, session.get('language', 'fr'))

    else:
        logger.error(f"[CHATBOT] user_id={user_id} | Etat inconnu: {session['state']}")
        session['state'] = 'inactive'
        user_sessions[user_id] = session
        return "Erreur d'état, veuillez recommencer en saluant Fennlingo."

def format_quiz_question(question_data):
    """Formats a quiz question for display, supports both 'options' dict and 'choices' list."""
    question_text = question_data['question']
    if 'options' in question_data and isinstance(question_data['options'], dict):
        options = question_data['options']
        options_str = "\n".join([f"{key.upper()}) {value}" for key, value in options.items()])
    elif 'choices' in question_data and isinstance(question_data['choices'], list):
        options = {chr(65+i).lower(): opt for i, opt in enumerate(question_data['choices'])}
        options_str = "\n".join([f"{key.upper()}) {value}" for key, value in options.items()])
        question_data['options'] = options
    else:
        options_str = ""
    return f"{question_text}\n{options_str}"

def start_quiz(user_id):
    """Demande le niveau à l'utilisateur avant de lancer le quiz."""
    session = user_sessions.get(user_id)
    if not session:
        return "Erreur : session non trouvée."
    lang = session.get('language', 'fr')
    session['state'] = 'waiting_quiz_level'
    user_sessions[user_id] = session
    if lang == 'fr':
        return "Quel niveau veux-tu ? (débutant, intermédiaire, avancé)"
    elif lang == 'en':
        return "Which level do you want? (beginner, intermediate, advanced)"
    else:
        return "أي مستوى تريد؟ (مبتدئ، متوسط، متقدم)"

def handle_quiz_answer(user_input, user_id):
    """Gère la réponse de l'utilisateur dans le quiz, avec gestion du niveau."""
    session = user_sessions.get(user_id)
    if not session:
        session = {'state': 'main_menu'}
        user_sessions[user_id] = session
        return "Erreur de session. Retour au menu principal."
    lang = session.get('language', 'fr')
    # Gestion du choix de niveau
    if session.get('state') == 'waiting_quiz_level':
        # Normalise la saisie niveau
        niveau_input = user_input.strip().lower()
        levels = {'fr': ['débutant', 'intermédiaire', 'avancé'], 'en': ['beginner', 'intermediate', 'advanced'], 'ar': ['مبتدئ', 'متوسط', 'متقدم']}
        levels_map = {'débutant': 'beginner', 'beginner': 'beginner', 'مبتدئ': 'beginner',
                      'intermédiaire': 'intermediate', 'intermediate': 'intermediate', 'متوسط': 'intermediate',
                      'avancé': 'advanced', 'advanced': 'advanced', 'متقدم': 'advanced'}
        found = None
        for l in levels[lang if lang in levels else 'fr']:
            if l in niveau_input:
                found = levels_map[l]
                break
        if not found:
            if lang == 'fr':
                return "Merci de choisir parmi : débutant, intermédiaire, avancé."
            elif lang == 'en':
                return "Please choose: beginner, intermediate, advanced."
            else:
                return "يرجى اختيار: مبتدئ، متوسط، متقدم."
        session['quiz_level'] = found
        session['state'] = 'in_quiz_level'
        user_sessions[user_id] = session
        return ask_quiz_question(user_id)
    # Gestion de la réponse à la question
    if session.get('state') == 'in_quiz_level' and 'current_quiz' in session:
        options = session['current_quiz']['options']
        answer_field = session['current_quiz']['answer']
        # Détecte dynamiquement la bonne clé d'option
        if answer_field in options:
            correct_answer_key = answer_field
            correct_answer_value = options[correct_answer_key]
        else:
            # Cherche la clé dont la valeur correspond à answer_field (insensible à la casse ou commence par la même lettre)
            correct_answer_key = None
            correct_answer_value = None
            for k, v in options.items():
                if answer_field.strip().lower() == v.strip().lower() or answer_field.strip().lower() == v.strip().lower()[0]:
                    correct_answer_key = k
                    correct_answer_value = v
                    break
            if correct_answer_key is None:
                # Si toujours pas trouvé, tente la première lettre de chaque option
                for k, v in options.items():
                    if answer_field.strip().lower() == k:
                        correct_answer_key = k
                        correct_answer_value = v
                        break
            if correct_answer_key is None:
                logger.error(f"[QUIZ] Incohérence: answer '{answer_field}' non trouvée dans les options {list(options.values())}")
                if lang == 'fr':
                    return f"Erreur interne : la réponse du quiz n'est pas valide. Merci de signaler ce bug."
                elif lang == 'en':
                    return f"Internal error: quiz answer is not valid. Please report this bug."
                else:
                    return f"خطأ داخلي: إجابة الكويز غير صالحة. يرجى الإبلاغ عن هذا الخطأ."
        user_answer = user_input.strip().lower()
        # Vérifie si la réponse utilisateur correspond à la lettre OU au texte de l'option
        is_correct = (
            user_answer == correct_answer_key.lower() or
            user_answer == correct_answer_value.strip().lower()
        )
        if is_correct:
            feedback = "Bonne réponse ! ✅" if lang == 'fr' else ("Correct! ✅" if lang == 'en' else "إجابة صحيحة! ✅")
        elif user_answer in options:
            # Mauvaise réponse mais la clé existe
            msg = f"Incorrect. ❌ La bonne réponse était : {correct_answer_key.upper()}) {correct_answer_value}" if lang == 'fr' \
                else (f"Incorrect. ❌ The correct answer was: {correct_answer_key.upper()}) {correct_answer_value}" if lang == 'en' \
                else f"إجابة خاطئة. ❌ الجواب الصحيح هو: {correct_answer_key.upper()}) {correct_answer_value}")
            feedback = msg
        elif user_answer in [v.strip().lower() for v in options.values()]:
            # Mauvaise réponse mais l'utilisateur a écrit le texte d'une mauvaise option
            msg = f"Incorrect. ❌ La bonne réponse était : {correct_answer_key.upper()}) {correct_answer_value}" if lang == 'fr' \
                else (f"Incorrect. ❌ The correct answer was: {correct_answer_key.upper()}) {correct_answer_value}" if lang == 'en' \
                else f"إجابة خاطئة. ❌ الجواب الصحيح هو: {correct_answer_key.upper()}) {correct_answer_value}")
            feedback = msg
        else:
            # Réponse invalide (clé inexistante)
            if lang == 'fr':
                return f"Réponse invalide. Merci de choisir parmi les options proposées : {', '.join(options.keys()).upper()} ou écrire la réponse complète."
            elif lang == 'en':
                return f"Invalid answer. Please choose from the available options: {', '.join(options.keys()).upper()} or write the full answer."
            else:
                return f"إجابة غير صالحة. يرجى اختيار أحد الحروف التالية: {', '.join(options.keys()).upper()} أو كتابة الإجابة كاملة."
        # Nouvelle question
        return f"{feedback}\n\n---\n\n{ask_quiz_question(user_id)}"
    # Si problème
    session['state'] = 'main_menu'
    user_sessions[user_id] = session
    return "Il y a eu un problème avec le quiz. Retour au menu principal."

def load_quiz_data():
    try:
        with open(DATA_DIR / "quiz_by_level_no_theme.json", "r", encoding="utf-8") as f:
            quiz_data = json.load(f)
            return quiz_data
    except Exception as e:
        logger.error(f"Error loading quiz data: {str(e)}")
        return {}
