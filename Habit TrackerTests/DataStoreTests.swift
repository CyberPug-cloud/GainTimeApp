import XCTest
@testable import Habit_Tracker

class DataStoreTests: XCTestCase {
    var sut: MockDataStore!
    var testHabits: [Habit]!
    
    override func setUp() {
        super.setUp()
        sut = MockDataStore()
        testHabits = [
            Habit(title: "Test 1", description: "Description 1", priority: .high),
            Habit(title: "Test 2", description: "Description 2", priority: .medium),
            Habit(title: "Test 3", description: "Description 3", priority: .low)
        ]
    }
    
    override func tearDown() {
        sut = nil
        testHabits = nil
        super.tearDown()
    }
    
    func testSaveAndLoadHabits() {
        // Given
        XCTAssertEqual(sut.loadHabits().count, 0, "Store should be empty initially")
        
        // When
        sut.saveHabits(testHabits)
        let loadedHabits = sut.loadHabits()
        
        // Then
        XCTAssertEqual(loadedHabits.count, testHabits.count)
        XCTAssertEqual(loadedHabits[0].title, testHabits[0].title)
        XCTAssertEqual(loadedHabits[1].title, testHabits[1].title)
        XCTAssertEqual(loadedHabits[2].title, testHabits[2].title)
    }
    
    func testDeleteHabit() {
        // Given
        sut.saveHabits(testHabits)
        let habitToDelete = testHabits[1]
        
        // When
        sut.deleteHabit(habitToDelete)
        let remainingHabits = sut.loadHabits()
        
        // Then
        XCTAssertEqual(remainingHabits.count, testHabits.count - 1)
        XCTAssertFalse(remainingHabits.contains { $0.id == habitToDelete.id })
    }
    
    func testUpdateHabit() {
        // Given
        sut.saveHabits(testHabits)
        var habitToUpdate = testHabits[0]
        let newTitle = "Updated Title"
        habitToUpdate.title = newTitle
        
        // When
        sut.updateHabit(habitToUpdate)
        let updatedHabits = sut.loadHabits()
        
        // Then
        XCTAssertEqual(updatedHabits[0].title, newTitle)
        XCTAssertEqual(updatedHabits.count, testHabits.count)
    }
    
    func testEmptyStateHandling() {
        // Given
        XCTAssertEqual(sut.loadHabits().count, 0)
        
        // When
        sut.saveHabits([])
        let emptyHabits = sut.loadHabits()
        
        // Then
        XCTAssertEqual(emptyHabits.count, 0)
    }
} 