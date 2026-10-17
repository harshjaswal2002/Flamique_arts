import {rm,mkdir,cp,writeFile} from 'node:fs/promises';
import {build} from 'esbuild';
await rm('public',{recursive:true,force:true}); await mkdir('public/admin',{recursive:true});
await cp('apps/storefront','public',{recursive:true}); await cp('apps/admin','public/admin',{recursive:true}); await cp('packages/shared','public/shared',{recursive:true});
await build({entryPoints:['packages/shared/supabase.js'],outfile:'public/shared/supabase.js',bundle:true,format:'esm',platform:'browser',target:['es2022'],minify:true});
await writeFile('public/robots.txt','User-agent: *\nAllow: /\nDisallow: /admin/\nDisallow: /checkout\nSitemap: https://flamique-arts.vercel.app/sitemap.xml\n');
console.log('Built storefront, admin, and shared modules.');

await writeFile('public/sitemap.xml','<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>https://flamique-arts.vercel.app/</loc></url></urlset>');
