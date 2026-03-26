import Testing
import Foundation
import CoreGraphics
@testable import Blueshot

// A minimal Annotation for testing purposes
struct DummyAnnotation: Annotation {
    let id = UUID()
    let tag: Int
    var boundingRect: CGRect { .zero }
    func draw(in context: CGContext, scale: CGFloat) {}
}

@MainActor
@Suite("UndoRedoManager")
struct UndoRedoManagerTests {
    @Test func initialStateHasNoHistory() {
        let mgr = UndoRedoManager()
        #expect(!mgr.canUndo)
        #expect(!mgr.canRedo)
    }

    @Test func undoRestoresPreviousState() {
        let mgr = UndoRedoManager()
        let a0: [any Annotation] = []
        let a1: [any Annotation] = [DummyAnnotation(tag: 1)]

        mgr.saveSnapshot(a0)
        let restored = mgr.undo(current: a1)
        #expect(restored?.count == 0)
        #expect(!mgr.canUndo)
        #expect(mgr.canRedo)
    }

    @Test func redoRestoresNextState() {
        let mgr = UndoRedoManager()
        let a0: [any Annotation] = []
        let a1: [any Annotation] = [DummyAnnotation(tag: 1)]

        mgr.saveSnapshot(a0)
        _ = mgr.undo(current: a1)
        let redone = mgr.redo(current: a0)
        #expect(redone?.count == 1)
    }

    @Test func newActionClearsRedoStack() {
        let mgr = UndoRedoManager()
        let a0: [any Annotation] = []
        let a1: [any Annotation] = [DummyAnnotation(tag: 1)]

        mgr.saveSnapshot(a0)
        _ = mgr.undo(current: a1)
        #expect(mgr.canRedo)

        // Save a new snapshot — redo stack should be cleared
        mgr.saveSnapshot(a0)
        #expect(!mgr.canRedo)
    }

    @Test func resetClearsAllHistory() {
        let mgr = UndoRedoManager()
        let a0: [any Annotation] = [DummyAnnotation(tag: 1)]
        mgr.saveSnapshot(a0)
        mgr.reset()
        #expect(!mgr.canUndo)
        #expect(!mgr.canRedo)
    }
}
