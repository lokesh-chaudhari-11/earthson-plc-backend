# -*- mode: python ; coding: utf-8 -*-


a = Analysis(
    ['plc_logic_driver.py'],
    pathex=[],
    binaries=[],
    datas=[('C:\\\\Users\\\\LokeshChaudhari\\\\AppData\\\\Local\\\\Programs\\\\Python\\\\Python313\\\\Lib\\\\site-packages\\\\pycomm3', 'pycomm3')],
    hiddenimports=['concurrent.futures', 'pyrebase', 'os'],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='plc_logic_driver',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)
