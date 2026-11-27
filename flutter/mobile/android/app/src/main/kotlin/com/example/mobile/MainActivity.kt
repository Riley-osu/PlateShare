package com.example.mobile

import android.location.Address
import android.location.Geocoder
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.Locale

class MainActivity : FlutterActivity() {
    private val geocoderChannel = "com.example.mobile/native_geocoder"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            geocoderChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "reverseGeocode" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    if (
                        latitude == null ||
                        longitude == null ||
                        !latitude.isFinite() ||
                        !longitude.isFinite() ||
                        latitude !in -90.0..90.0 ||
                        longitude !in -180.0..180.0
                    ) {
                        result.error(
                            "INVALID_COORDINATES",
                            "Invalid location coordinates.",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    if (!Geocoder.isPresent()) {
                        result.error(
                            "GEOCODER_UNAVAILABLE",
                            "Address lookup is unavailable.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val geocoder = Geocoder(this, Locale.getDefault())
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        geocoder.getFromLocation(
                            latitude,
                            longitude,
                            1,
                            object : Geocoder.GeocodeListener {
                                override fun onGeocode(addresses: MutableList<Address>) {
                                    sendAddressResult(addresses, result)
                                }

                                override fun onError(errorMessage: String?) {
                                    runOnUiThread {
                                        result.error(
                                            "GEOCODING_FAILED",
                                            errorMessage
                                                ?: "Unable to find a street address.",
                                            null
                                        )
                                    }
                                }
                            }
                        )
                    } else {
                        Thread {
                            try {
                                @Suppress("DEPRECATION")
                                val addresses = geocoder.getFromLocation(
                                    latitude,
                                    longitude,
                                    1
                                )
                                if (addresses.isNullOrEmpty()) {
                                    runOnUiThread {
                                        result.error(
                                            "ADDRESS_NOT_FOUND",
                                            "Unable to find a street address.",
                                            null
                                        )
                                    }
                                } else {
                                    sendAddressResult(addresses, result)
                                }
                            } catch (error: IOException) {
                                runOnUiThread {
                                    result.error(
                                        "GEOCODING_FAILED",
                                        error.message,
                                        null
                                    )
                                }
                            }
                        }
                            .start()
                    }
                }

                "searchAddresses" -> {
                    val query = call.argument<String>("query")?.trim()
                    if (query.isNullOrEmpty() || query.length < 3) {
                        result.success(emptyList<String>())
                        return@setMethodCallHandler
                    }
                    if (!Geocoder.isPresent()) {
                        result.error(
                            "GEOCODER_UNAVAILABLE",
                            "Address suggestions are unavailable.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    searchAddresses(query, result)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun searchAddresses(query: String, result: MethodChannel.Result) {
        val geocoder = Geocoder(this, Locale.getDefault())
        val lowerLeftLatitude = 35.95
        val lowerLeftLongitude = -97.25
        val upperRightLatitude = 36.28
        val upperRightLongitude = -96.85

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            geocoder.getFromLocationName(
                query,
                5,
                lowerLeftLatitude,
                lowerLeftLongitude,
                upperRightLatitude,
                upperRightLongitude,
                object : Geocoder.GeocodeListener {
                    override fun onGeocode(addresses: MutableList<Address>) {
                        sendAddressSuggestions(addresses, result)
                    }

                    override fun onError(errorMessage: String?) {
                        runOnUiThread {
                            result.error(
                                "ADDRESS_SEARCH_FAILED",
                                errorMessage ?: "Unable to search nearby addresses.",
                                null
                            )
                        }
                    }
                }
            )
        } else {
            Thread {
                try {
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocationName(
                        query,
                        5,
                        lowerLeftLatitude,
                        lowerLeftLongitude,
                        upperRightLatitude,
                        upperRightLongitude
                    )
                    sendAddressSuggestions(addresses.orEmpty(), result)
                } catch (error: IOException) {
                    runOnUiThread {
                        result.error(
                            "ADDRESS_SEARCH_FAILED",
                            error.message,
                            null
                        )
                    }
                }
            }
                .start()
        }
    }

    private fun sendAddressResult(
        addresses: List<Address>,
        result: MethodChannel.Result
    ) {
        val address = addresses.firstOrNull()?.getAddressLine(0)?.trim()
        runOnUiThread {
            if (address.isNullOrEmpty()) {
                result.error("ADDRESS_NOT_FOUND", "Unable to find a street address.", null)
            } else {
                result.success(address)
            }
        }
    }

    private fun sendAddressSuggestions(
        addresses: List<Address>,
        result: MethodChannel.Result
    ) {
        val suggestions = addresses
            .mapNotNull { it.getAddressLine(0)?.trim() }
            .filter { it.isNotEmpty() }
            .distinct()
        runOnUiThread {
            result.success(suggestions)
        }
    }
}
