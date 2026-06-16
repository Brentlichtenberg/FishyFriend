import Foundation

// MARK: - Data Models

enum KnotCategory: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case fundamentals  = "Fundamentals"
    case terminalKnots = "Terminal Knots"
    case terminalLoops = "Terminal Loops"
    case leaderTippet  = "Leader to Tippet"
    case flyLineLeader = "Fly Line to Leader"
    case backingFlyLine = "Backing to Fly Line"
    case backingReel   = "Backing to Reel"
    case specialty     = "Specialty & Saltwater"
    case rigging       = "Rigging"

    var icon: String {
        switch self {
        case .fundamentals:   return "book.fill"
        case .terminalKnots:  return "fish.fill"
        case .terminalLoops:  return "arrow.triangle.2.circlepath"
        case .leaderTippet:   return "link"
        case .flyLineLeader:  return "arrow.left.arrow.right"
        case .backingFlyLine: return "line.diagonal"
        case .backingReel:    return "circle.dotted"
        case .specialty:      return "water.waves"
        case .rigging:        return "hammer.fill"
        }
    }
}

enum KnotDiagramType {
    case improvedClinch, doubleDavy, uniKnot, palomar
    case nonSlipLoop, perfectionLoop, surgeonsLoop
    case doubleSurgeons, bloodKnot, loopToLoop
    case nailKnot, albright, arbor, snell
    case dropperRig, nymphRig, skagitRig
    case conceptText(String)
}

struct FlyFishingKnot: Identifiable {
    let id: String
    let name: String
    let altNames: [String]
    let category: KnotCategory
    let connection: String       // e.g., "Tippet → Fly"
    let strength: String?        // e.g., "~90% line strength"
    let bestFor: String
    let description: String
    let steps: [String]
    let proTips: [String]
    let diagram: KnotDiagramType
}

struct RiggingSetup: Identifiable {
    let id: String
    let name: String
    let description: String
    let components: [String]
    let specs: [(label: String, value: String)]
    let diagram: KnotDiagramType
}

// MARK: - All Knot Data (pages 4-28)

struct KnotGuideData {

    // MARK: Terminology
    static let terminology: [(term: String, definition: String)] = [
        ("Butt", "The thick part of the leader attached to the fly line."),
        ("Standing End", "The part of the line that leads away from the knot — the main working line."),
        ("Tag End", "The short free end of the line where the knot is tied. Trim after seating."),
        ("Tippet", "The last 1–2 feet of the leader to which the fly is tied. Can be the end of the leader or a separate piece of monofilament."),
        ("Turns / Wraps", "One complete revolution of line around another. Count carefully — too few weakens the knot."),
    ]

    // MARK: Tips
    static let tips: [(title: String, detail: String)] = [
        ("Lubricate First", "Wet the knot with water or saliva before drawing tight. This reduces friction heat which weakens monofilament."),
        ("Pull Slowly", "Tighten wraps in a neat spiral, each coil edge-to-edge with the next. Pulling quickly can cause loops to cross and cut each other."),
        ("Pull Tight", "A loose knot can slip and cut the line. Use a slow, steady continuous pull on both standing parts."),
        ("Seat the Knot", "Once tight, make one firm sharp pull to seat the knot fully. Only once."),
        ("Trim the Tag", "Cut the tag end ~⅛\" from the knot with clippers or nippers. Never use heat — it weakens the line."),
        ("Avoid Twisting", "When tying double-line knots, keep the two lines parallel — do not twist them together."),
    ]

