//
//  PlaceModel.swift
//  myPlaces
//
//  Created by Саня Eloy on 11.01.2020.
//  Copyright © 2020 Саня Eloy. All rights reserved.
//

import RealmSwift

class Place: Object {
    @objc dynamic var name = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var date = Date()
    
    convenience init (name:String, location: String?, type:String?, imageData: Data?){
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
    }
    // var restaurantImage: String?
    
//     let restaurantName = [
//        "Nonna", "Santorini Cafe", "Pasta & Pizza"]
//
//     func savePlaces(){
//
//        for place in restaurantName{
//            let image = UIImage(named: place)
//            guard let imageData = image?.pngData() else { return}
//            let newPlace = Place()
//            newPlace.name = place
//            newPlace.location = "Odessa"
//            newPlace.type = "Restaurant"
//            newPlace.imageData = imageData
//
//            StorageManager.saveObject(newPlace)
//        }
//       
//    }
    
}
