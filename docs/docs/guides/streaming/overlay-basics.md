# Overlay Basics

This guide explains how to use Griddy SDK data to create streaming overlays for live broadcasts.

## Overview

Streaming overlays display real-time NFL data on top of video streams. Common use cases:

- Live score displays
- Player statistics during games
- Fantasy football trackers
- Watch party information displays

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Griddy SDK │────▶│   Backend   │────▶│   Overlay   │
│             │     │   Server    │     │   (HTML)    │
└─────────────┘     └─────────────┘     └─────────────┘
      │                    │                    │
      │                    │                    │
   NFL API           WebSocket/SSE        OBS Browser
                                           Source
```

## Basic Score Overlay

### Python Backend

```python
from flask import Flask, jsonify
from griddy.nfl import GriddyNFL

app = Flask(__name__)
nfl = GriddyNFL(nfl_auth={"accessToken": "token"})

@app.route('/api/scores/<int:season>/<season_type>/<int:week>')
def get_scores(season: int, season_type: str, week: int):
    """Get current scores for overlay."""
    games = nfl.games.get_games(
        season=season,
        season_type=season_type,
        week=week
    )

    scores = []
    for game in games.games:
        scores.append({
            'id': game.id,
            'home': {
                'abbr': game.home_team.abbreviation,
                'score': game.home_team.score
            },
            'away': {
                'abbr': game.away_team.abbreviation,
                'score': game.away_team.score
            },
            'status': game.game_status,
            'quarter': getattr(game, 'quarter', None),
            'clock': getattr(game, 'game_clock', None)
        })

    return jsonify(scores)

if __name__ == '__main__':
    app.run(port=5000)
```

### HTML Overlay

```html
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      margin: 0;
      background: transparent;
      font-family: 'Arial', sans-serif;
    }

    .scoreboard {
      position: fixed;
      bottom: 20px;
      right: 20px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 15px;
      border-radius: 10px;
    }

    .game {
      display: flex;
      justify-content: space-between;
      margin-bottom: 10px;
      font-size: 18px;
    }

    .team {
      display: flex;
      align-items: center;
      gap: 10px;
    }

    .score {
      font-weight: bold;
      min-width: 30px;
      text-align: right;
    }

    .status {
      font-size: 12px;
      color: #aaa;
      text-align: center;
    }
  </style>
</head>
<body>
  <div class="scoreboard" id="scoreboard"></div>

  <script>
    async function updateScores() {
      try {
        const res = await fetch('http://localhost:5000/api/scores/2024/REG/1');
        const games = await res.json();

        const html = games.map(game => `
          <div class="game">
            <div class="team">
              <span>${game.away.abbr}</span>
              <span class="score">${game.away.score}</span>
            </div>
            <span class="status">${game.status}</span>
            <div class="team">
              <span class="score">${game.home.score}</span>
              <span>${game.home.abbr}</span>
            </div>
          </div>
        `).join('');

        document.getElementById('scoreboard').innerHTML = html;
      } catch (err) {
        console.error('Failed to update scores:', err);
      }
    }

    // Update every 30 seconds
    updateScores();
    setInterval(updateScores, 30000);
  </script>
</body>
</html>
```

## OBS Studio Integration

### Adding Browser Source

1. In OBS, add a new **Browser** source
2. Set the URL to your overlay HTML file or hosted URL
3. Set dimensions (e.g., 1920x1080)
4. Check "Shutdown source when not visible" to save resources

### Transparent Background

For overlays with transparent backgrounds:

1. Set `background: transparent` in CSS
2. In OBS Browser source properties, ensure "Custom CSS" is empty or doesn't override background

## Player Stats Overlay

```python
@app.route('/api/player/<player_id>/stats')
def get_player_stats(player_id: str):
    """Get player stats for overlay."""
    # Get player from appropriate endpoint
    player = nfl.players.get_player(player_id=player_id)

    return jsonify({
        'name': player.display_name,
        'position': player.position,
        'team': player.team.abbreviation,
        'stats': {
            # Include relevant stats based on position
        }
    })
```

## Real-Time Updates with WebSocket

For smoother real-time updates, use WebSocket:

```python
from flask import Flask
from flask_socketio import SocketIO, emit
import time
import threading

app = Flask(__name__)
socketio = SocketIO(app, cors_allowed_origins="*")

def score_updater():
    """Background thread to push score updates."""
    while True:
        games = nfl.games.get_live_game_stats(
            season=2024,
            season_type="REG",
            week=1
        )

        socketio.emit('scores', [{
            'id': g.game_id,
            'homeScore': g.home_score,
            'awayScore': g.away_score,
            'status': g.game_status
        } for g in games])

        time.sleep(30)

@socketio.on('connect')
def handle_connect():
    print('Client connected')

if __name__ == '__main__':
    thread = threading.Thread(target=score_updater, daemon=True)
    thread.start()
    socketio.run(app, port=5000)
```

Client-side WebSocket:

```javascript
const socket = io('http://localhost:5000');

socket.on('scores', (games) => {
  updateScoreboard(games);
});
```

## Styling Tips

### Team Colors

```css
.team-KC { color: #E31837; }  /* Chiefs */
.team-SF { color: #AA0000; }  /* 49ers */
.team-DAL { color: #003594; } /* Cowboys */
/* ... etc */
```

### Animations

```css
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.1); }
  100% { transform: scale(1); }
}

.score-changed {
  animation: pulse 0.5s ease-in-out;
}
```

## Best Practices

1. **Polling interval**: Don't poll too frequently - 30 seconds is usually sufficient
2. **Error handling**: Always handle API failures gracefully
3. **Caching**: Cache responses to reduce API calls
4. **Performance**: Keep overlays lightweight for smooth streaming
5. **Transparency**: Use transparent backgrounds for compositing