    // MARK: Knots
    static let knots: [FlyFishingKnot] = [

        // ── TERMINAL KNOTS ──────────────────────────────────────────

        FlyFishingKnot(
            id: "improved-clinch",
            name: "Improved Clinch Knot",
            altNames: ["Clinch Knot"],
            category: .terminalKnots,
            connection: "Tippet → Fly",
            strength: "~75–85% line strength",
            bestFor: "Monofilament under 25 lb · most freshwater situations",
            description: "The most widely used fly fishing knot. Time-tested, reliable, and quick to tie. Not recommended for braided line or heavy mono over 25 lb test.",
            steps: [
                "Pass the tag end of the tippet through the hook eye. Pull 6–8 inches through.",
                "Hold the tag end parallel to the standing line. Wrap the tag end 5–6 times around the standing line, working away from the eye.",
                "Bring the tag end back through the small loop that formed directly behind the eye.",
                "For the basic Clinch Knot: pull tight here. For the Improved Clinch: pass the tag through the large open loop you just created before pulling.",
                "Lubricate the knot, then slowly pull the standing line to close the wraps.",
                "Seat the knot with one firm pull, then trim the tag end close."
            ],
            proTips: [
                "Count your wraps — 5 is the minimum. 6–7 is better for thin tippet (5X–7X).",
                "The extra step of threading through the big loop (making it 'Improved') significantly increases strength and is worth the extra second."
            ],
            diagram: .improvedClinch
        ),

        FlyFishingKnot(
            id: "double-davy",
            name: "Double Davy Knot",
            altNames: ["Davy Knot"],
            category: .terminalKnots,
            connection: "Tippet → Fly",
            strength: "85–100% line strength",
            bestFor: "Small flies · fast tying · all tippet sizes",
            description: "Attributed to Davy Wotton. Compact, strong, and extremely fast to tie once learned. Rated 85–100% line strength with 90% as a reliable working assumption. Should be in every fly fisher's arsenal.",
            steps: [
                "Pass 3–4 inches of tippet through the hook eye.",
                "Make a simple overhand knot, then bring the tag end back through the loop — passing between the overhand knot and the hook itself.",
                "Continue the tag end: over the top of the loop, down through the loop, around the bottom of the loop, then back through.",
                "Tighten by pulling the tag end first to draw up the knot, then pull the standing line to fully seat it.",
                "Trim the tag end close to the knot."
            ],
            proTips: [
                "The key step is in step 2 — the tag must pass between the overhand knot and the hook. Getting this right makes the Double Davy ultra-strong.",
                "Once mastered this knot ties in under 5 seconds, getting you back to fishing faster."
            ],
            diagram: .doubleDavy
        ),

        FlyFishingKnot(
            id: "uni-knot",
            name: "Uni Knot",
            altNames: ["Duncan Knot", "Grinner Knot"],
            category: .terminalKnots,
            connection: "Tippet → Fly",
            strength: "~80% line strength",
            bestFor: "All tippet types · can leave a small loop for fly action",
            description: "Also called the Duncan or Grinner Knot. Versatile and dependable for tippet-to-fly connections. Some anglers find it easier than the Improved Clinch. Can be slid to the eye or left with a small loop to give the fly more natural movement.",
            steps: [
                "Pass tippet through the hook eye and double back parallel to the standing line, leaving 6 inches of tag end.",
                "Form a loop by laying the tag end over the doubled line.",
                "Wrap the tag end 4–6 turns around the doubled line and through the loop. More turns for thinner tippet.",
                "Lubricate, then pull the tag end to snug up the wraps. Turns should spiral neatly.",
                "Pull the standing end to slide the knot down to the hook eye — or stop just short to leave a small loop for fly movement.",
                "Trim the tag end."
            ],
            proTips: [
                "4 wraps for thick tippet (0X–2X), 5–6 wraps for thin tippet (4X–7X).",
                "Leaving the loop slightly open (don't slide all the way to the eye) gives streamers and wet flies more natural swimming action."
            ],
            diagram: .uniKnot
        ),

        FlyFishingKnot(
            id: "palomar",
            name: "Palomar Knot",
            altNames: [],
            category: .terminalKnots,
            connection: "Tippet → Fly",
            strength: "~95–100% line strength",
            bestFor: "Braided line · any monofilament · maximum strength applications",
            description: "One of the strongest terminal knots available, approaching 100% line strength when tied correctly. Works exceptionally well with braided fishing line. The key is keeping the doubled line from twisting during tying.",
            steps: [
                "Double 6 inches of tippet and pass the end of the loop through the hook eye.",
                "Tie a loose overhand knot with the hook hanging from the bottom. Keep it loose.",
                "Hold the overhand knot between thumb and forefinger. Pass the entire loop of line over the hook.",
                "Slide the loop up and seat it above the eye of the hook.",
                "Pull both the standing line and the tag end simultaneously to tighten the knot down onto the eye.",
                "Trim the tag end close."
            ],
            proTips: [
                "Make sure the loop goes completely over the hook on step 3 — it's easy to let it catch on the hook point.",
                "Keep the overhand knot loose until the loop is over the hook. Tightening too early makes the final seating difficult."
            ],
            diagram: .palomar
        ),

        // ── TERMINAL LOOPS ──────────────────────────────────────────

        FlyFishingKnot(
            id: "non-slip-loop",
            name: "Non-Slip Loop",
            altNames: ["Kreh Loop", "Lefty's Loop"],
            category: .terminalLoops,
            connection: "Tippet → Fly (loop) or Line → Line",
            strength: "~90% line strength",
            bestFor: "Streamers · wet flies · any presentation benefiting from free fly movement",
            description: "Popularized by fishing legend Lefty Kreh. Forms a fixed non-slip loop at the hook eye, allowing the fly to move freely and naturally. The loop does not tighten under tension — it stays open, giving the fly a lifelike swimming action.",
            steps: [
                "Make an overhand knot in the line about 10 inches from the end. Leave this knot open (loose).",
                "Pass the tag end through the hook eye and then back through the open overhand knot — entering from the same side it exited.",
                "Wrap the tag end around the standing line 3–5 times. Fewer wraps for heavier line, more for lighter.",
                "Bring the tag end back through the overhand knot, entering from the same side it exited before.",
                "Lubricate and slowly pull the tag end to cinch the wraps loosely together.",
                "Pull the loop and the standing line in opposite directions to seat the knot. The loop should remain open.",
                "Trim the tag end."
            ],
            proTips: [
                "3 turns for 25–60 lb · 4 turns for 10–25 lb · 5 turns for lines under 10 lb.",
                "The loop size is determined by how far from the hook you place the initial overhand knot — adjust to your preference."
            ],
            diagram: .nonSlipLoop
        ),

        FlyFishingKnot(
            id: "perfection-loop",
            name: "Perfection Loop",
            altNames: [],
            category: .terminalLoops,
            connection: "End of leader · Loop-to-loop connection",
            strength: "~95% line strength",
            bestFor: "Leader butt loops · tippet loops · very small loops",
            description: "Strong, reliable, and capable of forming a very small loop — ideal for loop-to-loop leader connections. Can also be used as a terminal knot to the fly. The resulting loop comes straight off the standing line (no angle offset).",
            steps: [
                "Form a loop at the end of the line by passing the tag end behind the standing line. This is Loop A.",
                "Pass the tag end around Loop A to form a second loop (Loop B) in front of Loop A.",
                "Continue the tag end around Loop A and then position it between the two loops.",
                "Drop Loop B and the fly (or whatever is attached) through Loop A from behind.",
                "Hold Loop B and pull it through Loop A smoothly.",
                "Close and seat the knot by pulling Loop B and the standing line in opposite directions.",
                "Trim the tag end."
            ],
            proTips: [
                "The key is step 3 — the tag end must come between the two loops, not around the outside.",
                "This knot ties very neatly straight in line, unlike the Surgeon's Loop which can angle off slightly."
            ],
            diagram: .perfectionLoop
        ),

        FlyFishingKnot(
            id: "surgeons-loop",
            name: "Surgeon's Loop",
            altNames: ["Double Surgeon's Loop", "Triple Surgeon's Loop"],
            category: .terminalLoops,
            connection: "End of leader or tippet",
            strength: "~95–100% line strength",
            bestFor: "Quick loop-to-loop connections · strong reliable loop in any diameter",
            description: "The simplest and fastest loop knot. Excellent strength and easy to tie even in cold or wet conditions. The double version (two passes through the loop) is standard; a triple version adds extra security.",
            steps: [
                "Double the end of the line to form a loop of the desired size.",
                "Make a simple overhand loop — fold the doubled line back on itself to form a loop.",
                "Pass the doubled end (both strands) through the loop once for a Single Surgeon's Loop.",
                "Pass the doubled end through the loop a second time for a Double Surgeon's Loop (recommended).",
                "Pass through a third time for a Triple Surgeon's Loop (added security, slightly bulkier).",
                "Hold the standing line and tag end and pull the loop firmly to tighten the knot.",
                "Trim the tag end."
            ],
            proTips: [
                "Always use the double version — the single version is too weak for consistent use.",
                "Wet the knot thoroughly before seating. The multiple wraps can overheat and weaken if tightened dry."
            ],
            diagram: .surgeonsLoop
        ),

        // ── LEADER TO TIPPET ────────────────────────────────────────

        FlyFishingKnot(
            id: "double-surgeons",
            name: "Double Surgeon's Knot",
            altNames: ["Surgeon's Knot", "Triple Surgeon's Knot"],
            category: .leaderTippet,
            connection: "Leader → Tippet (adding tippet)",
            strength: "~95–100% line strength",
            bestFor: "Joining lines of equal or unequal diameter · joining different materials",
            description: "One of the best and easiest knots for joining two lines. Works for equal or unequal diameters and different materials (mono to fluoro, for example). Simply two overhand knots with the full leader pulled through each time. Must be tightened by pulling all four strands simultaneously.",
            steps: [
                "Lay the leader and tippet on top of each other, overlapping by several inches.",
                "Form a simple loop using both lines together.",
                "Pass both the tag end AND the full leader through the loop. (First pass complete.)",
                "Pass both tag end and full leader through the loop a second time. (This is the Double Surgeon's.)",
                "Optional: pass through a third time for the Triple Surgeon's Knot.",
                "Lubricate the knot thoroughly.",
                "Pull all four ends tight simultaneously to seat the knot properly. Pulling only two strands will not seat it correctly.",
                "Trim both tag ends close."
            ],
            proTips: [
                "The critical step is tightening — pull all four strands at once. Hold the leader and tippet in one hand, the two tag ends in the other, and pull both pairs simultaneously.",
                "When joining lines of very different diameters (more than 2x difference), use a Blood Knot for a smaller profile."
            ],
            diagram: .doubleSurgeons
        ),

        FlyFishingKnot(
            id: "blood-knot",
            name: "Blood Knot",
            altNames: [],
            category: .leaderTippet,
            connection: "Leader → Tippet · Backing → Fly Line · any two lines",
            strength: "~85–95% line strength",
            bestFor: "Lines of similar diameter · slim profile needed · classic fly fishing connection",
            description: "A fly fishing classic. Makes a slim, strong join between two lines of similar diameter. 5–7 wraps on each side. Also useful for connecting backing to fly line or fly line to leader in place of a loop-to-loop connection. Works best when the two lines are within 2x of each other in diameter.",
            steps: [
                "Overlap the ends of the two lines to be joined by 6–8 inches.",
                "Holding the overlap point, wrap one tag end around the other line 5 times, working away from the center.",
                "Bring that tag end back and insert it through the gap between the two lines at the center.",
                "Hold this in place. Now wrap the other tag end around the other line 5 times in the opposite direction.",
                "Insert the second tag end through the center gap in the opposite direction from the first.",
                "Lubricate and slowly pull the two standing lines in opposite directions. The coils will wrap and gather neatly.",
                "Seat the knot with a firm pull. Trim both tag ends close."
            ],
            proTips: [
                "Keep the two lines parallel during tying — don't let them twist around each other.",
                "If the coils cross over each other when tightening, start over. Crossing coils dramatically weaken the knot."
            ],
            diagram: .bloodKnot
        ),

        // ── FLY LINE TO LEADER ──────────────────────────────────────

        FlyFishingKnot(
            id: "loop-to-loop",
            name: "Loop-to-Loop",
            altNames: ["Interlocking Loops"],
            category: .flyLineLeader,
            connection: "Fly Line loop → Leader loop",
            strength: "Exceptionally strong — strength limited by weakest loop",
            bestFor: "Quick leader changes · any loop-to-loop connection",
            description: "Not technically a knot — it's a method of interlocking two pre-formed loops. Exceptionally strong and allows quick leader changes in the field. Most modern fly lines come with a pre-formed loop at the tip. One critical pitfall: avoid a 'girth hitch' where one loop folds back on itself instead of interlocking correctly.",
            steps: [
                "Form a loop at the butt of your leader (Perfection Loop, Surgeon's Loop, etc.).",
                "Slip the leader loop over the fly line loop. Hold the fly line in your left hand.",
                "Run the entire leader through the fly line loop — pass it all the way through.",
                "Pull the lines in opposite directions to lock the loops together.",
                "Check: the loops should join together end-to-end forming a square knot shape. If one loop folds back forming a girth hitch, undo and redo.",
            ],
            proTips: [
                "Always check for a girth hitch — it's the most common mistake and can reduce strength by 50%.",
                "The correct result looks like a chain link — two loops interlocked at 90° to each other."
            ],
            diagram: .loopToLoop
        ),

        FlyFishingKnot(
            id: "nail-knot",
            name: "Nail Knot",
            altNames: [],
            category: .flyLineLeader,
            connection: "Leader butt → Fly Line · Backing → Fly Line",
            strength: "~85–95% line strength",
            bestFor: "Permanent leader-to-fly-line connection · no loop hardware needed",
            description: "A traditional fly fishing knot for attaching leader butt to fly line, or backing to fly line. Creates a smooth, slim connection that slides easily through rod guides. Requires a nail knot tool or a small tube. Uses the tool as a temporary guide for the wraps.",
            steps: [
                "Hold the nail knot tool in your palm. Lay the leader alongside the fly line tip, with 6+ inches extending beyond the tool tip.",
                "Hold the leader and fly line together against the tool with your thumb.",
                "Make 4–5 tight wraps with the leader around the fly line (and tool), working back toward your thumb.",
                "Feed the leader tag end under the coils just made and out through the tip of the tool.",
                "Slide the fly line end into the tip of the tool, under the coils, about ½ inch past the coils.",
                "Hold everything gently and give a quick, firm tug on the leader tag end. The knot slides off the tool onto the fly line.",
                "Tighten the knot firmly by pulling the tag end. Trim the tag end and fly line stub close."
            ],
            proTips: [
                "A tube or hollow needle works in place of a nail knot tool — and is easier to use.",
                "The coils must be tight and neat — loose coils won't grip the fly line properly."
            ],
            diagram: .nailKnot
        ),

        // ── BACKING TO FLY LINE ─────────────────────────────────────

        FlyFishingKnot(
            id: "albright",
            name: "Albright Knot",
            altNames: [],
            category: .backingFlyLine,
            connection: "Backing → Fly Line · joining lines of greatly unequal diameter",
            strength: "~90% line strength",
            bestFor: "Joining monofilament to braided line · very different line diameters",
            description: "One of the most reliable knots for joining lines of very unequal diameters or different materials — monofilament to braided line, backing to fly line. Ten wraps of the lighter line around the heavier line create a strong, slide-resistant connection.",
            steps: [
                "Make a loop in the heavier line (fly line) and run about 10 inches of the lighter line (backing) through the loop.",
                "Hold all three strands between thumb and index finger at the loop.",
                "Wrap the lighter line back over itself and over both strands of the loop — working toward the loop end.",
                "Make 10 tightly packed wraps.",
                "Feed the tag end of the lighter line back through the loop, exiting on the same side it entered.",
                "Hold both ends of the heavier line and slide the wraps toward the end of the loop while pulling the lighter line to tighten.",
                "Trim the tag end close to the knot."
            ],
            proTips: [
                "10 wraps is the standard — fewer wraps reduce strength significantly.",
                "The tag end must exit the loop on the same side it entered. Exiting the opposite side creates a loose knot."
            ],
            diagram: .albright
        ),

        FlyFishingKnot(
            id: "bimini-twist",
            name: "Bimini Twist",
            altNames: [],
            category: .backingFlyLine,
            connection: "Creates a 100% double-line loop at end of backing",
            strength: "100% line strength",
            bestFor: "Big game fly fishing · maximum strength backing loop",
            description: "Considered a 100% knot — when tied correctly it provides full line strength. Creates a double line with a loop at the end, to which a leader can be attached with a loop-to-loop connection. A complex knot best observed in video at animatedknots.com or howtoflyfish.orvis.com before attempting.",
            steps: [
                "Double the line into a loop and make 20 tight twists in the end of the loop.",
                "Slip the open loop over a knee (or both feet for a long loop). Keep constant pressure on both ends of the loop.",
                "Lower the hand holding the tag end until it slips back over the first twist. Open the loop angle to let the tag end roll over the column of twists toward their end.",
                "After rolling to the end of the twists, tie a half hitch (overhand) on the near side of the loop to lock everything in place. Maintain tension.",
                "Secure by making 3–5 half hitches around both loop strands, working from loop end back toward the knot.",
                "Tighten half hitches against the base of the knot. Clip excess tag end to about ¼ inch."
            ],
            proTips: [
                "Watch an animated video of this knot before attempting it — the three-dimensional action is difficult to convey in text.",
                "This is the only knot with 100% line strength. If big game fishing, it's worth learning."
            ],
            diagram: .conceptText("20 twists → roll tag end over column → lock with half hitches")
        ),

        // ── BACKING TO REEL ─────────────────────────────────────────

        FlyFishingKnot(
            id: "arbor",
            name: "Arbor Knot",
            altNames: [],
            category: .backingReel,
            connection: "Backing → Reel arbor",
            strength: "Functional for its purpose",
            bestFor: "Attaching any line to the reel spool",
            description: "A simple two-overhand-knot system for securing backing to the reel arbor. The goal isn't to hold a fish at the bare arbor — it's to have something strong enough to recover the reel if lost overboard, and to prevent the line from slipping on the spool.",
            steps: [
                "Wrap the line around the arbor (the center post of the spool) with the tag end.",
                "Tie a simple overhand knot around the standing part of the line with the tag end.",
                "Tie a second overhand knot in the tag end, 1–2 inches from the first knot.",
                "Pull the standing line to slide the first overhand knot down to the spool.",
                "The second knot jams against the first, preventing it from slipping through.",
                "Trim tag end close. Wind backing onto the reel."
            ],
            proTips: [
                "The Uni Knot (Duncan Knot) can also be used here for a slightly stronger connection.",
                "Wind the backing on under tension to ensure it sits evenly on the spool."
            ],
            diagram: .arbor
        ),

        // ── SPECIALTY ──────────────────────────────────────────────

        FlyFishingKnot(
            id: "haywire-twist",
            name: "Haywire Twist",
            altNames: [],
            category: .specialty,
            connection: "Wire leader → Hook or lure",
            strength: "Strongest wire-to-hook connection available",
            bestFor: "Wire leaders · big game · toothy species",
            description: "Considered the strongest connection for joining wire to a hook. Two distinct phases: haywire wraps (diagonal crossings at 90°+) followed by barrel wraps. It's the combination of both that makes this connection uniquely strong. Always break the wire by rocking — never cut with pliers as this leaves a dangerous sharp burr.",
            steps: [
                "Thread the wire through the hook eye. Hold the loop between finger and thumb.",
                "Cross one strand of wire under the other. Grip both strands and twist simultaneously — the critical part is that both strands cross each other at an angle exceeding 90°.",
                "Make at least 3½ haywire wraps — diagonal crossings at 90°+ angle.",
                "Switch to barrel wraps: push the tag end to a 90° angle from the standing wire. Make 5 barrel wraps around the standing part.",
                "Bend the tag end into a small 'handle' shape and rock it back and forth until the wire breaks at the last barrel wrap.",
                "Never cut the wire with pliers — the resulting burr can cause serious cuts."
            ],
            proTips: [
                "If only one strand is wrapping around the other (not both crossing), you're doing it wrong — the haywire wraps require mutual crossing.",
                "The rocking-to-break technique creates a clean break without a sharp burr. Take your time with it."
            ],
            diagram: .conceptText("Haywire wraps (3.5×) → Barrel wraps (5×) → Rock to break")
        ),

        FlyFishingKnot(
            id: "snell",
            name: "Snell Knot",
            altNames: ["Traditional Snell"],
            category: .specialty,
            connection: "Tippet → Hook (stinger/trailing hook setup)",
            strength: "~95% line strength",
            bestFor: "Tube flies with trailing hooks · provides straight-line pull",
            description: "One of the oldest methods to attach line to a hook. Actually a type of nail knot tied on the hook shank. Provides a reliable straight-line pull when setting the hook — used by fly fishers primarily for attaching stinger or trailing hooks on tube flies.",
            steps: [
                "Pass the tag end through the hook eye, then back through the hook eye a second time in the same direction. This forms a loop below the hook.",
                "Pinch the hook eye and both parts of the tippet together.",
                "Wrap the loop around the hook shank 5–7 times, working toward the hook point.",
                "While holding the wraps in place, slowly and steadily pull the standing line that passes through the eye.",
                "The wraps will slide up and tighten against the hook eye.",
                "When nearly tight, slide the knot up against the hook eye and pull firmly with pliers to fully set.",
                "A hemostat helps significantly when setting this knot."
            ],
            proTips: [
                "A hemostat clamped to the tag end is very helpful for controlling the tension as the knot seats.",
                "This knot provides a much more positive hook set than tying to the eye — the line pulls straight in line with the shank."
            ],
            diagram: .snell
        ),
    ]

