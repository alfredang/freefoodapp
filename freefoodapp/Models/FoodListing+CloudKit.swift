import CloudKit
import Foundation

/// Maps a `FoodListing` to and from a CloudKit `FoodListing` record so listings can be
/// shared through the public database. Up to three photos are stored as `CKAsset`s.
extension FoodListing {
    static let recordType = "FoodListing"

    init?(record: CKRecord) {
        guard
            let title = record["title"] as? String,
            let details = record["details"] as? String,
            let locationName = record["locationName"] as? String,
            let latitude = record["latitude"] as? Double,
            let longitude = record["longitude"] as? Double,
            let date = record["date"] as? Date,
            let startTime = record["startTime"] as? Date,
            let endTime = record["endTime"] as? Date,
            let createdAt = record["createdAt"] as? Date
        else { return nil }

        var photos: [Data] = []
        for key in ["photo0", "photo1", "photo2"] {
            if let asset = record[key] as? CKAsset,
               let url = asset.fileURL,
               let data = try? Data(contentsOf: url) {
                photos.append(data)
            }
        }

        self.init(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            title: title,
            details: details,
            locationName: locationName,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            date: date,
            startTime: startTime,
            endTime: endTime,
            photos: photos,
            createdAt: createdAt
        )
    }

    /// Build a CloudKit record, writing each photo to a temporary file for its `CKAsset`.
    func toRecord() throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["title"] = title as CKRecordValue
        record["details"] = details as CKRecordValue
        record["locationName"] = locationName as CKRecordValue
        record["latitude"] = coordinate.latitude as CKRecordValue
        record["longitude"] = coordinate.longitude as CKRecordValue
        record["date"] = date as CKRecordValue
        record["startTime"] = startTime as CKRecordValue
        record["endTime"] = endTime as CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["expiresAt"] = expiresAt as CKRecordValue

        let tmp = FileManager.default.temporaryDirectory
        for (index, data) in photos.prefix(3).enumerated() {
            let url = tmp.appendingPathComponent("\(id.uuidString)-photo\(index).jpg")
            try data.write(to: url, options: .atomic)
            record["photo\(index)"] = CKAsset(fileURL: url)
        }
        return record
    }
}
