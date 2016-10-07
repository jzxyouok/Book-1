//
//  ViewController.swift
//  Book
//
//  Created by LiuRon on 2016/9/24.
//  Copyright © 2016年 LiuRon. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import MBProgressHUD
import ESPullToRefresh

class BookViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    
    let identifierBookCell = "NormalCell"
    let url = "https://api.douban.com/v2/movie/search"
    let tag = "爱情"
    var books:JSON = []
    let pageSize = 10
    var page = 0
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //设置searchbar
        
        let searchController = storyboard?.instantiateViewController(withIdentifier: "BookSearchController") as! BookSearchController
        searchController.bookController = self
        searchView.addSubview(searchController.searchController.searchBar)
        
        
        //MARK:首次自动加载
        
//        使用es_startPullToRefresh首次加载，不过还是MBProgressHUD感觉舒服
//        tableView.es_startPullToRefresh()
        
        let loadingNotification:MBProgressHUD
        loadingNotification = MBProgressHUD.showAdded(to: self.view!, animated: true)
        loadingNotification.label.text = "Loading"
        
        Alamofire.request(url, method: .get, parameters: ["tag":tag,"start":0,"count":pageSize],encoding: URLEncoding.default).responseJSON {
            response in
            
            switch response.result {
            case .success:
                self.books = JSON(response.result.value)["subjects"]
                self.page = 1
                MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.tableView.reloadData()
            case .failure(let error):
                print(error)
            }
        }
        
        //MARK:下拉刷新数据
        self.tableView.es_addPullToRefresh {
            [weak self] in
            Alamofire.request((self?.url)!, method: .get, parameters: ["tag":(self?.tag)!,"start":0,"count":(self?.pageSize)],encoding: URLEncoding.default).responseJSON {
                response in
                
                switch response.result {
                case .success:
                    self?.books = JSON(response.result.value)["subjects"]
                    self?.page = 1
                    self?.tableView.reloadData()
                    self?.tableView.es_stopPullToRefresh(completion: true)
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        
        //MARK:上拉加载数据
        self.tableView.es_addInfiniteScrolling {
            [weak self] in
            Alamofire.request((self?.url)!, method: .get, parameters: ["tag":(self?.tag)!,"start":((self?.page)! * (self?.pageSize)!),"count":(self?.pageSize)],encoding: URLEncoding.default).responseJSON {
                response in
                
                switch response.result {
                case .success:
                    let count = self?.books.count
                    let KeyBooks = JSON(response.result.value)["subjects"]
                    
                    if KeyBooks.isEmpty {
                        //通过es_noticeNoMoreData()设置footer暂无数据状态
                        self?.tableView.es_noticeNoMoreData()
                    } else {
                        self?.books = JSON(self!.books.arrayObject! + KeyBooks.arrayObject!)
                        self?.page += 1
                        var indexpaths = [IndexPath]()
                        for (k,_):(String,JSON) in KeyBooks {
                            indexpaths.append([0,count!+Int(k)!])
                        }
                        //如果你的加载更多事件成功，调用es_stopLoadingMore()重置footer状态

                        self?.tableView.es_stopLoadingMore()
                        self?.tableView.insertRows(at: indexpaths, with: .automatic)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
            return 1
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bookCell = tableView.dequeueReusableCell(withIdentifier: identifierBookCell, for: indexPath) as! BookCell;
        bookCell.configureWithBook(book: books[indexPath.row])
        return bookCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        navigationController?.pushViewController(detailController, animated: true)
        detailController.book = books[indexPath.row]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

