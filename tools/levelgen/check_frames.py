"""Check palette variety, preserved subject pixels, and deterministic source output."""
import json
from pathlib import Path
from collections import Counter
import campaign
ROOT=Path(__file__).resolve().parents[2]
levels=json.loads((ROOT/'loop_miao/Content/campaign.json').read_text())
assert len(levels)==200
for index,level in enumerate(levels):
    chapter,kind=divmod(index,20)
    pattern=level['pattern'];legacy=campaign.artwork(kind,chapter,varied_frame=False)
    assert pattern==campaign.artwork(kind,chapter)
    assert len(pattern)==len(legacy)
    assert level['contentRevision']==2
    assert level['frameColors']==list(campaign.frame_palette(kind,chapter)[1:])
    outer=Counter();changes=0;n=len(pattern)
    for r,row in enumerate(pattern):
        for c,color in enumerate(row):
            edge=max(abs((c+.5)/n*2-1),abs((r+.5)/n*2-1))
            old=legacy[r][c]
            assert (old=='.')==(color=='.'),(index,'Changed geometry')
            if color!=old:
                assert .80<edge<.91,(index,'Changed subject or inner mat')
                changes+=1
            if .80<edge<.91 and color!='.':outer[color]+=1
    assert changes>0
    assert all(outer[color]>0 for color in level['frameColors'])
    if index:assert level['framePalette']!=levels[index-1]['framePalette']
for chapter in range(10):
    assert len({l['framePalette'] for l in levels[chapter*20:chapter*20+20]})==10
for kind in range(20):assert len({levels[chapter*20+kind]['framePalette'] for chapter in range(10)})==10
print('PASS: 200 boards, 10 palettes per chapter, no adjacent repeated palette; subjects, inner mats and geometry preserved.')
print('Palette counts:',dict(Counter(l['framePalette'] for l in levels)))
