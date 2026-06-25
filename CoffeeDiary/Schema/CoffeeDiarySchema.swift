import SwiftData

enum CoffeeDiarySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [BrewEntry.self, Bean.self, Grinder.self, Machine.self, Brewer.self]
    }
}

enum CoffeeDiaryMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [CoffeeDiarySchemaV1.self]
    }

    static var stages: [MigrationStage] { [] }
}
