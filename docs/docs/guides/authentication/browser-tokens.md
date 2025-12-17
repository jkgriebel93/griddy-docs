# Browser Tokens

The Python SDK supports automated browser-based authentication using Playwright. This guide explains how to use this feature.

!!! note "Python Only"
    Browser-based authentication is only available in the Python SDK. TypeScript users must provide tokens manually.

## Overview

Browser authentication automates the NFL.com login process to obtain access tokens without manual intervention. This is useful for:

- Automated scripts and pipelines
- Server-side applications
- Testing and development

## Setup

### Install Playwright

```bash
pip install playwright
playwright install chromium
```

### Basic Usage

```python
from griddy.nfl import GriddyNFL

# Authenticate with credentials
nfl = GriddyNFL(
    login_email="your_email@example.com",
    login_password="your_password"
)

# The SDK is now authenticated
games = nfl.games.get_games(season=2024, season_type="REG", week=1)
```

## Headless Mode

By default, browser authentication runs with a visible browser window. For server environments, use headless mode:

```python
nfl = GriddyNFL(
    login_email="your_email@example.com",
    login_password="your_password",
    headless_login=True  # Run without visible browser
)
```

## How It Works

1. Playwright launches a Chromium browser
2. Navigates to NFL.com login page
3. Fills in email and password
4. Completes the login flow
5. Extracts the access token from browser storage
6. Returns the token to the SDK

## Token Storage

After successful authentication, the SDK saves credentials to `creds.json`:

```python
# First run - browser authentication
nfl = GriddyNFL(
    login_email="user@example.com",
    login_password="password",
    headless_login=True
)

# Subsequent runs - use saved token
import json
with open("creds.json") as f:
    auth = json.load(f)

nfl = GriddyNFL(nfl_auth=auth)
```

!!! warning "Security"
    The `creds.json` file contains sensitive tokens. Add it to `.gitignore` and secure it appropriately.

## Error Handling

```python
from griddy.nfl import GriddyNFL

try:
    nfl = GriddyNFL(
        login_email="user@example.com",
        login_password="password",
        headless_login=True
    )
except Exception as e:
    print(f"Authentication failed: {e}")
    # Handle login failure - wrong credentials, network issues, etc.
```

## Environment Variables

Store credentials securely using environment variables:

```python
import os
from griddy.nfl import GriddyNFL

nfl = GriddyNFL(
    login_email=os.environ["NFL_EMAIL"],
    login_password=os.environ["NFL_PASSWORD"],
    headless_login=True
)
```

## CI/CD Usage

For automated pipelines:

```yaml
# GitHub Actions example
env:
  NFL_EMAIL: ${{ secrets.NFL_EMAIL }}
  NFL_PASSWORD: ${{ secrets.NFL_PASSWORD }}

steps:
  - name: Install Playwright
    run: |
      pip install playwright
      playwright install chromium

  - name: Run script
    run: python my_script.py
```

## Troubleshooting

### Browser Not Found

```bash
# Reinstall Playwright browsers
playwright install chromium
```

### Login Timeout

The login process may timeout if NFL.com is slow or has changed. Try:

1. Run without headless mode to see what's happening
2. Check your internet connection
3. Verify credentials are correct
4. Check if NFL.com is accessible

### CAPTCHA or MFA

If NFL.com requires CAPTCHA or multi-factor authentication:

1. Log in manually once to establish trust
2. Use `headless_login=False` to handle challenges manually
3. Consider using token-based authentication instead

## Best Practices

1. **Cache tokens**: Save and reuse tokens instead of logging in every time
2. **Use headless in production**: Always use `headless_login=True` in server environments
3. **Secure credentials**: Never commit credentials to version control
4. **Handle failures**: Implement retry logic for transient failures
5. **Refresh tokens**: Check token expiration and re-authenticate when needed
