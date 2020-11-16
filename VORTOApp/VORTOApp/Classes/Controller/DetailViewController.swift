//
//  DetailViewController.swift
//  VORTOApp
//
//  Created by Muhammad Luqman on 11/15/20.
//

import UIKit
import CDYelpFusionKit
import Cosmos
import SDWebImage
import MapKit
import CoreLocation
import Speech

class DetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var ratingView: CosmosView!
    
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var reviewCountLbl: UILabel!
    @IBOutlet weak var categoryLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    @IBOutlet weak var openCloseLbl: UILabel!
    @IBOutlet weak var phoneNumberLbl: UILabel!
    @IBOutlet weak var btnStartOrder: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D!
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var steps = [MKRoute.Step]()
    var stepCounter = 0
    
    var business: CDYelpBusiness?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.setDataOnView()
        imageView.layer.cornerRadius = 8.0
        imageView.clipsToBounds = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        setMapView()
    }
    
    @IBAction func btnStartOrder(_ sender: Any) {
        
        if let business = self.business{
            if let url = business.url{
                UIApplication.shared.open(url)
            }
        }
    }
    
    
    // MARK: - functions
    // Configure Map View

    func setMapView() {
        
        self.locationManager.requestAlwaysAuthorization()
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
        }
        
        if let coor = mapView.userLocation.location?.coordinate{
            mapView.setCenter(coor, animated: true)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {[weak self] in
            guard let self = self else {return}
            self.loadMapViewAfterDelay()
        }
        
    }
    
    func loadMapViewAfterDelay() {
        
        if let business = self.business, let coordinates = business.coordinates, let latitude = coordinates.latitude, let longitude = coordinates.longitude{
            
            self.getDirections(to: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2DMake(latitude, longitude))))
        }
    }
    
    // get Directions
    func getDirections(to destination: MKMapItem) {
        
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, _) in
            guard let response = response else { return }
            guard let primaryRoute = response.routes.first else { return }
            
            self.mapView.addOverlay(primaryRoute.polyline)
            self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
            
            self.steps = primaryRoute.steps
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]
                print(step.instructions)
                print(step.distance)
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
            }
                        
            let initialMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
        
    }
    
    // Set values on text and image
    func  setDataOnView() {
        
        if let business = self.business{
            if let url = business.imageUrl{
                self.imageView.sd_setImage(with:url, placeholderImage: UIImage(named: "placeholder"))
            }
            if let name = business.name{
                self.title = name
            }
            
            var locationCompt = ""
            if let adress = business.location?.addressOne{
                locationCompt = adress
            }
            if let adress = business.location?.addressTwo, adress.count > 0{
                locationCompt = locationCompt.count == 0 ? adress : "\(locationCompt), \(adress)"
            }
            if let city = business.location?.city{
                locationCompt = locationCompt.count == 0 ? city : "\(locationCompt), \(city)"
            }
            if let country = business.location?.country{
                locationCompt = locationCompt.count == 0 ? country : "\(locationCompt), \(country)"
            }
            self.locationLbl.text = locationCompt
            
            if let category = business.categories?.first?.title{
                self.categoryLbl.text = category
            }else{
                self.categoryLbl.text = ""
            }
            if let rating = business.rating{
                self.ratingView.rating = rating
            }else{
                self.ratingView.rating = 0
            }
            
            if let reviewCount = business.reviewCount{
                
                self.reviewCountLbl.text = reviewCount < 2 ? "\(reviewCount) Review" : "\(reviewCount) Reviews"
            }else{
                self.reviewCountLbl.text = "0 Review"
            }
            
            if let distance = business.distance{
                
                let km: Double =  Double(round(1000*(distance / 1000))/1000)
                self.distanceLbl.text = "\(km) Km"
                
            }else{
                
                self.distanceLbl.text = ""
            }
            
            if let isClosed = business.isClosed{
                
                self.openCloseLbl.text = isClosed ? "Closed" : "Open"
                self.openCloseLbl.textColor = isClosed ? .red : .green
                
            }
            
            if let displayPhone = business.displayPhone{
                
                self.phoneNumberLbl.text = displayPhone.count != 0 ? displayPhone : "###########"
                
            }
            
            self.btnStartOrder.RoundCornerLabel(cornerRadius: 20)
            
        }
    }
}

// MARK: - CLLocation Manager Delegate
extension DetailViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else { return }
        currentCoordinate = currentLocation.coordinate
        mapView.userTrackingMode = .followWithHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        print("ENTERED")
        stepCounter += 1
        if stepCounter < steps.count {
            
            let currentStep = steps[stepCounter]
            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            
        } else {
            
            let message = "Arrived at destination"
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
            
        }
    }
}

// MARK: - MKMap View Delegate
extension DetailViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            return renderer
        }
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.fillColor = .red
            renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }
    
}
