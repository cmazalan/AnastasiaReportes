import os
import json
import re
from datetime import datetime

html_path = r'c:\Users\cmaza\OneDrive\Documentos\ANASTASIA ANTIGRAVITY\press_report\press_report.html'
capturas_path = r'G:\.shortcut-targets-by-id\1mE_Xe8Vb5V3cCyFSbVFmEyxF4WdG7qlQ\CAPTURAS ANASTASIA'

# Read HTML
with open(html_path, 'r', encoding='utf-8') as f:
    html_content = f.read()

# Extract existing JSON
pattern = re.compile(r'const rawClippingsData = (\[.*?\]);', re.DOTALL)
match = pattern.search(html_content)
if not match:
    print("Could not find rawClippingsData in HTML.")
    exit(1)

json_str = match.group(1)
try:
    clippings = json.loads(json_str)
except json.JSONDecodeError as e:
    print("Error parsing JSON:", e)
    exit(1)

# Keep track of existing filenames to avoid duplicates
existing_filenames = {item['filename'] for item in clippings}
new_added = 0

# Recursively read CAPTURAS
for root, dirs, files in os.walk(capturas_path):
    for file in files:
        if file.startswith('.'):
            continue # skip hidden files
            
        if file not in existing_filenames:
            # It's a new file, we need to add it
            full_path = os.path.join(root, file)
            folder = os.path.basename(root)
            
            # Infer date from filename if possible (e.g. DD-MM-YYYY)
            date_str = ""
            date_match = re.search(r'(\d{2}-\d{2}-\d{4})', file)
            if date_match:
                date_str = date_match.group(1)
            else:
                date_str = "Desconocida"
                
            # Infer media type and extension
            ext = os.path.splitext(file)[1].lower()
            if ext in ['.mp4', '.mov', '.avi']:
                media_type = "Televisión / Video Online"
                note_type = "Mención/Cobertura"
            elif ext in ['.mp3', '.wav']:
                media_type = "Radio"
                note_type = "Mención/Cobertura"
            else:
                media_type = "Prensa Especializada / Portales Web / Redes"
                note_type = "Mención/Cobertura"
                
            tone = "Positivo (Difusión)"
            
            new_item = {
                "filename": file,
                "path": full_path,
                "folder": folder,
                "date": date_str,
                "media_type": media_type,
                "note_type": note_type,
                "tone": tone,
                "extension": ext
            }
            clippings.append(new_item)
            existing_filenames.add(file)
            new_added += 1

print(f"Added {new_added} new items.")

# Sort by date? Not strictly necessary if frontend does it, but let's keep it as is.
new_json_str = json.dumps(clippings, indent=2, ensure_ascii=False)

# Replace in HTML
new_html_content = html_content[:match.start(1)] + new_json_str + html_content[match.end(1):]

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(new_html_content)

print("Updated HTML successfully.")
