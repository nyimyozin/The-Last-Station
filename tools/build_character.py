"""Build the original Platform Zero traveler; Python stdlib only.
Authored lofts, swept hair locks and face patches, merged per joint/material.
Coordinates: metres, Y up, character faces -Z. No third-party model assets.
"""
import base64, json, math, struct
from pathlib import Path
from collections import defaultdict
sin, cos, pi = math.sin, math.cos, math.pi
ROOT = Path(__file__).resolve().parents[1]
palette = {'skin':'edcdb8','blush':'d8a493','hair':'293c4b','hairlight':'405867','ink':'26323e','white':'e8e4d6','navy':'344c60','trim':'aab8bc','ribbon':'b48067','skirt':'304453','pleat':'3d5667','sock':'303e4b','shoe':'4c4240','sole':'292e35','leather':'816b59','gold':'c9b38a','iris':'618b8c','irislight':'a0beb4','pupil':'203540','shine':'fff9e7'}
mats=[]
for name,h in palette.items():
    rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    mats.append({'name':name,'pbrMetallicRoughness':{'baseColorFactor':rgb+[1],'metallicFactor':0,'roughnessFactor':.9},'doubleSided':True})
mi={n:i for i,n in enumerate(palette)}
nodes=[]; geo=defaultdict(lambda:defaultdict(lambda:[[],[]]))
def node(name,pos=(0,0,0),parent=None):
    i=len(nodes); nodes.append({'name':name,'translation':list(pos),'children':[]})
    if parent is not None:nodes[parent]['children'].append(i)
    return i
root=node('Schoolgirl')
def surface(n,mat,v,f):
    out=geo[n][mat]; offset=len(out[0]); out[0].extend(v); out[1].extend(tuple(offset+x for x in t) for t in f)
def grid(n,mat,rows,closed=True):
    cols=len(rows[0]); v=sum(rows,[]); f=[]
    for r in range(len(rows)-1):
        for c in range(cols if closed else cols-1):
            a=r*cols+c;b=r*cols+(c+1)%cols;d=(r+1)*cols+c;e=(r+1)*cols+(c+1)%cols
            f.extend([(a,d,b),(b,d,e)])
    if sum(p[1] for p in rows[-1]) < sum(p[1] for p in rows[0]):
        f=[(a,c,b) for a,b,c in f]
    surface(n,mat,v,f)
def loft(n,mat,rings,segments=32,pleats=0):
    # Ring = y, half width, half depth, center z. Rounded cross-sections.
    rows=[]
    for y,rx,rz,z in rings:
        row=[]
        for j in range(segments):
            a=2*pi*j/segments; p=1+(0.045*cos(a*pleats) if pleats else 0)
            row.append((rx*cos(a)*p,y,z+rz*sin(a)*p))
        rows.append(row)
    grid(n,mat,rows)
def ellipsoid(n,mat,center,scale,seg=24,rings=12):
    rows=[]
    for j in range(rings+1):
        t=pi*j/rings
        rows.append([(center[0]+scale[0]*sin(t)*cos(2*pi*k/seg),center[1]+scale[1]*cos(t),center[2]+scale[2]*sin(t)*sin(2*pi*k/seg)) for k in range(seg)])
    grid(n,mat,rows)
def patch(n,mat,points):
    surface(n,mat,points,[(0,i,i+1) for i in range(1,len(points)-1)])
def tube(n,mat,points,r=.004,sides=8):
    # Swept small piping and seams, projected in XY.
    rows=[]
    for i,p in enumerate(points):
        q=points[min(i+1,len(points)-1)]; prev=points[max(0,i-1)]
        dx=q[0]-prev[0];dy=q[1]-prev[1];ll=math.hypot(dx,dy) or 1
        rows.append([(p[0]-dy/ll*r*cos(2*pi*k/sides),p[1]+dx/ll*r*cos(2*pi*k/sides),p[2]+r*sin(2*pi*k/sides)) for k in range(sides)])
    grid(n,mat,rows)
def lock(n,mat,points,widths,depth=.014):
    # Smoothly interpolate each authored guide section (Catmull-Rom).
    samples=[]
    for i in range(len(points)-1):
        for k in range(5):
            t=k/5
            def interp(vals):
                a,b,c,d=[vals[max(0,min(len(vals)-1,j))] for j in [i-1,i,i+1,i+2]]
                return .5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
            samples.append((tuple(interp([p[j] for p in points]) for j in range(3)),max(.001,interp(widths))))
    samples.append((points[-1],widths[-1]))
    rows=[]
    for p,w in samples:
        rows.append([(p[0]+w*cos(2*pi*k/12),p[1],p[2]+depth*sin(2*pi*k/12)) for k in range(12)])
    grid(n,mat,rows)
