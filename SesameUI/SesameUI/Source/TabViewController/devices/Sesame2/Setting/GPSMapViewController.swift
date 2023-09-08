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
    
    let defaultRadius = 150.0
    
    let scrollView = UIScrollView(frame: .zero)
    let contentStackView = UIStackView(frame: .zero)
    
    let locationManager = CLLocationManager()
    let mapView = MKMapView(frame: .zero)
    let displayLabel = UILabel(frame: .zero)
    var sliderView: CHUISliderSettingView!
    var containerView = UIView(frame: .zero)
    
    var sesame2: CHSesameLock!
    
    var circle: MKCircle?
    var currentAddress: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locationInfo = Sesame2Store.shared.getLocationForSesame2(sesame2)
        if locationInfo.0.coordinate.latitude == 0,
           locationInfo.0.coordinate.longitude == 0,
           locationInfo.1 == 0 {
            L.d("not set")
        } else {
            circle = MKCircle(center: locationInfo.0.coordinate, radius: locationInfo.1)
        }
        
        view.backgroundColor = .sesame2Gray
        scrollView.addSubview(contentStackView)
        scrollView.isScrollEnabled = false
        view.addSubview(scrollView)
        
        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 0
        contentStackView.distribution = .fill
        
        UIView.autoLayoutStackView(contentStackView, inScrollView: scrollView)
        
        containerView = UIView(frame: .zero)
        contentStackView.addArrangedSubview(containerView)
        containerView.autoPinEdgesToSuperview()
        
        // MARK: - Toggle View
        let toggleView = CHUIViewGenerator.toggle { [unowned self] sender,_ in
            if let toggle = sender as? UISwitch, toggle.isOn {
                Sesame2Store.shared.saveLocationForSesame2(self.sesame2, location: CLLocation(latitude: self.circle!.coordinate.latitude, longitude: self.circle!.coordinate.longitude), radius: self.circle!.radius)
                
                self.sesame2.setAutoUnlock(true)
            } else {
                self.sesame2.setAutoUnlock(false)
            }
        }
        toggleView.title = "co.candyhouse.sesame2.AutoUnlock".localized
        toggleView.switchView.isOn = sesame2.autoUnlockStatus()
        containerView.addSubview(toggleView)
        toggleView.autoPinTop()
        toggleView.autoPinLeading()
        toggleView.autoPinTrailing()
        
        // MARK: - Map
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true
        containerView.addSubview(mapView)
        mapView.autoPinTrailing()
        mapView.autoPinLeading()
        mapView.autoPinTopToBottomOfView(toggleView)
        mapView.autoPinBottom()
        navigationItem.rightBarButtonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        
        // MARK: - Desc View
        let descriptionTextView = UITextView(frame: .zero)
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(descriptionTextView)
        descriptionTextView.autoPinTopToBottomOfView(toggleView)
        descriptionTextView.autoPinLeading()
        descriptionTextView.autoPinTrailing()
        descriptionTextView.autoLayoutHeight(120)
        descriptionTextView.isEditable = false
        descriptionTextView.isSelectable = false
        descriptionTextView.text = "co.candyhouse.sesame2.gpsDescription".localized
        descriptionTextView.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        
        // MARK: - Slider
        let minimunValue = 2
        let maximumValue = 50
        sliderView = CHUIViewGenerator.slider(defaultValue: Float(circle?.radius ?? defaultRadius) / 10.0, maximumValue: Float(maximumValue), minimumValue: Float(minimunValue)) { [unowned self] slider,event in
            if let circle = circle {
                self.mapView.removeOverlay(circle)

                let newRadius = (slider as! UISlider).value * 10
                self.circle = MKCircle(center: circle.coordinate, radius: CLLocationDistance(newRadius))
                self.mapView.addOverlay(self.circle!)
                Sesame2Store.shared.saveLocationForSesame2(self.sesame2, location: CLLocation(latitude: self.circle!.coordinate.latitude, longitude: self.circle!.coordinate.longitude), radius: self.circle!.radius)

            }
        }
        containerView.addSubview(sliderView)
        sliderView.autoPinLeading()
        sliderView.autoPinTrailing()
        sliderView.autoPinBottom(constant: -50)
        sliderView.backgroundColor = .clear
        sliderView.tintColor = .lockRed
        sliderView.slider.thumbTintColor = .lockRed
        let minimumLabel = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 30))
        let maximumLabel = UILabel(frame: .init(x: 0, y: 0, width: 50, height: 30))
        minimumLabel.text = "\(minimunValue*10) m"
        minimumLabel.textColor = .lockRed
        maximumLabel.text = "\(maximumValue*10) m"
        maximumLabel.textColor = .lockRed
        sliderView.slider.minimumValueImage = UIImage.imageWithLabel(label: minimumLabel)
        sliderView.slider.maximumValueImage = UIImage.imageWithLabel(label: maximumLabel)

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "sesame2")
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnMap(gesture:)))
        self.mapView.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapOnMap(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self.mapView)
        let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
        //Now use this coordinate to add annotation on map.
        
        mapView.removeAnnotations(mapView.annotations)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        
        mapView.removeOverlays(mapView.overlays)
        let center = annotation.coordinate
        let regionRadius = self.circle?.radius ?? defaultRadius
        self.sliderView.slider.value = Float(regionRadius / 10)
        self.circle = MKCircle(center: center, radius: regionRadius)
        mapView.addOverlay(self.circle!)
        mapView.setCenter(center, animated: true)
        
        Sesame2Store.shared.saveLocationForSesame2(self.sesame2, location: CLLocation(latitude: self.circle!.coordinate.latitude, longitude: self.circle!.coordinate.longitude), radius: self.circle!.radius)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let window = UIApplication.shared.keyWindow
        let topPadding = window?.safeAreaInsets.top ?? 0
        containerView.autoLayoutHeight(view.frame.height-40-topPadding)
    }
    
    deinit {
        L.d("map deinit")
    }
}

