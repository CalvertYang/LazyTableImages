//
//  RootViewController.swift
//  LazyTableImages
//
//  Created by Calvert Yang on 11/12/15.
//  Copyright © 2015 Calvert. All rights reserved.
//

import UIKit

let customRowCount = 7

let cellIdentifier = "LazyTableCell"
let placeholderCellIdentifier = "PlaceholderCell"

class RootViewController: UITableViewController {

    var entries: NSArray?

    var imageDownloadsInProgress: [NSIndexPath: IconDownloader] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.terminateAllDownloads()
    }

    // If this view controller is going away, we need to cancel all outstanding downloads.
    deinit {
        self.terminateAllDownloads()
    }

    // MARK: - Table view data source

    // Customize the number of rows in the table view.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.entries?.count ?? 0

        if (count == 0) {
            return customRowCount
        }

        return count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell?

        let nodeCount = self.entries?.count ?? 0

        if (nodeCount == 0 && indexPath.row == 0) {
            // add a placeholder cell while waiting on table data
            cell = tableView.dequeueReusableCellWithIdentifier(placeholderCellIdentifier, forIndexPath: indexPath)
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)

            // Leave cells empty if there's no data yet
            if (nodeCount > 0) {
                // Set up the cell representing the app
                let appRecord = self.entries![indexPath.row] as! AppRecord

                cell!.textLabel!.text = appRecord.appName
                cell!.detailTextLabel?.text = appRecord.artist

                // Only load cached images; defer new downloads until scrolling ends
                if (appRecord.appIcon == nil) {
                    if (!self.tableView.dragging && !self.tableView.decelerating) {
                        self.startIconDownload(appRecord, forIndexPath:indexPath)
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell!.imageView!.image = UIImage(named: "Placeholder")
                } else {
                    cell!.imageView!.image = appRecord.appIcon
                }
            }
        }

        return cell!
    }

    // MARK: - Table cell image support

    //	startIconDownload:forIndexPath:
    func startIconDownload(appRecord: AppRecord, forIndexPath indexPath: NSIndexPath) {
        var iconDownloader = self.imageDownloadsInProgress[indexPath]

        if (iconDownloader == nil) {
            iconDownloader = IconDownloader()
            iconDownloader!.appRecord = appRecord
            iconDownloader!.completionHandler = {
                let cell = self.tableView.cellForRowAtIndexPath(indexPath)

                // Display the newly loaded image
                cell!.imageView!.image = appRecord.appIcon

                // Remove the IconDownloader from the in progress list.
                // This will result in it being deallocated.
                self.imageDownloadsInProgress.removeValueForKey(indexPath)
            }
            self.imageDownloadsInProgress[indexPath] = iconDownloader
            iconDownloader!.startDownload()
        }
    }

    //	loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    func loadImagesForOnscreenRows() {
        if (self.entries?.count > 0) {
            let visiblePaths = self.tableView.indexPathsForVisibleRows!

            for indexPath in visiblePaths as [NSIndexPath] {
                let appRecord = self.entries![indexPath.row] as! AppRecord

                // Avoid the app icon download if the app already has an icon
                if (appRecord.appIcon == nil) {
                    self.startIconDownload(appRecord, forIndexPath: indexPath)
                }
            }

        }
    }

    // MARK: - UIScrollViewDelegate

    //	scrollViewDidEndDragging:willDecelerate:
    //  Load images for all onscreen rows when scrolling is finished.
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (!decelerate) {
            self.loadImagesForOnscreenRows()
        }
    }

    //	scrollViewDidEndDecelerating:scrollView
    //  When scrolling stops, proceed to load the app icons that are on screen.
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }

    //	terminateAllDownloads
    func terminateAllDownloads() {
        // terminate all pending download connections
        let allDownloads = self.imageDownloadsInProgress.values
        allDownloads.forEach { $0.cancelDownload() }

        self.imageDownloadsInProgress.removeAll(keepCapacity: false)
    }

}
