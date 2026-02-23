def fetch_user(user_id):
    """Fetch user using synchronous requests."""
    import requests
    response = requests.get(f"/api/users/{user_id}")
    return response.json()
