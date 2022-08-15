//
//  ViewController.swift
//  Weather
//

import UIKit
import MapKit
import CoreLocation

extension CLLocation {
    func fetchCityAndCountry(completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        CLGeocoder().reverseGeocodeLocation(self) { completion($0?.first?.locality, $0?.first?.country, $1) }
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {

    @IBOutlet var table: UITableView!
    var models = [Interval]()
    
    let locationManager = CLLocationManager()
    
    var currentLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table.register(WeatherTableViewCell.nib(), forCellReuseIdentifier: WeatherTableViewCell.identifier)
        
        table.delegate = self
        table.dataSource = self
        
        table.backgroundColor = .systemBlue
        view.backgroundColor = .systemBlue
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupLocation()
    }
    
    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty, currentLocation == nil {
            currentLocation = locations.first
            locationManager.stopUpdatingLocation()
            requestWeatherForLocation()
        }
    }
    
    func requestWeatherForLocation() {
        guard let currentLocation = currentLocation else {
            return
        }
        
        let long = currentLocation.coordinate.longitude
        let lat = currentLocation.coordinate.latitude
        
        let url = "https://api.tomorrow.io/v4/timelines?location=\(lat),\(long)&fields=temperature,weatherCode&timesteps=1d&units=metric&apikey="
        
        URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { data, response, error in
            
            guard let data = data, error == nil else {
                print("Something went wrong.")
                return
            }
            
            var json: WeatherResponse?
            do {
                json = try JSONDecoder().decode(WeatherResponse.self, from: data)
            }
            catch {
                print("Error: \(error)")
            }
            
            guard let result = json else {
                return
            }
            
            let entries = result.data.timelines[0].intervals
            
            self.models.append(contentsOf: entries)
            
            DispatchQueue.main.async {
                self.table.reloadData()
                
                self.table.tableHeaderView = self.createTableHeader(result, long, lat)
            }
            
        }).resume()
    }
    
    func createTableHeader(_ result: WeatherResponse, _ long: CLLocationDegrees, _ lat: CLLocationDegrees) -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.width))
        
        headerView.backgroundColor = .systemBlue

        let locationLabel = UILabel(frame: CGRect(x: 10, y: 10, width: view.frame.size.width-20, height: headerView.frame.size.height/5))
        let summaryLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height, width: view.frame.size.width-20, height: headerView.frame.size.height/5))
        let tempLabel = UILabel(frame: CGRect(x: 10, y: 20+locationLabel.frame.size.height+summaryLabel.frame.size.height, width: view.frame.size.width-20, height: headerView.frame.size.height/2))
        
        headerView.addSubview(locationLabel)
        headerView.addSubview(summaryLabel)
        headerView.addSubview(tempLabel)
        
        locationLabel.textAlignment = .center
        summaryLabel.textAlignment = .center
        tempLabel.textAlignment = .center
        
        let weatherCode = result.data.timelines[0].intervals[0].values.weatherCode
        switch weatherCode {
        case 1000:
            summaryLabel.text = "Clear"
        case 1100, 1101, 1102, 1001, 2100, 2000:
            summaryLabel.text = "Cloudy"
        default:
            summaryLabel.text = "Rainy"
        }
        
        summaryLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        summaryLabel.textColor = .white
        
        let location = CLLocation(latitude: lat, longitude: long)
        location.fetchCityAndCountry { city, country, error in
            guard let city = city, error == nil else { return }
            
            locationLabel.text = "\(city)"
        }
        
        locationLabel.font = UIFont(name: "Helvetica-Bold", size: 32)
        locationLabel.textColor = .white
        
        tempLabel.text = "\(Int(result.data.timelines[0].intervals[0].values.temperature * 9/5 + 32))°F"
        tempLabel.font = UIFont(name: "Helvetica-Bold", size: 128)
        tempLabel.textColor = .white
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WeatherTableViewCell.identifier, for: indexPath) as! WeatherTableViewCell
        cell.configure(with: models[indexPath.row])
        cell.backgroundColor = .systemBlue
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

struct WeatherResponse: Codable {
    let data: Data
}

struct Data: Codable {
    let timelines: [WeatherData]
}

struct WeatherData: Codable {
    let timestep: String
    let endTime: String
    let startTime: String
    let intervals: [Interval]
}

struct Interval: Codable {
    let startTime: String
    let values: Values
}

struct Values: Codable {
    let temperature: Double
    let weatherCode: Int
}
