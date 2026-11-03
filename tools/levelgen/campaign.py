"""Original procedural atelier collection; deterministic construction + independent replay."""
import math, random, json
from pathlib import Path
from collections import Counter
import blockcat as core
ROOT=Path(__file__).resolve().parents[2]
NAMES=['Studio Cat','Tea Break','Moon Window','Garden Bloom','Little Cottage','Paper Boat','Butterfly','Desk Lamp','Love Letter','Acorn','Mushroom','Kite','Songbird','Cactus','Cozy Sock','Pocket Camera','Honey Jar','Lighthouse','Ribbon Gift','Starry Rocket']
CHAPTERS=['First Stitches','Sunlit Studio','Garden Notes','Seaside Letters','Autumn Shelf','Twilight Tea','Winter Keepsakes','Dream Workshop','Midnight Gallery','The Grand Collection']
# Distinct, readable toy-color borders. A coprime stride avoids identical
# neighboring frames and gives each subject a different palette in every chapter.
FRAME_PALETTES=[
    ('berry-fizz','R','P'), ('garden-mint','G','L'),
    ('sunny-sky','B','Y'), ('lilac-cream','P','W'),
    ('peach-candy','R','Y'), ('lagoon-lime','B','L'),
    ('golden-violet','P','Y'), ('fern-cream','G','W'),
    ('blueberry-pop','B','P'), ('strawberry-cream','R','W'),
]
def frame_palette(kind,chapter):
    return FRAME_PALETTES[(kind*3+chapter*9)%len(FRAME_PALETTES)]

def artwork(kind,chapter,*,varied_frame=True):
    n=20 if chapter==0 else 28 if chapter<4 else 36
    out=[]
    accent=['R','Y','B','P','L'][chapter%5]
    _,edge_a,edge_b=frame_palette(kind,chapter) if varied_frame else ('legacy','B','W')
    for r in range(n):
        line=''
        for c in range(n):
            x=(c+.5)/n*2-1; y=(r+.5)/n*2-1
            # paper mat with a decorative woven edge, varied per chapter
            k='W' if abs(x)<.91 and abs(y)<.91 else '.'
            if k=='W' and max(abs(x),abs(y))>.80: k=edge_a if (r+c+chapter)//3%2 else edge_b
            a=accent; hit=False
            if kind==0:
                hit=x*x/.52+y*y/.46<1 or (.27<abs(x)<.65 and -.76<y<-.25 and abs(x)<-.6*y+.25)
                if hit:k='Y'
                if hit and ((abs(abs(x)-.24)<.07 and -.1<y<.04) or (abs(x)<.07 and .18<y<.28)): k='K'
                if hit and .29<abs(x)<.45 and .12<y<.23:k=a
            elif kind==1:
                if (-.55<x<.35 and -.24<y<.55) or (.3<x<.64 and -.1<y<.38 and not(.36<x<.5 and .02<y<.25)):k=a
                if -.63<x<.59 and .55<y<.64:k='K'
                if abs(x+.1)<.05 and -.66<y<-.35:k='Y'
            elif kind==2:
                if abs(x)<.62 and abs(y)<.68:k='K'
                if (x+.15)**2+(y+.2)**2<.20 and (x-.03)**2+(y+.3)**2>.16:k='Y'
                if abs(x)<.04 or abs(y)<.04:k='B'
            elif kind==3:
                if abs(x)<.055 and -.1<y<.7:k='G'
                if (x-.23)**2/.07+(y-.35)**2/.025<1:k='L'
                if x*x+(y+.3)**2<.28:k=a if math.sin(math.atan2(y+.3,x)*6)>-.4 else 'W'
                if x*x+(y+.3)**2<.055:k='Y'
            elif kind==4:
                if abs(x)<.53 and -.15<y<.65:k='Y'
                if -.68<y<-.05 and abs(x)<(y+.8)*1.1:k=a
                if abs(x)<.13 and .2<y<.65:k='K'
                if .25<abs(x)<.4 and .04<y<.23:k='B'
            elif kind==5:
                if -.12<y<.5 and abs(x)<.72-y*.6:k=a
                if -.65<y<-.17 and -.55<x<.03 and x>y*.8:k='Y'
                if abs(y-.62)<.04:k='B'
            elif kind==6:
                if (abs(x)-.34)**2/.15+y*y/.34<1:k=a if abs(y)>.2 else 'Y'
                if abs(x)<.07 and abs(y)<.65:k='K'
                if .31<abs(x)<.44 and .15<abs(y)<.3:k='B'
            elif kind==7:
                if -.65<y<-.05 and abs(x)<.45+(y+.65)*.25:k=a
                if abs(x)<.06 and -.05<y<.6:k='K'
                if abs(x)<.45 and .58<y<.69:k='Y'
            elif kind==8:
                if abs(x)<.68 and abs(y)<.44:k='Y'
                if abs(x)<.68 and abs(y+.4-abs(x)*.65)<.05:k=a
                if x*x+(y-.08)**2<.045:k=a
            elif kind==9:
                if x*x/.27+(y-.1)**2/.36<1:k='Y'
                if x*x/.39+(y+.25)**2/.08<1:k='K' if (r+c)//3%2 else a
                if abs(x)<.06 and -.65<y<-.45:k='G'
            elif kind==10:
                if abs(x)<.19 and -.1<y<.64:k='Y'
                if x*x/.48+(y+.13)**2/.3<1 and y<.12:k=a
                if y<.03 and ((x+.3)**2+(y+.3)**2<.025 or (x-.23)**2+(y+.4)**2<.02):k='W'
            elif kind==11:
                if abs(x)/.6+abs(y+.2)/.58<1:k=a if x*y>0 else 'Y'
                if abs(x-math.sin(y*9)*.12)<.035 and .35<y<.8:k='K'
            elif kind==12:
                if x*x/.35+y*y/.24<1:k=a
                if (x+.1)**2/.14+(y-.12)**2/.07<1:k='B'
                if .48<x<.72 and abs(y+.15)<(.72-x):k='Y'
                if (x-.28)**2+(y+.15)**2<.01:k='K'
            elif kind==13:
                if (abs(x)<.17 and -.65<y<.42) or (.28<abs(x)<.45 and -.35<y<.14) or (abs(x)<.4 and .04<y<.19):k='G' if c%4 else 'L'
                if abs(x)<.37-y*.09 and .38<y<.72:k=a
            elif kind==14:
                if (-.31<x<.27 and -.65<y<.35) or ((x+.17)**2/.3+(y-.36)**2/.08<1):k=a if int((y+1)*9)%3 else 'Y'
            elif kind==15:
                if abs(x)<.65 and abs(y)<.44:k=a
                if -.4<x<-.1 and -.56<y<-.44:k='K'
                if x*x+y*y<.12:k='K'
                if x*x+y*y<.055:k='B'
                if .4<x<.54 and -.29<y<-.17:k='Y'
            elif kind==16:
                if abs(x)<.48 and -.42<y<.65:k='Y'
                if abs(x)<.52 and -.59<y<-.42:k=a
                if abs(x)<.36 and -.12<y<.37:k='W'
                if abs(x)+abs(y-.12)<.23:k=a
            elif kind==17:
                if abs(x)<.2+y*.13 and -.47<y<.69:k=a if int((y+1)*8)%3 else 'W'
                if abs(x)<.32 and -.66<y<-.44:k='Y'
                if abs(x)<.65 and .7<y<.77:k='B'
            elif kind==18:
                if abs(x)<.6 and -.3<y<.64:k=a
                if abs(x)<.09 and -.3<y<.64 or abs(y-.13)<.08 and abs(x)<.6:k='Y'
                if (abs(x)-.2)**2/.045+(y+.46)**2/.035<1:k='Y'
            else:
                if abs(x)<.25 and -.73<y<.45 and abs(x)<(y+.8)*.8:k=a
                if .2<abs(x)<.45 and .1<y<.6 and abs(x)<y*.8:k='B'
                if x*x+(y+.12)**2<.028:k='K'
                if abs(x)<.15 and .44<y<.77:k='Y'
            # Unique chapter accents at the mat corners
            if .66<abs(x)<.77 and .65<abs(y)<.77:k=accent if chapter%2 else 'Y'
            line+=k
        out.append(line)
    return out

