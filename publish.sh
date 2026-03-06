#!/bin/bash
set -euo pipefail

# publish.sh — Write a Markdown post and push to tamvada.me
#
# Usage:
#   ./publish.sh "Post Title" my-post.md "Short description of the post."
#
# Workflow:
#   1. Write your post as a .md file in assets/
#   2. Run this script — it updates posts.json, feed.xml, sitemap.xml
#   3. Commits everything and pushes to GitHub Pages
#
# Or just:
#   1. Write your .md file
#   2. Run: ./publish.sh "Title" filename.md "Description"

BLOG_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -lt 3 ]; then
    echo "Usage: ./publish.sh \"Post Title\" <filename.md> \"Short description\""
    echo ""
    echo "Example:"
    echo "  ./publish.sh \"Career FAQ\" career-faq.md \"What it takes to land an ME job.\""
    exit 1
fi

TITLE="$1"
FILENAME="$2"
DESCRIPTION="$3"
SLUG="${FILENAME%.md}"
DATE="$(date +%Y-%m-%d)"
PUB_DATE="$(date -R)"
ARTICLE_URL="https://tamvada.me/article.html?file=${FILENAME}"

# Check that the markdown file exists
if [ ! -f "${BLOG_DIR}/assets/${FILENAME}" ]; then
    echo "Error: assets/${FILENAME} not found."
    echo "Write your post first, then run this script."
    exit 1
fi

cd "$BLOG_DIR"

# --- Update posts.json ---
# Read existing posts, prepend new entry (newest first)
python3 -c "
import json, sys
with open('assets/posts.json', 'r') as f:
    posts = json.load(f)

new_post = {
    'slug': '${SLUG}',
    'title': '''${TITLE}''',
    'date': '${DATE}',
    'excerpt': '''${DESCRIPTION}'''
}

# Don't add duplicate
if not any(p['slug'] == new_post['slug'] for p in posts):
    posts.insert(0, new_post)

with open('assets/posts.json', 'w') as f:
    json.dump(posts, f, indent=2)
    f.write('\n')

print(f'Updated posts.json ({len(posts)} posts)')
"

# --- Update feed.xml ---
# Insert new item after the <atom:link> line
NEW_ITEM="    <item>\n      <title>${TITLE}</title>\n      <link>${ARTICLE_URL}</link>\n      <pubDate>${PUB_DATE}</pubDate>\n      <description>${DESCRIPTION}</description>\n    </item>"

# Check if this item already exists
if grep -q "file=${FILENAME}" feed.xml 2>/dev/null; then
    echo "feed.xml already has entry for ${FILENAME}, skipping"
else
    sed -i '' "/<atom:link.*\/>/a\\
${NEW_ITEM}
" feed.xml
    echo "Updated feed.xml"
fi

# --- Update sitemap.xml ---
if grep -q "file=${FILENAME}" sitemap.xml 2>/dev/null; then
    echo "sitemap.xml already has entry for ${FILENAME}, skipping"
else
    sed -i '' "/<\/urlset>/i\\
  <url><loc>${ARTICLE_URL}</loc></url>
" sitemap.xml
    echo "Updated sitemap.xml"
fi

# --- Git commit and push ---
git add "assets/${FILENAME}" assets/posts.json feed.xml sitemap.xml
git commit -m "Publish: ${TITLE}"
git push

echo ""
echo "Published! Live at: ${ARTICLE_URL}"
