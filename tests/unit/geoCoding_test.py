import pytest
import httpx
from unittest.mock import patch, MagicMock, AsyncMock
from geoCoding import geocodeAddress, geocodeError

# Required to tell pytest this file contains async tests
pytestmark = pytest.mark.asyncio

@patch("httpx.AsyncClient.get", new_callable=AsyncMock)
async def test_geocodeAddress_success(mock_get):
    """Test successful geocoding returns the correct lat/lon."""
    # Arrange: Mock the response object
    mock_response = MagicMock()
    mock_response.json.return_value = [{"lat": "36.1156", "lon": "-97.0584"}]
    mock_get.return_value = mock_response

    # Act
    lat, lon = await geocodeAddress("Stillwater, OK")

    # Assert
    assert lat == 36.1156
    assert lon == -97.0584
    mock_get.assert_called_once()
    
    # Verify the correct parameters and headers were sent
    _, kwargs = mock_get.call_args
    assert kwargs["params"]["q"] == "Stillwater, OK"
    assert kwargs["headers"]["User-Agent"] == "PlateShare/1.0 (tylsams@okstate.edu)"

@patch("httpx.AsyncClient.get", new_callable=AsyncMock)
async def test_geocodeAddress_empty_results(mock_get):
    """Test API returning an empty list raises a geocodeError."""
    mock_response = MagicMock()
    mock_response.json.return_value = []
    mock_get.return_value = mock_response

    with pytest.raises(geocodeError, match="Could not find that address"):
        await geocodeAddress("Nowhere Town, Fake State")

@patch("httpx.AsyncClient.get", new_callable=AsyncMock)
async def test_geocodeAddress_network_error(mock_get):
    """Test that httpx network exceptions are caught and re-raised."""
    # Arrange: Force the client to raise an exception
    mock_get.side_effect = httpx.HTTPError("Simulated network drop")

    # Assert
    with pytest.raises(geocodeError, match="timed out"):
        await geocodeAddress("123 Error St")