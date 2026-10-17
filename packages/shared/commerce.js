export function totals(cart,products,settings){const subtotal=cart.reduce((s,c)=>{const p=products.find(p=>p.id===c.id);return s+(p?p.price*c.quantity:0)},0);const shipping=subtotal===0||subtotal>=settings.freeShippingThreshold?0:settings.shippingFee;return {subtotal,shipping,total:subtotal+shipping};}
export const money=n=>new Intl.NumberFormat('en-IN',{style:'currency',currency:'INR',maximumFractionDigits:0}).format(n);
export const escapeHtml=v=>String(v??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
export function validateProduct(p){return typeof p.title==='string'&&p.title.trim().length>0&&Number.isFinite(p.price)&&p.price>0&&Number.isInteger(p.quantity)&&p.quantity>=0&&!!p.category;}
