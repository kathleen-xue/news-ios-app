//
//  FirstViewController.swift
//  hw9-private
//
//  Created by Kathleen Xue on 4/13/20.
//  Copyright © 2020 Kathleen Xue. All rights reserved.
//

import UIKit
import os.log
import SwiftyJSON
import CoreLocation
import MapKit
import Kingfisher
import SwiftSpinner
import Toast_Swift

class FirstViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, DetailedPageDelegate  {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var weatherApiImg: UIImageView!
    @IBOutlet weak var weatherApiCity: UILabel!
    @IBOutlet weak var weatherApiState: UILabel!
    @IBOutlet weak var weatherApiTemp: UILabel!
    @IBOutlet weak var weatherApiFeat: UILabel!
    @IBOutlet weak var homeNewsTable: UITableView!
    var locationManager: CLLocationManager!
    let geoCoder = CLGeocoder()
    var city = "Palo Alto"
    var state = "CA"
    var locationLat = 37.439
    var locationLon = -122.14
    var homeNewsData = [Any]()
    let homeNews = HomeNewsGetter()
    let searchController = SearchViewController()
    var searchData = [String]()
    var searchQuery = ""
    let bookmarkTrue = UIImage(systemName: "bookmark.fill")
    let bookmarkFalse = UIImage(systemName: "bookmark")
    var defaults = UserDefaults.standard
    var bookmarkArray = [String]()
    private let refreshControl = UIRefreshControl()
    override func viewDidLoad() {
        super.viewDidLoad()
        homeNewsTable.dataSource = self
        homeNewsTable.delegate = self
        //homeNewsTable.register(HomeNewsTableCell.self, forCellReuseIdentifier: "homeNewsCell")
        homeNewsTable.reloadData()
        if #available(iOS 10.0, *) {
            homeNewsTable.refreshControl = refreshControl
        } else {
            homeNewsTable.addSubview(refreshControl)
        }
        
        bookmarkArray = defaults.object(forKey: "bookmarkArray") as? [String] ?? [String]()
        //let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: Selector(("longPress:")))
        //self.view.addGestureRecognizer(longPressRecognizer)
        
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        weatherApiFeat.textColor = UIColor.white
        weatherApiTemp.textColor = UIColor.white
        weatherApiCity.textColor = UIColor.white
        weatherApiState.textColor = UIColor.white
        
        weatherApiImg.layer.cornerRadius = weatherApiImg.frame.height/8.0
        weatherApiImg.clipsToBounds = true
        SwiftSpinner.show("Loading Home Page...")
        homeNews.getHomeNews(completion: { (data) -> Void in
            //print(data)
            self.homeNewsData = data
            self.homeNewsTable.reloadData()
            SwiftSpinner.hide()
        })
        refreshControl.addTarget(self, action: #selector(refreshHomeNews(_:)), for: .valueChanged)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        homeNewsTable.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.defaults = UserDefaults.standard
        self.bookmarkArray = UserDefaults.standard.object(forKey: "bookmarkArray") as? [String] ?? [String]()
        homeNewsTable.reloadData()
    }
    
