import Foundation

/// Manages undo/redo for annotation arrays using a snapshot stack.
/// Does NOT use NSUndoManager — pure value-type snapshot approach.
@MainActor
final class UndoRedoManager {

    private var undoStack: [[any Annotation]] = []
    private var redoStack: [[any Annotation]] = []
    private let maxDepth = 50

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Call before any mutation to save the current state for undo.
    func saveSnapshot(_ annotations: [any Annotation]) {
        undoStack.append(annotations)
        if undoStack.count > maxDepth {
            undoStack.removeFirst()
        }
        redoStack.removeAll()  // new action clears redo history
    }

    /// Returns the previous state and advances the redo stack.
    func undo(current: [any Annotation]) -> [any Annotation]? {
        guard let previous = undoStack.popLast() else { return nil }
        redoStack.append(current)
        return previous
    }

    /// Returns the next state and advances the undo stack.
    func redo(current: [any Annotation]) -> [any Annotation]? {
        guard let next = redoStack.popLast() else { return nil }
        undoStack.append(current)
        return next
    }

    func reset() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}
