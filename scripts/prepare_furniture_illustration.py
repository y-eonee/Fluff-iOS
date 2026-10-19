"""원본 Figma 벡터의 면과 색을 보존해 회전 가능한 가구 데이터를 만든다.

실행: python3 scripts/prepare_furniture_illustration.py
외부 패키지는 사용하지 않는다. 원본의 보이지 않던 뒷면은 같은 색으로 닫는다.
"""
import copy
import json
import math
import re
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SVG = ET.parse(Path(__file__).with_name('room-illustration.svg')).getroot()
PATHS = {int(p.attrib['id'].removeprefix('Vector_')) if p.attrib['id'] != 'Vector' else 1: p.attrib
         for p in SVG.iter('{http://www.w3.org/2000/svg}path')}
SCALE_X, SCALE_Z = 76, 38.95
SCALE_Y = SCALE_X * math.sqrt(2) * math.sqrt(1 - (SCALE_Z / SCALE_X) ** 2)
INK = '#8E6A5C'


def points(d):
    tokens = re.findall(r'[MLHVCZmlhvcz]|[-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?', d)
    out, current, start, i, command = [], (0., 0.), (0., 0.), 0, None
    while i < len(tokens):
        if tokens[i].isalpha():
            command = tokens[i]; i += 1
        if command.upper() == 'Z':
            current = start; command = None
            continue
        count = {'M': 2, 'L': 2, 'H': 1, 'V': 1, 'C': 6}[command.upper()]
        numbers = list(map(float, tokens[i:i + count])); i += count
        relative = command.islower()
        x, y = current
        if command.upper() in ('M', 'L'):
            dest = (numbers[0] + (x if relative else 0), numbers[1] + (y if relative else 0))
            out.append(dest)
            if command.upper() == 'M':
                start = dest; command = 'l' if relative else 'L'
        elif command.upper() == 'H':
            dest = (numbers[0] + (x if relative else 0), y); out.append(dest)
        elif command.upper() == 'V':
            dest = (x, numbers[0] + (y if relative else 0)); out.append(dest)
        else:
            controls = [(numbers[j] + (x if relative else 0), numbers[j + 1] + (y if relative else 0)) for j in (0, 2, 4)]
            for step in range(1, 9):
                t = step / 8; u = 1 - t
                out.append(tuple(u ** 3 * current[k] + 3 * u * u * t * controls[0][k]
                                 + 3 * u * t * t * controls[1][k] + t ** 3 * controls[2][k] for k in (0, 1)))
            dest = controls[2]
        current = dest
    if len(out) > 2 and math.dist(out[0], out[-1]) < .0001:
        out.pop()
    return out


def unproject(p, axis, value):
    u = (p[0] - 171) / SCALE_X
    if axis == 'y':
        v = (p[1] - 229.9 + SCALE_Y * value) / SCALE_Z
        return [(u + v) / 2, value, (v - u) / 2]
    if axis == 'x':
        x, z = value, value - u
    else:
        x, z = value + u, value
    y = (229.9 + SCALE_Z * (x + z) - p[1]) / SCALE_Y
    return [x, y, z]


def face(vertices, color, stroke=False, custom=False, closed=True):
    return {'vertices': copy.deepcopy(vertices), 'color': color or 'none', 'stroke': stroke,
            'custom': custom, 'closed': closed, 'photo': False, 'hiddenByPhoto': False}


GROUPS = {
    3: list(range(3,13)) + [34,37] + list(range(65,70)),
    13: list(range(13,34)) + [35,36],
    38: list(range(38,65)), 70: [70,71], 81: list(range(81,131)),
    140: [140] + list(range(143,160)), 186: [186] + list(range(189,193)),
}


def attach_art(target, number, mapping):
    selected = GROUPS.get(number, [number])
    ps = [p for n in selected for p in points(PATHS[n]['d'])]
    lo = [min(p[i] for p in ps) - 3 for i in (0,1)]
    hi = [max(p[i] for p in ps) + 3 for i in (0,1)]
    target['textureVertices'] = [mapping(p) for p in ((lo[0],lo[1]),(hi[0],lo[1]),(hi[0],hi[1]),(lo[0],hi[1]))]
    target['art'] = {'paths': selected, 'box': [lo[0],lo[1],hi[0]-lo[0],hi[1]-lo[1]]}


