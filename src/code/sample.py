from fastapi import FastAPI
from functions import get_avatar_url, add_avatar_url

app = FastAPI()

@app.get("/avatar/random")
async def get_avatar():
    url = await get_avatar_url()
    return {"url": url}

@app.post("/avatar")
async def add_avatar():
    await add_avatar_url()
