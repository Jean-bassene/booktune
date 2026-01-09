@echo off
python -c "
import requests
url = 'https://librivox.org/api/feed/audiobooks/search/?format=json&author=dumas&limit=10'
r = requests.get(url, timeout=15)
print(f'Status: {r.status_code}')
if r.status_code == 200:
    data = r.json()
    books = data.get('books', [])
    print(f'Livres trouves: {len(books)}')
    for b in books[:3]:
        print(f'  - {b.get(\"title\")} par {b.get(\"authors\", [{}])[0].get(\"first_name\")} {b.get(\"authors\", [{}])[0].get(\"last_name\")}')
" > output.txt 2>&1
type output.txt
pause
