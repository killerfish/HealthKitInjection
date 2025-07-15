//
//  ContentView.swift
//  HealthKitInjection
//
//  Created by Usman Raza on 7/15/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isInjecting = false
    @State private var injectionComplete = false

    var body: some View {
        VStack(spacing: 20) {
            Text("HealthKit Mock Data Injection")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the button below to inject 7 days of test health data into Apple Health.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            Button(action: {
                Task {
                    isInjecting = true
                    injectionComplete = false
                    await HealthKitMockData().authorizeAndInjectData()
                    await MainActor.run {
                        isInjecting = false
                        injectionComplete = true
                    }
                }
            }) {
                HStack {
                    if isInjecting {
                        ProgressView()
                    } else {
                        Image(systemName: "waveform.path.ecg")
                    }
                    Text(isInjecting ? "Injecting..." : "Inject Mock Health Data")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .font(.headline)
            }

            if injectionComplete {
                Text("✅ Data injection complete.")
                    .foregroundColor(.green)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding(.top, 40)
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
