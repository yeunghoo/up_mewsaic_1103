"""Capture the actual UIKit app at native App Store sizes. No cropping or scaling."""
from pathlib import Path
import subprocess,json,time,argparse
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--app',required=True,help='Path to the freshly built Debug simulator app');p.add_argument('--device',choices=['iphone-large','iphone-faceid','ipad']);args=p.parse_args()
devices={
 'iphone-large':('5C68C7EA-F3F4-4F65-BE0B-9996789D5133','iPhone-6.9-1320x2868',1320,2868),
 'iphone-faceid':('0929DE3B-831C-4DF0-B393-FA90E43D4806','iPhone-6.5-1242x2688',1242,2688),
 'ipad':('7E16E452-A3FB-4FDD-9C98-F5488F309BB5','iPad-13-2064x2752',2064,2752)}
def sim(*a,check=True):return subprocess.run(['xcrun','simctl',*a],check=check,capture_output=True,text=True)
for key,(device,folder,w,h) in devices.items():
 if args.device and args.device!=key:continue
 listing=json.loads(sim('list','devices','--json').stdout)
 state=next(d['state'] for ds in listing['devices'].values() for d in ds if d['udid']==device)
 if state!='Booted':sim('boot',device)
 sim('bootstatus',device,'-b')
 # The iPad status bar uses the device language, independently of app launch arguments.
 languages=sim('spawn',device,'defaults','read','NSGlobalDomain','AppleLanguages',check=False).stdout
 if 'en' not in languages or 'zh' in languages:
  sim('spawn',device,'defaults','write','NSGlobalDomain','AppleLanguages','-array','en')
  sim('spawn',device,'defaults','write','NSGlobalDomain','AppleLocale','-string','en_US')
  sim('shutdown',device);sim('boot',device);sim('bootstatus',device,'-b')
 sim('install',device,args.app)
 sim('status_bar',device,'override','--time','9:41','--dataNetwork','wifi','--wifiMode','active','--wifiBars','3','--operatorName','','--cellularMode','active','--cellularBars','4','--batteryState','charged','--batteryLevel','100')
 out=ROOT/'AppStoreScreenshots'/folder;out.mkdir(parents=True,exist_ok=True)
 for num,scene in [(1,'home'),(2,'battle'),(3,'map'),(5,'daily-battle'),(6,'win')]:
  sim('terminate',device,'com.mewsaic.erden.nook.app',check=False)
  sim('launch',device,'com.mewsaic.erden.nook.app','-atelier.taught','YES','-AppleLanguages','(en)','-AppleLocale','en_US','-MCStoreScene',scene)
  time.sleep(2.5)
  file=out/f'{num:02}-{scene}.png';sim('io',device,'screenshot',str(file))
  header=file.read_bytes()[:26];actual=(int.from_bytes(header[16:20],'big'),int.from_bytes(header[20:24],'big'))
  assert actual==(w,h),(file,actual)
  print(file.relative_to(ROOT),flush=True)
 sim('status_bar',device,'clear')
 if state!='Booted':sim('shutdown',device)
