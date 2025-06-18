import os

BASE_DIR = os.path.dirname(__file__)
DATA_DIR = os.path.join(BASE_DIR, 'data')

PATHS = {
    'data': DATA_DIR,
    'contexts': os.path.join(DATA_DIR, 'enriched_contexts_with_martyrs.json'),
    'intent_dataset': os.path.join(DATA_DIR, 'intent_dataset_enriched.json'),
    'quiz_data': os.path.join(DATA_DIR, 'quiz_by_level_english.json'),
    'quiz_by_level': os.path.join(DATA_DIR, 'quiz_by_level_darija.json'),
    'user_scores': os.path.join(DATA_DIR, 'user_scores.json'),
    'translations': os.path.join(DATA_DIR, 'translations.json'),
    'errors_videos': os.path.join(DATA_DIR, 'errors_with_videos.json'),
    'correction_log': os.path.join(DATA_DIR, 'correction_log.json'),
    'recettes': os.path.join(DATA_DIR, 'recettes_algeriennes_etapes_detaillees_complet.json'),
    'errors_with_videos': os.path.join(DATA_DIR, 'errors_with_videos.json')
}
