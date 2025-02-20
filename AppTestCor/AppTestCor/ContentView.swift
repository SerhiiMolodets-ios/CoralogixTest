//
//  ContentView.swift
//  AppTestCor
//
//  Created by Serhii Molodets on 20.02.2025.
//

import SwiftUI
import SDKTestCor

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            CallCoralogix.call()
        }
    }
}
