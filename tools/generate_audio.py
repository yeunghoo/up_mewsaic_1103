"""Original synthesized toy-game effects. No third-party recordings or runtime network."""
import math, random, struct, wave
from pathlib import Path
out=Path(__file__).resolve().parents[1]/'loop_miao/Audio';out.mkdir(exist_ok=True)
rate=22050
for name,duration,volume in [('load',.16,.34),('shot',.09,.15),('hit',.12,.20),('win',.72,.27)]:
    rng=random.Random(12);samples=[]
    for i in range(int(rate*duration)):
        t=i/rate;u=t/duration;attack=min(1,t/.006);env=attack*(1-u)**2
        if name=='shot':v=math.sin(2*math.pi*(540*t-1600*t*t))*.8+rng.uniform(-1,1)*.16
        elif name=='hit':v=math.sin(2*math.pi*(900*t-2200*t*t))*.65+rng.uniform(-1,1)*.28
        elif name=='load':v=math.sin(2*math.pi*(430*t+1800*t*t))*.6+math.sin(2*math.pi*1080*t)*.18
        else:
            note=min(3,int(t/.18));f=[523.25,659.25,783.99,1046.5][note];local=t-note*.18
            env=min(1,local/.008)*math.exp(-local*9)*(1-u*.4);v=math.sin(2*math.pi*f*local)*.7+math.sin(2*math.pi*f*2*local)*.15
        samples.append(int(max(-1,min(1,v*env*volume))*32767))
    with wave.open(str(out/(name+'.wav')),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('Generated four original mono PCM effects')
