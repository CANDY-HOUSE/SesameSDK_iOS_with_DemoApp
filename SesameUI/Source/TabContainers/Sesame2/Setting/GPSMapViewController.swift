//
//  GPSMapViewController.swift
//  SesameUI
//
//  Created by Wayne Hsiao on 2020/9/11.
//  Copyright © 2020 CandyHouse. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SesameSDK

class GPSMapViewController: CHBaseViewController {
    
    let locationManager = CLLocationManager()
    let mapView = MKMapView(frame: .zero)
    let displayLabel = UILabel(frame: .zero)
    
    var sesame2: CHSesame2!
    var currentSelectedLocation: CLLocation?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(mapView)
        view.addSubview(displayLabel)
        
        displayLabel.backgroundColor = .white
        displayLabel.text = "Address"
        mapView.delegate = self
        mapView.showsUserLocation = true
        
        displayLabel.autoPinTop()
        displayLabel.autoPinCenterX()
        displayLabel.autoPinWidth()
        displayLabel.autoLayoutHeight(50)
        mapView.autoPinTopToBottomOfView(displayLabel)
        
        mapView.autoPinCenterX()
        mapView.autoPinWidth()
        mapView.autoPinBottom()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "sesame2")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        title = "Set Sesame2 Location"
    }
}

extension GPSMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let _ = annotation as? MKUserLocation {
            return nil
        } else {
            let confirmButton = mapView.dequeueReusableAnnotationView(withIdentifier: "sesame2", for: annotation)
            confirmButton.image = UIImage(named: "AppIcon")
            confirmButton.layer.cornerRadius = confirmButton.bounds.width / 2
            confirmButton.layer.masksToBounds = true
            confirmButton.isDraggable = true
            confirmButton.isSelected = true
            confirmButton.collisionMode = .circle
            
            return confirmButton
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if mapView.annotations.count < 2 {
            let center = userLocation.coordinate//map.userLocation.coordinate
            mapView.region = MKCoordinateRegion(center: center, latitudinalMeters: 200, longitudinalMeters: 200)
            let regionRadius = 100.0
            let circle = MKCircle(center: center, radius: regionRadius)
            mapView.addOverlay(circle)
            mapView.setCenter(center, animated: true)

            let annotation = MKPointAnnotation()
            annotation.coordinate = userLocation.coordinate
            mapView.addAnnotation(annotation)
            currentSelectedLocation = CLLocation(latitude: annotation.coordinate.latitude,
                                                 longitude: annotation.coordinate.longitude)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationView.DragState, fromOldState oldState: MKAnnotationView.DragState) {
        if newState == .ending {
            mapView.removeAnnotations(mapView.annotations)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = view.annotation!.coordinate
            
            mapView.addAnnotation(annotation)
            let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
            
            mapView.removeOverlays(mapView.overlays)
            let center = annotation.coordinate//map.userLocation.coordinate
//            mapView.region.center = center
//            mapView.region = MKCoordinateRegion(center: center, latitudinalMeters: 200, longitudinalMeters: 200)
            let regionRadius = 100.0
            let circle = MKCircle(center: center, radius: regionRadius)
            mapView.addOverlay(circle)
            mapView.setCenter(center, animated: true)
            
            currentSelectedLocation = location
            lookUpCurrentLocation(location) {_ in
                
            }
        }
    }
    
    func lookUpCurrentLocation(_ location: CLLocation, completionHandler: @escaping (CLPlacemark?)
                    -> Void ) {
        // Use the last reported location.
        if let lastLocation = self.locationManager.location {
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    let firstLocation = placemarks?[0]
                    completionHandler(firstLocation)
                }
                else {
                 // An error occurred during geocoding.
                    completionHandler(nil)
                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let _ = view as? MKAnnotationView,
            let currentSelectedLocation = currentSelectedLocation {
            let alertController = UIAlertController(title: "", message: "", preferredStyle: .alert)
            let action = UIAlertAction(title: "ok", style: .default) { _ in
                Sesame2Store.shared.saveLocationForSesame2(self.sesame2, location: currentSelectedLocation)
            }
            
            lookUpCurrentLocation(currentSelectedLocation) {
                alertController.message = "Set Sesame location to \($0?.name)"
            }
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(action)
            alertController.addAction(cancel)
            
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension GPSMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            startUpdateIfNeeded()
        } else {
            // remind user
        }
    }
    
    fileprivate func startUpdateIfNeeded() {
                
        if CLLocationManager.locationServicesEnabled() {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.pausesLocationUpdatesAutomatically = true
            locationManager.activityType = .automotiveNavigation
            locationManager.startUpdatingLocation()
        } else {
                // remind user
        }
            
        if CLLocationManager.significantLocationChangeMonitoringAvailable() {
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
                // remind user
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        centerUserLocation(locations.last!)
    }
    
    fileprivate func centerUserLocation(_ location: CLLocation) {
        
    }
}
