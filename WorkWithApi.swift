//
//  WorkWithApi.swift
//  SberCloud
//
//  Created by German Zvezdin on 25.02.2021.
//


import UniformTypeIdentifiers

class ApiTemplateClass: ObservableObject {
    
    
    // Эти структуры нужно будет поменять для конкретного запроса но их так же нужно будет передавать в качестве аргумента в функции запросов
    struct SPost: Encodable, Decodable {
        var text: String
    }
    struct ApiRes: Decodable{
        var answer: String
    }
    struct PostRes: Decodable {
        var id: Int
    }
    
    //completion - это замыкание функции т.е специальная ффункция которая выполнится только после того как завершится основная
    private func ApiPostData<T: Encodable>(send: T, _ completion:@escaping (_ id: Int)->Void) {
        
        
        
        guard let encoded = try? JSONEncoder().encode(send) else {
            print("Failed to encode order")
            return
        }
        
        let url = URL(string: "API URL")!
        var request = URLRequest(url: url)
        request.setValue(
            "application/json",
            forHTTPHeaderField: "Content-Type"
        )
        let body = encoded
        request.httpMethod = "POST"
        request.httpBody = body
        let session = URLSession.shared
        
        let task = session.dataTask(with: request) { (data, response, error) in
                            
            if let error = error {
                print("Error: \(error)")
            } else if let data = data {
                //в случае успеха сервер сообщает нам уникальный SID по которому мы находим результат
                //декодируем данные от сервера
                if let decodedOrder = try? JSONDecoder().decode(PostRes.self, from: data) {
                    //т.к запросы выполняются в отдельном потоке вызываем внешний декоратор который замыкает функцию(т.е вызывается в случае ее завершения)
                    //внутрь замыкания передается SID для дальнейшего использования
                    completion(decodedOrder.id)
                
                } else {}
            } else {
                print("ERROR2")
            }
        }
        task.resume()
        
        
    }
    
    
    //конкретный гет запрос к может строчка к URL`y API будет как у нас число и будет тип инт но возможно и строчка с URL и будет String
    private func ApiGetData<T1, T2>(GetId: T1,  _ completion:@escaping (_ isSuccess:T2, _ status: Bool)->Void) {
            
            //Вытаскиваем нужный url
            let url = URL(string: "API/\(GetId)")!
            
            var request = URLRequest(url: url)
            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
            
            request.httpMethod = "GET"
            
            
            
            let session = URLSession.shared
            
           
            let task = session.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    completion("" as! T2, false)
                } else if let data = data {
                    if let decodedOrder = try? JSONDecoder().decode(ApiRes.self, from: data) {
                        print(decodedOrder.answer)
                        if decodedOrder.answer == "In work" || decodedOrder.answer == "" {
                            completion("" as! T2, false)
                        } else {
                            completion(decodedOrder.answer as! T2, true)
                        }
                        
                    } else {
                        completion("" as! T2, false)
                    }
                } else {
                    print("ERROR2")
                    completion("" as! T2, false)
                }
            }
            
            task.resume()
            
        }
    
    
    public func Send<T: Encodable>(send: T){
            //Вызов API
        self.ApiPostData(send: send) {
                (res) in
                    DispatchQueue.main.async {
                        //Обработка того что вернет POST запрос
                    }
        }
    }
    
    private func WaitResFromApi<T1, T2>(GetId: T1, _ completion:@escaping (_ isSuccess:T2)->Void){
            let interval = 0.75
            var count = 0
            DispatchQueue.main.async {
                Timer.scheduledTimer(withTimeInterval: interval,repeats: true) { t in
                    self.ApiGetData(GetId: GetId) {
                        (res: T2, flag) in
                        if flag {
                            DispatchQueue.main.async {
                                completion(res)
                            }
                            t.invalidate()
                        }
                    }
                    count+=1
                    if count >= 100 {
                        t.invalidate()
                        DispatchQueue.main.async {
                            completion("Server timeout" as! T2)
                        }
                    }
                    
                }
            }
        }
    //Correct type прослойка потому что шаблон типа Т2 почему-то нельзя использовать без его объявления
    public func GetRes<T1, T2>(GetId: T1, CorrectType: T2.Type) {
        self.WaitResFromApi(GetId: GetId){ (res: T2) in
                DispatchQueue.main.async {
                    //Обработка того что вернет GET запрос
                    
            }
        }
    }
}
