# Frank Xue's Personal Website

A modern, responsive personal portfolio website built with Jekyll and hosted on GitHub Pages.

## 🌟 Features

- **Responsive Design**: Works perfectly on desktop, tablet, and mobile devices
- **Modern UI/UX**: Clean, professional design with smooth animations
- **Fast Loading**: Optimized for performance with minimal dependencies
- **SEO-Friendly**: Proper meta tags and structure for search engines
- **Easy to Customize**: Well-organized code and clear documentation

## 📂 Site Structure

- **Home**: Hero section with introduction and featured projects
- **About**: Personal background, skills, and experience
- **Projects**: Detailed showcase of work and accomplishments
- **Contact**: Contact form and social links

## 🚀 Getting Started

### Prerequisites

- Ruby 2.7 or higher
- Bundler gem
- Git

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/frankxue831/frankxue831.github.io.git
   cd frankxue831.github.io
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Serve the site locally:
   ```bash
   bundle exec jekyll serve
   ```

4. Visit `http://localhost:4000` in your browser

## ✨ Customization

### Site Configuration

Edit `_config.yml` to customize:
- Site title, description, and URL
- Social media usernames
- Contact email
- SEO settings

### Content Updates

- **Home Page**: Edit `index.html`
- **About Page**: Edit `about.html`
- **Projects**: Edit `projects.html`
- **Contact**: Edit `contact.html`

### Styling

- Main styles: `assets/css/style.css`
- Color scheme: CSS custom properties at the top of the stylesheet
- Responsive breakpoints: Already configured for mobile, tablet, and desktop

### Adding New Pages

1. Create a new HTML file (e.g., `blog.html`)
2. Add front matter with layout and title
3. Add navigation links in `_layouts/page.html`

## 🎨 Design Features

- **Color Scheme**: Professional blue and gray palette
- **Typography**: Inter font family for modern readability
- **Animations**: Subtle hover effects and transitions
- **Components**: Reusable buttons, cards, and form elements

## 📱 Responsive Design

- Mobile-first approach
- Flexible grid systems
- Optimized touch targets
- Readable typography at all sizes

## 🔧 Technical Details

- **Framework**: Jekyll (GitHub Pages compatible)
- **CSS**: Custom CSS with CSS Grid and Flexbox
- **JavaScript**: Minimal vanilla JS (if needed)
- **Hosting**: GitHub Pages with custom domain support

## 📧 Contact Form

The contact form is ready for integration with:
- Formspree
- Netlify Forms
- EmailJS
- Custom backend solution

## 🚀 Deployment

The site automatically deploys to GitHub Pages when you push to the main branch.

### Custom Domain

1. Add your domain to `CNAME` file
2. Configure DNS with your domain provider
3. Enable HTTPS in GitHub Pages settings

## 📝 License

This project is open source and available under the [Apache License 2.0](LICENSE).

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

---

**Live Site**: [www.frankxue.dev](https://www.frankxue.dev)
**GitHub**: [@frankxue831](https://github.com/frankxue831)
