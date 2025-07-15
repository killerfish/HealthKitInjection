//
//  HealthKitMockData.swift
//  HealthKitInjection
//
//  Created by Usman Raza on 7/15/25.
//

import HealthKit

class HealthKitMockData {
    let healthStore = HKHealthStore()

    func requestAuthorization() async throws {
        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .vo2Max)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: types, read: types) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authorization failed"]))
                }
            }
        }
    }

    func clearExistingSamples() async throws {
        let types: [HKSampleType] = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .vo2Max)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        for type in types {
            try await withCheckedThrowingContinuation { continuation in
                let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: [])
                let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    guard let samples = samples else {
                        continuation.resume()
                        return
                    }

                    self.healthStore.delete(samples) { success, error in
                        continuation.resume()
                    }
                }
                self.healthStore.execute(query)
            }
        }
    }

    func authorizeAndInjectData() async {
        do {
            try await requestAuthorization()
            print("✅ Authorized HealthKit")

            try await clearExistingSamples()
            print("🧹 Cleared samples")

            try await injectMockData()
            print("✅ Data injection complete")

        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }

    private func injectMockData() async throws {
        let calendar = Calendar.current
        let now = Date()

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            let startOfDay = calendar.startOfDay(for: date)

            try await saveQuantitySample(.stepCount, value: Double(5000 + i * 1000), unit: .count(), date: startOfDay)
            try await saveQuantitySample(.vo2Max, value: 40.0 + Double(i) * 0.5, unit: HKUnit(from: "mL/kg*min"), date: startOfDay)
            try await saveQuantitySample(.restingHeartRate, value: Double(55 - i), unit: .count().unitDivided(by: .minute()), date: startOfDay)
            try await saveQuantitySample(.heartRateVariabilitySDNN, value: Double(70 + i * 2), unit: .secondUnit(with: .milli), date: startOfDay)
            try await saveSleepSample(hours: 7.0 + Double(i % 3) * 0.5, date: startOfDay)
        }
    }

    private func saveQuantitySample(_ identifier: HKQuantityTypeIdentifier, value: Double, unit: HKUnit, date: Date) async throws {
        let type = HKQuantityType.quantityType(forIdentifier: identifier)!
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func saveSleepSample(hours: Double, date: Date) async throws {
        let type = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let end = Calendar.current.date(byAdding: .hour, value: Int(hours), to: date)!
        let sample = HKCategorySample(type: type, value: HKCategoryValueSleepAnalysis.asleep.rawValue, start: date, end: end)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.save(sample) { _, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
