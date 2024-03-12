import { defineConfig } from "vite";
import adapter from "elm-pages/adapter/netlify.js";
import { ViteWebfontDownload } from "vite-plugin-webfont-dl";
import redirects from "./redirect.js";

export default {
  vite: defineConfig({
    assetsInclude: ['/elm-pages.js'],
    plugins: [
      ViteWebfontDownload([
        // "https://fonts.googleapis.com/css2?family=IBM+Plex+Mono&display=swap&subset=latin",
      ]),
    ]

  }),
  adapter,
  redirects,
  headTagsTemplate(context) {
    return `
<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-EK2K1R622C"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-EK2K1R622C');
</script>    
<link rel="stylesheet" href="/style.css" />
<meta name="generator" content="elm-pages v${context.cliVersion}" />
`;
  },
  preloadTagForFile(file) {
    // add preload directives for JS assets and font assets, etc., skip for CSS files
    // this function will be called with each file that is procesed by Vite, including any files in your headTagsTemplate in your config
    return !file.endsWith(".css");
  },
};
