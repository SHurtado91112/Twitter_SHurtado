//
//  TweetsViewController.swift
//  Chirpi
//
//  Created by Steven Hurtado on 2/19/17.
//  Copyright © 2017 Steven Hurtado. All rights reserved.
//

import UIKit
import MBProgressHUD

class TweetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{

    var tweets : [Tweet] = []
    
    var isMoreDataLoading = false
    var loadingMoreView:InfiniteScrollActivityView?

    let client = TwitterClient.sharedInstance
    
    var tweetInstanceName: String?
    var tweetInstanceHandle: String?
    var tweetInstanceTagLine: String?
    var tweetInstanceAvatar: String?
    var tweetInstanceFollowing: String?
    var tweetInstanceFollower: String?
    var tweetInstanceFavorite: String?
    var tweetInstanceColor: String?
    var tweetInstanceBanner: String?
    
    @IBOutlet weak var logNavBarBtn: UIBarButtonItem!
    

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpInfiniteIndicator()
        
        self.logNavBarBtn.tintColor = UIColor.myOffWhite
        
        self.logNavBarBtn.setTitleTextAttributes([NSFontAttributeName: UIFont(name: "Avenir Next", size: 16)!], for: .normal)
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120
        
        print(User.currentUser?.name! as String!)
        
        
        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = UIColor.myOnyxGray
        
        MBProgressHUD.appearance().tintColor = UIColor.myRoseMadder
        MBProgressHUD.appearance().backgroundColor = UIColor.myRoseMadder
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        client?.homeTimeline(success: { (tweets: [Tweet]) in
            self.tweets = tweets
            
            self.tableView.reloadData()
            
            MBProgressHUD.hide(for: self.view, animated: true)
            
        }, failure: { (error: Error) in
            print("Error: \(error.localizedDescription)")
            MBProgressHUD.hide(for: self.view, animated: true)
        })
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        self.tableView.insertSubview(refreshControl, at: 0)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        navigationController?.navigationBar.barTintColor = UIColor.myRoseMadder
        
