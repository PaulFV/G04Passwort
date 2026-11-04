#!/usr/bin/env python3
"""Generates PRIVACY.md from lib/features/legal/legal_texts.dart (source of truth)."""
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
src = (root / 'lib/features/legal/legal_texts.dart').read_text()
consts = dict(re.findall(r"static const String (\w+) =\s*'([^']*)';",
                         (root / 'lib/core/constants/app_constants.dart').read_text()))


def text(block: str) -> str:
    t = ''.join(re.findall(r"'((?:[^'\\]|\\.)*)'", block)).replace('\\n', '\n')
    return re.sub(r'\$\{AppConstants\.(\w+)\}', lambda m: consts[m.group(1)], t)


privacy = src[src.index('abstract final class PrivacyText'):src.index('abstract final class CopyrightText')]
out = ['# Datenschutzerklärung – G04Passwort', '',
       text(re.search(r'static const intro =\s*(.*?);\n', privacy, re.S).group(1)), '']
for m in re.finditer(r"LegalSection\('([^']*)', \[(.*?)\]\)", privacy, re.S):
    out += [f'## {m.group(1)}', '']
    for para in re.split(r"(?<='),\s*\n", m.group(2)):
        if text(para).strip():
            out += [text(para), '']
out.append(f"*Stand: {consts['legalDate']}*")
(root / 'PRIVACY.md').write_text('\n'.join(out) + '\n')
