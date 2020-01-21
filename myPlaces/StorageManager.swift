//
//  StorageManager.swift
//  myPlaces
//
//  Created by Саня Eloy on 17.01.2020.
//  Copyright © 2020 Саня Eloy. All rights reserved.
//

import RealmSwift

let realm = try! Realm()

class StorageManager {
    static func saveObject(_ place: Place){
        try! realm.write {
            realm.add(place)
        }
    }
    static func deleteObject(_ place: Place){
        try! realm.write {
            realm.delete(place)
        }
    }
}
