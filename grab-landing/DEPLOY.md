# Deployment Instructions

## GitHub Pages Setup

1. **Enable GitHub Pages** in your repository:
   - Go to Settings → Pages: https://github.com/arach/grab/settings/pages
   - Under "Source", select "GitHub Actions"
   - Save the settings

2. **Automatic Deployment**:
   - The site automatically deploys when changes are pushed to the `master` branch
   - Only changes in the `grab-landing/` directory trigger deployment

3. **Manual Deployment**:
   - Go to Actions tab: https://github.com/arach/grab/actions
   - Select "Deploy Landing Page to GitHub Pages"
   - Click "Run workflow"

## Local Testing

To test the production build locally:

```bash
cd grab-landing
npm run build
npx serve out
```

## Production URL

Once deployed, your site will be available at:
https://arach.github.io/grab/

Note: The first deployment may take a few minutes to become available.

## Troubleshooting

- If images don't load, ensure they're in the `public/` directory
- For routing issues, check that `basePath` in `next.config.ts` is set correctly
- The `.nojekyll` file is automatically created during build to ensure proper GitHub Pages rendering