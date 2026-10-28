import httpx

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"
userAgent = "PlateShare/1.0 (tylsams@okstate.edu)"

class geocodeError(Exception):
    pass

async def geocodeAddress(address: str) -> tuple[float,float]:
    """Returns (lat, lng) for an address string and
    raises geocodeError on failure."""
    params = {"q": address, "format": "jsonv2", "limit": 1}
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.get(
                NOMINATIM_URL, params = params, headers = {"User-Agent": userAgent}
            )
            resp.raise_for_status()
            results = resp.json()
    except httpx.HTTPError as e:
        raise geocodeError(f"Geocoding service unavailable: {e}")
    
    if not results:
        raise geocodeError("Could not find address. Check it and try again")
    
    return float(results[0]["lat"]), float(results[0]["lon"])