MODELS = {k: [] for k in ['wall', 'floor', 'bed', 'desk', 'shelf', 'chair', 'sofa', 'rugRound', 'rugSquare', 'plant', 'frame', 'lamp']}


def add(kind, number, axis, value, custom=False):
    path = PATHS[number]
    vertices = [unproject(p, axis, value) for p in points(path['d'])]
    MODELS[kind].append(face(vertices, path.get('fill'), 'stroke' in path, custom, path['d'].strip().endswith('Z')))
    MODELS[kind][-1]['source'] = number
    MODELS[kind][-1]['normal'] = {'x':[1,0,0],'y':[0,1,0],'z':[0,0,1]}[axis]
    attach_art(MODELS[kind][-1], number, lambda p: unproject(p, axis, value))
    return vertices


def plane_from_edge(vertices, projected):
    # 원본의 대각선은 x 또는 z 축, 세로선은 높이 축이다.
    for a, b in zip(projected, projected[1:] + projected[:1]):
        dx, dy = b[0] - a[0], b[1] - a[1]
        if abs(dx) > 0.1:
            axis = 'z' if dy / dx > 0 else 'x'
            index = 2 if axis == 'z' else 0
            # 앞서 만든 윗면에 있는 공통 꼭짓점의 깊이를 쓴다.
            near, _ = min(((j, p) for j in range(len(vertices)) for p in projected),
                          key=lambda pair: math.dist(pair[1], project(vertices[pair[0]])))
            return axis, vertices[near][index]
    raise ValueError('No horizontal edge')


def project(v):
    x, y, z = v
    return [171 + SCALE_X * (x - z), 229.9 + SCALE_Z * (x + z) - SCALE_Y * y]


def cuboid(kind, first, top, custom=False):
    top_vertices = add(kind, first, 'y', top, custom)
    for number in (first + 1, first + 2):
        poly = points(PATHS[number]['d'])
        axis, value = plane_from_edge(top_vertices, poly)
        add(kind, number, axis, value, custom)
    # 원본에서 가려진 면도 막아 회전 후 속이 비어 보이지 않게 한다.
    all_vertices = [v for f in MODELS[kind][-3:] for v in f['vertices']]
    lo = [min(v[j] for v in all_vertices) for j in range(3)]
    hi = [max(v[j] for v in all_vertices) for j in range(3)]
    color = PATHS[first + 2].get('fill', '#E7C3A2')
    box = [[lo[0], lo[1], lo[2]], [hi[0], lo[1], lo[2]], [hi[0], hi[1], lo[2]], [lo[0], hi[1], lo[2]],
           [lo[0], lo[1], hi[2]], [hi[0], lo[1], hi[2]], [hi[0], hi[1], hi[2]], [lo[0], hi[1], hi[2]]]
    for indices, normal in zip(([0, 1, 2, 3], [0, 3, 7, 4], [0, 4, 5, 1]), ([0,0,-1],[-1,0,0],[0,-1,0])):
        MODELS[kind].append(face([box[i] for i in indices], color, True, custom))
        MODELS[kind][-1]['normal'] = normal


for n in list(range(3, 13)) + [34, 37] + list(range(65, 70)):
    add('wall', n, 'x', -1, n < 38)
for n in list(range(13, 34)) + [35, 36]:
    add('wall', n, 'z', -1, True)
for n in range(38, 65):
    add('floor', n, 'y', 0, True)
add('floor', 1, 'z', 1, True)
add('floor', 2, 'x', 1, True)
for n in (70, 71):
    add('frame', n, 'z', -0.998, n == 70)
cuboid('shelf', 72, 1.09, True)
cuboid('shelf', 75, 1.09 + 11.4 / SCALE_Y)
cuboid('shelf', 78, 1.09 + 15.2 / SCALE_Y)
for n in range(81, 131):
    add('rugRound', n, 'y', .01, 82 <= n <= 129)
cuboid('bed', 131, 53.2 / SCALE_Y)
cuboid('bed', 134, 15.2 / SCALE_Y)
cuboid('bed', 137, 24.7 / SCALE_Y)
cuboid('bed', 140, 27.55 / SCALE_Y)
for n in range(143, 160):
    add('bed', n, 'y', 27.55 / SCALE_Y + .0005, n < 159)
