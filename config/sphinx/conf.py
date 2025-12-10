"""Sphinx configuration for Griddy Python SDK documentation."""

import os
import sys

# Add SDK source to path
sys.path.insert(0, os.path.abspath('../../tmp/python-sdk/src'))

# Project information
project = 'Griddy Python SDK'
copyright = '2025, John Griebel'
author = 'John Griebel'

# Extensions
extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.viewcode',
    'sphinx.ext.napoleon',
    'sphinx.ext.intersphinx',
    'sphinx_autodoc_typehints',
    'myst_parser',
]

# AutoDoc settings
autodoc_default_options = {
    'members': True,
    'member-order': 'bysource',
    'special-members': '__init__',
    'undoc-members': True,
    'exclude-members': '__weakref__',
    'show-inheritance': True,
}

# Napoleon settings (Google/NumPy style docstrings)
napoleon_google_docstring = True
napoleon_numpy_docstring = True
napoleon_include_init_with_doc = True
napoleon_include_private_with_doc = False
napoleon_include_special_with_doc = True
napoleon_use_admonition_for_examples = True
napoleon_use_admonition_for_notes = True
napoleon_use_admonition_for_references = True

# Type hints
autodoc_typehints = 'description'
autodoc_typehints_format = 'short'

# Theme
html_theme = 'furo'
html_theme_options = {
    'light_css_variables': {
        'color-brand-primary': '#7C3AED',
        'color-brand-content': '#5B21B6',
    },
    'dark_css_variables': {
        'color-brand-primary': '#A78BFA',
        'color-brand-content': '#C4B5FD',
    },
}

# MyST parser for markdown support
myst_enable_extensions = [
    'colon_fence',
    'deflist',
    'fieldlist',
]

# Intersphinx mappings
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
    'httpx': ('https://www.python-httpx.org/', None),
    'pydantic': ('https://docs.pydantic.dev/latest/', None),
}

# Output settings
html_static_path = ['_static']
html_title = 'Griddy Python SDK'
html_short_title = 'Griddy Python'
html_logo = '_static/griddy-logo.svg'
html_favicon = '_static/favicon.png'

# Autosummary
autosummary_generate = True