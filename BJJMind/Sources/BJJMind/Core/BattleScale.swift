import Foundation

// MARK: - BJJPosition

enum BJJPosition: String, CaseIterable, Equatable {
    case submission
    case backControl
    case mount
    case sideControl
    case halfGuard
    case openGuard
    case closedGuard  // center/neutral position

    /// Maps to Supabase question topic
    var topic: String {
        switch self {
        case .submission:  return "submission"
        case .backControl: return "back_control"
        case .mount:       return "mount"
        case .sideControl: return "side_control"
        case .halfGuard:   return "half_guard"
        case .openGuard:   return "open_guard"
        case .closedGuard: return "closed_guard"
        }
    }

    var displayName: String {
        switch self {
        case .submission:  return "Submission"
        case .backControl: return "Back Control"
        case .mount:       return "Mount"
        case .sideControl: return "Side Control"
        case .halfGuard:   return "Half Guard"
        case .openGuard:   return "Open Guard"
        case .closedGuard: return "Closed Guard"
        }
    }

    /// BJJ competition points awarded per turn spent in this position.
    /// Submission = 0 since it ends the fight immediately.
    var bjjPoints: Int {
        switch self {
        case .submission:  return 0
        case .backControl: return 4
        case .mount:       return 4
        case .sideControl: return 2
        case .halfGuard:   return 0
        case .openGuard:   return 0
        case .closedGuard: return 0
        }
    }
}

// MARK: - BattleScale

/// Represents the positional scale used in the battle system.
/// The scale is symmetric around a center index (neutral/guard position).
/// Moving right (higher index) = advancing into opponent's territory.
/// Reaching either endpoint = submission win.
///
/// Scale grows as user completes more learning cycles.
struct BattleScale {

    /// Full sequence of positions from left endpoint to right endpoint.
    /// positions[0] and positions[last] are both `.submission` (win conditions).
    /// positions[centerIndex] is the neutral/guard position.
    let positions: [BJJPosition]

    /// Index of the center (neutral) position where the marker starts.
    let centerIndex: Int

    // MARK: - Factory

    /// Returns the battle scale for a given learning cycle.
    ///
    /// - Cycle 1 (Closed Guard): [sub, mnt, sc, cg, ●, cg, sc, mnt, sub]
    /// - Cycle 2 (Half Guard):   [sub, bk, mnt, sc, hg, ●, hg, sc, mnt, bk, sub]
    /// - Cycle 3 (Turtle):       same as Cycle 2 (Turtle doesn't add new scale positions)
    /// - Cycle 4 (Open Guard):   [sub, bk, mnt, sc, hg, og, ●, og, hg, sc, mnt, bk, sub]
    static func forCycle(_ cycle: Int) -> BattleScale {
        switch cycle {
        case 1:
            // 9 positions, center at index 4
            let positions: [BJJPosition] = [
                .submission,
                .mount, .sideControl, .closedGuard,
                .closedGuard,  // center
                .closedGuard, .sideControl, .mount,
                .submission
            ]
            return BattleScale(positions: positions, centerIndex: 4)

        case 2, 3:
            // 11 positions, center at index 5
            // Cycle 3 (Turtle) reuses the half guard scale
            let positions: [BJJPosition] = [
                .submission,
                .backControl, .mount, .sideControl, .halfGuard,
                .halfGuard,   // center
                .halfGuard, .sideControl, .mount, .backControl,
                .submission
            ]
            return BattleScale(positions: positions, centerIndex: 5)

        default:
            // Cycle 4+ adds Open Guard: 13 positions, center at index 6
            let positions: [BJJPosition] = [
                .submission,
                .backControl, .mount, .sideControl, .halfGuard, .openGuard,
                .openGuard,   // center
                .openGuard, .halfGuard, .sideControl, .mount, .backControl,
                .submission
            ]
            return BattleScale(positions: positions, centerIndex: 6)
        }
    }

    // MARK: - Queries

    /// Returns "top" if marker is in the opponent's zone (advancing),
    /// or "bottom" if at center or in the player's zone (defending).
    ///
    /// - marker > center → you're in opponent's territory → on top (attacking)
    /// - marker ≤ center → you're at neutral or in your territory → on bottom (guard)
    func perspective(atMarkerIndex index: Int) -> String {
        index > centerIndex ? "top" : "bottom"
    }

    /// BJJ points value of the position at the given marker index.
    func pointsForPosition(atMarkerIndex index: Int) -> Int {
        guard index >= 0 && index < positions.count else { return 0 }
        return positions[index].bjjPoints
    }

    /// Returns true if the marker has reached a submission endpoint (win condition).
    func isSubmission(atMarkerIndex index: Int) -> Bool {
        index == 0 || index == positions.count - 1
    }
}
