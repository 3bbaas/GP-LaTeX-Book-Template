async def fetch_user(user_id):
    """Fetch user using async httpx."""
    import httpx
    async with httpx.AsyncClient() as client:
        response = await client.get(f"/api/users/{user_id}")
        return response.json()