# Fitted sailor blouse, shaped shoulder line and waist.
loft(root,'white',[(.91,.145,.095,0),(.94,.168,.107,0),(1.04,.157,.103,0),(1.17,.18,.115,0),(1.28,.19,.104,0),(1.32,.155,.082,0),(1.345,.076,.06,0)])
loft(root,'skin',[(1.30,.064,.054,0),(1.43,.061,.054,0)])
loft(root,'navy',[(.915,.159,.108,0),(.955,.167,.111,0)])
# The collar is a tailored V at the front and square sailor flap at the back.
for s in [-1,1]:
    patch(root,'navy',[(s*.066,1.345,-.062),(s*.19,1.285,-.10),(s*.095,1.19,-.133),(0,1.16,-.137),(s*.033,1.285,-.125)])
    tube(root,'trim',[(s*.083,1.329,-.083),(s*.164,1.282,-.117),(s*.072,1.194,-.143),(0,1.173,-.145)],.003)
patch(root,'navy',[(-.066,1.343,.043),(.066,1.343,.043),(.182,1.286,.087),(.157,1.153,.116),(-.157,1.153,.116),(-.182,1.286,.087)])
tube(root,'trim',[(-.158,1.272,.104),(-.137,1.172,.126),(.137,1.172,.126),(.158,1.272,.104)],.003)
ribbon=node('Ribbon',(0,1.205,-.15),root)
for s in [-1,1]:
    patch(ribbon,'ribbon',[(0,0,-.008),(s*.08,.029,0),(s*.071,-.027,-.006),(0,-.016,-.016)])
    patch(ribbon,'ribbon',[(s*.008,-.01,-.017),(s*.04,-.118,-.018),(s*.007,-.105,-.025),(-s*.012,-.02,-.021)])
ellipsoid(ribbon,'gold',(0,-.008,-.023),(.015,.018,.009))
# Skirt has actual pleat topology and a bound hem; full opaque inner lining.
skirt=node('Skirt',(0,.94,0),root)
loft(skirt,'skirt',[(0,.163,.108,0),(-.075,.19,.132,0),(-.24,.247,.176,0),(-.335,.271,.19,0)],96,16)
loft(skirt,'trim',[(-.321,.27,.19,0),(-.334,.273,.192,0)],96,16)
loft(skirt,'navy',[(-.33,.265,.186,0),(-.331,0,0,0)],48)
for j in range(16):
    a=2*pi*j/16
    patch(skirt,'pleat',[(.166*cos(a),-.01,.111*sin(a)),(.27*cos(a-.023),-.317,.19*sin(a-.023)),(.27*cos(a+.023),-.317,.19*sin(a+.023))])
# Articulated legs; knees are hidden inside overlapping shaped surfaces.
for side,s in [('Left',-1),('Right',1)]:
    hip=node(side+'Leg',(s*.10,.86,0),root)
    loft(hip,'skin',[(.015,.073,.073,0),(-.08,.073,.071,0),(-.24,.056,.055,0),(-.375,.049,.05,0)])
    knee=node(side+'Knee',(0,-.36,0),hip)
    ellipsoid(knee,'skin',(0,0,0),(.05,.057,.052))
    loft(knee,'skin',[(0,.049,.051,0),(-.105,.051,.052,.008),(-.20,.04,.043,.008)])
    loft(knee,'sock',[(-.075,.052,.054,.006),(-.092,.054,.056,.006),(-.23,.041,.044,.008),(-.36,.032,.037,0)])
    loft(knee,'trim',[(-.079,.054,.056,.006),(-.086,.054,.056,.006)])
    ellipsoid(knee,'shoe',(0,-.414,-.042),(.059,.047,.114))
    ellipsoid(knee,'sole',(0,-.445,-.04),(.062,.018,.118))
    patch(knee,'leather',[(-.052,-.392,-.036),(.052,-.392,-.036),(.046,-.397,-.069),(-.046,-.397,-.069)])
    # Arms have tapered sleeves, cuffs and a separate elbow joint.
    arm=node(side+'Arm',(s*.19,1.275,0),root)
    loft(arm,'white',[(.025,.044,.056,0),(0,.065,.069,0),(-.11,.057,.06,0),(-.225,.048,.052,0)])
    elbow=node(side+'Elbow',(0,-.205,0),arm)
    loft(elbow,'white',[(.015,.049,.052,0),(-.10,.045,.049,-.004),(-.195,.038,.042,-.008)])
    loft(elbow,'navy',[(-.175,.041,.045,-.008),(-.213,.039,.043,-.008)])
    loft(elbow,'trim',[(-.187,.042,.046,-.008),(-.193,.042,.046,-.008)])
    ellipsoid(elbow,'skin',(0,-.255,-.007),(.034,.061,.025))
    ellipsoid(elbow,'skin',(-s*.031,-.24,-.017),(.015,.031,.015))
