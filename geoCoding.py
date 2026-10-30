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
        async with httpx.AsyncClient(timeout=15) as client:
            resp = await client.get(
                NOMINATIM_URL, params = params, headers = {"User-Agent": userAgent}
            )
            resp.raise_for_status()
            results = resp.json()
    except httpx.HTTPError as e:
         print(f"[geocode] timeout: {e!r}")
         raise geocodeError("Geocoding service timed out. Please try again.")
    except httpx.HTTPStatusError as e:
        print(f"[geocode] HTTP {e.response.status_code}: {e.response.text[:200]}")
        raise geocodeError(f"Geocoding service returned HTTP {e.response.status_code}.")
    except httpx.HTTPError as e:
        print(f"[geocode] {type(e).__name__}: {e!r}")
        raise geocodeError(f"Geocoding service unavailable ({type(e).__name__}).")

    if not results:
        raise geocodeError("Could not find that address. Please check it and try again.")

    return float(results[0]["lat"]), float(results[0]["lon"])