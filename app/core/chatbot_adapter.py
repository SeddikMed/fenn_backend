import json
import os
import sys
from app.core.chatbot_cli import generate_menu_text, get_user_progress
from app.services.chatbot import update_user_progress
from app.services.chatbot.chatbotfinal import (
    rule_based_correct, 
    log_correction, 
    view_user_corrections, 
    view_user_badges, 
    attribuer_badge, 
    show_user_progress, 
    run_quiz_level, 
    run_learning_path, 
    run_challenge_quiz, 
    run_revision_mode, 
    process_input, 
    predict_intent, 
    detect_lang, 
    launch_context_chat, 
    get_level_label, 
    get_quiz_data_by_lang, 
    check_frequent_errors, 
    generate_correction_explanation, 
    correct_grammar_with_video, 
    map_level_to_internal
)

# --- DEBUG: Vérification explicite de l'import log_correction ---
print(f"[DEBUG] log_correction imported from chatbotfinal: {log_correction}")

import random

def process_api_input(user_input, user_id="default", session_data=None):
    """
    Orchestrateur API : gère tous les états de session et appelle la bonne logique métier.
    Ajoute message de bienvenue et détection de langue lors de la première interaction.
    """
    if session_data is None or not session_data.get("activated"):
        if session_data is None:
            session_data = {"state": "menu", "lang": None, "context": None, "level": None, "asked_questions": [], "score": 0}
            welcome_msg = (
                "👋 Salut ! Je suis Fenn, ton assistant d'anglais.\n"
                "Réveille-moi avec ‘salut fenn’ ou commence à discuter !"
            )
            return {
                "messages": [
                    {"text": welcome_msg, "type": "welcome"}
                ],
                "session_data": session_data,
                "type": "activation"
            }
        else:
            detected_lang = detect_lang(user_input)
            session_data["lang"] = detected_lang
            session_data["activated"] = True
            lang_msg = f"🌐 Langue détectée : {detected_lang.upper()}"
            menu_text = generate_menu_text(detected_lang)
            return {
                "messages": [
                    {"text": lang_msg, "type": "lang_detected"},
                    {"text": menu_text, "type": "menu"}
                ],
                "session_data": session_data,
                "type": "activation"
            }
    user_input_lower = user_input.lower().strip()
    # Détection de langue si pas encore faite
    if not session_data.get("lang"):
        session_data["lang"] = detect_lang(user_input)
    lang = session_data["lang"]
    state = session_data.get("state", "menu")

    # MENU PRINCIPAL
    if state == "menu":
        intent = predict_intent(user_input_lower)
        # Gestion quiz multi-langue robuste
        lang_key = (lang or "en").lower()
        quiz_levels = {
            "fr": ["débutant", "intermédiaire", "avancé"],
            "en": ["beginner", "intermediate", "advanced"],
            "dz": ["moubtadi2", "moutawasset", "moutakadem"]
        }
        quiz_levels_display = {
            "fr": "débutant, intermédiaire, avancé",
            "en": "beginner, intermediate, advanced",
            "dz": "moubtadi2, moutawasset, moutakadem"
        }
        # --- Ajout du mode contexte ---
        if intent == "context" or user_input_lower in ["3", "contexte", "context"]:
            session_data["state"] = "context"
            # Charger les thèmes
            with open("data/enriched_contexts_with_martyrs.json", "r", encoding="utf-8") as f:
                contexts = json.load(f)
            themes = [contexts[k]["title"] if "title" in contexts[k] else k for k in contexts.keys()]
            session_data["available_themes"] = list(contexts.keys())
            return {
                "messages": [
                    {"text": "💬 Choisis un thème :", "type": "context_intro"},
                    {"text": "\n".join([f"{i+1}. {title}" for i, title in enumerate(themes)]), "type": "context_list"}
                ],
                "session_data": session_data,
                "type": "context_list"
            }
        if lang_key not in quiz_levels:
            lang_key = "en"
        if intent == "quiz" or user_input_lower in ["1", "quiz"]:
            session_data["state"] = "quiz_level_selection"
            return {"text": f"🔢 Niveaux disponibles : {quiz_levels_display[lang_key]}\nChoisis un niveau :", "type": "quiz_setup", "session_data": session_data}
        elif intent == "correction" or user_input_lower in ["4", "saha7", "corrige"]:
            session_data["state"] = "correction"
            return {"text": "✏️ Envoie-moi la phrase à corriger.", "type": "correction", "session_data": session_data}
        elif intent == "progression" or user_input_lower in ["progression", "progress", "5"]:
            session_data["state"] = "menu"
            user_progress = get_user_progress(user_id)
            total_score = user_progress.get("total_score", 0)
            quizzes = user_progress.get("quizzes", {})
            if quizzes:
                details = "\n".join([f"   • {quiz}: {score}" for quiz, score in quizzes.items()])
            else:
                details = "Aucun quiz complété pour l'instant."
            msg = f"📈 Progression : {total_score}\n{details}"
            return {"text": msg, "type": "progression", "session_data": session_data}
        elif intent == "badges" or user_input_lower in ["badges", "🏅"]:
            badges = get_user_badges(user_id)
            return {"text": f"🏅 Badges : {badges}", "type": "badges", "session_data": session_data}
        elif intent == "logs" or user_input_lower in ["6", "logs"]:
            # Lecture du fichier de logs corrections
            import os, json
            # Utilise le même chemin absolu que log_correction
            log_file = os.path.join(os.path.dirname(__file__), "..", "services", "chatbot", "data", "correction_log.json")
            log_file = os.path.abspath(log_file)
            print(f"[DEBUG] Reading correction log from {log_file}")
            try:
                with open(log_file, "r", encoding="utf-8") as f:
                    logs_data = json.load(f)
                user_logs = logs_data.get(user_id, [])
                if not user_logs:
                    logs_text = "Aucun historique de correction."
                else:
                    logs_text = "\n".join([f"🔹 {i+1}. {log['original']} ➔ {log['corrected']}" for i, log in enumerate(user_logs[-5:])])
            except Exception:
                logs_text = "Aucun historique de correction."
            return {"text": f"📝 Logs :\n{logs_text}", "type": "logs", "session_data": session_data}
        elif intent == "challenge" or user_input_lower in ["7", "challenge"] or session_data.get("awaiting_challenge_level") or "challenge_questions" in session_data:
            # Challenge quiz (mode app)
            lang_key = session_data.get("lang", "fr")
            quiz_data = get_quiz_data_by_lang(lang_key)
            niveaux = ["beginner", "intermediate", "advanced"]
            # Si on attend un niveau, et que la réponse utilisateur est un niveau valide
            if session_data.get("awaiting_challenge_level") and user_input_lower in niveaux:
                level = user_input_lower
                # Préparer la liste des questions pour ce challenge
                import random
                questions = quiz_data.get(level, [])
                if not questions:
                    session_data.pop("awaiting_challenge_level", None)
                    return {"text": "❌ Aucun quiz disponible pour ce niveau.", "type": "challenge", "session_data": session_data}
                questions = random.sample(questions, min(5, len(questions)))
                session_data["challenge_level"] = level
                session_data["challenge_questions"] = questions
                session_data["challenge_index"] = 0
                session_data["challenge_score"] = 0
                session_data.pop("awaiting_challenge_level", None)
                # Afficher la première question
                q = questions[0]
                labels = ['a', 'b', 'c', 'd']
                q_text = f"[1/5] {q['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, q['choices'])])
                return {"text": q_text, "type": "challenge_question", "session_data": session_data}
            # Si on est en cours de challenge (challenge_questions dans session_data)
            elif "challenge_questions" in session_data and "challenge_index" in session_data:
                idx = session_data["challenge_index"]
                questions = session_data["challenge_questions"]
                level = session_data["challenge_level"]
                score = session_data["challenge_score"]
                q = questions[idx]
                labels = ['a', 'b', 'c', 'd']
                # Vérifier la réponse utilisateur
                if user_input_lower in labels:
                    answer_label = labels.index(user_input_lower)
                    correct = q['choices'][answer_label].strip().lower() == q['answer'].strip().lower()
                    if correct:
                        score += 1
                        feedback = "✅ Bonne réponse !"
                    else:
                        feedback = f"❌ Mauvaise réponse. Réponse attendue : {q['answer']}"
                    idx += 1
                    # Si encore des questions
                    if idx < len(questions):
                        next_q = questions[idx]
                        q_text = f"[{idx+1}/5] {next_q['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, next_q['choices'])])
                        session_data["challenge_index"] = idx
                        session_data["challenge_score"] = score
                        return {"text": f"{feedback}\n\n{q_text}", "type": "challenge_question", "session_data": session_data}
                    else:
                        # Fin du challenge
                        final_score = score
                        session_data.pop("challenge_questions", None)
                        session_data.pop("challenge_index", None)
                        session_data.pop("challenge_level", None)
                        session_data.pop("challenge_score", None)
                        return {"text": f"🏁 Challenge terminé ! Score : {final_score}/5", "type": "challenge_end", "session_data": session_data}
                else:
                    # Réponse non valide
                    q_text = f"[{idx+1}/5] {q['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, q['choices'])])
                    return {"text": f"Merci de répondre par a, b, c ou d.\n\n{q_text}", "type": "challenge_question", "session_data": session_data}
            # Sinon, proposer les niveaux
            niveaux_affich = ", ".join(niveaux)
            session_data["awaiting_challenge_level"] = True
            return {"text": f"🚩 Mode Challenge ! Choisis un niveau : {niveaux_affich}", "type": "challenge_select_level", "session_data": session_data}
        elif intent == "revision" or user_input_lower in ["8", "revision", "révision"]:
            # Mode révision (mode app)
            lang_key = session_data.get("lang", "fr")
            import os, json
            mistakes_file = os.path.join("backend", "app", "services", "chatbot", "data", "mistakes.json")
            try:
                with open(mistakes_file, "r", encoding="utf-8") as f:
                    mistakes_data = json.load(f)
                user_mistakes = mistakes_data.get(user_id, [])
                if not user_mistakes:
                    mistakes_text = "Aucune erreur à réviser."
                else:
                    mistakes_text = "\n".join([f"🔁 {i+1}. {m.get('question','')} ➔ {m.get('answer','')}" for i, m in enumerate(user_mistakes[-5:])])
            except Exception:
                mistakes_text = "Aucune erreur à réviser."
            return {"text": f"📚 Révision :\n{mistakes_text}", "type": "revision", "session_data": session_data}
        elif intent == "traduction" or user_input_lower in ["translate", "traduire"]:
            session_data["state"] = "traduction"
            return {"text": "🌐 Envoie-moi la phrase à traduire.", "type": "traduction", "session_data": session_data}
        elif intent == "parcours" or user_input_lower in ["parcours", "learning_path", "2"]:
            session_data["state"] = "parcours"
            session_data["parcours_index"] = 0
            session_data["parcours_score"] = 0
            session_data["parcours_levels"] = ["débutant", "intermédiaire", "avancé"]
            return {"text": "📚 Début du parcours d'apprentissage. Niveau 1 : débutant.", "type": "parcours", "session_data": session_data}
        else:
            menu_text = generate_menu_text(lang)
            return {"text": menu_text, "type": "menu", "session_data": session_data}

    # MODE CONTEXTE (navigation dans les thèmes)
    if state == "context":
        # Retour menu si demandé
        if user_input_lower in ["menu", "retour", "back", "exit", "quitter"]:
            session_data["state"] = "menu"
            menu_text = generate_menu_text(lang)
            return {
                "messages": [
                    {"text": "🔙 Retour au menu principal.", "type": "menu_return"},
                    {"text": menu_text, "type": "menu"}
                ],
                "session_data": session_data,
                "type": "menu"
            }
        # Sélection de thème par numéro ou nom
        theme_idx = None
        try:
            theme_idx = int(user_input_lower) - 1
        except:
            pass
        theme_key = None
        if theme_idx is not None and 0 <= theme_idx < len(session_data.get("available_themes", [])):
            theme_key = session_data["available_themes"][theme_idx]
        else:
            # Recherche par nom, titre, ou sous-chaîne du titre
            with open("data/enriched_contexts_with_martyrs.json", "r", encoding="utf-8") as f:
                contexts = json.load(f)
            for k in session_data.get("available_themes", []):
                v = contexts.get(k, {})
                # Match sur clé brute
                if user_input_lower == k.lower():
                    theme_key = k
                    break
                # Match sur titre exact
                if "title" in v and user_input_lower == v["title"].lower():
                    theme_key = k
                    break
                # Match sur sous-chaîne du titre
                if "title" in v and user_input_lower in v["title"].lower():
                    theme_key = k
                    break
                # Match sur sous-chaîne de la clé
                if user_input_lower in k.lower():
                    theme_key = k
                    break
        if theme_key:
            with open("data/enriched_contexts_with_martyrs.json", "r", encoding="utf-8") as f:
                contexts = json.load(f)
            theme = contexts[theme_key]
            msg = theme.get("title", theme_key.replace("_", " ").title())
            # Affichage résumé ou liste principale
            if "summary" in theme:
                msg += "\n" + theme["summary"]
            elif "translations" in theme:
                # Affichage formaté des traductions de pronoms
                msg += "\n\n" + "\n".join([f"{k} → {v}" for k, v in theme["translations"].items()])
            elif "vocab" in theme:
                # Affichage formaté du vocabulaire (ex: légumes, fruits...)
                msg += "\n\n" + "\n".join([f"{k} → {v}" for k, v in theme["vocab"].items()])
            elif "categories" in theme:
                # Affichage pour fruits_vocabulary, vegetables_vocabulary, etc.
                for cat, mots in theme["categories"].items():
                    msg += f"\n\n{cat} :\n"
                    msg += "\n".join([f"{k} → {v}" for k, v in mots.items()])
            elif "topics" in theme:
                # Affichage pour health_body (body_parts, common_symptoms, etc.)
                for cat, mots in theme["topics"].items():
                    msg += f"\n\n{cat.replace('_', ' ').capitalize()} :\n"
                    msg += "\n".join([f"{k} → {v}" for k, v in mots.items()])
            elif "expressions" in theme:
                # Affichage pour real_english_phrases
                for fr, data in theme["expressions"].items():
                    msg += f"\n\n{fr} :\n"
                    if isinstance(data["en"], list):
                        msg += "\n".join([f"- {eng}" for eng in data["en"]])
                    else:
                        msg += f"- {data['en']}"
            elif "history" in theme:
                msg += "\n" + "\n".join(theme["history"])
            elif "fun_facts" in theme:
                msg += "\n" + "\n".join(theme["fun_facts"])
            # Liste des martyrs (exemple)
            elif "martyrs" in theme:
                msg += "\nMartyrs :\n" + "\n".join([f"- {m['name']}" for m in theme["martyrs"]])
            # Liste des recettes (exemple)
            elif "recettes" in theme:
                msg += "\nRecettes :\n" + "\n".join([f"- {r['title']}" for r in theme["recettes"]])
            return {
                "messages": [
                    {"text": msg, "type": "context_theme"},
                    {"text": "Tape 'menu' pour revenir au menu principal.", "type": "context_info"}
                ],
                "session_data": session_data,
                "type": "context_theme"
            }
        else:
            # Thème inconnu
            return {
                "messages": [
                    {"text": "❌ Thème inconnu. Réessaie avec un numéro ou un nom valide.", "type": "context_error"}
                ],
                "session_data": session_data,
                "type": "context_error"
            }
    # SÉLECTION DU NIVEAU DE QUIZ
    if state == "quiz_level_selection":

        lang_key = (lang or "en").lower()
        quiz_levels = {
            "fr": ["débutant", "intermédiaire", "avancé"],
            "en": ["beginner", "intermediate", "advanced"],
            "dz": ["moubtadi2", "moutawasset", "moutakadem"]
        }
        quiz_levels_display = {
            "fr": "débutant, intermédiaire, avancé",
            "en": "beginner, intermediate, advanced",
            "dz": "moubtadi2, moutawasset, moutakadem"
        }
        if lang_key not in quiz_levels:
            lang_key = "en"
        level = user_input_lower
        internal_level = map_level_to_internal(level, lang_key)
        if not internal_level:
            return {"text": f"❌ Niveau inconnu. Choisis : {quiz_levels_display[lang_key]}", "type": "quiz_setup", "session_data": session_data}
        quiz_data = get_quiz_data_by_lang(lang_key)
        if internal_level not in quiz_data:
            return {"text": "Aucune question disponible pour ce niveau.", "type": "quiz_end", "session_data": session_data}
        session_data["level"] = level
        session_data["quiz_json_key"] = internal_level
        session_data["state"] = "quiz_question"
        session_data["asked_questions"] = []
        session_data["score"] = 0
        session_data["current_question_idx"] = 0
        questions = quiz_data[internal_level]
        if not questions:
            return {"text": "Aucune question disponible pour ce niveau.", "type": "quiz_end", "session_data": session_data}
        first_question = questions[0]
        session_data["current_question"] = first_question
        session_data["choices_order"] = random.sample(["a", "b", "c", "d"], 4)
        return {"messages": [{"text": f"❓ {first_question['question']}\n" + "\n".join([f"{choice} - {first_question['choices'][i]}" for i, choice in enumerate(session_data["choices_order"])]), "type": "quiz_question"}], "session_data": session_data, "type": "quiz_question"}

    # QUESTION DE QUIZ
    if state == "quiz_question":
        quiz_json_key = session_data.get("quiz_json_key")
        if not quiz_json_key:
            session_data["state"] = "menu"
            return {"text": "Erreur de session quiz. Retour au menu.", "type": "quiz_end", "session_data": session_data}
        quiz_data = get_quiz_data_by_lang(lang)
        if quiz_json_key not in quiz_data:
            session_data["state"] = "menu"
            return {"text": "Aucune question trouvée pour ce niveau.", "type": "quiz_end", "session_data": session_data}
        questions = quiz_data[quiz_json_key]
        if not questions:
            session_data["state"] = "menu"
            return {"text": "Aucune question trouvée pour ce niveau.", "type": "quiz_end", "session_data": session_data}
        current_question_index = session_data.get("current_question_idx", 0)
        if current_question_index >= len(questions):
            update_user_progress(user_id, quiz_json_key, session_data["score"])
            session_data["state"] = "menu"
            return {"text": f"🏁 Quiz terminé ! Score : {session_data['score']}", "type": "quiz_end", "session_data": session_data}
        question = questions[current_question_index]
        choices_order = session_data.get("choices_order")
        if not choices_order:
            choices_order = random.sample(["a", "b", "c", "d"], 4)
            session_data["choices_order"] = choices_order
        if user_input_lower == "pick":
            update_user_progress(user_id, quiz_json_key, session_data["score"])
            session_data["state"] = "menu"
            return {"text": f"🏁 Quiz terminé ! Score : {session_data['score']}", "type": "quiz_end", "session_data": session_data}
        # Permettre la sortie universelle (pick, exit...) à tout moment
        user_answer_text = user_input.strip().lower()
        if user_answer_text in ["pick", "exit", "quitter", "stop"]:
            update_user_progress(user_id, quiz_json_key, session_data["score"])
            session_data["state"] = "menu"
            return {"text": f"🏁 Quiz terminé ! Score : {session_data['score']}", "type": "quiz_end", "session_data": session_data}
        # Permettre la réponse par a/b/c/d OU par texte exact
        valid_letters = choices_order
        # Si l'utilisateur tape a/b/c/d
        if user_answer_text in valid_letters:
            idx_choice = valid_letters.index(user_answer_text)
            selected = question["choices"][idx_choice].strip().lower()
        # Sinon, il tape la réponse textuelle
        elif user_answer_text in [c.strip().lower() for c in question["choices"]]:
            selected = user_answer_text
        else:
            return {"text": "Réponse invalide. Réponds par a/b/c/d ou écris la réponse exacte, ou tape 'pick' pour quitter.", "type": "quiz_feedback", "session_data": session_data}
        correct = selected == question["answer"].strip().lower()
        session_data["asked_questions"].append(question["question"])
        if correct:
            session_data["score"] += 1
            feedback = "✅ Bonne réponse !"
        else:
            feedback = f"❌ Mauvaise réponse. Réponse attendue : {question['answer']}"
        next_question_index = current_question_index + 1
        if next_question_index < len(questions):
            next_question = questions[next_question_index]
            session_data["current_question_idx"] = next_question_index  # <-- Correction : avancer à la question suivante
            # Génère l'affichage directement sans utiliser d'id
            choices = next_question.get("choices", [])
            choices_display = "\n".join([f"{choice} - {choices[i]}" for i, choice in enumerate(choices_order)])
            question_text = f"❓ {next_question['question']}\n{choices_display}"
            if not question_text:
                return {"text": "Aucune question disponible pour ce niveau.", "type": "quiz_end", "session_data": session_data}
            # Affiche la question et les choix si disponibles
            choices = next_question.get("choices")
            # Toujours afficher les choix formatés, jamais la liste brute
            return {"messages": [
                {"text": f"{feedback}", "type": "feedback"},
                {"text": f"❓ {question_text}", "type": "quiz_question"}
            ], "session_data": session_data, "type": "quiz_question"}
        else:
            update_user_progress(user_id, quiz_json_key, session_data["score"])
            session_data["state"] = "menu"
            return {"messages": [
                {"text": f"{feedback}", "type": "feedback"},
                {"text": f"🏁 Quiz terminé ! Score : {session_data['score']}", "type": "quiz_end"}
            ], "session_data": session_data, "type": "quiz_end"}
            return {"text": f"{feedback}\n🏁 Quiz terminé ! Score : {session_data['score']}", "type": "quiz_end", "session_data": session_data}

    # CORRECTION
    if state == "correction":
        correction = rule_based_correct(user_input)
        session_data["state"] = "menu"
        if correction:
            # DEBUG : Affiche le user_id utilisé pour le logging correction
            print(f"[DEBUG] log_correction called with user_id={user_id}")
            # Log la correction utilisateur dans correction_log.json
            log_correction(user_id, correction['original'], correction['corrected'])
            return {"messages": [
                {"text": f"Correction : {correction['corrected']}", "type": "correction"},
                {"text": f"Explications : {correction['explanations']}", "type": "correction_explanation"},
                {"text": generate_menu_text(lang), "type": "menu"}
            ], "session_data": session_data, "type": "correction"}
        else:
            return {"messages": [
                {"text": "Aucune correction nécessaire.", "type": "correction"},
                {"text": generate_menu_text(lang), "type": "menu"}
            ], "session_data": session_data, "type": "correction"}

    # PROGRESSION
    if state == "progression":
        try:
            # Appel à la fonction console pour affichage riche
            from app.services.chatbot.chatbotfinal import show_user_progress
            import io, sys
            old_stdout = sys.stdout
            sys.stdout = mystdout = io.StringIO()
            show_user_progress(user_id, lang)
            sys.stdout = old_stdout
            msg = mystdout.getvalue()
        except Exception:
            msg = "Aucune donnée de progression disponible."
        session_data["state"] = "menu"
        return {"messages": [
            {"text": msg, "type": "progression"},
            {"text": generate_menu_text(lang), "type": "menu"}
        ], "session_data": session_data, "type": "progression"}

    # BADGES
    # (Ancienne gestion par try/except supprimée, harmonisée plus haut)

    # SORTIE
    if state == "exit":
        session_data["state"] = "end"
        return {"messages": [
            {"text": t("goodbye", lang), "type": "exit"}
        ], "session_data": session_data, "type": "exit"}

    # PROGRESSION & BADGES harmonisé console
    if state == "progression":
        from app.services.chatbot.chatbotfinal import show_user_progress, view_user_badges
        progress_msg = show_user_progress(user_id, lang)
        badges_msg = view_user_badges(user_id, lang)
        session_data["state"] = "menu"
        return {"messages": [
            {"text": progress_msg, "type": "progression"},
            {"text": badges_msg, "type": "badges"},
            {"text": generate_menu_text(lang), "type": "menu"}
        ], "session_data": session_data, "type": "progression"}

    # LOGS/HISTORIQUE harmonisé console
    if state == "logs":
        from app.services.chatbot.chatbotfinal import view_user_corrections
        logs_msg = view_user_corrections(user_id, lang)
        session_data["state"] = "menu"
        return {"messages": [
            {"text": logs_msg, "type": "logs"},
            {"text": generate_menu_text(lang), "type": "menu"}
        ], "session_data": session_data, "type": "logs"}

    # CHALLENGE harmonisé console
    if state == "challenge":
        from app.services.chatbot.chatbotfinal import run_challenge_quiz
        challenge_result = run_challenge_quiz(user_id, lang, session_data)
        session_data["state"] = "menu"
        return {"messages": [
            {"text": challenge_result, "type": "challenge"},
            {"text": generate_menu_text(lang), "type": "menu"}
        ], "session_data": session_data, "type": "challenge"}

    # (Suite du code pour parcours, etc.)

    if state == "parcours":
        parcours_levels = session_data.get("parcours_levels", ["débutant", "intermédiaire", "avancé"])
        choices_orders = session_data.get("choices_orders")
        lang_key = (lang or "en").lower()
        # Liste des niveaux à parcourir dans l'ordre
        if not parcours_levels:
            # On garde la logique de sélection des niveaux par langue, mais on utilisera le mapping universel ensuite
            parcours_levels = {
                "fr": ["débutant", "intermédiaire", "avancé"],
                "en": ["beginner", "intermediate", "advanced"],
                "dz": ["مبتدئ", "متوسط", "متقدم", "moubtadi2", "moutawasset", "moutakadem"]
            }.get(lang_key, ["beginner", "intermediate", "advanced"])
            session_data["parcours_levels"] = parcours_levels
            session_data["parcours_index"] = 0
            session_data["parcours_score"] = 0
            session_data["choices_orders"] = []
            parcours_index = 0
            parcours_score = 0
            choices_orders = []
            current_question_idx = 0
            session_data["current_question_idx"] = 0
            # Message multilingue de début de parcours
            # Correction : initialisation multilingue + première question
            first_level = parcours_levels[0]
            internal_level = map_level_to_internal(first_level, lang_key)
            level_label = get_level_label(internal_level, lang_key) if internal_level else first_level
            start_msg = t("learning_path_start", lang_key, level=level_label)
            quiz_json_key = map_level_to_internal(first_level, lang_key)
            quiz_data = get_quiz_data_by_lang(lang_key)
            questions = quiz_data.get(quiz_json_key)
            if not questions or len(questions) == 0:
                return {"messages": [
                    {"text": t("no_questions_for_level", lang_key, level=level_label), "type": "parcours_info"}
                ], "session_data": session_data, "type": "parcours_info"}
            session_data["choices_orders"] = [random.sample(['a', 'b', 'c', 'd'], 4) for _ in questions]
            session_data["current_question_idx"] = 0
            question = questions[0]
            labels = ['a', 'b', 'c', 'd']
            question_text = t("level_question_intro", lang_key, level=level_label, num=1) + f" {question['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, question['choices'])])
            session_data["state"] = "parcours"
            session_data["_just_entered_parcours"] = False
            return {"messages": [
                {"text": start_msg, "type": "parcours"},
                {"text": question_text, "type": "parcours_question"}
            ], "session_data": session_data, "type": "parcours_question"}
        # --- Boucle principale du parcours : gestion question/réponse ---
        # Toujours recharger les questions du niveau courant à partir de la session
        parcours_index = session_data.get("parcours_index", 0)
        parcours_levels = session_data.get("parcours_levels", [])
        if parcours_index >= len(parcours_levels):
            # Sécurité, fin du parcours
            total_score = session_data.get("parcours_score", 0)
            session_data["state"] = "menu"
            session_data.pop("parcours_levels", None)
            session_data.pop("parcours_index", None)
            session_data.pop("parcours_score", None)
            session_data.pop("choices_orders", None)
            session_data.pop("current_question_idx", None)
            end_msg = t("learning_path_completed", lang_key)
            if end_msg == "learning_path_completed":
                end_msg = f"🎉 Parcours terminé ! Score total : {total_score}"
            else:
                end_msg += f" (Score : {total_score})"
            return {"messages": [
                {"text": end_msg, "type": "parcours_end"},
                {"text": generate_menu_text(lang), "type": "menu"}
            ], "session_data": session_data, "type": "parcours_end"}
        niveau = parcours_levels[parcours_index]
        from app.services.chatbot.chatbotfinal import map_level_to_internal
        quiz_json_key = map_level_to_internal(niveau, lang_key)
        quiz_data = get_quiz_data_by_lang(lang_key)
        questions = quiz_data.get(quiz_json_key, [])
        choices_orders = session_data.get("choices_orders")
        idx = session_data.get("current_question_idx", 0)
        if idx >= len(questions):
            # Fin du niveau, passer au suivant
            session_data["parcours_index"] += 1
            session_data["current_question_idx"] = 0
            if session_data["parcours_index"] < len(session_data["parcours_levels"]):
                next_niveau = session_data["parcours_levels"][session_data["parcours_index"]]
                quiz_json_key = map_level_to_internal(next_niveau, lang_key)
                quiz_data = get_quiz_data_by_lang(lang_key)
                next_questions = quiz_data.get(quiz_json_key)
                if not next_questions:
                    return {"messages": [
                        {"text": t("no_questions_for_level", lang_key, level=get_level_label(quiz_json_key, lang_key)), "type": "parcours_info"}
                    ], "session_data": session_data, "type": "parcours_info"}
                session_data["choices_orders"] = [random.sample(['a', 'b', 'c', 'd'], 4) for _ in next_questions]
                session_data["current_question_idx"] = 0
                question = next_questions[0]
                labels = ['a', 'b', 'c', 'd']
                question_text = t("level_question_intro", lang_key, level=get_level_label(quiz_json_key, lang_key), num=1) + f" {question['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, question['choices'])])
                return {"messages": [
                    {"text": t("level_completed_next", lang_key, level=get_level_label(map_level_to_internal(niveau, lang_key), lang_key)), "type": "parcours_info"},
                    {"text": question_text, "type": "parcours_question"}
                ], "session_data": session_data, "type": "parcours_question"}
            else:
                # Fin du parcours
                total_score = session_data.get("parcours_score", 0)
                session_data["state"] = "menu"
                session_data.pop("parcours_levels", None)
                session_data.pop("parcours_index", None)
                session_data.pop("parcours_score", None)
                session_data.pop("choices_orders", None)
                session_data.pop("current_question_idx", None)
                end_msg = t("learning_path_completed", lang_key)
                if end_msg == "learning_path_completed":
                    end_msg = f"🎉 Parcours terminé ! Score total : {total_score}"
                else:
                    end_msg += f" (Score : {total_score})"
                return {"messages": [
                    {"text": end_msg, "type": "parcours_end"},
                    {"text": generate_menu_text(lang), "type": "menu"}
                ], "session_data": session_data, "type": "parcours_end"}
        q = questions[idx]
        if isinstance(choices_orders, list) and idx < len(choices_orders):
            valid_choices = choices_orders[idx]
        else:
            valid_choices = []  # valeur par défaut si None ou hors limites
        labels = ['a', 'b', 'c', 'd']
        # Si c'est la première question ou retour du menu
        if user_input == "" or session_data.get("_just_entered_parcours"):
            session_data["_just_entered_parcours"] = False
            question_text = t("level_question_intro", lang_key, level=get_level_label(quiz_json_key, lang_key), num=idx+1) + f" {q['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, q['choices'])])
            session_data["state"] = "parcours"
            return {"messages": [
                {"text": question_text, "type": "parcours_question"}
            ], "session_data": session_data, "type": "parcours_question"}
        # Validation de la réponse
        user_answer_text = user_input.strip().lower()
        selected = None
        if user_answer_text in labels:
            selected = q['choices'][labels.index(user_answer_text)].strip().lower()
        elif user_answer_text in [c.strip().lower() for c in q['choices']]:
            selected = user_answer_text
        else:
            from app.services.chatbot.chatbotfinal import t as chatbot_t
            print("DEBUG lang_key:", lang_key)
            print("DEBUG t('invalid_answer', lang_key):", chatbot_t('invalid_answer', lang_key))
        # --- Ajout : quitter le mode parcours sans quitter le bot (PRIORITAIRE) ---
        if user_answer_text in ["quitter", "exit", "menu", "retour", "back", "main menu"]:
            session_data["state"] = "menu"
            menu_text = generate_menu_text(lang_key)
            return {"text": "🚪 Tu as quitté le mode parcours.\n" + menu_text, "type": "menu", "session_data": session_data}
        # --- Fin ajout ---

        print("DEBUG t('level_question_intro', lang_key):", chatbot_t('level_question_intro', lang_key))
        question_text = f"❌ {chatbot_t('invalid_answer', lang_key)}\n"
        question_text += chatbot_t("level_question_intro", lang_key, level=get_level_label(quiz_json_key, lang_key), num=idx+1) + f" {q['question']}\n"
        question_text += "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, q['choices'])])
        print("QUESTION_TEXT FINAL:", question_text)
        session_data["state"] = "parcours"
        return {"messages": [
            {"text": question_text, "type": "parcours_question"}
        ], "session_data": session_data, "type": "parcours_question"}
        # --- Ajout : quitter le mode parcours sans quitter le bot ---
        if user_answer_text in ["quitter", "exit", "menu", "retour", "back", "main menu"]:
            session_data["state"] = "menu"
            menu_text = generate_menu_text(lang_key)
            return {"text": "🚪 Tu as quitté le mode parcours.\n" + menu_text, "type": "menu", "session_data": session_data}
        # --- suite parcours classique ---
        correct = selected == q["answer"].strip().lower()
        from app.services.chatbot.chatbotfinal import t as chatbot_t
        feedback = chatbot_t("good_answer", lang_key) if correct else chatbot_t("bad_answer", lang_key, answer=q["answer"])
        if correct:
            session_data["parcours_score"] = session_data.get("parcours_score", 0) + 1
        # Passer à la question suivante
        session_data["current_question_idx"] = idx + 1
        session_data["state"] = "parcours"
        # Affichage feedback + question suivante ou passage au niveau suivant
        next_idx = idx + 1
        if next_idx < len(questions):
            next_q = questions[next_idx]
            question_text = chatbot_t("level_question_intro", lang_key, level=get_level_label(quiz_json_key, lang_key), num=next_idx+1) + f" {next_q['question']}\n" + "\n".join([f"   {lbl}) {opt}" for lbl, opt in zip(labels, next_q['choices'])])
            return {"messages": [
                {"text": feedback, "type": "parcours_feedback"},
                {"text": question_text, "type": "parcours_question"}
            ], "session_data": session_data, "type": "parcours_question"}
        else:
            # Fin du niveau, passer au suivant
            session_data["parcours_index"] += 1
            session_data["current_question_idx"] = 0
            session_data["state"] = "parcours"
            return {"messages": [
                {"text": feedback, "type": "parcours_feedback"},
                {"text": chatbot_t("level_completed_next", lang_key, level=get_level_label(map_level_to_internal(niveau, lang_key), lang_key)), "type": "parcours_info"}
            ], "session_data": session_data, "type": "parcours_info"}
