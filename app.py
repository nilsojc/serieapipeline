from flask import Flask, jsonify, send_from_directory
import requests
import os

app = Flask(__name__)

# SerpAPI base URL and API key
SERP_API_URL = "https://serpapi.com/search.json"
SERP_API_KEY = os.getenv("SPORTS_API_KEY")

# Serve the index.html file
@app.route('/')
def serve_index():
    return send_from_directory('.', 'index.html')

# Serve static files (CSS, logos, etc.)
@app.route('/<path:filename>')
def serve_static(filename):
    return send_from_directory('.', filename)

# API endpoint to fetch Serie A schedule
@app.route('/sports', methods=['GET'])
def get_serieA_schedule():
    # Fetches the Serie A schedule from SerpAPI and returns it as JSON
    try:
        # Query SerpAPI
        params = {
            "engine": "google",
            "q": "Serie A schedule",
            "api_key": SERP_API_KEY
        }
        response = requests.get(SERP_API_URL, params=params)
        response.raise_for_status()
        data = response.json()

        # Extract games from sports_results
        games = data.get("sports_results", {}).get("games", [])
        if not games:
            return jsonify({"message": "No Serie A schedule available.", "games": []}), 200

        # Format the schedule into JSON
        formatted_games = []
        for game in games:
            teams = game.get("teams", [])
            if len(teams) == 2:
                away_team = teams[0].get("name", "Unknown")
                home_team = teams[1].get("name", "Unknown")
            else:
                away_team, home_team = "Unknown", "Unknown"

            game_info = {
                "away_team": away_team,
                "home_team": home_team,
                "venue": game.get("venue", "Unknown"),
                "date": game.get("date", "Unknown"),
                "time": f"{game.get('time', 'Unknown')} ET" if game.get("time", "Unknown") != "Unknown" else "Unknown"
            }
            formatted_games.append(game_info)

        return jsonify({"message": "Serie A schedule fetched successfully.", "games": formatted_games}), 200

    except Exception as e:
        return jsonify({"message": "An error occurred.", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)