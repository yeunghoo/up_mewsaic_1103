"""Ten master challenges: two slots, shuffled five-choice windows, verified witnesses."""
from pathlib import Path
from collections import Counter
import json, random
import campaign
import blockcat as core
ROOT=Path(__file__).resolve().parents[2]
TITLES=['Prism Prowler','Midnight Bloom','Clockwork Moon','Neon Wings','Hidden Harbor','Lantern Labyrinth','Starlight Express','Secret Garden','Golden Signal','Confetti Vault']
KINDS=[0,3,2,6,5,7,19,13,17,18]
LIMITS=[110,105,95,90,100,105,90,95,110,85]
def sample(pattern,queue,seed,trials=24):
    n=len(pattern);core.settle.rows=n;core.settle.cols=n
    initial={(r,c):k for r,row in enumerate(pattern) for c,k in enumerate(row) if k!='.'}
    failures=0
    for trial in range(trials):
        rng=random.Random(seed*100+trial);grid=dict(initial);slots=[None]*2;pending=list(range(len(queue)))
        while grid and None in slots and pending:
            ready=core.collectible(grid,n,n);counts=Counter(grid[p] for p in ready);options=pending[:5]
            idx=rng.choice(options) if rng.random()<.20 else max(options,key=lambda j:counts[queue[j]['color']]/queue[j]['capacity'])
            pack=queue[idx];slots[slots.index(None)]=(pack['color'],0,pack['capacity']);pending.remove(idx);core.settle(grid,slots)
        failures+=bool(grid)
    return failures

def main():
    levels=[];reports=[]
    for i,kind in enumerate(KINDS):
        # Daily puzzles already have multicolor mats; keep their verified layout stable.
        pattern=campaign.artwork(kind,1+i%3,varied_frame=False)
        # Original multicolor tesserae hidden in the paper mat create interleaved exposure depths.
        palette='BRGPL'
        pattern=[''.join(palette[(r//4+c//4+i)%5] if k=='W' and (r//3+c//3)%3 else k for c,k in enumerate(row)) for r,row in enumerate(pattern)]
        best=None
        for attempt in range(8):
            seed=5000+i*101+attempt
            original,_,peak=campaign.construct(pattern,seed,2)
            rng=random.Random(seed);order=[]
            for start in range(0,len(original),5):
                group=list(range(start,min(start+5,len(original))));rng.shuffle(group);order+=group
            queue=[original[j] for j in order];witness=[order.index(j) for j in range(len(original))]
            failures=sample(pattern,queue,seed,24)
            if best is None or failures>best[0]:best=(failures,queue,witness,seed,peak)
            if failures>=15:break
        failures,queue,witness,seed,peak=best
        n=len(pattern);core.settle.rows=n;core.settle.cols=n
        grid={(r,c):k for r,row in enumerate(pattern) for c,k in enumerate(row) if k!='.'};slots=[None]*2;pending=list(range(len(queue)));trace=[]
        for idx in witness:
            assert idx in pending[:5] and None in slots
            p=queue[idx];slots[slots.index(None)]=(p['color'],0,p['capacity']);pending.remove(idx);core.settle(grid,slots)
            trace.append({'remaining':len(grid),'slots':[None if s is None else list(s) for s in slots]})
        assert not grid and all(s is None for s in slots)
        # Measured native volley witnesses take 62–90s; allow about 20s for decisions.
        level=dict(id=f'daily-{i+1:02}',title=TITLES[i],chapter='Daily Master Challenge',slots=2,window=5,preview=5,pattern=pattern,baskets=queue,timeLimit=LIMITS[i],solution=witness)
        levels.append(level);reports.append(dict(id=level['id'],seed=seed,trials=24,noisyFailures=failures,peak=peak,trace=trace))
        print(level['id'],len(queue),'packs; noisy failures',failures,'/24',flush=True)
    (ROOT/'loop_miao/Content/daily.json').write_text(json.dumps(levels,separators=(',',':')))
    (ROOT/'tools/levelgen/daily_validation.json').write_text(json.dumps(reports,separators=(',',':')))
if __name__=='__main__':main()
