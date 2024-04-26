//
//  ContentView.swift
//  Fetch
//
//  Created by Jian Ma on 4/25/24.
//

import SwiftUI

enum AsyncState<T> {
    case loading
    case loaded(T)
    case failedToLoad(Error)
}

struct MealsListView: View {
    struct Meal: Identifiable {
        let id: String
        let title: String
        let thumbnail: String
        
        init(id: String, title: String, thumbnail: String) {
            self.id = id
            self.title = title
            self.thumbnail = thumbnail
        }
        
        init(from: Fetch.Meal) {
            self.id = from.idMeal
            self.thumbnail = from.strMealThumb
            self.title = from.strMeal
        }
    }
    
    struct MealDetail {
        
        let id: String
        let title: String
        let category: String
        let area: String
        let instructions: String

        init(id: String, title: String, category: String, area: String, instructions: String) {
            self.id = id
            self.title = title
            self.category = category
            self.area = area
            self.instructions = instructions
        }
        
        init(from: Fetch.MealDetail) {
            self.area = from.strArea
            self.id = from.idMeal
            self.instructions = from.strInstructions
            self.category = from.strCategory
            self.title = from.strMeal
        }
    }
    
    @MainActor
    final class ViewModel: ObservableObject {
        typealias ListState = AsyncState<[Meal]>
        typealias MealState = AsyncState<MealsListView.MealDetail>
        let client: MealClient
        
        @Published private var mealDetails: [String: MealState] = [:]
        @Published var listState: ListState = .loading
        @Published var destination: String? = nil

        init(
            client: MealClient
        ) {
            self.client = client
        }
        
        var detailState: MealState? {
            destination.flatMap { mealDetails[$0] }
        }

        func onTask() async {
            do {
                self.listState = .loading
                self.listState = .loaded(try await client
                    .fetchMeals()
                    .map(Meal.init(from:))
                    .sorted(by: {
                        $0.title < $1.title
                    })
                )
                
            } catch {
                self.listState = .failedToLoad(error)
            }
        }
        
        func onMealTapped(_ mealID: String) {
            destination = mealID

            Task {
                do {
                    self.mealDetails[mealID] = .loading

                    let remoteDetail = try await client.fetchMealDetail(mealID)

                    self.mealDetails[mealID] = .loaded(MealDetail(
                        from: remoteDetail
                    ))
                } catch {
                    self.mealDetails[mealID] = .failedToLoad(error)

                }
            }
        }
    }

    @ObservedObject var viewModel: ViewModel
    
    
    var body: some View {
        VStack {
            
            switch viewModel.listState {
            case .loading:
                genericLoadingView
            case .loaded(let meals):
                List(meals) { meal in
                    HStack {
                        AsyncImage(
                            url: URL(string: meal.thumbnail),
                            content: { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                            },
                            placeholder: {
                                ProgressView()
                            }
                        )
                        .frame(width: 100, height: 100)
                        
                        
                        Text(meal.title)
                    }
                    .onTapGesture {
                        viewModel.onMealTapped(meal.id)
                    }
                }
            case .failedToLoad(let error):
                
                Button(action: {
//                    viewModel.onRetyButtonTapped()
                }, label: {
                    Text("something went wrong.. \(error.localizedDescription)")
                })
            }
        }
        .task {
            await viewModel.onTask()
        }
        .sheet(
            isPresented: Binding(
                get: {
                    viewModel.destination != nil
                },
                set: { isPresented in
                    if !isPresented {
                        viewModel.destination = nil
                    }
                }
            ),
            content: {
                if let state = viewModel.detailState {
                    
                    NavigationStack {
                        
                        switch state {
                        case .failedToLoad(let error):
                            Button(action: {
            //                    viewModel.onRetyButtonTapped()
                                
                            }, label: {
                                Text("something went wrong.. \(error.localizedDescription)")
                            })
                        case .loaded(let model):
                            ScrollView {
                                Text(model.title)
                                    .font(.title)
                                
                                Text("something simple.. \(viewModel.destination ?? "")")
                                
                                Text(model.area)
                                
                                Text(model.instructions)
                                    .font(.body)
                                
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 32)
                        case .loading:
                            genericLoadingView
                        }
                        
                    }
                    .presentationDetents([.medium, .large])
                } else {
                    ProgressView("Loading....")
                }
            })
        .padding()
    }
    
    private var genericLoadingView: some View {
        HStack {
            Text("Chopping the onions...")
                .padding(.trailing, 16)
            ProgressView()
        }

    }
}

#Preview {
    MealsListView(
        viewModel: MealsListView.ViewModel(client: .live)
//        viewModel: MealsListView.ViewModel(client: .mock)
    )
}
