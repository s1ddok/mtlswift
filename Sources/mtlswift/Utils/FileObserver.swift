//
//  FileObserver.swift
//  mtlswift
//
//  Created by Andrey Volodin on 25/09/2019.
//

import Foundation

class FileObserver {
    private let url: URL
    private let queue: DispatchQueue
    private var source: DispatchSourceFileSystemObject?

    init(file: URL) {
        self.url = file
        self.queue = DispatchQueue(label: "me.avolodin.mtlswift.fileObserving")
    }

    func start(closure: @escaping () -> Void) {
        // Obtain a descriptor from the file system
        let fileDescriptor = open(self.url.path, O_EVTONLY)

        guard fileDescriptor >= 0 else {
            return
        }

        // Create our dispatch source
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: DispatchSource.FileSystemEvent.all.subtracting(.attrib),
            queue: queue)

        // Assign the closure to it, and resume it to start observing
        source.setEventHandler(handler: { [unowned source] in
            closure()
            if source.data.contains(.delete) {
                source.cancel()
            }
        })
        source.setCancelHandler(handler: {
            close(fileDescriptor)
            self.start(closure: closure)
        })
        source.resume()
        self.source = source
    }
}
