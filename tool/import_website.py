"""One-time snapshot importer for the inspected website's constant Dart subset.
Never writes to the website or the user's application-data store.
Run with: python tool/import_website.py ../portfolio_app
"""
import ast
import json
from pathlib import Path
import re
import shutil
import sys

root = Path(sys.argv[1]).resolve()
out = Path(__file__).resolve().parent.parent
verify = '--verify' in sys.argv[2:]
if (out/'assets/seed/portfolio.json').exists() and not verify:
    raise SystemExit('Seed is frozen. Use --verify to compare; no existing seed or local data will be overwritten.')
symbols = {}
token_re = re.compile(r'''\s+|//[^\n]*|/\*.*?\*/|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|0x[0-9A-Fa-f]+|[0-9]+|[A-Za-z_][\w.]*|[^\s]''', re.S)

class Parser:
    def __init__(self, text):
        self.tokens = [m.group() for m in token_re.finditer(text) if not m.group().isspace() and not m.group().startswith(('//', '/*'))]
        self.i = 0
    def pop(self):
        v = self.tokens[self.i]; self.i += 1; return v
    def peek(self): return self.tokens[self.i] if self.i < len(self.tokens) else ''
    def need(self, token):
        actual = self.pop()
        if actual != token: raise ValueError(f'Expected {token}, found {actual}')
    def value(self):
        t = self.pop()
        if t.startswith(('"', "'")):
            v = ast.literal_eval(t)
            while self.peek().startswith(('"', "'")): v += ast.literal_eval(self.pop())
            return v
        if t in ('true', 'false', 'null'): return {'true': True, 'false': False, 'null': None}[t]
        if t[0].isdigit(): return int(t, 0) if t.startswith('0x') else int(t)
        if t == '[':
            result = []
            while self.peek() != ']':
                result.append(self.value())
                if self.peek() != ',': break
                self.pop()
            self.need(']'); return result
        if t == '{':
            result = {}
            while self.peek() != '}':
                k = self.value(); self.need(':'); result[k] = self.value()
                if self.peek() != ',': break
                self.pop()
            self.need('}'); return result
        if t == 'Color':
            self.need('('); result = self.value(); self.need(')'); return result
        if self.peek() == '(':
            if t not in ('Project', 'Education', 'Experience', 'ExperienceMilestone'): raise ValueError(t)
            self.pop(); result = {}
            while self.peek() != ')':
                k = self.pop(); self.need(':'); result[k] = self.value()
                if self.peek() != ',': break
                self.pop()
            self.need(')'); return result
        if t.startswith('Icons.'): return t.split('.')[1]
        if t in symbols: return symbols[t]
        raise ValueError(f'Unsupported constant: {t}')

def constants(relative, owner):
    text = (root / relative).read_text(encoding='utf-8-sig')
    result = {}
    for m in re.finditer(r'static const [\w<>, ?]+?\s+(\w+)\s*=', text):
        parser = Parser(text[m.end():]); value = parser.value(); parser.need(';')
        result[m[1]] = value
        symbols[f'{owner}.{m[1]}'] = value
        symbols[m[1]] = value
    return result

a = constants('lib/utils/core/app_assets.dart', 'AppAssets')
s = constants('lib/utils/core/app_strings.dart', 'AppStrings')
sections = {}
for section in ['about', 'skills', 'projects', 'education', 'experience', 'contact']:
    sections[section] = constants(f'lib/widgets/sections/{section}_section.dart', section)

def identify(records, prefix):
    for i, record in enumerate(records): record.update(id=f'{prefix}-{i+1:03}', revision=1)
    return records

projects = identify(sections['projects']['projects'], 'project')
for p in projects:
    p.setdefault('liveUrl', None); p.setdefault('githubUrl', None)
education = identify(sections['education']['educationList'], 'education')
for e in education:
    e.setdefault('isCurrent', False); e.setdefault('certificateUrl', None)
