import requests

# Tester différentes URLs de l'API LibriVox
urls = [
    'https://librivox.org/api/feed/audiobooks/?format=json',
    'https://librivox.org/api/feed/audiobooks/?format=json&title=sherlock',
    'https://librivox.org/api/feed/audiobooks/?format=json&author=doyle',
    'https://librivox.org/api/feed/audiobooks/?format=json&title=dumas',
]

print("=== Test API LibriVox ===")
for url in urls:
    try:
        r = requests.get(url, timeout=10)
        print(f"{r.status_code}: {url}")
        if r.status_code == 200:
            data = r.json()
            books = data.get('books', [])
            print(f"  -> {len(books)} livres")
            if books:
                print(f"  Exemple: {books[0].get('title', 'N/A')}")
        elif r.status_code == 404:
            print(f"  -> Aucun résultat")
        elif r.status_code == 402:
            print(f"  -> API limitée (Payment Required)")
    except Exception as e:
        print(f"ERREUR: {e}")
