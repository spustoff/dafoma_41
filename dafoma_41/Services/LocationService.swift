//
//  LocationService.swift
//  NewsEaseAvi
//
//  Created by Вячеслав on 9/9/25.
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled: Bool = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Guide user to settings
            errorMessage = "Location access is required for local news. Please enable location services in Settings."
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            errorMessage = "Location services are disabled. Please enable them in Settings."
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
        errorMessage = nil
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    func getCurrentLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.requestLocation()
    }
    
    func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = "Failed to get address: \(error.localizedDescription)"
                    return
                }
                
                if let placemark = placemarks?.first {
                    self?.updateAddress(from: placemark)
                }
            }
        }
    }
    
    func geocodeAddress(_ address: String, completion: @escaping (CLLocation?) -> Void) {
        geocoder.geocodeAddressString(address) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                if let placemark = placemarks?.first,
                   let location = placemark.location {
                    completion(location)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100 // Update every 100 meters
        
        authorizationStatus = locationManager.authorizationStatus
        
        // Monitor authorization status changes
        $authorizationStatus
            .sink { [weak self] status in
                self?.handleAuthorizationStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthorizationStatusChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            errorMessage = nil
            if isLocationEnabled {
                startLocationUpdates()
            }
        case .denied, .restricted:
            stopLocationUpdates()
            errorMessage = "Location access is required for local news. Please enable location services in Settings."
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    private func updateAddress(from placemark: CLPlacemark) {
        var addressComponents: [String] = []
        
        if let name = placemark.name {
            addressComponents.append(name)
        }
        
        if let locality = placemark.locality {
            addressComponents.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            addressComponents.append(administrativeArea)
        }
        
        if let country = placemark.country {
            addressComponents.append(country)
        }
        
        currentAddress = addressComponents.joined(separator: ", ")
    }
    
    // MARK: - Utility Methods
    
    func distanceBetween(_ location1: CLLocation, _ location2: CLLocation) -> CLLocationDistance {
        return location1.distance(from: location2)
    }
    
    func isLocationWithinRadius(_ location: CLLocation, center: CLLocation, radius: CLLocationDistance) -> Bool {
        return distanceBetween(location, center) <= radius
    }
    
    func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: distance)
    }
    
    func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return String(format: "%.6f, %.6f", coordinate.latitude, coordinate.longitude)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out old or inaccurate locations
        guard location.timestamp.timeIntervalSinceNow > -5.0,
              location.horizontalAccuracy < 100 else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = location
            self?.errorMessage = nil
            
            // Get address for the location
            self?.reverseGeocode(location: location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self?.errorMessage = "Location access denied. Please enable location services in Settings."
                case .locationUnknown:
                    self?.errorMessage = "Unable to determine location. Please try again."
                case .network:
                    self?.errorMessage = "Network error while getting location. Please check your connection."
                default:
                    self?.errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                self?.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = status
        }
    }
}

// MARK: - Location Extensions

extension CLLocation {
    var cityName: String? {
        return nil // This would be populated through reverse geocoding
    }
    
    var countryName: String? {
        return nil // This would be populated through reverse geocoding
    }
    
    func isWithinRadius(of center: CLLocation, radius: CLLocationDistance) -> Bool {
        return distance(from: center) <= radius
    }
}

// MARK: - Import MapKit for MKDistanceFormatter

import MapKit

