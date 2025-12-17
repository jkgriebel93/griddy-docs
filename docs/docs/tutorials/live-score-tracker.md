# Tutorial: Live Score Tracker

Create a real-time score tracker that monitors NFL games and alerts you to score changes.

## What You'll Build

A score tracker that:

- Monitors games in progress
- Detects score changes
- Sends notifications when scores update
- Handles rate limiting properly

## Prerequisites

- Completed the [First API Call](first-api-call.md) tutorial
- Python 3.14+ with griddy installed

## Step 1: Project Setup

Create your project files:

```bash
mkdir score-tracker
cd score-tracker
touch tracker.py
```

## Step 2: Create the Score Tracker Class

```python
#!/usr/bin/env python3
"""NFL Live Score Tracker."""

import os
import time
from dataclasses import dataclass
from typing import Dict, List, Optional, Callable
from griddy.nfl import GriddyNFL
from griddy.core.exceptions import GriddyError

@dataclass
class GameState:
    """Current state of a game."""
    game_id: str
    home_team: str
    away_team: str
    home_score: int
    away_score: int
    status: str
    quarter: Optional[str] = None
    clock: Optional[str] = None

class ScoreTracker:
    """Tracks live NFL game scores."""

    def __init__(self, nfl: GriddyNFL, poll_interval: int = 30):
        self.nfl = nfl
        self.poll_interval = poll_interval
        self._game_states: Dict[str, GameState] = {}
        self._callbacks: List[Callable] = []
        self._running = False

    def add_callback(self, callback: Callable[[GameState, GameState], None]):
        """Add callback for score changes.

        Callback receives (old_state, new_state).
        """
        self._callbacks.append(callback)

    def _notify(self, old_state: Optional[GameState], new_state: GameState):
        """Notify all callbacks of a change."""
        for callback in self._callbacks:
            try:
                callback(old_state, new_state)
            except Exception as e:
                print(f"Callback error: {e}")

    def _fetch_games(self, season: int, season_type: str, week: int) -> List[GameState]:
        """Fetch current game states."""
        games = self.nfl.games.get_games(
            season=season,
            season_type=season_type,
            week=week
        )

        states = []
        for game in games.games:
            state = GameState(
                game_id=game.id,
                home_team=game.home_team.abbreviation,
                away_team=game.away_team.abbreviation,
                home_score=game.home_team.score or 0,
                away_score=game.away_team.score or 0,
                status=game.game_status,
                quarter=getattr(game, 'quarter', None),
                clock=getattr(game, 'game_clock', None)
            )
            states.append(state)

        return states

    def _check_for_changes(self, new_states: List[GameState]):
        """Check for score changes and notify callbacks."""
        for new_state in new_states:
            old_state = self._game_states.get(new_state.game_id)

            # Check for changes
            if old_state is None:
                # New game - notify
                self._notify(None, new_state)
            elif (old_state.home_score != new_state.home_score or
                  old_state.away_score != new_state.away_score or
                  old_state.status != new_state.status):
                # Score or status changed
                self._notify(old_state, new_state)

            # Update stored state
            self._game_states[new_state.game_id] = new_state

    def start(self, season: int, season_type: str, week: int):
        """Start tracking scores."""
        self._running = True
        print(f"Starting score tracker for {season} {season_type} Week {week}")
        print(f"Polling every {self.poll_interval} seconds...")
        print()

        while self._running:
            try:
                states = self._fetch_games(season, season_type, week)
                self._check_for_changes(states)

                # Adjust poll interval based on game status
                live_games = [s for s in states if s.status == "IN_PROGRESS"]
                if live_games:
                    sleep_time = self.poll_interval
                else:
                    sleep_time = self.poll_interval * 2  # Slower when no live games

                time.sleep(sleep_time)

            except GriddyError as e:
                print(f"API Error: {e.message}")
                time.sleep(60)  # Back off on error

            except KeyboardInterrupt:
                self.stop()

    def stop(self):
        """Stop tracking."""
        self._running = False
        print("\nScore tracker stopped.")
```

## Step 3: Create Notification Handlers

```python
def console_notification(old: Optional[GameState], new: GameState):
    """Print score changes to console."""
    timestamp = time.strftime("%H:%M:%S")

    if old is None:
        # New game discovered
        print(f"[{timestamp}] Tracking: {new.away_team} @ {new.home_team}")
        return

    # Score change
    if old.home_score != new.home_score or old.away_score != new.away_score:
        score_diff_home = new.home_score - old.home_score
        score_diff_away = new.away_score - old.away_score

        print(f"[{timestamp}] SCORE UPDATE: "
              f"{new.away_team} {new.away_score} @ "
              f"{new.home_team} {new.home_score}")

        if score_diff_home > 0:
            print(f"           {new.home_team} +{score_diff_home}")
        if score_diff_away > 0:
            print(f"           {new.away_team} +{score_diff_away}")

    # Status change
    if old.status != new.status:
        if new.status == "FINAL":
            winner = new.home_team if new.home_score > new.away_score else new.away_team
            print(f"[{timestamp}] FINAL: {new.away_team} {new.away_score} @ "
                  f"{new.home_team} {new.home_score} - {winner} wins!")
        elif new.status == "IN_PROGRESS" and old.status != "IN_PROGRESS":
            print(f"[{timestamp}] KICKOFF: {new.away_team} @ {new.home_team}")
```