# Face: jaw and cheek loops are authored instead of a sphere.
head=node('Head',(0,1.535,0),root)
loft(head,'skin',[(-.155,.015,.02,-.047),(-.143,.054,.047,-.033),(-.115,.095,.071,-.02),(-.08,.123,.09,-.01),(-.025,.146,.105,0),(.04,.151,.116,.008),(.10,.135,.105,.013),(.145,.094,.075,.016),(.17,.018,.02,.016)],48)
for s in [-1,1]:ellipsoid(head,'skin',(s*.144,-.02,.006),(.024,.038,.019))
# Almond eyes on the front of the face, curved to follow cheeks.
def face_z(x,y,offset=0):
    return -.109*math.sqrt(max(.08,1-(x/.16)**2))-.005-offset
for s in [-1,1]:
    cx=s*.066
    eye=node(('Left' if s<0 else 'Right')+'Eye',(cx,-.012,face_z(cx,-.012,.008)),head)
    nodes[eye]['scale']=[1,.8,1]
    # Local depth follows the face slope.
    slope=s*.47
    def ep(x,y,z=0):return (x,y,slope*x+z)
    outline=[(-.044,.004),(-.027,.026),(.007,.029),(.035,.017),(.042,.001),(.025,-.024),(-.008,-.028),(-.035,-.017)]
    patch(eye,'white',[ep(x,y) for x,y in outline])
    def disc(mat,rx,ry,z,cx=0,cy=0):
        patch(eye,mat,[ep(cx+rx*cos(2*pi*j/32),cy+ry*sin(2*pi*j/32),z) for j in range(32)])
    disc('iris',.023,.027,-.002)
    disc('irislight',.017,.014,-.003,0,-.011)
    disc('pupil',.010,.023,-.004,0,.003)
    disc('shine',.006,.007,-.006,-.007,.013)
    disc('shine',.0025,.003,-.006,.010,-.015)
    tube(eye,'ink',[ep(x,y,-.007) for x,y in outline[:5]],.0038)
    tube(eye,'ink',[ep(x,y,-.004) for x,y in outline[4:]+outline[:1]],.0015)
    tube(head,'hair',[(cx-.032,.034,face_z(cx-.032,.034,.01)),(cx,.043,face_z(cx,.043,.01)),(cx+.032,.038,face_z(cx+.032,.038,.01))],.003)
# Subtle nose and neutral mouth; no exaggerated smile or rosy circles.
ellipsoid(head,'skin',(0,-.054,-.11),(.013,.022,.016),16,8)
tube(head,'blush',[(-.018,-.102,-.091),(0,-.105,-.095),(.018,-.102,-.091)],.002)
# Hair cap with a front opening: hemisphere plus shaped bob panels.
rows=[]
for i in range(13):
    t=(pi*.54)*i/12
    rows.append([(.163*sin(t)*cos(2*pi*j/48),.017+.177*cos(t),.022+.139*sin(t)*sin(2*pi*j/48)) for j in range(48)])
# Trim front of lower cap so fringe, rather than a helmet, frames the eyes.
for i,row in enumerate(rows):
    for j,(x,y,z) in enumerate(row):
        if z<0 and y<.083:row[j]=(x,.083,z)
grid(head,'hair',rows)
hair=node('Hair',(0,.07,.01),head)
# Back and side locks follow a curved bob silhouette, with staggered tips.
for j in range(13):
    a=-.12+(pi+.24)*j/12
    x=.157*cos(a);z=.139*sin(a)+.015
    lock(hair,'hair',[(x,.015,z),(x*1.06,-.075,z*1.04),(x*1.04,-.19,z), (x*.90,-.265+ .012*cos(j*1.7),z*.88)], [.033,.038,.035,.001],.024)
    if j%2==0:
        lock(hair,'hairlight',[(x*.99,-.018,z+.023),(x*1.04,-.095,z+.025),(x,-.18,z+.022)], [.003,.005,.001],.001)
