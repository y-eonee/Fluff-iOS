// 피그마 원본 SVG 필터를 PNG로 보존한다. iOS의 SVG 에셋 컴파일러는 질감 필터를 지원하지 않는다.
// node scripts/render_design_a_assets.cjs <sharp 모듈 경로>
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[2] || 'sharp');
const catalog = path.join(__dirname, '../Malrang/Assets.xcassets/DesignA');
(async () => {
  let count = 0;
  for (const folder of fs.readdirSync(catalog).filter(name => name.endsWith('.imageset'))) {
    const directory = path.join(catalog, folder);
    const source = fs.readdirSync(directory).find(name => name.endsWith('.svg'));
    if (!source) continue;
    const name = folder.replace('.imageset', '');
    // 루트 치수와 원본 필터 수치는 유지하고 Retina 3배 밀도로만 렌더링한다.
    await sharp(path.join(directory, source), {density:216}).png().toFile(path.join(directory, name + '@3x.png'));
    fs.writeFileSync(path.join(directory, 'Contents.json'), JSON.stringify({
      images:[{filename:name+'@3x.png',idiom:'universal',scale:'3x'}],
      info:{author:'xcode',version:1}
    }, null, 2) + '\n');
    count++;
  }
  console.log(`Rendered ${count} original A assets with Figma texture filters`);
})().catch(error => { console.error(error); process.exitCode = 1; });
