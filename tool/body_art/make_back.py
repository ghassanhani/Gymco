import re, sys
src=open('tool/body_art/front.svg').read()
paths=re.findall(r'<path d="[^"]*" fill="#[0-9A-F]+"/>',src)
gaps=[q.replace('#F9F9F9','#C5C5C5') for q in paths if q.startswith(('<path d="M216.103 976.414','<path d="M776.062 975.144','<path d="M497.453 1683.06'))]
assert len(gaps)==3
base=[paths[0],paths[2]]+gaps+[paths[73]]
M='#F9F9F9'
# Left-side muscles (viewer's left = body's left from behind); right side mirrored.
L={
 'delt_rear': "M258 562 C190 552 112 590 80 690 C66 750 84 800 112 826 C150 770 214 694 296 640 C286 600 274 578 258 562 Z",
 'upper_back': "M306 646 C254 694 228 760 232 836 C296 846 366 824 436 786 C408 724 360 674 306 646 Z",
 'lats': "M236 858 C250 990 286 1124 336 1214 C388 1182 446 1124 488 1086 C474 994 452 870 440 802 C368 842 296 862 236 858 Z",
 'lower_back': "M490 1104 C456 1156 428 1244 424 1344 C446 1372 472 1384 490 1386 Z",
 'flank': "M338 1236 C304 1274 290 1334 294 1384 C344 1376 392 1360 414 1346 C414 1294 424 1206 450 1156 C414 1188 374 1216 338 1236 Z",
 'glutes': "M494 1400 C430 1390 334 1396 276 1454 C236 1514 244 1604 294 1654 C364 1694 452 1684 494 1644 Z",
 'hamstrings': "M290 1706 C254 1806 258 1956 294 2104 C334 2152 404 2152 444 2122 C474 1984 484 1834 478 1706 C424 1720 344 1720 290 1706 Z",
 'calves_out': "M300 2320 C262 2420 266 2580 316 2716 C340 2750 374 2736 382 2660 C392 2530 388 2400 376 2310 Z",
 'calves_in': "M392 2310 C406 2400 412 2540 404 2676 C424 2720 458 2700 470 2600 C484 2470 468 2360 440 2296 Z",
 'triceps': "M120 836 C86 900 82 996 108 1100 C132 1124 164 1120 180 1096 C198 1004 194 906 172 846 Z",
 'forearms': "M96 1178 C66 1270 66 1390 96 1500 C112 1514 132 1510 142 1494 C176 1384 190 1264 180 1178 Z",
}
TRAPS="M440 432 C420 482 330 522 262 556 C334 598 424 700 499 1050 C574 700 664 598 736 556 C668 522 578 482 558 432 C530 452 468 452 440 432 Z"
def mirror(d):
    out=[];toks=re.findall(r'[A-Za-z]|-?\d+\.?\d*',d);i=0;isx=True
    for t in toks:
        if t.isalpha(): out.append(t); isx=True; continue
        v=float(t)
        out.append(f'{998-v:g}' if isx else f'{v:g}'); isx=not isx
    return ' '.join(out)
parts=[f'<path id="traps" d="{TRAPS}" fill="{M}" stroke="#C5C5C5" stroke-width="16" stroke-linejoin="round"/>']
for k,d in L.items():
    parts.append(f'<path id="{k}-l" d="{d}" fill="{M}" stroke="#C5C5C5" stroke-width="16" stroke-linejoin="round"/>')
    parts.append(f'<path id="{k}-r" d="{mirror(d)}" fill="{M}" stroke="#C5C5C5" stroke-width="16" stroke-linejoin="round"/>')
# the spine, and the line between the hamstring heads
lines=['<path d="M499 1060 L499 1390" stroke="#C8C4C5" stroke-width="10" stroke-linecap="round"/>']
for x in (382,616):
    lines.append(f'<path d="M{x} 1730 C{x-4} 1880 {x-6} 1990 {x+(4 if x<499 else -4)} 2110" stroke="#C5C5C5" stroke-width="8" stroke-linecap="round" fill="none"/>')
svg=('<svg width="998" height="3142" viewBox="0 0 998 3142" fill="none" xmlns="http://www.w3.org/2000/svg">\n'
     +'\n'.join(base+parts+lines)+'\n</svg>\n')
open(sys.argv[1],'w').write(svg)