cuboid('bed', 160, 31.35 / SCALE_Y)
for n in (163, 166, 169, 172):
    cuboid('desk', n, 36.1 / SCALE_Y)
cuboid('desk', 175, 40.28 / SCALE_Y, True)
# 책상 위 작은 조명도 원본 위치와 크기로 유지한다.
center = unproject([281.961, 177.936], 'y', 40.28 / SCALE_Y)
for n in (178, 179):
    poly = points(PATHS[n]['d'])
    front = [[center[0] + (p[0] - 281.961) / (2 * SCALE_X), center[1] + (177.936 - p[1]) / SCALE_Y,
              center[2] - (p[0] - 281.961) / (2 * SCALE_X)] for p in poly]
    MODELS['desk'].append(face(front, PATHS[n].get('fill'), True, False, n == 179))
    MODELS['desk'][-1]['normal'] = [1,0,1]
    attach_art(MODELS['desk'][-1], n, lambda p: [center[0]+(p[0]-281.961)/(2*SCALE_X), center[1]+(177.936-p[1])/SCALE_Y, center[2]-(p[0]-281.961)/(2*SCALE_X)])
    if n == 179:
        back = [[x - .012, y, z - .012] for x, y, z in front]
        MODELS['desk'].append(face(back[::-1], PATHS[n]['fill'], True))
        MODELS['desk'][-1]['normal'] = [-1,0,-1]
        for i in range(len(front)):
            j = (i + 1) % len(front)
            MODELS['desk'].append(face([front[i], back[i], back[j], front[j]], PATHS[n]['fill']))
cuboid('chair', 180, 15.2 / SCALE_Y, True)
cuboid('chair', 183, 47.5 / SCALE_Y, True)
cuboid('chair', 186, 20.9 / SCALE_Y)
for n in range(189, 193):
    add('chair', n, 'y', 20.9 / SCALE_Y + .0005)
cuboid('plant', 193, 15.2 / SCALE_Y)
for n in range(196, 199):
    # 잎은 원본 곡선을 앞뒤로 두께 있게 연결해 종이 조각처럼 서 있게 한다.
    poly = points(PATHS[n]['d'])
    cx, cz = unproject([53.96, 226.004], 'y', 0)[::2]
    vertices = [[cx + (p[0] - 53.96) / (2 * SCALE_X), (226.004 - p[1]) / SCALE_Y,
                 cz - (p[0] - 53.96) / (2 * SCALE_X)] for p in poly]
    back = [[x - .008, y, z - .008] for x, y, z in vertices]
    MODELS['plant'].append(face(vertices, PATHS[n]['fill'], True, True))
    MODELS['plant'][-1]['normal'] = [1,0,1]
    attach_art(MODELS['plant'][-1], n, lambda p: [cx+(p[0]-53.96)/(2*SCALE_X),(226.004-p[1])/SCALE_Y,cz-(p[0]-53.96)/(2*SCALE_X)])
    MODELS['plant'].append(face(back[::-1], PATHS[n]['fill'], True, True))
    MODELS['plant'][-1]['normal'] = [-1,0,-1]
    for i in range(len(vertices)):
        j = (i + 1) % len(vertices)
        MODELS['plant'].append(face([vertices[i], back[i], back[j], vertices[j]], PATHS[n]['fill'], False, True))
# 원본 책상 조명의 사다리꼴 갓과 가는 기둥.
for n in (178, 179):
    poly = points(PATHS[n]['d'])
    vertices = [[(p[0] - 281.961) / (2 * SCALE_X), (177.936 - p[1]) / SCALE_Y,
                 -(p[0] - 281.961) / (2 * SCALE_X)] for p in poly]
    MODELS['lamp'].append(face(vertices, PATHS[n].get('fill'), True, n == 179, n == 179))
    MODELS['lamp'][-1]['normal'] = [1,0,1]
    attach_art(MODELS['lamp'][-1], n, lambda p: [(p[0]-281.961)/(2*SCALE_X),(177.936-p[1])/SCALE_Y,-(p[0]-281.961)/(2*SCALE_X)])


