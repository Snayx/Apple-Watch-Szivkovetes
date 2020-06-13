//
//  ViewController.swift
//  HeartRateStatistics
//
//  Created by David Renyak on 2020. 06. 08..
//  Copyright © 2020. David Renyak. All rights reserved.
//

import UIKit
import HealthKit

extension ViewController: HeartRateDelegate {

func heartRateUpdated(heartRateSamples: [HKSample]) {
        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else {
            return
        }
    
        DispatchQueue.main.async {
            self.heartRateSamples = heartRateSamples
            guard let sample = heartRateSamples.first else {
                return
            }
            let value = Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
            self.heartRateLabel.text = String(value)
        }
    }
}
class ViewController: UIViewController {
    let healthKitManager = HealthKitManager.sharedInstance
    var heartRateSamples: [HKQuantitySample] = [HKQuantitySample]()
    var heartRateQuery: HKQuery?
    
    @IBOutlet weak var heartRateLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        healthKitManager.authorizeHealthKit { (success, error) in
            print("Was healthkit successful? \(success)")
            self.retrieveHeartRateData()
        }
    }
    func retrieveHeartRateData() {
        
        if let query = healthKitManager.createHeartRateStreamingQuery(Date()) {
            self.heartRateQuery = query
            self.healthKitManager.heartRateDelegate = self
            self.healthKitManager.healthStore.execute(query)
        }
    }


}

