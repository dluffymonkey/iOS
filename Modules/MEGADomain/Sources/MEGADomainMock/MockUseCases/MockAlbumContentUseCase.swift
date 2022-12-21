import Foundation
import MEGADomain
import Combine

public struct MockAlbumContentUseCase: AlbumContentsUseCaseProtocol {
    public var updatePublisher: AnyPublisher<Void, Never>
    private var nodes = [NodeEntity]()

    public init(nodes: [NodeEntity], updatePublisher: AnyPublisher<Void, Never> = Empty().eraseToAnyPublisher()) {
        self.nodes = nodes
        self.updatePublisher = updatePublisher
    }

    public func favouriteAlbumNodes() async throws -> [NodeEntity] {
        nodes
    }
    
    public func nodes(forAlbum album: AlbumEntity) async throws -> [NodeEntity] {
        nodes
    }
}
