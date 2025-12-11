"""Automatically generate API reference pages for the Python SDK.

This script runs at build time via mkdocs-gen-files plugin.
It walks the SDK source tree and creates virtual Markdown files
with mkdocstrings directives for each module.
"""

from pathlib import Path
import mkdocs_gen_files

# Navigation builder for literate-nav
nav = mkdocs_gen_files.Nav()

# Path to the cloned SDK source (relative to docs/ directory)
src = Path(__file__).parent.parent / "tmp" / "python-sdk" / "src"

# Package name (adjust if your package has a different name)
PACKAGE_NAME = "griddy"

# Manual overrides - these files exist in the repo and should not be auto-generated
# This allows you to write custom documentation for key modules
MANUAL_OVERRIDES = {
    # "griddy/index.md",  # Uncomment to use a hand-crafted package overview
}


def should_skip_module(parts: tuple[str, ...]) -> bool:
    """Determine if a module should be skipped."""
    # Skip private modules (starting with _) except __init__
    for part in parts:
        if part.startswith("_") and part != "__init__":
            return True

    # Skip test modules
    if "tests" in parts or "test" in parts:
        return True

    # Skip migration/script modules if present
    if "scripts" in parts or "migrations" in parts:
        return True

    return False


def get_module_title(parts: tuple[str, ...], is_package: bool) -> str:
    """Generate a human-readable title for a module."""
    if not parts:
        return PACKAGE_NAME.title()

    name = parts[-1]

    # Special case titles
    title_map = {
        "auth": "Authentication",
        "api": "API Client",
        "cli": "Command Line Interface",
        "utils": "Utilities",
        "config": "Configuration",
        "exc": "Exceptions",
        "exceptions": "Exceptions",
        "types": "Type Definitions",
        "models": "Data Models",
        "endpoints": "API Endpoints",
        "client": "Client",
    }

    if name in title_map:
        return title_map[name]

    # Convert snake_case to Title Case
    return name.replace("_", " ").title()


# Walk the source tree
for path in sorted(src.rglob("*.py")):
    # Get module path relative to src
    module_path = path.relative_to(src).with_suffix("")

    # Convert to documentation path
    doc_path = path.relative_to(src).with_suffix(".md")
    full_doc_path = Path("sdk-reference/python", doc_path)

    # Build the module identifier parts
    parts = tuple(module_path.parts)

    # Skip modules that should be excluded
    if should_skip_module(parts):
        continue

    # Handle __init__.py files (package index)
    is_package = parts[-1] == "__init__"
    if is_package:
        parts = parts[:-1]
        if not parts:
            # Root package __init__.py
            doc_path = Path("index.md")
            full_doc_path = Path("sdk-reference/python/index.md")
        else:
            doc_path = doc_path.with_name("index.md")
            full_doc_path = full_doc_path.with_name("index.md")

    # Skip if this is a manual override
    relative_doc = full_doc_path.relative_to("sdk-reference/python").as_posix()
    if relative_doc in MANUAL_OVERRIDES:
        continue

    # Build navigation entry
    if parts:
        nav[parts] = doc_path.as_posix()
    else:
        nav[("index",)] = doc_path.as_posix()

    # Generate the module identifier for mkdocstrings
    identifier = ".".join(parts) if parts else PACKAGE_NAME

    # Get title
    title = get_module_title(parts, is_package)

    # Generate the markdown file content
    with mkdocs_gen_files.open(full_doc_path, "w") as fd:
        # Write title
        fd.write(f"# {title}\n\n")

        # Add breadcrumb for nested modules
        if len(parts) > 1:
            breadcrumb_parts = []
            for i, part in enumerate(parts[:-1]):
                # Calculate relative path from current file to this part's index.md
                # e.g., from griddy/nfl/sdk.md: griddy->../index.md, nfl->index.md
                rel_path = "../" * (len(parts) - i - 2) + "index.md"
                breadcrumb_parts.append(f"[{part}]({rel_path})")
            breadcrumb_parts.append(f"**{parts[-1]}**")
            fd.write(f"*{' / '.join(breadcrumb_parts)}*\n\n")

        # Add module docstring notice for packages
        if is_package:
            fd.write(f"::: {identifier}\n")
            fd.write("    options:\n")
            fd.write("      show_root_heading: false\n")
            fd.write("      show_root_toc_entry: false\n")
            fd.write("      members: false\n")
            fd.write("\n---\n\n")
            fd.write("## Module Contents\n\n")
            fd.write(f"::: {identifier}\n")
            fd.write("    options:\n")
            fd.write("      show_root_heading: false\n")
            fd.write("      show_submodules: false\n")
        else:
            # Regular module
            fd.write(f"::: {identifier}\n")

    # Set the edit path to point to the actual source file
    mkdocs_gen_files.set_edit_path(full_doc_path, path.relative_to(src.parent.parent))

# Generate the navigation file for literate-nav plugin
with mkdocs_gen_files.open("sdk-reference/python/SUMMARY.md", "w") as nav_file:
    nav_file.writelines(nav.build_literate_nav())