# Simple gestionnaire de session en mémoire (à améliorer pour production)
_sessions = {}

def get_session(user_id):
    return _sessions.get(user_id, {"state": "menu", "lang": None, "context": None})

def save_session(user_id, session_data):
    _sessions[user_id] = session_data
