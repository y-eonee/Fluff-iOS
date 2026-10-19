// 현재 입체 면·RGBA 텍스처를 깊이 버퍼로 검증하는 미리보기. GPU·앱 화면 조작 없이 동작한다.
// node scripts/render_illustration_preview.cjs <sharp 모듈 경로>
const fs=require('node:fs'), path=require('node:path');
const sharp=require(process.argv[2]||'sharp');
const root=path.resolve(__dirname,'..');
const models=JSON.parse(fs.readFileSync(path.join(root,'Malrang/Resources/RoomIllustration.json'),'utf8'));
const directory=path.join(root,'Malrang/Resources/IllustrationTextures');
const output='/tmp/malrang-original-style';
fs.mkdirSync(output,{recursive:true});
const ratio=38.95/76, vertical=Math.sqrt(2)*Math.sqrt(1-ratio*ratio), cameraY=2*ratio/vertical;
const textures=new Map();
const project=([x,y,z])=>[x-z,ratio*(x+z)-vertical*y,x+z+cameraY*y];
function transform([x,y,z],pose={}) {
  const c=Math.cos(pose.yaw||0),s=Math.sin(pose.yaw||0); x*=pose.mirror?-1:1;
  return [c*x+s*z+(pose.x||0),y+(pose.y||0),-s*x+c*z+(pose.z||0)];
}
function faces(kind,pose={}) {
  return models[kind].map((f,layer)=>{
    const textured=!!f.texture && f.textureVertices?.length===4;
    const points=(textured?f.textureVertices:f.vertices).map(p=>p.slice());
    if(points.length>=3) {
      const a=points[1].map((v,i)=>v-points[0][i]),b=points[2].map((v,i)=>v-points[0][i]);
      let n=[a[1]*b[2]-a[2]*b[1],a[2]*b[0]-a[0]*b[2],a[0]*b[1]-a[1]*b[0]];
      const length=Math.hypot(...n)||1; if(n[0]+n[1]*0.85+n[2]<0)n=n.map(v=>-v);
      for(const p of points)for(let i=0;i<3;i++)p[i]+=n[i]/length*layer*0.00004;
    }
    return {f,points:points.map(p=>project(transform(p,pose))),indices:textured?[0,1,2,0,2,3]:f.triangles,
            uv:[[0,1],[1,1],[1,0],[0,0]],texture:textured?textures.get(f.texture):null};
  });
}
function color(value) {
  if(value==='white')return [255,255,255,255];
  const n=parseInt(value.slice(1),16);return [(n>>16)&255,(n>>8)&255,n&255,255];
}
function sample(texture,u,v) {
  const {data,width,height}=texture;
  // IllustrationMesh와 같은 V 좌표를 쓰되 PNG 행은 위에서 아래로 읽는다.
  v=1-v;
  const x=Math.max(0,Math.min(width-1,u*(width-1))),y=Math.max(0,Math.min(height-1,v*(height-1)));
  const x0=Math.floor(x),y0=Math.floor(y),x1=Math.min(width-1,x0+1),y1=Math.min(height-1,y0+1);
  const tx=x-x0,ty=y-y0;
  const p0=(y0*width+x0)*4,p1=(y0*width+x1)*4,p2=(y1*width+x0)*4,p3=(y1*width+x1)*4;
  return [0,1,2,3].map(c=>(data[p0+c]*(1-tx)+data[p1+c]*tx)*(1-ty)+(data[p2+c]*(1-tx)+data[p3+c]*tx)*ty);
}
function raster(surfaces,width,height,scale,dx,dy,paper=false) {
  const data=Buffer.alloc(width*height*4),depth=new Float64Array(width*height);depth.fill(-Infinity);
  if(paper)for(let i=0;i<width*height;i++){data[i*4]=255;data[i*4+1]=255;data[i*4+2]=244;data[i*4+3]=255;}
  for(const face of surfaces) {
    const ps=face.points.map(([x,y,z])=>[x*scale+dx,y*scale+dy,z]);
    const flat=face.f.color==='none'?null:color(face.f.color);
    for(let k=0;k<face.indices.length;k+=3) {
      const ia=face.indices[k],ib=face.indices[k+1],ic=face.indices[k+2],a=ps[ia],b=ps[ib],c=ps[ic];
      const determinant=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1]);
      if(Math.abs(determinant)<1e-8)continue;
      const x0=Math.max(0,Math.floor(Math.min(a[0],b[0],c[0]))),x1=Math.min(width-1,Math.ceil(Math.max(a[0],b[0],c[0])));
      const y0=Math.max(0,Math.floor(Math.min(a[1],b[1],c[1]))),y1=Math.min(height-1,Math.ceil(Math.max(a[1],b[1],c[1])));
      for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++) {
        const px=x+0.5,py=y+0.5;
        const u=((b[1]-c[1])*(px-c[0])+(c[0]-b[0])*(py-c[1]))/determinant;
        const v=((c[1]-a[1])*(px-c[0])+(a[0]-c[0])*(py-c[1]))/determinant,w=1-u-v;
        if(u<0||v<0||w<0)continue;
        const z=u*a[2]+v*b[2]+w*c[2],pixel=y*width+x;
        if(z<depth[pixel]-1e-7)continue;
        const rgba=face.texture?sample(face.texture,u*face.uv[ia][0]+v*face.uv[ib][0]+w*face.uv[ic][0],u*face.uv[ia][1]+v*face.uv[ib][1]+w*face.uv[ic][1]):flat;
        if(!rgba||rgba[3]<25.5)continue;
        const offset=pixel*4,alpha=rgba[3]/255,destination=data[offset+3]/255,combined=alpha+destination*(1-alpha);
        for(let j=0;j<3;j++)data[offset+j]=Math.round((rgba[j]*alpha+data[offset+j]*destination*(1-alpha))/combined);
        data[offset+3]=Math.round(combined*255);depth[pixel]=z;
      }
    }
  }
  return sharp(data,{raw:{width,height,channels:4}}).png().toBuffer();
}
async function thumbnail(kind,pose={}) {
  const fs=faces(kind,pose),ps=fs.flatMap(f=>f.points);
  const lo=[Math.min(...ps.map(p=>p[0])),Math.min(...ps.map(p=>p[1]))],hi=[Math.max(...ps.map(p=>p[0])),Math.max(...ps.map(p=>p[1]))];
  const scale=Math.min(400/(hi[0]-lo[0]),280/(hi[1]-lo[1]));
  return raster(fs,480,360,scale,240-(lo[0]+hi[0])/2*scale,180-(lo[1]+hi[1])/2*scale);
}
(async()=>{
  for(const name of new Set(Object.values(models).flat().map(f=>f.texture).filter(Boolean))) {
    const {data,info}=await sharp(path.join(directory,name+'.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
    textures.set(name,{data,width:info.width,height:info.height});
  }
  const kinds=['bed','desk','shelf','chair','sofa','rugRound','rugSquare','plant','frame','lamp'];
  const labels=['침대','책상','선반','의자','소파','원형 러그','사각 러그','화분','액자','조명'];
  let sheet='';
  for(let i=0;i<kinds.length;i++) {
    const kind=kinds[i],destination=path.join(output,`furniture_${kind}.png`),catalog=path.join('/tmp/malrang-source-catalog',`furniture_${kind}.png`);
    const native=await thumbnail(kind);fs.writeFileSync(path.join(output,`mesh_${kind}.png`),native);
    if(fs.existsSync(catalog))fs.copyFileSync(catalog,destination);else fs.writeFileSync(destination,native);
    const uri='data:image/png;base64,'+fs.readFileSync(destination).toString('base64');
    sheet+=`<g transform="translate(${i%3*480} ${Math.floor(i/3)*410})"><image href="${uri}" width="480" height="360"/><text x="240" y="390" font-family="sans-serif" font-size="24" fill="#6B4A3E" text-anchor="middle">${labels[i]}</text></g>`;
  }
  await sharp(Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="1640"><rect width="100%" height="100%" fill="#FFFFF4"/>${sheet}</svg>`)).png().toFile(path.join(output,'furniture-preview.png'));
  const poses=[['floor',{}],['wall',{}],['rugRound',{x:0.2118,z:0.2119}],['bed',{x:-0.5996,z:-0.22}],
    ['shelf',{x:0.4316,y:1.038,z:-0.9185}],['frame',{x:-0.598,y:0.866,z:-0.9775}],['desk',{x:0.4105,z:-0.7995}],
    ['plant',{x:-0.8425,z:0.6975}],['chair',{x:0.54,z:0.0201}]];
  fs.writeFileSync(path.join(output,'room-preview.png'),await raster(poses.flatMap(([kind,pose])=>faces(kind,pose)),1200,1100,240,600,760,true));
  const turns=[];
  for(let i=0;i<4;i++)turns.push({input:await thumbnail('bed',{yaw:i*Math.PI/2}),left:i*480,top:0});
  await sharp({create:{width:1920,height:360,channels:4,background:{r:255,g:255,b:244,alpha:1}}}).composite(turns).png().toFile(path.join(output,'rotation-preview.png'));
  console.log('Validated original textures with depth-buffer rendering; generated catalog, room, mesh, and rotation previews');
})().catch(error=>{console.error(error);process.exitCode=1;});