extension GPSMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.fillColor = UIColor.lockRed.withAlphaComponent(0.3)
        return circleRenderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if let _ = annotation as? MKUserLocation {
            return nil
        } else {
            let confirmButton = mapView.dequeueReusableAnnotationView(withIdentifier: "sesame2", for: annotation)
            confirmButton.image = UIImage(named: "AppIcon")
            confirmButton.bounds = CGRect(x: confirmButton.bounds.midX, y: confirmButton.bounds.midY, width: 30, height: 30)
            confirmButton.layer.cornerRadius = confirmButton.bounds.width / 2
            confirmButton.layer.masksToBounds = true
            confirmButton.isDraggable = false
            confirmButton.isSelected = false
            confirmButton.collisionMode = .circle
            return confirmButton
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if mapView.annotations.count < 2 {
            if let circle = circle {
                let center = circle.coordinate//map.userLocation.coordinate
                
                mapView.region = MKCoordinateRegion(center: center, latitudinalMeters: circle.radius * 2.5, longitudinalMeters: circle.radius * 2.5)
                mapView.addOverlay(circle)
                mapView.setCenter(center, animated: true)

                let annotation = MKPointAnnotation()
                annotation.coordinate = circle.coordinate
                mapView.addAnnotation(annotation)
            } else {
                let center = userLocation.coordinate//map.userLocation.coordinate
                mapView.region = MKCoordinateRegion(center: center, latitudinalMeters: defaultRadius * 2.5, longitudinalMeters: defaultRadius * 2.5)
                self.circle = MKCircle(center: center, radius: defaultRadius)
                self.sliderView?.slider.value = Float(defaultRadius / 10)
                mapView.addOverlay(circle!)
                mapView.setCenter(center, animated: true)

                let annotation = MKPointAnnotation()
                annotation.coordinate = userLocation.coordinate
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    static func instanceWithSesame2(_ sesame2: CHSesameLock) -> GPSMapViewController {
        let gpsView = GPSMapViewController(nibName: nil, bundle: nil)
        gpsView.sesame2 = sesame2
        return gpsView
    }
}

extension GPSMapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if CLLocationManager.authorizationStatus() == .notDetermined || CLLocationManager.authorizationStatus() == .denied {
            self.locationManager.requestWhenInUseAuthorization()
        } else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            self.locationManager.requestAlwaysAuthorization()
        }
    }
}
