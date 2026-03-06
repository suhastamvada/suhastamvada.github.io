/**
 * Blog post listing for the index page.
 * Fetches posts.json and renders the post list.
 */

(function () {
  'use strict';

  const postListEl = document.getElementById('post-list');
  if (!postListEl) return;

  function formatDate(dateStr) {
    const date = new Date(dateStr + 'T00:00:00');
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  }

  function renderPosts(posts) {
    if (!posts || posts.length === 0) {
      postListEl.innerHTML =
        '<li class="empty-state">No posts yet. Check back soon.</li>';
      return;
    }

    // Sort by date, newest first
    posts.sort((a, b) => new Date(b.date) - new Date(a.date));

    postListEl.innerHTML = posts
      .map(
        (post) => `
        <li class="post-item">
          <a href="article.html?file=${encodeURIComponent(post.slug + '.md')}">
            <p class="post-date">${formatDate(post.date)}</p>
            <h2 class="post-title">${post.title}</h2>
            <p class="post-excerpt">${post.excerpt}</p>
          </a>
        </li>`
      )
      .join('');
  }

  fetch('assets/posts.json')
    .then((response) => {
      if (!response.ok) throw new Error('Failed to load posts');
      return response.json();
    })
    .then(renderPosts)
    .catch(() => {
      postListEl.innerHTML =
        '<li class="empty-state">Could not load posts.</li>';
    });
})();