# Asymmetrical swept fringe, tapered curved locks rather than cones.
for x,end,tip in [(-.116,-.11,-.043),(-.073,-.063,-.010),(-.024,-.015,.020),(.025,.047,.042),(.069,.095,.012),(.116,.137,-.068)]:
    lock(head,'hair',[(x*.65,.151,-.079),(x,.113,-.124),(end,.067,-.137),(end,tip,face_z(end,tip,.017))],[.027,.034,.027,.001],.012)
# Restrained brass hair pin.
tube(head,'gold',[(.137,.065,-.083),(.147,.034,-.074)],.004)
tube(head,'gold',[(.144,.067,-.076),(.153,.037,-.063)],.003)
# Compact familiar leather backpack, with modeled piping and shoulder straps.
ellipsoid(root,'leather',(0,1.105,.151),(.139,.17,.069),24,12)
ellipsoid(root,'leather',(0,1.23,.159),(.144,.055,.074),24,8)
tube(root,'gold',[(-.115,1.19,.201),(-.119,1.02,.194),(0,.973,.20),(.119,1.02,.194),(.115,1.19,.201)],.003)
for s in [-1,1]:
    tube(root,'leather',[(s*.115,.98,.09),(s*.139,1.18,.101),(s*.137,1.31,.055),(s*.126,1.30,-.076),(s*.123,1.11,-.107),(s*.139,1.01,-.073)],.014,10)
    ellipsoid(root,'gold',(s*.037,1.165,.217),(.012,.022,.005),12,6)
# Export glTF with smooth vertex normals and one mesh per joint.
buf=bytearray(); views=[]; accessors=[]; meshes=[]
def accessor(values,typ,component):
    while len(buf)%4:buf.append(0)
    start=len(buf); flat=[x for row in values for x in row] if typ=='VEC3' else values
    buf.extend(struct.pack('<'+('f' if component==5126 else 'I')*len(flat),*flat))
    vi=len(views);views.append({'buffer':0,'byteOffset':start,'byteLength':len(buf)-start})
    ac={'bufferView':vi,'componentType':component,'count':len(values),'type':typ}
    if typ=='VEC3':ac.update(min=[min(row[i] for row in values) for i in range(3)],max=[max(row[i] for row in values) for i in range(3)])
    accessors.append(ac);return len(accessors)-1
triangles=0
for ni,groups in geo.items():
    primitives=[]
    for mat,(v,f) in groups.items():
        normals=[[0.,0.,0.] for _ in v]
        # Our ring winding faces outward; normalize the area-weighted average.
        for a,b,c in f:
            u=[v[b][i]-v[a][i] for i in range(3)];w=[v[c][i]-v[a][i] for i in range(3)]
            nn=[u[1]*w[2]-u[2]*w[1],u[2]*w[0]-u[0]*w[2],u[0]*w[1]-u[1]*w[0]]
            for k in (a,b,c):
                for i in range(3):normals[k][i]+=nn[i]
        for n in normals:
            l=math.sqrt(sum(x*x for x in n)) or 1
            for i in range(3):n[i]/=l
        primitives.append({'attributes':{'POSITION':accessor(v,'VEC3',5126),'NORMAL':accessor(normals,'VEC3',5126)},'indices':accessor([i for t in f for i in t],'SCALAR',5125),'material':mi[mat]})
        triangles+=len(f)
    nodes[ni]['mesh']=len(meshes);meshes.append({'name':nodes[ni]['name'],'primitives':primitives})
for n in nodes:
    if not n['children']:del n['children']
gltf={'asset':{'version':'2.0','generator':'Platform Zero original character builder'},'scene':0,'scenes':[{'nodes':[root]}],'nodes':nodes,'meshes':meshes,'materials':mats,'bufferViews':views,'accessors':accessors,'buffers':[{'byteLength':len(buf),'uri':'data:application/octet-stream;base64,'+base64.b64encode(buf).decode()}]}
path=ROOT/'art/character/schoolgirl.gltf';path.write_text(json.dumps(gltf,separators=(',',':'))+'\n')
print(f'{path.name}: {triangles:,} triangles, {len(meshes)} articulated meshes, {len(buf):,} geometry bytes')
