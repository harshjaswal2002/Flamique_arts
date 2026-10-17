export const categories = [
{id:'candles',name:'Scented candles',description:'A little light. A whole lot of feeling.'},
{id:'sculptural',name:'Sculptural candles',description:'Little works of art, made to glow.'},
{id:'decor',name:'Handmade décor',description:'Thoughtful details for your favourite corners.'},
{id:'gifts',name:'Gift sets',description:'For the people who make life warmer.'}
];
const img=(id)=>`https://images.unsplash.com/${id}?auto=format&fit=crop&w=1000&q=85`;
export const products=[
{id:'amber-glow',title:'The Amber Glow',category:'candles',description:'A warm, comforting candle for slow evenings and familiar corners. Sample product: final wax, fragrance, burn time and care details will be confirmed by the maker.',price:649,quantity:12,image:img('photo-1602874801007-bd458bb1b8b6'),tag:'Bestseller',scent:'Amber · Vanilla',weight:'180 g'},
{id:'soft-mornings',title:'Soft Mornings',category:'candles',description:'An easy little ritual for a softer start to your day. Sample product; specifications and materials are awaiting confirmation.',price:549,quantity:8,image:img('photo-1603006905003-be475563bc59'),tag:'A little everyday luxury',scent:'Fresh linen · Cotton',weight:'150 g'},
{id:'bloom',title:'Bloom, Slowly',category:'sculptural',description:'A playful sculptural piece for shelves, bedside tables and thoughtful gifts. Sample product; colour and dimensions to be confirmed.',price:399,quantity:6,image:img('photo-1605651202774-7d573fd3f12d'),tag:'Hand-poured',scent:'Floral notes',weight:'120 g'},
{id:'golden-hour',title:'Golden Hour',category:'candles',description:'A golden glow for the moments you want to stay in. Sample product; fragrance and burn time to be confirmed.',price:749,quantity:10,image:img('photo-1602523961358-f9f03dd557db'),tag:'Made for slow living',scent:'Sandalwood · Warm spice',weight:'200 g'},
{id:'little-rituals',title:'Little Rituals Set',category:'gifts',description:'A thoughtful pairing for a birthday, thank-you or just because. Sample gift set; contents and packaging to be confirmed.',price:1199,quantity:5,image:img('photo-1603006905003-be475563bc59'),tag:'Gift-worthy',scent:'Curated collection',weight:'Gift set'},
{id:'quiet-corner',title:'The Quiet Corner',category:'decor',description:'A handmade accent for the corners that feel most like you. Sample piece; material, size and finish to be confirmed.',price:449,quantity:7,image:img('photo-1490312278390-ab64016e0aa9'),tag:'Made with care',scent:'Artisan décor',weight:'One piece'}
];
