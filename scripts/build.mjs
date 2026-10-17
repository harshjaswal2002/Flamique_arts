import {rm,mkdir,cp,writeFile} from 'node:fs/promises';
await rm('public',{recursive:true,force:true}); await mkdir('public/admin',{recursive:true});
await cp('apps/storefront','public',{recursive:true}); await cp('apps/admin','public/admin',{recursive:true}); await cp('packages/shared','public/shared',{recursive:true});
await writeFile('public/robots.txt','User-agent: *\nAllow: /\nDisallow: /admin/\nDisallow: /checkout\n');
console.log('Built storefront, admin, and shared modules.');