    // MARK: Rigging Setups

    static let rigging: [RiggingSetup] = [

        RiggingSetup(
            id: "dropper-rig",
            name: "Dropper Rig",
            description: "The basic dropper rig uses two flies — a top fly and a trailing fly ('dropper') connected by a length of monofilament. The dropper length is typically 1.5× the depth of the water being fished. When the top fly is a dry fly, it's called a 'dry-dropper' and no indicator is needed.",
            components: [
                "Top fly (dry fly, nymph, or wet fly)",
                "Monofilament or fluorocarbon dropper section (length = water depth × 1.5)",
                "Bottom fly (nymph or wet fly)",
                "Strike indicator (if both flies are subsurface)",
            ],
            specs: [
                ("Dropper formula", "Depth (ft) × 1.5 = dropper length (ft)"),
                ("Example", "3 ft deep → 4.5 ft dropper"),
                ("Dry-dropper", "Top fly = dry fly; indicator not needed"),
                ("Double-dropper", "Both subsurface; indicator recommended"),
                ("Tippet ring option", "Attach both droppers to a tippet ring for easy changes"),
            ],
            diagram: .dropperRig
        ),

        RiggingSetup(
            id: "czech-nymphing",
            name: "Czech / Tight-Line Nymphing",
            description: "Tight-line nymphing keeps a taut connection between flies and rod so any hesitation in the drift is immediately felt. No strike indicator — pure contact nymphing. Requires focus and drift control. Czech and Polish styles use longer rods and heavily weighted flies that reach the bottom without a tuck cast.",
            components: [
                "Rod: 10–11 ft, 3–4 weight",
                "Leader: approximately as long as the rod",
                "Sighter: bright colored mono section built into leader",
                "Tippet: 3X–5X",
                "Flies: heavy bead-head nymphs (no split shot needed)",
            ],
            specs: [
                ("Drift length", "Short: 1–20 feet"),
                ("Approach", "Straight up or slightly upstream and across"),
                ("Leader", "Rod-length or shorter"),
                ("Tippet diameter", "3X to 5X"),
                ("Weight", "Heavy bead-head flies; no split shot"),
                ("Indicator", "Colored sighter mono built into leader"),
            ],
            diagram: .nymphRig
        ),

        RiggingSetup(
            id: "george-harvey",
            name: "Harvey / Humphreys Method",
            description: "Developed by George Harvey and Joe Humphreys. Features the 'tuck cast' — a hard stop on the forward cast that tucks flies down into pockets. Often uses split shot and non-weighted flies. Rod is held high to keep line off water. Leader sections or the line/leader connection serve as the indicator.",
            components: [
                "Rod: 9–10 ft",
                "Leader: 8–12 feet",
                "Tippet: 3X–5X",
                "Non-weighted or lightly weighted flies",
                "Split shot for depth",
                "Knotted leader section as indicator",
            ],
            specs: [
                ("Drift length", "Short to medium: 1–30 feet"),
                ("Line on water", "Often lies on top, gets picked up during drift"),
                ("Leader length", "8–12 feet"),
                ("Tippet", "3X–5X"),
                ("Weight", "Split shot plus lightly weighted flies"),
                ("Indicator", "Knotted leader section or line/leader junction"),
            ],
            diagram: .nymphRig
        ),

        RiggingSetup(
            id: "french-nymphing",
            name: "French Nymphing",
            description: "Championship-winning method — France won 6 World Fly Fishing Championships with this technique. Uses a very long leader (18–20 ft) with a curly-Q sighter section. The leader never touches the water (except the tippet). Requires a long, light rod and complete arm elevation. No slack in the system at any time.",
            components: [
                "Rod: 10–12 ft (or longer), 2–4 weight",
                "Leader: 18–20 ft total",
                "20-lb butt section (6 ft)",
                "15-lb mid section (3 ft)",
                "Curly-Q sighter section (2 ft)",
                "5X or 6X tippet (5 ft)",
                "Anchor fly + dropper fly",
            ],
            specs: [
                ("Rod length", "10–12 ft or longer"),
                ("Leader total", "18–20 feet"),
                ("Butt", "6 ft of 20-lb mono"),
                ("Mid section", "3 ft of 15-lb mono"),
                ("Sighter", "2 ft curly-Q (bright mono coiled on a nail/pen tube, boiled 5 min, frozen overnight)"),
                ("Tippet", "5 ft of 5X, size depends on species"),
                ("Arm position", "Extended and elevated throughout drift — leader never touches water"),
            ],
            diagram: .nymphRig
        ),

        RiggingSetup(
            id: "skagit",
            name: "Skagit Rigging",
            description: "Developed on Washington's Skagit River by Ed Ward and Jerry French for swinging flies for steelhead and salmon. Uses a shooting head system designed for heavy flies, winter conditions, and deep presentations. Has evolved into a year-round setup and spread worldwide.",
            components: [
                "Running line: monofilament (dedicated Skagit mono running line)",
                "Swivel (optional, reduces line torque from two-hand casting)",
                "Shooting head: 20–26 ft, grain weight matched to rod and fly size",
                "Sink tip section: matched to desired depth/presentation",
                "Level mono tippet: total leader = 1.5× rod length",
            ],
            specs: [
                ("Running line", "Monofilament (dedicated Skagit mono)"),
                ("Head length", "20–26 feet"),
                ("Grain weight", "Matched to rod, fly size, and species"),
                ("Leader total", "1.5× rod length"),
                ("Leader components", "Sink tip + level monofilament"),
                ("Evolution", "Rods getting shorter and lighter; heads shorter but same grain weight"),
            ],
            diagram: .skagitRig
        ),
    ]

    // MARK: Quick Reference

    static let quickReference: [(useCase: String, knots: [String])] = [
        ("Attach Tippet to a Fly", ["Improved Clinch", "Double Davy", "Palomar", "Uni Knot"]),
        ("Loop-on-Fly for Movement", ["Non-Slip Loop", "Perfection Loop"]),
        ("Add Tippet to Leader", ["Double Surgeon's Knot", "Blood Knot"]),
        ("Fly Line to Leader", ["Loop-to-Loop", "Nail Knot", "Knotless Connection"]),
        ("Backing to Fly Line", ["Albright Knot", "Bimini Twist"]),
        ("Backing to Reel", ["Arbor Knot"]),
        ("Join Similar Diameter Lines", ["Blood Knot", "Double Surgeon's Knot"]),
        ("Join Dissimilar Diameter Lines", ["Albright Knot", "Nail Knot", "Surgeon's Knot"]),
        ("Wire Leader", ["Haywire Twist"]),
        ("Make a Loop", ["Perfection Loop", "Surgeon's Loop", "Non-Slip Loop"]),
        ("Trailing Hook / Tube Fly", ["Snell Knot"]),
    ]
}
