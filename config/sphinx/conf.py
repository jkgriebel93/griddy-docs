import os
import sys
from pathlib import Path
source_path = Path("tmp/griddy-sdk-python/src")
print(f"source path: {source_path}")
sys.path.insert(0, os.path.abspath('../src'))

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.napoleon',
    'sphinx.ext.viewcode',
    'sphinx_autodoc_typehints',
    "sphinx_wagtail_theme"
]

html_theme = 'sphinx_wagtail_theme'
autodoc_member_order = 'bysource'