//
//  ReloadData.swift
//  CoreDataAndNetWork
//
//  Created by SUNIL MOMIDI on 23/07/16.
//  Copyright © 2016 Sunil Momidi. All rights reserved.
//

import UIKit
import CoreData

class ReloadDataTableViewController: UITableViewController {
    var entryArray : AnyObject = []
    
    @IBAction func refreshBtnClicked(sender: AnyObject) {
        let appDelegate =
            UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Books")
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            self.books = results as! [NSManagedObject]
            if self.books.count == 0 {
                fetchDataFromNetwork()
            }
            else{
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    
                })
            }
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
       

    }
    @IBOutlet weak var refreshBtn: UIBarButtonItem!
    //core data array object
    var books = [NSManagedObject]()
    
    func fetchDataFromNetwork() {
        // send hppt get request
        let url = "https://itunes.apple.com/us/rss/topaudiobooks/limit=10/json"
        let nsUrl = NSURL(string:  url)
        let request = NSMutableURLRequest(URL: nsUrl!)
        request.HTTPMethod="GET"
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request){
            data,response,error in
            
            if error != nil{
                print("error = \(error)")
            }
            else{
                do{
                    let jsonArray1 =  try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves) as! NSDictionary
                    print("Json \(jsonArray1)")
                    
                    
                    let feeds = jsonArray1
                    
                    let feedsObj = feeds["feed"] as! NSDictionary
                    let entryArray = feedsObj["entry"] as! NSArray
                    
                    for dict in entryArray {
                        let author = dict["im:artist"]
                        let authorName = author!!["label"] as! String
                        
                        let book = dict["title"]
                        let bookTitle = book!!["label"] as! String
                        
                        self.saveBookToBooks(authorName, bookTitle: bookTitle)
                    }
                    
                } catch {
                    
                }
            }
        }
        task.resume()
    }
    func saveBookToBooks(author: String, bookTitle : String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("Books",inManagedObjectContext:managedContext)
        let book = NSManagedObject(entity: entity!,insertIntoManagedObjectContext: managedContext)
        book.setValue(author, forKey: "authorName")
        book.setValue(bookTitle, forKey: "bookTitle")
        do {
            try managedContext.save()
            self.books.append(book)
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "CoreData"
//        dispatch_async(dispatch_get_main_queue(), {
//            self.tableView.reloadData()
//        })
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.books.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let book = self.books[indexPath.row]
        let authorName = book.valueForKey("authorName") as? String
        let bookTitle = book.valueForKey("bookTitle") as? String
        cell.textLabel?.text = authorName
        cell.detailTextLabel?.text = bookTitle
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70.0
    }

}
