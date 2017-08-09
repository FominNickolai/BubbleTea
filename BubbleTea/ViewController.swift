//
//  ViewController.swift
//  BubbleTea
//
//  Created by Fomin Mykola on 8/9/17.
//  Copyright © 2017 Fomin Mykola. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    //MARK: - Properties
    private let filterViewControllerSegueIdentifier = "toFilterViewController"
    fileprivate let venueCellIdentifier = "VenueCell"
    var coreDataStack: CoreDataStack!
    
    var fetchRequest: NSFetchRequest<Venue>!
    var venues: [Venue] = []
    
    var asyncFetchRequest: NSAsynchronousFetchRequest<Venue>!
    
    //MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!

    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchRequest = Venue.fetchRequest()
        
        asyncFetchRequest = NSAsynchronousFetchRequest<Venue>(fetchRequest: fetchRequest, completionBlock: { [unowned self] (result) in
            guard let venues = result.finalResult else { return }
            self.venues = venues
            self.tableView.reloadData()
        })
        
        do {
            try coreDataStack.managedContext.execute(asyncFetchRequest)
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    //MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == filterViewControllerSegueIdentifier, let navController = segue.destination as? UINavigationController, let filterVC = navController.topViewController as? FilterViewController else { return }
        filterVC.coreDataStack = coreDataStack
        filterVC.delegate = self
    }
}

//MARK: - IBActions
extension ViewController {
    @IBAction func unwindToVenueListViewController(_ segue: UIStoryboardSegue) {
        
    }
}

//MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venues.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: venueCellIdentifier, for: indexPath)
        let venue = venues[indexPath.row]
        cell.textLabel?.text = venue.name
        cell.detailTextLabel?.text = venue.priceInfo?.priceCategory
        return cell
    }
}

//MARK: - Helpres Methods
extension ViewController {
    
    func fetchAndReload() {
        do {
            venues = try coreDataStack.managedContext.fetch(fetchRequest)
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch: \(error), \(error.userInfo)")
        }
    }
    
}

//MARK: - FilterViewControllerDelegate
extension ViewController: FilterViewControllerDelegate {
    func filterViewController(filter: FilterViewController, didSelectPredicate predicate: NSPredicate?, sortDescriptor: NSSortDescriptor?) {
        
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = nil
        
        fetchRequest.predicate = predicate
        
        if let sr = sortDescriptor {
            fetchRequest.sortDescriptors = [sr]
        }
        
        fetchAndReload()
        
    }
}



















