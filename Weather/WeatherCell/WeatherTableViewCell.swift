//
//  WeatherTableViewCell.swift
//  Weather
//

import UIKit

class WeatherTableViewCell: UITableViewCell {
    
    @IBOutlet var dayLabel: UILabel!
    @IBOutlet var tempLabel: UILabel!
    @IBOutlet var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .systemBlue
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    static let identifier = "WeatherTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "WeatherTableViewCell", bundle: nil)
    }
    
    func configure(with model: Interval) {
        self.tempLabel.text = "\(Int(model.values.temperature * 9/5 + 32))°"
        
        let time = model.startTime
        
        var start = time.index(time.startIndex, offsetBy: 5)
        var end = time.index(time.endIndex, offsetBy: -13)
        var range = start..<end
        let month = String(time[range])
        
        start = time.index(time.startIndex, offsetBy: 8)
        end = time.index(time.endIndex, offsetBy: -10)
        range = start..<end
        let day = String(time[range])
        
        let displayTime = "\(month)/\(day)"
        
        let iconType: String
        
        let weatherCode = model.values.weatherCode
        switch weatherCode {
        case 1000:
            iconType = "clear"
        case 1100, 1101, 1102, 1001, 2100, 2000:
            iconType = "cloud"
        default:
            iconType = "rain"
        }
        
        self.dayLabel.text = displayTime
        self.iconImageView.image = UIImage(named: iconType)
        self.iconImageView.contentMode = .scaleAspectFit
        
    }
    
    func getDayForDate(_ date: Date?) -> String {
        guard let inputDate = date else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: inputDate)
    }
}
