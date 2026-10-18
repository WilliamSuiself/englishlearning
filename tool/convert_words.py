import json
import re
import os

def parse_txt_file(filepath, level):
    words = []
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # Format: word\tdefinition  (tab or multiple spaces separated)
            parts = re.split(r'\t+|\s{2,}', line, maxsplit=1)
            if len(parts) < 2:
                # Try single space split for word + definition
                parts = line.split(' ', 1)
                if len(parts) < 2:
                    continue
            word = parts[0].strip()
            definition = parts[1].strip() if len(parts) > 1 else ''
            if not word or not definition:
                continue
            # Extract part of speech if present at start of definition
            pos_match = re.match(r'^(n|v|adj|adv|prep|conj|pron|num|art|vt|vi|aux|abbr)\.\s*', definition)
            pos = None
            if pos_match:
                pos = pos_match.group(1)
                definition = definition[pos_match.end():]
            words.append({
                'word': word,
                'definition': definition,
                'part_of_speech': pos,
                'level': level,
            })
    return words

levels = [
    ('/tmp/cet4_raw.txt', 'CET4'),
    ('/tmp/cet6_raw.txt', 'CET6'),
    ('/tmp/kaoyan_raw.txt', '考研'),
    ('/tmp/toefl_raw.txt', 'TOEFL'),
]

all_words = []
seen = set()
for filepath, level in levels:
    words = parse_txt_file(filepath, level)
    for w in words:
        key = w['word'].lower()
        if key not in seen:
            seen.add(key)
            all_words.append(w)
        else:
            # Update existing word with higher level if needed
            for existing in all_words:
                if existing['word'].lower() == key:
                    # Keep the first occurrence but update level to higher one
                    level_order = {'CET4': 1, 'CET6': 2, '考研': 3, 'TOEFL': 4}
                    if level_order.get(level, 99) < level_order.get(existing['level'], 99):
                        existing['level'] = level
                    break

# Sort by word
all_words.sort(key=lambda w: w['word'].lower())

# Write as compact JSON
output_path = '/Users/suiyunhai/coding/EnglishLearning/assets/data/words_all.json'
with open(output_path, 'w', encoding='utf-8') as f:
    json.dump(all_words, f, ensure_ascii=False, separators=(',', ':'))

print(f"Total unique words: {len(all_words)}")
print(f"Written to: {output_path}")
print(f"File size: {os.path.getsize(output_path) / 1024 / 1024:.1f} MB")

# Also write level summary
from collections import Counter
level_counts = Counter(w['level'] for w in all_words)
print(f"Level distribution: {dict(level_counts)}")