def box(kind, size, center, colors, custom=False):
    x, y, z = center; w, h, d = [v / 2 for v in size]
    vertices = [[x-w,y-h,z-d],[x+w,y-h,z-d],[x+w,y+h,z-d],[x-w,y+h,z-d],
                [x-w,y-h,z+d],[x+w,y-h,z+d],[x+w,y+h,z+d],[x-w,y+h,z+d]]
    for i, indices in enumerate(([0,1,2,3],[1,5,6,2],[5,4,7,6],[4,0,3,7],[3,2,6,7],[0,4,5,1])):
        MODELS[kind].append(face([vertices[j] for j in indices], colors[i % len(colors)], True, custom))
        MODELS[kind][-1]['normal'] = [[0,0,-1],[1,0,0],[0,0,1],[-1,0,0],[0,1,0],[0,-1,0]][i]


# 원본에 없는 목록 가구도 같은 면 색과 윤곽선으로 만든다.
pink = ['#E99FB2', '#F2AEBF', '#F7B9C8']
box('sofa', [.9,.26,.4], [0,.19,0], pink, True)
box('sofa', [.9,.34,.06], [0,.43,-.17], pink, True)
for x in (-.4125,.4125):
    box('sofa', [.075,.25,.4], [x,.3,0], pink, True)
for x in (-.2,.2):
    box('sofa', [.18,.16,.055], [x,.4,-.07], ['#CFE8F2','#AFD3E2','#BFDDEA'])
for x in (-.35,.35):
    for z in (-.13,.13):
        box('sofa', [.05,.06,.05], [x,.03,z], ['#E7C3A2','#CFA585','#DDB493'])
box('rugSquare', [.9,.01,.6], [0,.005,0], ['#FFFDF8'])
for row in range(6):
    for col in range(8):
        if (row + col) % 2 == 0:
            x = -.45 + (col + .5) * .9 / 8; z = -.3 + (row + .5) * .6 / 6
            MODELS['rugSquare'].append(face([[x-.05625,.011,z-.05],[x+.05625,.011,z-.05],
                                            [x+.05625,.011,z+.05],[x-.05625,.011,z+.05]], '#F7B9C8', False, True))

SIZES = {'bed':[.802,.577,.922], 'desk':[.662,.705,.441], 'shelf':[.602,.217,.142], 'chair':[.362,.516,.362],
         'sofa':[.9,.6,.4], 'rugRound':[.801,.01,.801], 'rugSquare':[.9,.011,.6], 'plant':[.208,.528,.208],
         'frame':[.32,.351,.025], 'lamp':[.113,.268,.138]}

for kind, faces in MODELS.items():
    if kind in ('wall', 'floor'):
        continue
    vertices = [v for f in faces for v in f['vertices']]
    lo = [min(v[i] for v in vertices) for i in range(3)]
    hi = [max(v[i] for v in vertices) for i in range(3)]
    size = SIZES[kind]
    scale = [size[i] / max(hi[i] - lo[i], .001) for i in range(3)]
    if kind in ('frame', 'lamp'):
        # 평면 원화에 두께를 더하고 정면 비율을 유지한다.
        scale[2] = scale[0]
    for f in faces:
        for v in f['vertices'] + f.get('textureVertices', []):
            v[:] = [round((v[i] - (lo[i] if i == 1 else (hi[i] + lo[i]) / 2)) * scale[i], 6) for i in range(3)]

for f in MODELS['rugRound']:
    for v in f['vertices'] + f.get('textureVertices', []):
        v[1] += .008

# 액자와 조명의 뒷면을 닫는다.
for kind in ('frame', 'lamp'):
    originals = copy.deepcopy(MODELS[kind])
    for f in originals:
        if kind == 'frame' and f.get('source') == 71:
            continue
        if f['color'] == 'none':
            continue
        back = [[x, y, z - .025] for x, y, z in f['vertices']]
        MODELS[kind].append(face(back[::-1], f['color'], f['stroke'], f['custom']))
        MODELS[kind][-1]['normal'] = [0,0,-1]
        if f['closed']:
            for i, v in enumerate(f['vertices']):
                j = (i + 1) % len(f['vertices'])
                MODELS[kind].append(face([v, back[i], back[j], f['vertices'][j]], f['color'], True))