        tabBarController?.tabBar.tintColor = UIColor.myRoseMadder
    
        
        if(KeysAndTokens.composeSent)
        {
            MBProgressHUD.appearance().tintColor = UIColor.myRoseMadder
            MBProgressHUD.appearance().backgroundColor = UIColor.myRoseMadder
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            client?.homeTimeline(success: { (tweets: [Tweet]) in
                self.tweets = tweets
                MBProgressHUD.hide(for: self.view, animated: true)
                self.tableView.reloadData()
                
            }, failure: { (error: Error) in
                print("Error: \(error.localizedDescription)")
                MBProgressHUD.hide(for: self.view, animated: true)
            })
            
            MBProgressHUD.hide(for: self.view, animated: true)

            KeysAndTokens.composeSent = false
        }
    }
    
    func setUpInfiniteIndicator()
    {
        // Set up Infinite Scroll loading indicator
        let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
        loadingMoreView = InfiniteScrollActivityView(frame: frame)
        loadingMoreView!.isHidden = true
        self.tableView.addSubview(loadingMoreView!)
        
        var insets = tableView.contentInset
        insets.bottom += InfiniteScrollActivityView.defaultHeight
        tableView.contentInset = insets
    }
    
    func refreshControlAction(_ refreshControl: UIRefreshControl)
    {
        
        client?.homeTimeline(success: { (tweets: [Tweet]) in
            self.tweets = tweets
            
            self.tableView.reloadData()
            refreshControl.endRefreshing()
            
        }, failure: { (error: Error) in
            print("Error: \(error.localizedDescription)")
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return tweets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        
        let tweet = self.tweets[indexPath.row]
        
        if(tweet.mediaURL != nil)
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tweetImageCell", for: indexPath) as! TweetCell
            cell.hasImage = true
            cell.tweet = tweet
            cell.recognizer.indexPath = indexPath
            cell.recognizer.addTarget(self, action: #selector(TweetsViewController.ActivateSegue))
            
            return cell
        }
        else
        {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "tweetCell", for: indexPath) as! TweetCell
            
            cell.hasImage = false
            cell.tweet = tweet
            
            cell.recognizer.indexPath = indexPath
            cell.recognizer.addTarget(self, action: #selector(ActivateSegue(_:)))
            
            return cell
        }
    }
    
    func ActivateSegue(_ sender : Any?)
    {
        let recog = sender as! CustomTap
        let indexPath = recog.indexPath
        
        self.performSegue(withIdentifier: "timelineToProfileSegue", sender: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let cell = tableView.cellForRow(at: indexPath) as! TweetCell
        
        cell.selectionStyle = .none
        
        if(cell.hasImage)
        {
            self.performSegue(withIdentifier: "tweetDetailWithImageSegue", sender: indexPath)
        }
        else
        {
            self.performSegue(withIdentifier: "tweetDetailSegue", sender: indexPath)
        }
        
        
    }
    
    @IBAction func logOutPressed(_ sender: Any)
    {
        TwitterClient.sharedInstance?.logOut()
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if (!isMoreDataLoading)
        {
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging)
            {
                isMoreDataLoading = true
                
                // Update position of loadingMoreView, and start loading indicator
                let frame = CGRect(x: 0, y: tableView.contentSize.height, width: tableView.bounds.size.width, height: InfiniteScrollActivityView.defaultHeight)
                loadingMoreView?.frame = frame
                loadingMoreView!.startAnimating()

                
                loadMoreData()
            }
        }
    }
    
    func loadMoreData()
    {
        // Configure session so that completion handler is executed on main UI thread
        client?.homeTimelineWithIncrease(success: { (tweets: [Tweet]) in
            self.tweets = tweets
            
            // Update flag
            self.isMoreDataLoading = false
            
            // Stop the loading indicator
            self.loadingMoreView!.stopAnimating()
            
            // Reload the tableView now that there is new data
            self.tableView.reloadData()
            
        }, failure: { (error: Error) in
            print("Error: \(error.localizedDescription)")
            self.loadingMoreView!.stopAnimating()
        })
        
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if(segue.identifier == "timelineToProfileSegue")
        {
            let indexPath = sender as! IndexPath
            
            let cell = tableView.cellForRow(at: indexPath) as! TweetCell
            
            let dest = segue.destination as! UserProfileViewController
            
            dest.nameText = cell.nameLabel.text!
            
            dest.user = dest.nameText!
            
            dest.handleText = "\(cell.handleLabel.text!)"
            dest.tagText = cell.tweet.tagline!
            dest.avatarString = cell.tweet.avatarLink!
            
            dest.followingCount =  cell.tweet.userFollowing
            dest.followerCount = cell.tweet.userFollower
            dest.favoriteCount = cell.tweet.userFav
            dest.profileColor = cell.tweet.profileColor!
            dest.bannerString = cell.tweet.userBannerString
            
        }
        else if(segue.identifier == "tweetDetailWithImageSegue")
        {
            let indexPath = sender as! IndexPath
            
            let cell = tableView.cellForRow(at: indexPath) as! TweetCell
            
            let dest = segue.destination as! DetailTableViewController
            
            dest.detailUser = cell.retweetUser
            dest.contentText = cell.tweetLabel.text!
            dest.contentImageString = cell.tweet.mediaURL!
            dest.rechirpCount = cell.tweet.retweetCount
            dest.favCount = cell.tweet.favCount
            dest.hasImage = true
            if(cell.tweet.timestamp != nil)
            {
                dest.dateStamp = cell.tweet.timestamp!
            }
            
        }
        else if(segue.identifier == "tweetDetailSegue")
        {
            let indexPath = sender as! IndexPath
            
            let cell = tableView.cellForRow(at: indexPath) as! TweetCell
            
            let dest = segue.destination as! DetailTableViewController
            
            print("CELL USER: \(cell.retweetUser)")
            
            dest.detailUser = cell.retweetUser
            dest.contentText = cell.tweetLabel.text!
            dest.rechirpCount = cell.tweet.retweetCount
            dest.favCount = cell.tweet.favCount
            dest.hasImage = false
            if(cell.tweet.timestamp != nil)
            {
                dest.dateStamp = cell.tweet.timestamp!
            }
        }
    }

}

class InfiniteScrollActivityView: UIView {
    var activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView()
    static let defaultHeight:CGFloat = 60.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupActivityIndicator()
    }
    
    override init(frame aRect: CGRect) {
        super.init(frame: aRect)
        setupActivityIndicator()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        activityIndicatorView.center = CGPoint(x: self.bounds.size.width/2, y: self.bounds.size.height/2)
    }
    
    func setupActivityIndicator() {
        activityIndicatorView.activityIndicatorViewStyle = .white
        
        activityIndicatorView.color = UIColor.myOnyxGray
        
        activityIndicatorView.hidesWhenStopped = true
        self.addSubview(activityIndicatorView)
    }
    
    func stopAnimating() {
        self.activityIndicatorView.stopAnimating()
        self.isHidden = true
    }
    
    func startAnimating() {
        self.isHidden = false
        self.activityIndicatorView.startAnimating()
    }
}
