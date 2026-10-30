import sys,struct,re
from elftools.elf.elffile import ELFFile
from capstone import *
# Disassembles functions of the game's native library. Usage: python tools/armdis.py <name regex> [max functions]
# The full dump used for research is made by tools/setup_re.py (re/all.txt).
import os
so=os.environ.get('HB_SO') or os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'re','libgame.so')
f=open(so,'rb'); e=ELFFile(f)
data=open(so,'rb').read()
segs=[(s['p_vaddr'],s['p_offset'],s['p_filesz']) for s in e.iter_segments() if s['p_type']=='PT_LOAD']
def v2o(a):
    for va,off,sz in segs:
        if va<=a<va+sz: return off+a-va
def rd(a,n):
    o=v2o(a); return data[o:o+n] if o is not None else b''
def cstr(a):
    b=rd(a,80)
    if not b: return None
    s=b.split(b'\0')[0]
    if len(s)>=1 and all(32<=c<127 for c in s): return s.decode()
syms={}
for secname in ('.dynsym','.symtab'):
    sec=e.get_section_by_name(secname)
    if sec:
        for s in sec.iter_symbols():
            if s['st_value'] and s['st_info']['type']=='STT_FUNC': syms[s.name]=(s['st_value']&~1,s['st_size'],s['st_value']&1)
def find(pat): return [(n,v) for n,v in syms.items() if re.search(pat,n)]
if __name__=='__main__':
    pat=sys.argv[1]
    for n,(a,sz,th) in find(pat)[:int(sys.argv[2]) if len(sys.argv)>2 else 3]:
        print('=====',n,hex(a),sz,'thumb' if th else 'arm')
        md=Cs(CS_ARCH_ARM,CS_MODE_THUMB if th else CS_MODE_ARM); md.detail=False
        code=rd(a,sz or 400)
        byaddr={v[0]:k for k,v in syms.items()}
        lit={}
        def gen():
            off=0
            while off<len(code):
                got=False
                for ins in md.disasm(code[off:],a+off):
                    got=True; off=ins.address-a+ins.size; yield ins
                if not got or off<len(code):
                    off+=2
        for i in gen():
            extra=''
            m=re.search(r'^(r\d+|ip), \[pc, #(0x[0-9a-f]+|\d+)\]',i.op_str) if i.mnemonic.startswith('ldr') else None
            if m:
                pc=((i.address+4)&~3) if th else i.address+8
                w=struct.unpack('<I',rd(pc+int(m.group(2),0),4))[0]
                lit[m.group(1)]=w; extra=f'   ; ={w:#x}'
            m=re.match(r'^(r\d+), pc$',i.op_str) if i.mnemonic.startswith('add') else None
            if m and m.group(1) in lit:
                t=(lit[m.group(1)]+i.address+(4 if th else 8))&0xffffffff
                st=cstr(t); extra=f'   ; -> {t:#x} {st!r}'
            m=re.match(r'^#(0x[0-9a-f]+)$',i.op_str) if i.mnemonic in('bl','blx','b') else None
            if m:
                t=int(m.group(1),0)
                if t in byaddr: extra=f'   ; {byaddr[t]}'
            print(f'{i.address:x}: {i.mnemonic} {i.op_str}{extra}')
