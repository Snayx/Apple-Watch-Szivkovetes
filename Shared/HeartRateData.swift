//
//  HeartRateData.swift
//  HeartRateStatistics
//
//  Created by David Renyak on 2020. 06. 08..
//  Copyright © 2020. David Renyak. All rights reserved.
//

import Foundation
class HeartRateData{
    var lastHeartRate: Double = 0.0
    
    func setLastHeartRate(newHeartRate: Double){
        self.lastHeartRate = newHeartRate
    }
    func getLastHeartRate() -> Int{
        return Int(self.lastHeartRate)
    }
}