experiences = identify(sections['experience']['experiences'], 'experience')
for e in experiences:
    e.setdefault('isCurrent', False); e.setdefault('milestones', [])
    identify(e['milestones'], e['id'] + '-milestone')
    for m in e['milestones']: m.setdefault('type', 'Promotion'); m.setdefault('highlights', [])
categories = identify(sections['skills']['categories'], 'category')
for c in categories:
    identify(c['skills'], c['id'] + '-skill')
    for skill in c['skills']:
        skill['assetPath'] = skill.pop('asset')
        skill['colorValue'] = skill.pop('color')
        skill['themeAdaptive'] = skill.get('themeAdaptive', False)
about, contact = sections['about'], sections['contact']
profile = dict(id='profile-main', revision=1, name=about['personalInfo'][0]['value'],
    heroName=s['name'], heroTitle=s['title'], tagline=s['tagline'], photoPath=a['photoPath'],
    primaryCtaLabel=s['viewWork'], primaryCtaTarget=s['projects'], secondaryCtaLabel=s['getInTouch'], secondaryCtaTarget=s['contact'],
    bio=about['bio'], personalDetails=identify(about['personalInfo'], 'personal-detail'),
    email=contact['email'], phone=contact['phone'], location=contact['location'],
    socialLinks=identify([dict(label=k, url=contact[v], iconPath=a[icon]) for k,v,icon in [
        ('GitHub','githubUrl','iconGithub'),('LinkedIn','linkedinUrl','iconLinkedin'),('WhatsApp','whatsappUrl','iconWhatsapp')]], 'social'),
    orbitIconPaths=a['heroOrbitIcons'])
media = []
# Static JSON content is not media; preserve original media ordering/IDs.
paths = sorted([*(root/'assets/images').rglob('*'), *(root/'assets/icons').rglob('*')]) + [root/'web/cv.pdf']
for path in paths:
    if not path.is_file(): continue
    relative = path.relative_to(root).as_posix()
    kind = 'document' if path.suffix == '.pdf' else 'icon' if path.suffix == '.svg' else 'image'
    target = out/'assets/seed/media'/relative
    if verify:
        assert target.read_bytes() == path.read_bytes(), f'Media mismatch: {relative}'
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
    media.append(dict(id=f'media-{len(media)+1:03}', revision=1, sourcePath=relative,
                      localPath=f'media/{relative}', kind=kind, label=path.name))
headings = [dict(id=k, revision=1, heading=sections[k]['heading'], subtitle=sections[k].get('subtitle','')) for k in sections]
settings = dict(id='settings-main', revision=1, brandName=s['portfolio'], brandSuffix=s['dev'], appTitle=s['myPortfolio'],
    browserTitle='My Portfolio', description='My personal portfolio', cvPath='web/cv.pdf', cvLabel=s['downloadCv'],
    cvDownloadFilename=s['name']+'_CV.pdf', navigationLabels=[dict(id=k,revision=1,label=label) for k,label in [
        ('hero',s['home']),('about',s['aboutUpper']),('skills',s['skillsUpper']),('projects',s['projectsUpper']),
        ('education',s['educationUpper']),('experience',s['experienceUpper']),('contact',s['contactUpper'])]])
content = dict(projects=projects, education=education, experiences=experiences, skillCategories=categories,
               profiles=[profile], media=media, settings=[settings], sectionContent=headings)
assert [len(projects),len(education),len(experiences),len(categories),len(media)] == [8,5,3,4,42]
assert sum(len(c['skills']) for c in categories) == 15
document = dict(schemaVersion=1, revision=1, content=content)
if verify:
    assert json.loads((out/'assets/seed/portfolio.json').read_text(encoding='utf-8')) == document, 'Seed content differs from website source'
else:
    (out/'assets/seed/portfolio.json').write_text(json.dumps(document,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{"Verified" if verify else "Imported"} {len(projects)} projects, profile, 5 education entries, 3 experiences, 15 skills, 42 media files. Website unmodified.')
