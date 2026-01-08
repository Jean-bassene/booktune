import re

with open('lib/screens/player_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Supprimer l'affichage de currentChapterTitle (le doublon)
pattern = r"        if \(player\.currentChapterTitle != null\) \.\.\.\[\n          const SizedBox\(height: 4\),\n          Text\(\n            player\.currentChapterTitle!,\n            style: const TextStyle\(\n              color: Colors\.white54,\n              fontSize: 12,\n            \),\n            textAlign: TextAlign\.center,\n            maxLines: 1,\n            overflow: TextOverflow\.ellipsis,\n          \),\n        \],"

content = re.sub(pattern, '', content)

with open('lib/screens/player_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Modification appliquee avec succes')
