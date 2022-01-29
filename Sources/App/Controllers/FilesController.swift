//
//  FilesController.swift
//  
//
//  Created by Eduard Dzhumagaliev on 30.01.2022.
//

import Vapor

class FilesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let files = routes.grouped("files")

        files.group(":fileId") { file in
            file.delete(use: remove)
            file.post(use: upload)
            file.get(use: download)
        }

        files.get(use: index)
    }

    func index(req: Request) throws -> [File] {
        return try! FileManager.default.contentsOfDirectory(atPath: req.application.directory.publicDirectory).map { filePath in
            let fileSize = try! FileManager.default.attributesOfItem(atPath: req.application.directory.publicDirectory + filePath)[.size] as! Int

            return File(name: filePath, size: fileSize)
        }
    }

    func download(req: Request) throws -> EventLoopFuture<Response> {
        let key = req.parameters.get("fileId")!
        let path = req.application.directory.publicDirectory + key
        return req.eventLoop.makeSucceededFuture(req.fileio.streamFile(at: path))
    }

    func upload(req: Request) throws -> EventLoopFuture<String> {
        let key = req.parameters.get("fileId")!
        let path = req.application.directory.publicDirectory + key
        return req.body.collect()
            .unwrap(or: Abort(.noContent))
            .flatMap { req.fileio.writeFile($0, at: path) }
            .map { key }
    }

    func remove(req: Request) throws -> String {
        let key = req.parameters.get("fileId")!
        let path = req.application.directory.publicDirectory + key
        if (try? FileManager.default.removeItem(atPath: path)) != nil {
            return "success"
        } else {
            return "error"
        }
    }
}
