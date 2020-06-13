//
//  InterfaceController.swift
//  HeartRateStatistics WatchKit Extension
//
//  Created by David Renyak on 2020. 06. 08..
//  Copyright © 2020. David Renyak. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit

class InterfaceController: WKInterfaceController {

    @IBOutlet weak var workoutButton: WKInterfaceButton!
    let healthKitManager = HealthKitManager.sharedInstance
        
        var isWorkoutInProgress = false
        
        var workoutSession: HKWorkoutSession?
        
        var workoutStartDate: Date?
        
        var heartRateQuery: HKQuery?
        
        var heartRateSamples: [HKQuantitySample] = [HKQuantitySample]()
        
        override func awake(withContext context: Any?) {
            super.awake(withContext: context)
            
            self.workoutButton.setEnabled(false)
            
            // Configure interface objects here.
            healthKitManager.authorizeHealthKit { (success, error) in
                print("Was healthkit successful? \(success)")
                
                self.workoutButton.setEnabled(true)
                
                self.createWorkoutSession()
            }
        }
        
        override func willActivate() {
            // This method is called when watch view controller is about to be visible to user
            super.willActivate()
        }
        
        override func didDeactivate() {
            // This method is called when watch view controller is no longer visible
            super.didDeactivate()
        }

        @IBAction func startOrStopWorkout() {
            
            if isWorkoutInProgress {
                print("End workout")
                endWorkoutSession()
            } else {
                print("Start workout")
                startWorkoutSession()
            }
            isWorkoutInProgress = !isWorkoutInProgress
            self.workoutButton.setTitle(isWorkoutInProgress ? "End Workout" : "Start Workout")
        }
        var builder: HKWorkoutBuilder?
        func createWorkoutSession() {
            
            let workoutConfiguration = HKWorkoutConfiguration()
            workoutConfiguration.activityType = .other
            workoutConfiguration.locationType = .unknown
            
            do{
                workoutSession = try HKWorkoutSession(healthStore: healthKitManager.healthStore, configuration: workoutConfiguration)
                builder = workoutSession!.associatedWorkoutBuilder()
                workoutSession?.delegate = self
            } catch {
                dismiss()
                print("Error")
                return
            }
            /*do {
                workoutSession = try HKWorkoutSession(configuration: workoutConfiguration)
                workoutSession?.delegate = self
            } catch {
                print("Exception thrown")
            }*/
        }
        
        func startWorkoutSession() {

            if self.workoutSession == nil {
                createWorkoutSession()
            }
            guard let session = workoutSession else {
                print("Cannot start a workout without a workout session")
                return
            }
            self.workoutStartDate = Date()
            session.startActivity(with: workoutStartDate)
        }
        
        func endWorkoutSession() {
            guard let session = workoutSession else {
                print("Cannot start a workout without a workout session")
                return
            }
            session.stopActivity(with: Date())
            saveWorkout()
        }
        
        func saveWorkout() {
            
            guard let startDate = workoutStartDate else {
                return
            }
            let workout = HKWorkout(activityType: .other, start: startDate, end: Date())
            healthKitManager.healthStore.save(workout) { [weak self] (success, error) in
                print("Was save workout successful? \(success)")
                
                guard let samples = self?.heartRateSamples else {
                    return
                }
                
                self?.healthKitManager.healthStore.add(samples, to: workout, completion: { (success, error) in
                    if success {
                        print("Successfully saved heart rate samples.")
                    }
                })
            }
        }
    }
    extension InterfaceController: HKWorkoutSessionDelegate {
        
        func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
            print("Workout failed with error: \(error)")
        }
        
        func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
            
            switch toState {
            case .running:
                print("workout started")
                
                guard let workoutStartDate = workoutStartDate else {
                    return
                }
                if let query = healthKitManager.createHeartRateStreamingQuery(workoutStartDate) {
                    self.heartRateQuery = query
                    self.healthKitManager.heartRateDelegate = self
                    healthKitManager.healthStore.execute(query)
                }
            case .ended:
                print("workout ended")
                if let query = self.heartRateQuery {
                    healthKitManager.healthStore.stop(query)
                }
            default:
                print("Other workout state")
            }
        }
    }
    extension InterfaceController: HeartRateDelegate {
        
        func heartRateUpdated(heartRateSamples: [HKSample]) {
            
            guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else {
                return
            }
            
            DispatchQueue.main.async {
                self.heartRateSamples = heartRateSamples
                guard let sample = heartRateSamples.first else {
                    return
                }
                let _ = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                //_ = String(format: "%.00f", value)
                //self.heartRateLabel.setText(heartRateString)
            }
        }
    }