    func toggleBookmark(id: String) {
        if self.bookmarkArray.firstIndex(of: id) != nil {
            self.bookmarkArray = self.bookmarkArray.filter{$0 != id}
        } else {
            self.bookmarkArray.append(id)
        }
        defaults.set(self.bookmarkArray, forKey: "bookmarkArray")
        self.homeNewsTable.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchController.searchBar.delegate = self
        self.present(UINavigationController(rootViewController: searchController), animated: false, completion: nil)
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchController.autosuggest(query: searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchController.searchBar.text = ""
        self.dismiss(animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchQuery = searchBar.text ?? ""
        self.dismiss(animated: true)
        let searchVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SearchResultsPageController") as! SearchResultsPageController
        searchBar.text = ""
        searchVC.searchQuery = self.searchQuery
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    /*func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }*/
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch(segue.identifier ?? "") {
            case "ShowDetail":
                guard let detailNewsController = segue.destination as? DetailedPageViewController else {
                    fatalError("Unexpected destination: \(segue.destination)")
                }
                guard let detailNewsCell = sender as? HomeNewsTableCell else {
                    fatalError("Unexpected sender: \(String(describing: sender))")
                }
                guard let indexPath = homeNewsTable.indexPath(for: detailNewsCell) else {
                    fatalError("The selected cell is not being displayed by the table")
                }
                detailNewsController.delegate = self
                
                let idJSON = JSON(self.homeNewsData[indexPath.row])
                let selectedNews = idJSON["id"].stringValue
                if self.bookmarkArray.firstIndex(of: selectedNews) != nil {
                    detailNewsController.parentIsBookmarked = true
                } else {
                    detailNewsController.parentIsBookmarked = false
                }
                //print(selectedNews!)
                //print(selectedNews!)
                detailNewsController.thumbnailData = selectedNews
            
            /*case "SearchResultsPage":
                if let navVC = segue.destination as? UINavigationController{
                    if let searchResultsController = navVC.children[0] as? SearchResultsPageController{
                        searchResultsController.searchQuery = self.searchQuery
                    }
                }
            */
            default:
                os_log("showing NO detail.", log: OSLog.default, type: .debug)
                fatalError("Unexpected Segue Identifier; \(String(describing: segue.identifier))")
        }
    }
    
    /*func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {

        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {

            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = homeNewsTable.indexPathForRow(at: touchPoint) {
                
                
                // your code here, get the row for the indexPath or do whatever you want
            }
        }
    }*/
    
    @objc private func refreshHomeNews(_ sender: Any) {
        // Fetch Weather Data
        homeNews.getHomeNews(completion: { (data) -> Void in
            //print(data)
            self.homeNewsData = data
            self.homeNewsTable.reloadData()
            self.refreshControl.endRefreshing()
            //self.bookmarkArray = UserDefaults.standard. //self.activityIndicatorView.stopAnimating()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print(self.homeNewsData)
        return self.homeNewsData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeNewsCell", for: indexPath) as! HomeNewsTableCell
        //cell.textLabel?.text = "HI"
        let currentJson = JSON(self.homeNewsData[indexPath.item])
        let id = currentJson["id"].stringValue
        cell.id = id
        cell.url = currentJson["webUrl"].stringValue
        if self.bookmarkArray.firstIndex(of: cell.id) != nil {
            cell.bookmarkButton.setImage(self.bookmarkTrue, for: .normal)
            cell.isBookmarked = true
        } else {
            cell.bookmarkButton.setImage(self.bookmarkFalse, for: .normal)
            cell.isBookmarked = false
        }
        
        cell.bookmarkButtonAction = { [unowned self] in
            let bkArr = self.defaults.object(forKey: "bookmarkArray") as? [String] ?? [String]()
            if bkArr.firstIndex(of: cell.id) != nil {
                cell.isBookmarked = false
                cell.bookmarkButton.setImage(self.bookmarkFalse, for: .normal)
                self.bookmarkArray = self.bookmarkArray.filter {$0 != cell.id}
                self.view.makeToast("Article removed from Bookmarks")
            } else {
                cell.isBookmarked = true
                cell.bookmarkButton.setImage(self.bookmarkTrue, for: .normal)
                self.bookmarkArray.append(cell.id)
                self.view.makeToast("Article bookmarked. Check out the Bookmarks tab to view")
            }
            self.defaults.set(self.bookmarkArray, forKey: "bookmarkArray")
        }
        
        if let section = currentJson["sectionName"].string {
            cell.homeNewsTableSection?.text = section
        }
        else {
            cell.homeNewsTableSection?.text = "None"
        }
        if let title = currentJson["webTitle"].string {
            cell.homeNewsTableTitle?.text = title
        }
        else {
            cell.homeNewsTableTitle?.text = "None"
        }
        if let imgUrlString =  currentJson["fields"]["thumbnail"].string {
            let url = URL(string: imgUrlString)
            cell.homeNewsTableImg?.kf.setImage(with: url)
        }
        else {
            cell.homeNewsTableImg?.image = UIImage(named: "default-guardian")
        }
        if let publishedTime = currentJson["webPublicationDate"].string {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            let date = dateFormatter.date(from:publishedTime)!
            let now = Date()
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .abbreviated
            formatter.allowedUnits = [.month, .day, .hour, .minute, .second]
            formatter.maximumUnitCount = 1
            let string = String(formatter.string(from: date, to: now)!)
            cell.homeNewsTableTime?.text = "\(string) ago"
        }
        else {
            cell.homeNewsTableTime?.text = "NaNs ago"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   contextMenuConfigurationForRowAt indexPath: IndexPath,
      point: CGPoint) -> UIContextMenuConfiguration? {
        let cell = self.homeNewsTable.cellForRow(at: indexPath) as! HomeNewsTableCell
        
        let twitter = UIAction(title: "Share with Twitter",
                              image: UIImage(named: "twitter")) { _ in
                                UIApplication.shared.openURL(NSURL(string: "https://twitter.com/intent/tweet?text=Check%20out%20this%20article!&hashtags=CSCI571&url=\(cell.url)")! as URL)
      }
        if cell.isBookmarked {
            let bookmark = UIAction(title: "Bookmark",
              image: UIImage(systemName: "bookmark.fill")) { action in
                  self.bookmarkArray = self.bookmarkArray.filter{$0 != self.bookmarkArray[indexPath.row]}
                  cell.isBookmarked = false
                  self.defaults.set(self.bookmarkArray, forKey: "bookmarkArray")
                self.view.makeToast("Article removed from Bookmarks")
                  self.homeNewsTable.reloadData()
            }
            return UIContextMenuConfiguration(identifier: nil,
              previewProvider: nil) { _ in
              UIMenu(title: "Menu", children: [twitter, bookmark])
            }
        } else {
            let bookmark = UIAction(title: "Bookmark",
              image: UIImage(systemName: "bookmark")) { action in
                self.bookmarkArray.append(cell.id)
                  cell.isBookmarked = true
                  self.defaults.set(self.bookmarkArray, forKey: "bookmarkArray")
                self.view.makeToast("Article bookmarked. Check out the Bookmarks tab to view")
                  self.homeNewsTable.reloadData()
            }
            return UIContextMenuConfiguration(identifier: nil,
              previewProvider: nil) { _ in
              UIMenu(title: "Menu", children: [twitter, bookmark])
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        self.locationLat = locValue.latitude
        self.locationLon = locValue.longitude
        let weather = WeatherGetter()
        let location = CLLocation(latitude: locationLat, longitude: locationLon)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                placemarks, error -> Void in

                // Place details
                guard let placeMark = placemarks?.first else { return }
                self.state = placeMark.administrativeArea ?? "CA"
                self.state = weather.convertStateToLongState(state: self.state)
                print(self.state)
                self.weatherApiState.text = self.state
                // City
                self.city = placeMark.subAdministrativeArea ?? "Palo Alto"
                print(self.city)
                self.weatherApiCity.text = self.city
        })
        weather.getWeather(lat: self.locationLat, lon: self.locationLon) {
        isValid in
            print(isValid)
            // do something with the returned Bool
            DispatchQueue.main.async {
               // update UI
                self.weatherApiTemp.text = weather.temperature
                self.weatherApiFeat.text = weather.features
                if weather.features == "Clouds" {
                    self.weatherApiImg.image = UIImage(named: "cloudy_weather")
                }
                else if weather.features == "Clear" {
                    self.weatherApiImg.image = UIImage(named: "clear_weather")
                }
                else if weather.features == "Snow" {
                    self.weatherApiImg.image = UIImage(named: "snowy_weather")
                }
                else if weather.features == "Rain" {
                    self.weatherApiImg.image = UIImage(named: "rainy_weather")
                }
                else if weather.features == "Thunderstorm" {
                    self.weatherApiImg.image = UIImage(named: "thunder_weather")
                }
                else {
                    self.weatherApiImg.image = UIImage(named: "sunny_weather")
                }
            }
        }
    }
}

