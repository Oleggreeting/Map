//
//  ViewController.swift
//  MapView
//
//  Created by Олег Mатюхин on 17/12/2022.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    let geocoder = CLGeocoder()
    let locationManager = CLLocationManager()
    var annotationsArray = [MKPointAnnotation]()
    let search = UISearchBar(frame: .zero)
    
    let mapView: MKMapView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(MKMapView())
    
    let buttonAdd: UIButton = {
        let add = UIButton()
        add.setTitle("AddPoint", for: .normal)
        add.translatesAutoresizingMaskIntoConstraints = false
        add.backgroundColor = .systemBlue
        add.layer.cornerRadius = 5
        add.layer.borderColor = UIColor.gray.cgColor
        add.layer.borderWidth = 1
        return add
    }()
    
    let buttonStart: UIButton = {
        let s = UIButton()
        s.translatesAutoresizingMaskIntoConstraints = false
        s.setTitleColor(.systemPink, for: .normal)
        s.backgroundColor = .green
        s.setTitle("Start", for: .normal)
        s.layer.cornerRadius = 25
        s.layer.borderColor = UIColor.gray.cgColor
        s.layer.borderWidth = 1
        return s
    }()
    
    let buttonDelete: UIButton = {
        let d = UIButton()
        d.backgroundColor = .red
        d.translatesAutoresizingMaskIntoConstraints = false
        d.setTitle("Delet", for: .normal)
        d.layer.cornerRadius = 5
        d.layer.borderColor = UIColor.gray.cgColor
        d.layer.borderWidth = 1
        return d
    }()
    
    lazy var buttonMyLocation: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setBackgroundImage(UIImage(systemName: "paperplane.circle"), for: .normal)
        return $0
    }(UIButton())
    
    lazy var buttonRepeat: UIButton = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.setBackgroundImage(UIImage(systemName: "repeat"), for: .normal)
        $0.tintColor = .gray
        return $0
    }(UIButton())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsCompass = true
        mapView.delegate = self
        setupLocationManager()
        mapView.showsUserLocation = true
        constraints()
        setupButtons()
        visibilityOfButtons()
        addGesture()
        
        navigationItem.titleView = search
        search.delegate = self
        myLocation()
    }
    
    
    //MARK: - Buttons
    @objc func repeatPlacemarks(){
        repeatItems()
    }
    @objc func start(){
        buttonStart.animation()
        startNavigation()
    }
    
    @objc func findMyLocation(){
        buttonMyLocation.animation()
        myLocation()
    }
    
    @objc func deleteWay(){
        removePlacemarks()
    }
    
    @objc func showPointOfTouch(_ gesture: UITapGestureRecognizer){
        let point = gesture.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        if annotationsArray.isEmpty{
            createPoint(coordinate: coordinate)
            showPoint(coordinate)
        } else {
            mapView.removeAnnotations(annotationsArray)
            annotationsArray = []
            mapView.showAnnotations(annotationsArray, animated: true)
        }
        
    }
    
    
    //MARK: - Functions
    
    private func startNavigation(){
        guard let location = annotationsArray.first?.coordinate else {return}
        var loc = location
        let startLocation = CLLocation(latitude: location.latitude,
                                       longitude: location.longitude)
        guard let currentLocation = locationManager.location else {return}
        if currentLocation.distance(from: startLocation) > 50 {
            loc = currentLocation.coordinate
            repeatItems()
        }
        let span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        let region = MKCoordinateRegion(center: loc, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    private func createDirection(){
        if annotationsArray.count > 1 {
            for i in 0..<annotationsArray.count - 1 {
                let request =  createRequest(start: annotationsArray[i], finish: annotationsArray[ i + 1])
                let direction = MKDirections(request: request)
                direction.calculate { [unowned self] response, error in
                    guard let response = response else {return}
                    guard let shortRout = response.routes.first else {return}
                    mapView.addOverlay(shortRout.polyline)
                }
                
            }
        }
    }
    
    private func createRequest(start: MKPointAnnotation, finish: MKPointAnnotation) -> MKDirections.Request {
        let startPoint = start.coordinate
        let endPoint = finish.coordinate
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startPoint))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endPoint))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        return request
        
    }
    
    private func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func createPoint(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotationsArray.append(annotation)
    }
    
    private func repeatItems(){
        annotationsArray = annotationsArray.reversed()
        mapView.removeAnnotations(annotationsArray)
        mapView.removeOverlays(mapView.overlays)
        createDirection()
        addTitleForPlacemark()
        mapView.showAnnotations(annotationsArray, animated: true)
    }
    
    @objc private func removePlacemarks() {
        mapView.removeAnnotations(annotationsArray)
        mapView.removeOverlays(mapView.overlays)
        annotationsArray = []
        
        let annotation = MKPointAnnotation()
        guard let coordinate = locationManager.location?.coordinate else {return}
        annotation.coordinate = coordinate
        annotationsArray.append(annotation)
        visibilityOfButtons()
        mapView.showAnnotations(annotationsArray, animated: true)
    }
    
    fileprivate func showPoint(_ coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01,
                                                               longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)
        createPoint(coordinate: coordinate)
        mapView.showAnnotations(annotationsArray, animated: true)
    }
    
    private func myLocation(){
        //        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinate = CLLocationCoordinate2D(latitude: 52.437042, longitude: 16.811160)
        showPoint(coordinate)
        
    }
    
    
    
    private func addTitleForPlacemark(){
        if annotationsArray.count > 1 {
            annotationsArray.first?.title = "Start"
            annotationsArray.last?.title = "Finish"
            for i in 1..<annotationsArray.count - 1 {
                annotationsArray[i].title = "Point \(i)"
            }
            createDirection()
        }
    }
    
    private func visibilityOfButtons(){
        switch annotationsArray.count {
        case 1:
            buttonStart.isHidden = true
            buttonDelete.isHidden = true
            buttonRepeat.isHidden = true
        default:
            buttonStart.isHidden = false
            buttonDelete.isHidden = false
            buttonRepeat.isHidden = false
        }
    }
    
    
    private func setupButtons(){
        buttonRepeat.addTarget(self, action: #selector(repeatPlacemarks), for: .touchUpInside)
        buttonMyLocation.addTarget(self, action: #selector(findMyLocation), for: .touchUpInside)
        buttonDelete.addTarget(self, action: #selector(deleteWay), for:.touchUpInside )
        buttonMyLocation.setImage(UIImage(named: "paperplane.circle"), for: .normal)
        buttonStart.addTarget(self, action: #selector(start), for: .touchUpInside)
    }
    
    private func createPlacemark(text: String){
        geocoder.geocodeAddressString(text) {[self] request, error in
            if error != nil  {return}
            guard let location = request?.first?.location else {return}
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotationsArray.append(annotation)
            addTitleForPlacemark()
            visibilityOfButtons()
            mapView.showAnnotations(annotationsArray, animated: true)
        }
    }
    
    private func addGesture(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(showPointOfTouch))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        mapView.addGestureRecognizer(tap)
    }
    
    
    
    private func constraints(){
        view.addSubview(mapView)
        view.addSubview(buttonDelete)
        view.addSubview(buttonMyLocation)
        view.addSubview(buttonStart)
        view.addSubview(buttonRepeat)
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            buttonDelete.widthAnchor.constraint(equalToConstant: 70),
            buttonDelete.heightAnchor.constraint(equalToConstant: 40),
            buttonDelete.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            buttonDelete.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            buttonMyLocation.widthAnchor.constraint(equalToConstant: 40),
            buttonMyLocation.heightAnchor.constraint(equalToConstant: 40),
            buttonMyLocation.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            buttonMyLocation.bottomAnchor.constraint(equalTo: buttonDelete.topAnchor, constant: -150),
            
            buttonRepeat.widthAnchor.constraint(equalToConstant: 40),
            buttonRepeat.heightAnchor.constraint(equalToConstant: 40),
            buttonRepeat.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            buttonRepeat.bottomAnchor.constraint(equalTo: buttonMyLocation.topAnchor, constant: -30),
            
            buttonStart.heightAnchor.constraint(equalToConstant: 50),
            buttonStart.widthAnchor.constraint(equalToConstant: 50),
            buttonStart.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            buttonStart.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}


//MARK: - UISearchBarDelegate

extension MapViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText, "1")
    }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        print("beginEditing")
        return true
    }
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        print("EndEditing")
        return false
    }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("cancel")
    }
    func searchBarBookmarkButtonClicked(_ searchBar: UISearchBar) {
        print("Bookmark")
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchButton")
    }
    
}
//MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else {return}
        annotationsArray.first?.coordinate = coordinate
        print(coordinate)
        mapView.showAnnotations(annotationsArray, animated: true)
        self.locationManager.stopUpdatingLocation()
    }
    
}

//MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        render.strokeColor = .blue
        return render
    }
    
}

//MARK" - ButtonAnimation
extension UIButton{
    func animation(){
        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform.init(scaleX: 0.9, y: 0.9)
        }completion: { _  in
            UIView.animate(withDuration: 0.2) {
                self.transform = CGAffineTransform.init(scaleX: 1, y: 1)
            }
        }
    }
}