def construct(pattern,seed,slot_count):
    rng=random.Random(seed); n=len(pattern);core.settle.rows=n;core.settle.cols=n
    grid={(r,c):k for r,row in enumerate(pattern) for c,k in enumerate(row) if k!='.'}
    slots=[None]*slot_count; queue=[];trace=[]; peak=0
    while grid:
        assert None in slots
        ready=core.collectible(grid,n,n); avail=Counter(grid[p] for p in ready); counts=Counter(grid.values())
        reserved=Counter()
        for s in slots:
            if s:reserved[s[0]]+=s[2]-s[1]
        pressure=seed>20 and slots.count(None)>1 and rng.random()<.8
        options=[k for k in (counts if pressure else avail) if counts[k]>reserved[k]]
        rng.shuffle(options)
        if not pressure: options.sort(key=lambda k:avail[k],reverse=True)
        color=options[0]; remaining=counts[color]-reserved[color]
        cap=min(remaining, max(12,min(110,int(avail[color]*(1.25 if slots.count(None)>1 else .8)))) )
        if pressure:cap=min(remaining,110,max(16,int(remaining*.65)))
        # last free slot always drains immediately, guaranteeing construction progress
        if slots.count(None)==1:cap=min(cap,avail[color])
        slot=slots.index(None);slots[slot]=(color,0,cap);queue.append({'color':color,'capacity':cap})
        core.settle(grid,slots);peak=max(peak,sum(s is not None for s in slots))
        trace.append({'remaining':len(grid),'slots':[None if s is None else list(s) for s in slots]})
    assert all(s is None for s in slots)
    assert len(queue)<=64,(seed,len(queue))
    return queue,trace,peak

def main():
    levels=[]; reports=[]
    for chapter in range(10):
        for kind in range(20):
            num=chapter*20+kind+1; slots=3 if num<=20 else 4 if num<=40 else 5
            p=artwork(kind,chapter);q,t,peak=construct(p,num,slots)
            levels.append(dict(id=f'atelier-{num:03}',title=NAMES[kind],chapter=CHAPTERS[chapter],slots=slots,window=slots,preview=5,pattern=p,baskets=q,contentRevision=2,framePalette=frame_palette(kind,chapter)[0],frameColors=list(frame_palette(kind,chapter)[1:])))
            reports.append(dict(id=levels[-1]['id'],blocks=sum(k!='.' for row in p for k in row),baskets=len(q),peak=peak,trace=t))
    assert len({tuple(l['pattern']) for l in levels})==200
    (ROOT/'loop_miao/Content/campaign.json').write_text(json.dumps(levels,separators=(',',':')))
    (ROOT/'tools/levelgen/campaign_validation.json').write_text(json.dumps(reports,separators=(',',':')))
    print('Generated 200 unique boards; basket counts',min(len(l['baskets']) for l in levels),max(len(l['baskets']) for l in levels))
if __name__=='__main__':main()
