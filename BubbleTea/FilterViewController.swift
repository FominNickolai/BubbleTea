//
//  FilterViewController.swift
//  BubbleTea
//
//  Created by Fomin Mykola on 8/9/17.
//  Copyright © 2017 Fomin Mykola. All rights reserved.
//

import UIKit
import CoreData

protocol FilterViewControllerDelegate: class {
    func filterViewController(
        filter: FilterViewController,
        didSelectPredicate predicate: NSPredicate?,
        sortDescriptor: NSSortDescriptor?)
}

class FilterViewController: UITableViewController {
    
    @IBOutlet weak var firstPriceCategoryLabel: UILabel!
    @IBOutlet weak var secondPriceCategoryLabel: UILabel!
    @IBOutlet weak var thirdPriceCategoryLabel: UILabel!
    
    @IBOutlet weak var numDealsLabel: UILabel!
    
    //MARK: - Price section
    @IBOutlet weak var cheapVenueCell: UITableViewCell!
    @IBOutlet weak var moderateVenueCell: UITableViewCell!
    @IBOutlet weak var expensiveVenueCell: UITableViewCell!
    
    //MARK: - Most popular section
    @IBOutlet weak var offeringDealCell: UITableViewCell!
    @IBOutlet weak var walkingDistanceCell: UITableViewCell!
    @IBOutlet weak var userTipsCell: UITableViewCell!
    
    //MARK: - Sort section
    @IBOutlet weak var nameAZSortCell: UITableViewCell!
    @IBOutlet weak var nameZASortCell: UITableViewCell!
    @IBOutlet weak var distanceSortCell: UITableViewCell!
    @IBOutlet weak var priceSortCell: UITableViewCell!
    
    //MARK: - Properties
    var coreDataStack: CoreDataStack!
    
    weak var delegate: FilterViewControllerDelegate?
    var selectedSortDescriptor: NSSortDescriptor?
    var selectedPredicate: NSPredicate?
    
    //MARK: - Predicates
    lazy var cheapVenuePredicate: NSPredicate = {
        return NSPredicate(format: "%K == %@", #keyPath(Venue.priceInfo.priceCategory), "$")
    }()
    
    lazy var moderateVenuePredicate: NSPredicate = {
        return NSPredicate(format: "%K == %@", #keyPath(Venue.priceInfo.priceCategory), "$$")
    }()
    
    lazy var expensiveVenuePredicate: NSPredicate = {
        return NSPredicate(format: "%K == %@", #keyPath(Venue.priceInfo.priceCategory), "$$$")
    }()
    
    lazy var offeringDealPredicate: NSPredicate = {
        return NSPredicate(format: "%K > 0", #keyPath(Venue.specialCount))
    }()
    
    lazy var walkingDistancePredicate: NSPredicate = {
        return NSPredicate(format: "%K < 500", #keyPath(Venue.location.distance))
    }()
    
    lazy var hasUserTipsPredicate: NSPredicate = {
        return NSPredicate(format: "%K > 0", #keyPath(Venue.stats.tipCount))
    }()
    
    //MARK: Sort Descriptors
    lazy var nameSortDescriptor: NSSortDescriptor = {
        let compareSelector = #selector(NSString.localizedStandardCompare(_:))
        return NSSortDescriptor(key: #keyPath(Venue.name), ascending: true, selector: compareSelector)
    }()
    
    lazy var distanceSortDescriptor: NSSortDescriptor = {
        return NSSortDescriptor(key: #keyPath(Venue.location.distance), ascending: true)
    }()
    
    lazy var priceSortDescriptor: NSSortDescriptor = {
        return NSSortDescriptor(key: #keyPath(Venue.priceInfo.priceCategory), ascending: true)
    }()
    
    //MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        populateVenueCount(with: cheapVenuePredicate, and: firstPriceCategoryLabel)
        populateVenueCount(with: moderateVenuePredicate, and: secondPriceCategoryLabel)
        populateVenueCount(with: expensiveVenuePredicate, and: thirdPriceCategoryLabel)
        
        populateDealsCountLabel()
    }

}
//MARK: - IBActions
extension FilterViewController {
    
    @IBAction func searchButtonTapped(_ sender: UIBarButtonItem) {
        delegate?.filterViewController(filter: self, didSelectPredicate: selectedPredicate, sortDescriptor: selectedSortDescriptor)
        dismiss(animated: true)
    }
    
}

//MARK: UITableViewDelegate
extension FilterViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        //Price section
        switch cell {
        case cheapVenueCell:
            selectedPredicate = cheapVenuePredicate
        case moderateVenueCell:
            selectedPredicate = moderateVenuePredicate
        case expensiveVenueCell:
            selectedPredicate = expensiveVenuePredicate
        //Most Popular section
        case offeringDealCell:
            selectedPredicate = offeringDealPredicate
        case walkingDistanceCell:
            selectedPredicate = walkingDistancePredicate
        case userTipsCell:
            selectedPredicate = hasUserTipsPredicate
        //Sort by section
        case nameAZSortCell:
            selectedSortDescriptor = nameSortDescriptor
        case nameZASortCell:
            selectedSortDescriptor = nameSortDescriptor.reversedSortDescriptor as? NSSortDescriptor
        case distanceSortCell:
            selectedSortDescriptor = distanceSortDescriptor
        case priceSortCell:
            selectedSortDescriptor = priceSortDescriptor
        default:
            break
        }
        cell.accessoryType = .checkmark
    }
}

//MARK: - Helpers methods
extension FilterViewController {
    
    func populateVenueCount(with predicate: NSPredicate, and displayInLabel: UILabel) {
        
        let fetchRequest = NSFetchRequest<NSNumber>(entityName: "Venue")
        fetchRequest.resultType = .countResultType
        fetchRequest.predicate = predicate
        
        do {
            let countResult = try coreDataStack.managedContext.fetch(fetchRequest)
            let count = countResult.first!.intValue
            displayInLabel.text = "\(count) bubble tea places"
        } catch let error as NSError {
            print("Could not fech \(error), \(error.userInfo)")
        }
        
    }
    
    func populateDealsCountLabel() {
        let fetchRequest = NSFetchRequest<NSDictionary>(entityName: "Venue")
        fetchRequest.resultType = .dictionaryResultType
        
        let sumExpressionDesc = NSExpressionDescription()
        sumExpressionDesc.name = "sumDeals"
        
        let specialCountExp = NSExpression(forKeyPath: \Venue.specialCount)
        sumExpressionDesc.expression = NSExpression(forFunction: "sum:", arguments: [specialCountExp])
        sumExpressionDesc.expressionResultType = .integer32AttributeType
        
        fetchRequest.propertiesToFetch = [sumExpressionDesc]
        
        do {
            let results = try coreDataStack.managedContext.fetch(fetchRequest)
            let resultDict = results.first!
            let numDeals = resultDict["sumDeals"]!
            numDealsLabel.text = "\(numDeals) total deals"
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        
    }
    
}






