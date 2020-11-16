//
//  SearchBusinessCell.swift
//  VORTOApp
//
//  Created by Muhammad Luqman on 11/15/20.
//

import UIKit
import Cosmos
import CDYelpFusionKit
import SDWebImage

class SearchBusinessCell: UITableViewCell {

    // MARK: - Outlets
    @IBOutlet weak var imageIcon: UIImageView!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var ratingView: CosmosView!

    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var priceLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var reviewCountLbl: UILabel!
    @IBOutlet weak var categoryLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    // MARK: - set UI
    func  setDataOnCell(business: CDYelpBusiness) {
        
        if let url = business.imageUrl{
            
            self.imageIcon.sd_setImage(with:url, placeholderImage: UIImage(named: "placeholder"))
        }
        
        if let name = business.name{
            self.nameLbl.text = name
        }
        if let price = business.price{
            self.priceLbl.text = price
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
        
    }

}
