// Node용 sharp는 빌드 도구에서만 사용하며 iOS 앱에는 포함되지 않는다.
// node scripts/render_illustration_textures.cjs <sharp 모듈 경로>
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[2] || 'sharp');
const repository = path.resolve(__dirname, '..');
const input = '/tmp/malrang-illustration-svg';
const output = path.join(repository, 'Malrang/Resources/IllustrationTextures');
fs.mkdirSync(output, {recursive:true});
const names = JSON.parse(fs.readFileSync(path.join(input,'manifest.json'),'utf8'));
(async () => {
  // 원본 feTurbulence/feDisplacementMap을 그대로 렌더링한다.
  for (const name of names) {
    await sharp(path.join(input,name+'.svg'), {density:288}).png().toFile(path.join(output,name+'.png'));
  }
  const expected = new Set(names.map(name => name+'.png'));
  for (const filename of fs.readdirSync(output)) {
    if (filename.startsWith('illustration_') && filename.endsWith('.png') && !expected.has(filename)) fs.unlinkSync(path.join(output,filename));
  }
  const catalog = '/tmp/malrang-source-catalog';
  fs.mkdirSync(catalog,{recursive:true});
  await sharp(path.join(__dirname,'memo-board.svg'),{density:288}).png()
    .toFile(path.join(output,'memo_board.png'));
  for (const filename of fs.readdirSync(input).filter(name=>name.startsWith('catalog_') && name.endsWith('.svg'))) {
    await sharp(path.join(input,filename),{density:288}).resize(480,360,{fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).png()
      .toFile(path.join(catalog,filename.replace('catalog_','furniture_').replace('.svg','.png')));
  }
  console.log(`Rendered ${names.length} original-filter furniture textures`);
})().catch(error => { console.error(error); process.exitCode = 1; });
