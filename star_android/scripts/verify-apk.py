#!/usr/bin/env python3
"""Fail CI for a wrong ABI or an APK that still needs Metro to load JS."""
import sys
import zipfile
with zipfile.ZipFile(sys.argv[1]) as apk:
    names = apk.namelist()
    abis = {p.split('/')[1] for p in names if p.startswith('lib/') and p.endswith('.so')}
    assert abis == {'arm64-v8a'}, f'Unexpected native ABIs: {abis}'
    assert 'assets/index.android.bundle' in names, 'Missing standalone JavaScript bundle'
    assert any('libhermes.so' in p for p in names), 'Missing Hermes runtime'
    assert any('libreactnative.so' in p for p in names), 'Missing React Native runtime'
print('APK verified: ARM64 only, Hermes, React Native and embedded JS bundle.')