## Step 4: Add Desktop Notifications (Optional)

```python
def try_desktop_notification(title: str, message: str):
    """Try to send a desktop notification."""
    try:
        # macOS
        import subprocess
        subprocess.run([
            "osascript", "-e",
            f'display notification "{message}" with title "{title}"'
        ], capture_output=True)
    except Exception:
        pass

    try:
        # Linux with notify-send
        import subprocess
        subprocess.run(["notify-send", title, message], capture_output=True)
    except Exception:
        pass

def desktop_notification(old: Optional[GameState], new: GameState):
    """Send desktop notification for score changes."""
    if old is None:
        return

    if old.home_score != new.home_score or old.away_score != new.away_score:
        title = "NFL Score Update"
        message = f"{new.away_team} {new.away_score} @ {new.home_team} {new.home_score}"
        try_desktop_notification(title, message)

    if old.status != new.status and new.status == "FINAL":
        title = "Game Final"
        winner = new.home_team if new.home_score > new.away_score else new.away_team
        message = f"{winner} wins! Final: {new.away_score}-{new.home_score}"
        try_desktop_notification(title, message)
```

## Step 5: Main Application

```python
def main():
    import argparse

    parser = argparse.ArgumentParser(description="NFL Live Score Tracker")
    parser.add_argument("--season", type=int, default=2024)
    parser.add_argument("--week", type=int, default=1)
    parser.add_argument("--season-type", default="REG",
                       choices=["PRE", "REG", "POST"])
    parser.add_argument("--interval", type=int, default=30,
                       help="Poll interval in seconds")
    parser.add_argument("--desktop-notify", action="store_true",
                       help="Enable desktop notifications")
    args = parser.parse_args()

    # Get token
    token = os.environ.get("NFL_ACCESS_TOKEN")
    if not token:
        print("Please set NFL_ACCESS_TOKEN environment variable")
        return

    # Create client and tracker
    nfl = GriddyNFL(nfl_auth={"accessToken": token})
    tracker = ScoreTracker(nfl, poll_interval=args.interval)

    # Add notification handlers
    tracker.add_callback(console_notification)
    if args.desktop_notify:
        tracker.add_callback(desktop_notification)

    # Start tracking
    try:
        tracker.start(args.season, args.season_type, args.week)
    except KeyboardInterrupt:
        print("\nStopping tracker...")
    finally:
        tracker.stop()

if __name__ == "__main__":
    main()
```

## Step 6: Run the Tracker

```bash
# Basic usage
python tracker.py --season 2024 --week 1

# With desktop notifications
python tracker.py --season 2024 --week 1 --desktop-notify

# Custom poll interval
python tracker.py --season 2024 --week 1 --interval 15
```

## Sample Output

```
Starting score tracker for 2024 REG Week 1
Polling every 30 seconds...

[14:00:01] Tracking: BAL @ KC
[14:00:01] Tracking: GB @ PHI
[14:00:01] Tracking: ARI @ BUF
[14:05:32] KICKOFF: BAL @ KC
[14:12:45] SCORE UPDATE: BAL 0 @ KC 7
           KC +7
[14:25:18] SCORE UPDATE: BAL 7 @ KC 7
           BAL +7
...
[17:45:00] FINAL: BAL 27 @ KC 20 - BAL wins!
```

## Enhancements

### Team-Specific Tracking

```python
def team_filter(teams: List[str]):
    """Create a callback that only notifies for specific teams."""
    def callback(old: Optional[GameState], new: GameState):
        if new.home_team in teams or new.away_team in teams:
            console_notification(old, new)
    return callback

# Usage
tracker.add_callback(team_filter(["KC", "SF"]))
```

### Log to File

```python
def file_logger(filename: str):
    """Create a callback that logs to file."""
    def callback(old: Optional[GameState], new: GameState):
        with open(filename, "a") as f:
            timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"{timestamp},{new.away_team},{new.away_score},"
                   f"{new.home_team},{new.home_score},{new.status}\n")
    return callback

# Usage
tracker.add_callback(file_logger("scores.csv"))
```

## Next Steps

- Add webhook notifications (Slack, Discord)
- Build a web interface with live updates
- Add play-by-play tracking
