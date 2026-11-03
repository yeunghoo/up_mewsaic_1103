"""Seeded noisy-policy sampling; does not claim to replace human playtesting."""
import json, random
from pathlib import Path
import blockcat as c
root=Path(__file__).resolve().parents[2]
levels=json.loads((root/'loop_miao/Content/campaign.json').read_text())
results=[]
for n,l in enumerate(levels):
    c.SLOTS=l['slots'];c.WINDOW=l['window'];c.settle.rows=len(l['pattern']);c.settle.cols=len(l['pattern'][0])
    grid={(r,col):k for r,row in enumerate(l['pattern']) for col,k in enumerate(row) if k!='.'}
    q=[(b['color'],b['capacity']) for b in l['baskets']]
    failures=0
    for trial in range(12):
        rng=random.Random(n*100+trial);g=dict(grid);slots=[None]*c.SLOTS;pending=list(range(len(q)))
        while g and None in slots and pending:
            visible=pending[:c.WINDOW];ready=c.collectible(g,c.settle.rows,c.settle.cols)
            counts={k:sum(g[p]==k for p in ready) for k,_ in q}
            pick=rng.choice(visible) if rng.random()<.15 else max(visible,key=lambda i:counts.get(q[i][0],0)/q[i][1])
            slots[slots.index(None)]=(q[pick][0],0,q[pick][1]);pending.remove(pick);c.settle(g,slots)
        failures+=bool(g)
    results.append({'id':l['id'],'trials':12,'noisy_failures':failures})
    if n%20==19: print(f'Assessed {n+1}/200',flush=True)
(root/'tools/levelgen/difficulty_sample.json').write_text(json.dumps(results,indent=2))
print('Sample failure rate:',sum(r['noisy_failures'] for r in results)/2400)
