import requests
import argparse
import sys

BASE_URL = "https://librivox.org/api/feed/audiobooks/search/"

def search_audiobooks(query, search_by='title'):
    """
    Searches for LibriVox audiobooks.

    Args:
        query (str): The search term.
        search_by (str): 'title' or 'author'. Defaults to 'title'.

    Returns:
        list: A list of dictionaries, each representing an audiobook,
              or None if an error occurs.
    """
    params = {
        'format': 'json'
    }
    if search_by == 'title':
        params['title'] = query
    elif search_by == 'author':
        params['author'] = query
    else:
        print("Error: search_by must be 'title' or 'author.", file=sys.stderr)
        return None

    try:
        response = requests.get(BASE_URL, params=params)
        response.raise_for_status()  # Raise an HTTPError for bad responses (4xx or 5xx)
        data = response.json()

        audiobooks = []
        if 'books' in data:
            for book in data['books']:
                audiobooks.append({
                    'id': book.get('id'),
                    'title': book.get('title'),
                    'description': book.get('description'),
                    'url_librivox': book.get('url_librivox'),
                    'authors': book.get('authors', [])
                })
        return audiobooks
    except requests.exceptions.RequestException as e:
        print(f"Error making API request: {e}", file=sys.stderr)
        return None
    except ValueError as e:
        print(f"Error parsing JSON response: {e}", file=sys.stderr)
        return None

def main():
    parser = argparse.ArgumentParser(
        description="Search LibriVox audiobooks via their API."
    )
    parser.add_argument(
        "query",
        help="The search term for title or author."
    )
    parser.add_argument(
        "--by",
        choices=["title", "author"],
        default="title",
        help="Specify whether to search by 'title' or 'author' (default: title)."
    )
    args = parser.parse_args()

    print(f"Searching LibriVox for '{args.query}' by {args.by}...")
    results = search_audiobooks(args.query, args.by)

    if results:
        if not results:
            print("No audiobooks found matching your query.")
        else:
            for i, book in enumerate(results):
                print(f"\n--- Audiobook {i + 1} ---")
                print(f"Title: {book['title']}")
                print(f"LibriVox URL: {book['url_librivox']}")
                authors = ", ".join([f"{a['first_name']} {a['last_name']}" for a in book.get('authors', []) if a.get('first_name') and a.get('last_name')])
                if authors:
                    print(f"Authors: {authors}")
                else:
                    print("Authors: N/A")
                # Optionally print a truncated description
                # print(f"Description: {book['description'][:200]}...")
    else:
        print("Could not retrieve search results.")

if __name__ == "__main__":
    main()
