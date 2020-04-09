//
//  MapViewController.swift
//  myPlaces
//
//  Created by Саня Eloy on 27.02.2020.
//  Copyright © 2020 Саня Eloy. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    var locationManager = CLLocationManager()
    let regionInMeters = 1000.00
    var incomeSegueIndentifier = ""
    var placeCordinate: CLLocationCoordinate2D?
    // Маршруты
    var directionsArray: [MKDirections] = []
    // Предыдущее расположение пользователя
    var previousLocation: CLLocation?{
        didSet{
                startTrackingUserLocation()
        }
    }

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var buttonDone: UIButton!
    @IBOutlet var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addressLabel.text = ""
        mapView.delegate = self
        setupMapView()
        checkLocationServices()
    }
   
    
    @IBAction func centerViewInUserLocation() {
        showUserLocation()
    }
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    // При нажатии передаем текушее название адреса.
    @IBAction func doneButtonPressed() {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
    
    private func setupMapView(){
        
        goButton.isHidden = true
        if incomeSegueIndentifier == "showPlace"{
            setupPlacemark()
            mapPinImage.isHidden = true
            addressLabel.isHidden = true
            buttonDone.isHidden = true
            goButton.isHidden = false
        }
    }
    private func resetMapView(withNew directions: MKDirections){
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        // Отменяем все маршруты
        let _ = directionsArray.map{$0.cancel()}
        // Удаляем массив
        directionsArray.removeAll()
    }
    private func setupPlacemark(){
        guard let location = place.location else {return}
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location){(placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            
            guard let placemarks = placemarks else {return}
            
            let placemark = placemarks.first
            
            let annotation = MKPointAnnotation()
            
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            
            guard let placemarkLocation = placemark?.location else { return }
            
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }

    private func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAutorization()
        }else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                self.showAlert(title: "Location Services are Disable", message: "To enable it go: Setting ->Privacy -> Location services and turn On")
            }
        }
    }
    private func setupLocationManager(){
        locationManager.delegate = self
        // точность нахождения по локации
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
    }
    // права доступа к геолокации
    private func checkLocationAutorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if incomeSegueIndentifier == "getAddress" { showUserLocation()}
            break
        case .denied:
            // show alert controller
            break
        case . notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            // show alert controller
            break
        case .authorizedAlways:
            break
        @unknown default:
            print("New case is available")
        }
    }
    private func showUserLocation(){
        if let location =  locationManager.location?.coordinate{
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func startTrackingUserLocation(){
        guard let previousLocation = previousLocation else{ return}
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: previousLocation) > 50 else{ return}
        self.previousLocation = center
        // Задержка 3 сек до фокусировки нашего расположении на карте
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
        
    }
    private func getDirections(){
        // Узнаем текщее метонахождение
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found")
            return
        }
        locationManager.startUpdatingLocation()
        // Передача предыдущего местоположения пользователя
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
        let directions = MKDirections(request: request)
        // Удаляем маршрут перед созданием нового
        resetMapView(withNew: directions)
        // Расчет маршрута
        directions.calculate{ (response,error) in
            if let error = error{
                print(error)
                return
            }
            guard let response = response else {
                self.showAlert(title: "Error", message: "Direction is not available")
                return
            }
            for route in response.routes{
                // Подробная геометрия всего маршрута
                self.mapView.addOverlay(route.polyline)
                // отображение всего маршрута на экране
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                // Растояние
                let distance = String(format: "%1.f", route.distance / 1000)
                let timeInterval = route.expectedTravelTime
                
                print("Растояние до места: \(distance) км.")
                print("Время в пути составит: \(timeInterval) сек.")
            }
        }
    }
    // Настрока для построения маршрута
    private func createDirectionsRequest(from cordinate: CLLocationCoordinate2D) -> MKDirections.Request?{
        //Кординаты
        guard let destinationCordinate = placeCordinate else {
            return nil
        }
        //Старт маршрута
        let startingLocation = MKPlacemark(coordinate: cordinate)
        //
        let destination = MKPlacemark(coordinate: destinationCordinate)
        // Начальная и конечная точка маршрута
        let request = MKDirections.Request()
        // Начальна точка
        request.source = MKMapItem(placemark: startingLocation)
        // Конечная точка маршрута
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    // Возвращаем кардинаты точки по центру экрана
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation{
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    private func showAlert(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Ok", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

// Правка отображения булавки на карте

extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {return nil}
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView // булавка
        if annotationView  == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier) // булавка
            annotationView?.canShowCallout = true
        }
        if let imageData = place.imageData{
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        
        }
        return annotationView
    }
    //Отображение адреса текущего региона
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        if incomeSegueIndentifier == "showPlace" && previousLocation != nil{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showUserLocation()
            }
        }
        // Освобождение ресурсов
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center){(placemarks,error) in
            if let error = error{
                print(error)
                return
            }
            guard let placemarks = placemarks else {return}
            let placemark = placemarks.first
            let streetName = placemark?.thoroughfare
            let buildNumber = placemark?.subThoroughfare
            
            DispatchQueue.main.async {
                if streetName != nil && buildNumber != nil{
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil{
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    // Отображение линии маршрута
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
}

extension MapViewController: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAutorization()
    }
}
