//
//  TwitterClient.swift
//  Chirpi
//
//  Created by Steven Hurtado on 2/19/17.
//  Copyright © 2017 Steven Hurtado. All rights reserved.
//

import UIKit
import BDBOAuth1Manager

class TwitterClient: BDBOAuth1SessionManager
{
    static let sharedInstance = TwitterClient(baseURL: URL(string: KeysAndTokens.baseURL)!, consumerKey: KeysAndTokens.consumerKey, consumerSecret: KeysAndTokens.consumerSecret)
    
    static var count = 20
    
    var loginSuccess: (()->())?
    var loginFailure: ((Error)->())?
    
    func login(success: @escaping ()->(), failure: @escaping (Error)->())
    {
        
        loginSuccess = success
        loginFailure = failure
        
        TwitterClient.sharedInstance?.deauthorize()
        TwitterClient.sharedInstance?.fetchRequestToken(withPath: KeysAndTokens.requestToken, method: "GET", callbackURL: URL(string: KeysAndTokens.callbackURL), scope: nil, success: { (requestToken: BDBOAuth1Credential?) -> Void in
            print("Request Token Success")
            
            let url = URL(string: KeysAndTokens.baseURL + KeysAndTokens.authorizeURL + (requestToken?.token)!)!
            
            
            
            UIApplication.shared.open(url, options: [:], completionHandler: { (false) in
                print("I'm in.")
            })
            
        }, failure: { (error: Error?) -> Void in
            print("Error: \(error?.localizedDescription)")
            
            self.loginFailure?(error!)
        })
    }
    
    func handleOpenURL(url: URL)
    {
        let requestToken = BDBOAuth1Credential(queryString: url.query!)
        fetchAccessToken(withPath: KeysAndTokens.accessToken, method: "POST", requestToken: requestToken, success: { (accessToken: BDBOAuth1Credential?) in
            
            print("Access Token Success")
            
            self.currentAccount(success: { (user: User) in
                User.currentUser = user
                self.loginSuccess?()
            }, failure: { (error: Error) in
                
                
                self.loginFailure?(error)
            })
//            client?.currentAccount()
//            client?.homeTimeline(success: { (tweets: [Tweet]) in
//                for tweet in tweets
//                {
//                    print(tweet.text)
//                }
//                
//            }, failure: { (error: Error) in
//                print("Error: \(error.localizedDescription)")
//            })
//
        }, failure: { (error: Error?) in
            
            print("Error: \(error!)")
            self.loginFailure?(error!)
            
        })
    }
    
    func logOut()
    {
        User.currentUser = nil
        deauthorize()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: User.userDidLogOutNotification), object: nil)
    }
    
    func favWithId(id: String)
    {
        let urlString = KeysAndTokens.baseURL + KeysAndTokens.favorite_URL + "\(id)"
        
        post(urlString, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            print("Favorited")
        }) { (task: URLSessionDataTask?, error: Error) in
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func unfavWithId(id: String)
    {
        let urlString = KeysAndTokens.baseURL + KeysAndTokens.unfavorite_URL + "\(id)"
        
        post(urlString, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            print("Unfavorited")
        }) { (task: URLSessionDataTask?, error: Error) in
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func retweetWithId(id: String)
    {
        let urlString = KeysAndTokens.baseURL + KeysAndTokens.retweet_URL + "\(id).json"
        
        post(urlString, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            print("Retweeted")
        }) { (task: URLSessionDataTask?, error: Error) in
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func unretweetWithId(id: String)
    {
        let urlString = KeysAndTokens.baseURL + KeysAndTokens.unretweet_URL + "\(id).json"
        
        post(urlString, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            print("Unretweeted")
        }) { (task: URLSessionDataTask?, error: Error) in
            print("Error: \(error.localizedDescription)")
        }
    }
    
    func userTimeline(name: String, success: @escaping ([Tweet]) -> (), failure: (Error) -> ())
    {
        let param: [String : AnyObject] = ["Name": name as AnyObject]
        
        get(KeysAndTokens.user_timeline, parameters: param, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            
            let dictionary = response as! [NSDictionary]
            
            let tweets = Tweet.tweetsFromArray(dictionaries: dictionary)
            
            //            print(tweets[0].text!)
            success(tweets)
            
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            print("error: \(error)")
        })
        
    }
    
    func userInfo(name: String, success: @escaping (String) -> (), failure: (Error) -> ())
    {
        let param: [String : AnyObject] = ["Name": name as AnyObject]
        
        get(KeysAndTokens.user_info, parameters: param, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            
            let dictionary = response as! NSDictionary
            
            let sizes = dictionary["sizes"] as? NSDictionary
            
            let mobile_retina = sizes?["mobile_retina"] as? NSDictionary
            
            let url = mobile_retina?["url"] as? String
            
            //            print(tweets[0].text!)
            success(url!)
            
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            print("error: \(error)")
        })
        
    }

    func postTweet(message: String)
    {
        let urlString = KeysAndTokens.baseURL + KeysAndTokens.update_tweet + "\(message)"
        
        post(urlString, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            
            print("Successful Chirp!")
            
        }) { (task: URLSessionDataTask?, error: Error) in
            
            print("error: \(error)")
        }
    }
    
    func homeTimeline(success: @escaping ([Tweet]) -> (), failure: (Error) -> ())
    {
        get(KeysAndTokens.home_timeline, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            
            //                print("Tweets Accessed: \(response)")
            
            let dictionary = response as! [NSDictionary]
            
            let tweets = Tweet.tweetsFromArray(dictionaries: dictionary)
            
//            print(tweets[0].text!)
            success(tweets)
            
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            print("error: \(error)")
        })

    }
    
    func homeTimelineWithIncrease(success: @escaping ([Tweet]) -> (), failure: (Error) -> ())
    {
        TwitterClient.count += 60
        
        if(TwitterClient.count >= 200)
        {
            TwitterClient.count = 200
        }
        
        TwitterClient.count = 20
        
        let parameters: [String : AnyObject] = ["count": TwitterClient.count as AnyObject]
        
        get(KeysAndTokens.home_timeline, parameters: parameters, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            
            //                print("Tweets Accessed: \(response)")
            
            let dictionary = response as! [NSDictionary]
            
            let tweets = Tweet.tweetsFromArray(dictionaries: dictionary)
            
            //            print(tweets[0].text!)
            success(tweets)
            
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            print("error: \(error)")
        })
        
    }
    
    func currentAccount(success: @escaping (User) -> (), failure: @escaping (Error)->())
    {
        get(KeysAndTokens.verify_credentials, parameters: nil, progress: nil, success: { (task: URLSessionDataTask, response: Any?) in
            let userDictionary = response as! NSDictionary
            
            let user = User(dictionary: userDictionary)
            
            success(user)
            
        }, failure: { (task: URLSessionDataTask?, error: Error) in
            failure(error)
        })

    }
}
