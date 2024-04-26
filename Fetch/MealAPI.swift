//
//  MealAPI.swift
//  Fetch
//
//  Created by Jian Ma on 4/25/24.
//

import Foundation
/*
 https://themealdb.com/api/json/v1/1/filter.php?c=Dessert
 https://themealdb.com/api/json/v1/1/lookup.php?i=MEAL_ID
 */

struct MealClient {
    //  https://themealdb.com/api/json/v1/1/filter.php?c=Dessert
    let fetchMeals: () async throws -> [Meal]
    
    //  https://themealdb.com/api/json/v1/1/lookup.php?i=MEAL_ID
    let fetchMealDetail: (String) async throws -> MealDetail
    
    static let mock = MealClient(
        fetchMeals: {
            let bundle = Bundle.main
            guard let url = bundle.url(forResource: "MealRootSample", withExtension: "json") else {
                throw URLError(.fileDoesNotExist)
            }
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let mealRoot = try decoder.decode(MealRoot.self, from: data)
            return mealRoot.meals
        },
        fetchMealDetail: { _ in
            throw URLError(.badURL)
        }
    )
    
    static let slowLive: MealClient = {
        let base = live
        
        
        return MealClient(
            fetchMeals: {
                
                try await Task.sleep(for: .seconds(3))
                return try await live.fetchMeals()
                
            },
            fetchMealDetail: { mealID in
                try await Task.sleep(for: .seconds(3))
                
                return try await live.fetchMealDetail(mealID)
            }
        )
    }()
    
    
    static let live: MealClient = {
        let session = URLSession.shared
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "themealdb.com"
        
        let decoder = JSONDecoder()
        
        return MealClient(
            fetchMeals: { [copy = components] in
                var mutable = copy
                mutable.path = "/api/json/v1/1/filter.php"
                
                mutable.queryItems = [
                    URLQueryItem(name: "c", value: "Dessert")
                ]
                
                guard let url = mutable.url else {
                    throw URLError(.badURL)
                }
                
                let (data, _) = try await session.data(from: url)
                
                return try decoder.decode(MealRoot.self, from: data).meals
            },
            fetchMealDetail: { [copy = components] mealID in
                
                var mutable = copy
                mutable.path = "/api/json/v1/1/lookup.php"
                
                mutable.queryItems = [
                    URLQueryItem(name: "i", value: mealID)
                ]
                
                guard let url = mutable.url else {
                    throw URLError(.badURL)
                }
                
                let (data, _) = try await session.data(from: url)
                
                guard let detail = try decoder.decode(MealDetailRoot.self, from: data).meals.first else {
                    throw URLError(.badServerResponse)
                }
                return detail
            }
        )
    }()
}

struct MealRoot: Codable {
    let meals: [Meal]
}

struct Meal: Codable {
    let strMeal: String
    let strMealThumb: String
    let idMeal: String
}


struct MealDetailRoot: Codable {
    let meals: [MealDetail]
}

struct MealDetail: Codable {
    let idMeal: String
    let strMeal: String
    let strCategory: String
    let strArea: String
    let strInstructions: String
    let strMealThumb: String
    let strYoutube: String
    let strIngredient1, strIngredient2, strIngredient3, strIngredient4: String
    let strIngredient5, strIngredient6, strIngredient7, strIngredient8: String
    let strIngredient9, strMeasure1, strMeasure2, strMeasure3: String
    let strMeasure4, strMeasure5, strMeasure6, strMeasure7: String
    let strMeasure8, strMeasure9: String
}
