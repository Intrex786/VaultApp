import Foundation
import CoreData

// MARK: - VaultItem Managed Object

@objc(VaultItem)
final class VaultItem: NSManagedObject {
    @NSManaged var id:            UUID
    @NSManaged var encryptedData: Data
    @NSManaged var iv:            Data
    @NSManaged var vaultTag:      String
    @NSManaged var travelHidden:  Bool
    @NSManaged var createdAt:     Date
    @NSManaged var updatedAt:     Date
}

// MARK: - VaultStore

/// Actor-isolated CoreData store. Model is built programmatically — no .xcdatamodel file required.
actor VaultStore {

    static let shared = VaultStore()

    private let container: NSPersistentContainer

    private init() {
        container = Self.buildContainer()
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("VaultStore: CoreData failed to load — \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // MARK: - CoreData Bootstrap

    private static func buildContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "VaultStore", managedObjectModel: buildModel())
        return container
    }

    private static func buildModel() -> NSManagedObjectModel {
        let model  = NSManagedObjectModel()
        let entity = NSEntityDescription()
        entity.name                    = "VaultItem"
        entity.managedObjectClassName  = "VaultItem"

        func attr(_ name: String, _ type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name          = name
            a.attributeType = type
            a.isOptional    = optional
            return a
        }

        entity.properties = [
            attr("id",            .UUIDAttributeType),
            attr("encryptedData", .binaryDataAttributeType),
            attr("iv",            .binaryDataAttributeType),
            attr("vaultTag",      .stringAttributeType),
            attr("travelHidden",  .booleanAttributeType),
            attr("createdAt",     .dateAttributeType),
            attr("updatedAt",     .dateAttributeType),
        ]

        model.entities = [entity]
        return model
    }

    // MARK: - Context Helpers

    private func background() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }

    // MARK: - Insert

    @discardableResult
    func insert(
        encryptedData: Data,
        iv: Data,
        vaultTag: String,
        travelHidden: Bool = false
    ) async throws -> NSManagedObjectID {
        let ctx = background()
        return try await ctx.perform {
            let item           = VaultItem(context: ctx)
            item.id            = UUID()
            item.encryptedData = encryptedData
            item.iv            = iv
            item.vaultTag      = vaultTag
            item.travelHidden  = travelHidden
            item.createdAt     = Date()
            item.updatedAt     = Date()
            try ctx.save()
            return item.objectID
        }
    }

    // MARK: - Fetch

    /// Fetches items, optionally filtered by tag. Pass `includingTravelHidden: false` for travel mode.
    func fetch(
        tag: String? = nil,
        includingTravelHidden: Bool = true
    ) async throws -> [[String: Any]] {
        let ctx = background()
        return try await ctx.perform {
            let request = NSFetchRequest<VaultItem>(entityName: "VaultItem")

            var predicates: [NSPredicate] = []
            if let tag { predicates.append(NSPredicate(format: "vaultTag == %@", tag)) }
            if !includingTravelHidden { predicates.append(NSPredicate(format: "travelHidden == NO")) }
            request.predicate    = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            return try ctx.fetch(request).map { Self.snapshot($0) }
        }
    }

    /// Returns a single item snapshot by UUID, or nil if not found.
    func fetchByID(_ id: UUID) async throws -> [String: Any]? {
        let ctx = background()
        return try await ctx.perform {
            let request           = NSFetchRequest<VaultItem>(entityName: "VaultItem")
            request.predicate     = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit    = 1
            guard let item = try ctx.fetch(request).first else { return nil }
            return Self.snapshot(item)
        }
    }

    // MARK: - Update Encrypted Payload

    func update(_ id: UUID, encryptedData: Data, iv: Data) async throws {
        let ctx = background()
        try await ctx.perform {
            let request        = NSFetchRequest<VaultItem>(entityName: "VaultItem")
            request.predicate  = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let item = try ctx.fetch(request).first else { return }
            item.encryptedData = encryptedData
            item.iv            = iv
            item.updatedAt     = Date()
            try ctx.save()
        }
    }

    // MARK: - Travel Mode

    func setTravelHidden(_ id: UUID, hidden: Bool) async throws {
        let ctx = background()
        try await ctx.perform {
            let request        = NSFetchRequest<VaultItem>(entityName: "VaultItem")
            request.predicate  = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let item = try ctx.fetch(request).first else { return }
            item.travelHidden = hidden
            item.updatedAt    = Date()
            try ctx.save()
        }
    }

    // MARK: - Delete

    func delete(_ id: UUID) async throws {
        let ctx = background()
        try await ctx.perform {
            let request        = NSFetchRequest<VaultItem>(entityName: "VaultItem")
            request.predicate  = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1
            guard let item = try ctx.fetch(request).first else { return }
            ctx.delete(item)
            try ctx.save()
        }
    }

    func deleteAll() async throws {
        let ctx = background()
        try await ctx.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "VaultItem")
            let batch   = NSBatchDeleteRequest(fetchRequest: request)
            try ctx.execute(batch)
            try ctx.save()
        }
    }

    // MARK: - Private

    /// Returns a value-type snapshot so managed objects don't escape the context.
    private static func snapshot(_ item: VaultItem) -> [String: Any] {
        [
            "id":            item.id,
            "encryptedData": item.encryptedData,
            "iv":            item.iv,
            "vaultTag":      item.vaultTag,
            "travelHidden":  item.travelHidden,
            "createdAt":     item.createdAt,
            "updatedAt":     item.updatedAt,
        ]
    }
}