# 두께를 추가한 뒤에도 실제 배치 영역 안에 들어오도록 중심을 맞춘다.
for kind in ('frame', 'lamp'):
    vertices = [v for f in MODELS[kind] for v in f['vertices']]
    lo, hi = min(v[2] for v in vertices), max(v[2] for v in vertices)
    factor = min(1, SIZES[kind][2] / max(hi - lo, .001))
    for f in MODELS[kind]:
        for v in f['vertices'] + f.get('textureVertices', []):
            v[2] = round((v[2] - (lo + hi) / 2) * factor, 6)


def triangulate(vertices):
    if len(vertices) < 3:
        return []
    a, b, c = vertices[:3]
    ab = [b[i] - a[i] for i in range(3)]; ac = [c[i] - a[i] for i in range(3)]
    normal = [ab[1]*ac[2]-ab[2]*ac[1], ab[2]*ac[0]-ab[0]*ac[2], ab[0]*ac[1]-ab[1]*ac[0]]
    drop = max(range(3), key=lambda i: abs(normal[i]))
    axes = [i for i in range(3) if i != drop]
    poly = [[v[i] for i in axes] for v in vertices]
    cross = lambda a,b,c: (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    area = sum(poly[i][0]*poly[(i+1)%len(poly)][1]-poly[(i+1)%len(poly)][0]*poly[i][1] for i in range(len(poly)))
    direction = 1 if area > 0 else -1
    indices, triangles = list(range(len(poly))), []
    while len(indices) > 2:
        found = False
        for i,b in enumerate(indices):
            a,c = indices[i-1],indices[(i+1)%len(indices)]
            if cross(poly[a],poly[b],poly[c])*direction <= 1e-12:
                continue
            if any(min(cross(poly[a],poly[b],poly[p])*direction,
                       cross(poly[b],poly[c],poly[p])*direction,
                       cross(poly[c],poly[a],poly[p])*direction) > 1e-12 for p in indices if p not in (a,b,c)):
                continue
            triangles.extend([a,b,c]); indices.pop(i); found=True; break
        if not found:
            # 중복되거나 같은 직선 위에 놓인 원본 꼭짓점을 제거한다.
            collinear = next((i for i,b in enumerate(indices) if abs(cross(poly[indices[i-1]],poly[b],poly[indices[(i+1)%len(indices)]])) < 1e-9), None)
            if collinear is None:
                raise ValueError('Could not triangulate illustration face')
            indices.pop(collinear)
    return triangles

for faces in MODELS.values():
    for f in faces:
        f['triangles'] = triangulate(f['vertices']) if f['color'] != 'none' else []

# 사진은 무늬 조각마다 반복하지 않고 가구의 한 면 전체에 붙인다.
photo_faces = {'wall': {3,13}, 'floor': {38}, 'bed': {140}, 'desk': {175},
               'shelf': {77}, 'chair': {186}, 'rugRound': {81}, 'frame': {70}}
for kind, faces in MODELS.items():
    for f in faces:
        number = f.get('source', 0)
        f['photo'] = number in photo_faces.get(kind, set())
        f['hiddenByPhoto'] = ((kind == 'bed' and 143 <= number <= 159)
            or (kind == 'rugRound' and 82 <= number <= 129)
            or (kind == 'wall' and number in set(range(4,13)) | set(range(14,34))))
        # source는 아래 텍스처 병합에서 쓴다.
MODELS['sofa'][4]['photo'] = True
MODELS['rugSquare'][4]['photo'] = True
for f in MODELS['rugSquare'][6:]:
    f['hiddenByPhoto'] = True
# 입체 잎과 조명 갓의 앞면.
MODELS['plant'][6]['photo'] = True
MODELS['lamp'][1]['photo'] = True


# 원본과 같은 평면의 무늬를 함께 렌더링한다. 선을 다시 그리거나 임의 노이즈로 바꾸지 않는다.
secondary = {n for first, ns in GROUPS.items() for n in ns if n != first}
for kind in MODELS:
    MODELS[kind] = [f for f in MODELS[kind] if f.get('source') not in secondary]

ET.register_namespace('', 'http://www.w3.org/2000/svg')
defs = ET.tostring(SVG.find('{http://www.w3.org/2000/svg}defs'), encoding='unicode')
MODELS['rugSquare'][4]['extras'] = copy.deepcopy(MODELS['rugSquare'][6:])
MODELS['rugSquare'] = MODELS['rugSquare'][:6]
svg_dir = Path('/tmp/malrang-illustration-svg')
svg_dir.mkdir(exist_ok=True)
manifest = []
for kind, fs in MODELS.items():
    for index, f in enumerate(fs):
        art = f.pop('art', None)
        f.pop('source', None)
        if art:
            body = ''.join(ET.tostring(ET.Element('path', PATHS[n]), encoding='unicode') for n in art['paths'])
            x,y,w,h = art['box']
        elif f['stroke']:
            vs = f['vertices']
            ps = [project(v) for v in vs]
            x,y = min(p[0] for p in ps)-3,min(p[1] for p in ps)-3
            w,h = max(p[0] for p in ps)+3-x,max(p[1] for p in ps)+3-y
            # 삼차원 평면의 원본 투영을 역변환해 텍스처를 같은 면 위에 놓는다.
            a = vs[0]; sa = ps[0]
            pair = next(((j,k) for j in range(1,len(vs)) for k in range(j+1,len(vs))
                         if abs((ps[j][0]-sa[0])*(ps[k][1]-sa[1])-(ps[k][0]-sa[0])*(ps[j][1]-sa[1])) > 1e-6), None)
            if pair is None:
                continue
            j,k = pair
            ux,uy = ps[j][0]-sa[0],ps[j][1]-sa[1]
            vx,vy = ps[k][0]-sa[0],ps[k][1]-sa[1]
            determinant = ux*vy-vx*uy
            def mapping(p):
                u=((p[0]-sa[0])*vy-(p[1]-sa[1])*vx)/determinant
                v=(ux*(p[1]-sa[1])-uy*(p[0]-sa[0]))/determinant
                return [round(a[i]+(vs[j][i]-a[i])*u+(vs[k][i]-a[i])*v,6) for i in range(3)]
            f['textureVertices'] = [mapping(p) for p in ((x,y),(x+w,y),(x+w,y+h),(x,y+h))]
            d='M'+'L'.join(f'{p[0]},{p[1]}' for p in ps)+('Z' if f['closed'] else '')
            body=ET.tostring(ET.Element('path', {'d':d,'fill':f['color'],'stroke':'#8E6A5C','stroke-width':'1.045','stroke-linejoin':'round'}),encoding='unicode')
        else:
            continue
        for extra in f.pop('extras', []):
            ps = [project(v) for v in extra['vertices']]
            d = 'M'+'L'.join(f'{p[0]},{p[1]}' for p in ps)+'Z'
            body += ET.tostring(ET.Element('path', {'d':d,'fill':extra['color']}),encoding='unicode')
        name=f'illustration_{kind}_{index}'
        f['texture'] = name
        svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{x} {y} {w} {h}" fill="none">{defs}<g filter="url(#filter0_g_0_4)">{body}</g></svg>'
        (svg_dir/(name+'.svg')).write_text(svg)
        manifest.append(name)
(svg_dir/'manifest.json').write_text(json.dumps(manifest))

output = ROOT / 'Malrang/Resources/RoomIllustration.json'
output.write_text(json.dumps(MODELS, separators=(',', ':')) + '\n')
print(f'Wrote {sum(map(len, MODELS.values()))} illustration faces to {output}')

# 목록은 원본 가구 그림 자체를 쓴다. 방 안의 면 텍스처와 같은 필터·색·비율이다.
catalog_paths = {'bed': list(range(131,163)), 'desk': list(range(163,180)), 'shelf': list(range(72,81)),
                 'chair': list(range(180,193)), 'rugRound': list(range(81,131)), 'plant': list(range(193,199)),
                 'frame': [70,71], 'lamp': [178,179]}
for kind, numbers in catalog_paths.items():
    ps = [p for n in numbers for p in points(PATHS[n]['d'])]
    x,y = min(p[0] for p in ps)-3,min(p[1] for p in ps)-3
    w,h = max(p[0] for p in ps)+3-x,max(p[1] for p in ps)+3-y
    body = ''.join(ET.tostring(ET.Element('path', PATHS[n]),encoding='unicode') for n in numbers)
    svg=f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="{x} {y} {w} {h}" fill="none">{defs}<g filter="url(#filter0_g_0_4)">{body}</g></svg>'
    (svg_dir/('catalog_'+kind+'.svg')).write_text(svg)
