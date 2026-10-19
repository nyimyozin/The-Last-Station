"""Original synthesized score and sound effects; no samples."""
import numpy as np
import wave
from pathlib import Path
SR=22050
ROOT=Path(__file__).parent
rng=np.random.default_rng(47)
def write(name,y,loop=False):
 y=np.tanh(np.asarray(y,dtype=float))*.78
 if not loop:
  n=min(240,len(y)//4); y[:n]*=np.linspace(0,1,n); y[-n:]*=np.linspace(1,0,n)
 with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
  f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR); f.writeframes((y*32767).astype('<i2').tobytes())
def note(freq,dur=4):
 t=np.arange(int(SR*dur))/SR
 return (np.sin(2*np.pi*freq*t)*np.exp(-t*1.2)+.24*np.sin(2*np.pi*freq*2.003*t)*np.exp(-t*2)+.06*np.sin(2*np.pi*freq*4*t)*np.exp(-t*4))*(1-np.exp(-t*50))
def hz(m): return 440*2**((m-69)/12)
def mix_at(buf,sample,start): np.add.at(buf,(np.arange(len(sample))+int(start*SR))%len(buf),sample)
song=np.zeros(SR*96)
chords=[[50,57,62,65],[46,53,58,62],[53,60,65,69],[48,55,60,64]]
melody=[74,77,81,77,72,74,69,65,70,74,77,74,69,65,62,69]
for bar in range(16):
 for j,n in enumerate(chords[(bar//2)%4]): mix_at(song,note(hz(n),7)*.095,bar*6+j*.7)
 for j in range(2): mix_at(song,note(hz(melody[(bar+j)%16]),6)*.12,bar*6+1+j*2.25)
song+=np.roll(song,int(SR*.47))*.19+np.roll(song,int(SR*.93))*.1
write('music',song,True)
t=np.arange(SR*24)/SR
soft=np.convolve(rng.normal(0,1,len(t)),np.ones(160)/160,mode='same')
write('wind',soft*(.14+.07*np.sin(2*np.pi*t/24))+.008*np.sin(2*np.pi*55*t),True)
for name,softness in [('stone',3),('grass',16)]:
 t=np.arange(int(SR*.22))/SR
 n=np.convolve(rng.normal(0,1,len(t)),np.ones(softness)/softness,mode='same')
 write(name,n*np.exp(-t*29)*.32+np.sin(2*np.pi*110*t)*np.exp(-t*40)*.16)
for i,f in enumerate([659.25,440,554.37]): write('tone'+str(i),note(f,2)*.35)
for name,notes in [('collect',[74,81,86]),('success',[62,69,74,78,81]),('error',[50,49])]:
 out=np.zeros(SR*4)
 for j,n in enumerate(notes): mix_at(out,note(hz(n),2)*.23,j*.17)
 write(name,out)
t=np.arange(SR*18)/SR
rumble=np.convolve(rng.normal(0,1,len(t)),np.ones(75)/75,mode='same')
amp=np.sin(np.pi*np.clip(t/18,0,1))**1.5
clack=(np.sin(2*np.pi*(7*t-.12*t*t))>.96).astype(float)
train=(rumble*.8+clack*rumble*.6)*amp
train+=(np.sin(2*np.pi*220*t)+.3*np.sin(2*np.pi*330*t))*.08*np.exp(-((t-3)/1.3)**2)
write('train',train)
for name in ['music','wind']:
 (ROOT/(name+'.wav.import')).write_text('[remap]\nimporter="wav"\ntype="AudioStreamWAV"\n\n[deps]\nsource_file="res://audio/'+name+'.wav"\n\n[params]\nedit/loop_mode=2\nedit/loop_begin=0\nedit/loop_end=-1\ncompress/mode=0\n')
print('Composed 11 original audio files')
