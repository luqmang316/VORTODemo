//
//  SearchViewController.swift
//  VORTOApp
//
//  Created by Muhammad Luqman on 11/15/20.
//

import UIKit
import CoreLocation
import CDYelpFusionKit

// MARK: - Enum
enum Segue: String {
    
    case DetailSegue = "DetailSegue"
    
}

class SearchViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak private var tableView: UITableView!
    @IBOutlet weak var searchBusinessesTxt: UISearchBar!
    @IBOutlet weak var notFountLbl: UILabel!
    
    // MARK: - Property
    let locationManager = CLLocationManager()
    var location = (latitude: 0.0, longitude: 0.0, city: "", country: "")
    
    var yelpSearchResponse: CDYelpSearchResponse?
    var selectedBusiness: CDYelpBusiness?
    var limit = 20
    
    let identifierCell = "SearchBusinessCell"
    
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.searchBusinessesTxt.returnKeyType = .done
        
        //Authorize using your clientId.
        CDYelpFusionKitManager.shared.configure()

        //Request location authorization when the app is in use
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        // Set table footer view
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {

        self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })

    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func openUrl(_ url: URL) {
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if(segue.identifier == Segue.DetailSegue.rawValue){
            
            let detailVC = segue.destination as! DetailViewController
            detailVC.business = self.selectedBusiness
            
        }
    }
}

// MARK: - CLLocationManagerDelegate Methods

extension SearchViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locationCoordinate: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locationCoordinate.latitude) \(locationCoordinate.longitude)")
        
        guard let location: CLLocation = manager.location else { return }
        
        fetchCityAndCountry(from: location) { city, country, error in
            guard let city = city, let country = country, error == nil else { return }
            print(city + ", " + country)
            self.location = (locationCoordinate.latitude, locationCoordinate.longitude, city, country)
            
        }
    }
    
    func fetchCityAndCountry(from location: CLLocation, completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            completion(placemarks?.first?.locality, placemarks?.first?.country, error)
        }
    }
    
}


// MARK: - UISearchBarDelegate Methods

extension SearchViewController: UISearchBarDelegate{
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        // When user has entered text into the search box
        print(searchText)
        //Search for businesses by keyword, category.
        self.searchBusiness(searchText)
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        
    }
    
    func searchBusiness(_ searchText: String, isPagination: Bool = false) {
        
        if searchText.count == 0 {
            
            CDYelpFusionKitManager.shared.apiClient.cancelAllPendingAPIRequests()
            self.yelpSearchResponse = nil
            self.tableView.reloadData()
            
        }else{
            
            var offSet = 0
            if let yelpSearchResponse = self.yelpSearchResponse, let businesses = yelpSearchResponse.businesses, businesses.count > 0 {
                offSet = businesses.count
            }
            
            CDYelpFusionKitManager.shared.apiClient.searchBusinesses(byTerm: searchText,
                                                                     location: "\(self.location.city) \(self.location.country)",
                                                                     latitude: self.location.latitude,
                                                                     longitude: self.location.longitude,
                                                                     radius: 10000,
                                                                     categories: nil,
                                                                     locale: .english_unitedStates,
                                                                     limit: limit,
                                                                     offset: offSet,
                                                                     sortBy: .rating,
                                                                     priceTiers: nil,
                                                                     openNow: true,
                                                                     openAt: nil,
                                                                     attributes: nil) { (response) in
                if let response = response {
                    
                    if isPagination {
                        if let yelpSearchResponse = self.yelpSearchResponse, let businesses = yelpSearchResponse.businesses{
                            
                            if let newBusinesses = response.businesses, newBusinesses.count > 0{
                                self.yelpSearchResponse?.businesses = businesses + newBusinesses
                            }
                        }
                    }else{
                        self.yelpSearchResponse = response
                    }
                    
                    self.tableView.reloadData()
                    
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource Methods

extension SearchViewController: UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let yelpSearchResponse = self.yelpSearchResponse, let businesses = yelpSearchResponse.businesses, businesses.count > 0 {
            
            self.notFountLbl.isHidden = true
            return businesses.count
        }
        
        self.notFountLbl.isHidden = false
        return 0
    }
    
    // swiftlint:disable function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifierCell, for: indexPath) as? SearchBusinessCell else {
            
            return UITableViewCell()
        }
        
        if let yelpSearchResponse = self.yelpSearchResponse, let businesses = yelpSearchResponse.businesses{
            
            let business = businesses[indexPath.row]
            cell.setDataOnCell(business: business)
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        
        if let yelpSearchResponse = self.yelpSearchResponse, let businesses = yelpSearchResponse.businesses, businesses.count > 0, let total = yelpSearchResponse.total {
            
            if indexPath.row == businesses.count - 1 {
                // we are at last cell load more content
                if businesses.count < total {
                    // we need to bring more records as there are some pending records available
                    if let txt = self.searchBusinessesTxt.text{
                        self.searchBusiness(txt, isPagination: true)
                        print("Businesses.count: \(businesses.count)")
                        print("Total: \(total)")
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
}

// MARK: - UITableView Delegate Methods

extension SearchViewController: UITableViewDelegate {
    
    // swiftlint:disable function_body_length
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let yelpSearchResponse = self.yelpSearchResponse, let businesses = yelpSearchResponse.businesses{
            self.selectedBusiness = businesses[indexPath.row]
            self.performSegue(withIdentifier: Segue.DetailSegue.rawValue, sender: self)
        }
        
    }
    
}
