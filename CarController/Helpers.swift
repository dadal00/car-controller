//
//  Helpers.swift
//  CarController
//
//  Created by Dylan Adal on 4/22/26.
//

func randomString(length: Int = Wifi.Bonjour.idLength) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyz"
    return String((0..<length).map { _ in letters.randomElement()! })
}
